"""A fake ComfyUI server for the runner's tests: no GPU, no model, no torch.

It speaks the routes and messages the runner uses, in the shapes ComfyUI v0.36.0 sends them (server.py,
execution.py): GET /system_stats, /models/{folder}, /history/{id}, /view, POST /prompt, /upload/image, /free, and
the /ws WebSocket with status, execution_start, execution_cached, executing, progress, executed, execution_success.
"Executing" a prompt draws a small PNG per SaveImage node whose color comes from the prompt's seed, so the same
prompt gives the same bytes. Test knobs: ram_free, vram_free, die_on_prompt (shut down in the middle of the n-th
prompt, 1-based), fail_on_prompt (send execution_error), models (per folder).
"""
import base64
import hashlib
import io
import json
import struct
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

from PIL import Image

GIB = 1024 ** 3


class FakeComfy:
    def __init__(self, port=0, ram_free=40 * GIB, vram_free=14 * GIB, models=None, die_on_prompt=None,
                 fail_on_prompt=None, step_delay=0.02):
        self.ram_free, self.vram_free = ram_free, vram_free
        self.models = models or {}
        self.die_on_prompt, self.fail_on_prompt = die_on_prompt, fail_on_prompt
        self.step_delay = step_delay
        self.prompts, self.history, self.files, self.uploads = [], {}, {}, {}
        self.freed = 0
        self.sockets, self.lock = [], threading.Lock()
        self.executing = False
        fake = self

        class Handler(BaseHTTPRequestHandler):
            protocol_version = "HTTP/1.1"

            def log_message(self, *args):
                pass

            def _json(self, body, status=200):
                data = json.dumps(body).encode()
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)

            def do_GET(self):
                url = urlsplit(self.path)
                if url.path == "/ws":
                    return fake._websocket(self)
                if url.path == "/system_stats":
                    busy = fake.executing
                    return self._json({
                        "system": {"os": "fake", "ram_total": 64 * GIB, "ram_free": fake.ram_free - (2 * GIB if busy else 0),
                                   "comfyui_version": "0.36.0", "python_version": "3.13.0 (fake)",
                                   "pytorch_version": "0.0.0+fake", "embedded_python": False, "argv": ["main.py"]},
                        "devices": [{"name": "cuda:0 Fake GPU", "type": "cuda", "index": 0, "vram_total": 16 * GIB,
                                     "vram_free": fake.vram_free - (3 * GIB if busy else 0),
                                     "torch_vram_total": 0, "torch_vram_free": 0}]})
                if url.path.startswith("/models/"):
                    folder = url.path[len("/models/"):]
                    if folder not in fake.models:
                        self.send_response(404)
                        self.send_header("Content-Length", "0")
                        self.end_headers()
                        return
                    return self._json(fake.models[folder])
                if url.path.startswith("/history/"):
                    pid = url.path[len("/history/"):]
                    return self._json({pid: fake.history[pid]} if pid in fake.history else {})
                if url.path == "/view":
                    q = parse_qs(url.query)
                    data = fake.files.get(q["filename"][0])
                    if data is None:
                        self.send_response(404)
                        self.send_header("Content-Length", "0")
                        self.end_headers()
                        return
                    self.send_response(200)
                    self.send_header("Content-Type", "image/png")
                    self.send_header("Content-Length", str(len(data)))
                    self.end_headers()
                    self.wfile.write(data)
                    return
                self._json({"error": "not found"}, 404)

            def do_POST(self):
                length = int(self.headers.get("Content-Length") or 0)
                body = self.rfile.read(length)
                url = urlsplit(self.path)
                if url.path == "/prompt":
                    request = json.loads(body)
                    prompt = request.get("prompt")
                    if not isinstance(prompt, dict) or not any(n.get("class_type") == "SaveImage" for n in prompt.values()):
                        return self._json({"error": {"type": "prompt_no_outputs", "message": "Prompt has no outputs"},
                                           "node_errors": {}}, 400)
                    pid = request.get("prompt_id") or str(uuid.uuid4())
                    fake.prompts.append(request)
                    number = len(fake.prompts)
                    self._json({"prompt_id": pid, "number": number, "node_errors": {}})
                    threading.Thread(target=fake._execute, args=(pid, prompt, number), daemon=True).start()
                    return
                if url.path == "/upload/image":
                    marker = b'filename="'
                    start = body.index(marker) + len(marker)
                    name = body[start:body.index(b'"', start)].decode()
                    fake.uploads[name] = hashlib.sha256(body).hexdigest()
                    return self._json({"name": name, "subfolder": "", "type": "input"})
                if url.path == "/free":
                    fake.freed += 1
                    self.send_response(200)
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                    return
                self._json({"error": "not found"}, 404)

        self.httpd = ThreadingHTTPServer(("127.0.0.1", port), Handler)
        self.httpd.daemon_threads = True
        self.port = self.httpd.server_address[1]
        self.url = f"http://127.0.0.1:{self.port}"
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *exc):
        self.stop()

    def stop(self):
        try:
            self.httpd.shutdown()
        except Exception:
            pass
        self.httpd.server_close()
        with self.lock:
            for s in self.sockets:
                try:
                    s.close()
                except OSError:
                    pass
            self.sockets.clear()

    # ---------- websocket ----------
    def _websocket(self, handler):
        key = handler.headers["Sec-WebSocket-Key"]
        accept = base64.b64encode(hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest()).decode()
        handler.send_response(101, "Switching Protocols")
        handler.send_header("Upgrade", "websocket")
        handler.send_header("Connection", "Upgrade")
        handler.send_header("Sec-WebSocket-Accept", accept)
        handler.end_headers()
        handler.wfile.flush()
        sock = handler.connection
        with self.lock:
            self.sockets.append(sock)
        sid = parse_qs(urlsplit(handler.path).query).get("clientId", [uuid.uuid4().hex])[0]
        self._send(sock, {"type": "status", "data": {"status": {"exec_info": {"queue_remaining": 0}}, "sid": sid}})
        # A binary preview frame, as ComfyUI sends during sampling: the client must skip it.
        self._send_raw(sock, 0x2, struct.pack(">I", 1) + b"\x89PNG fake preview")
        try:
            while True:
                data = sock.recv(4096)
                if not data:
                    break
        except OSError:
            pass
        handler.close_connection = True

    def _send_raw(self, sock, opcode, payload):
        n = len(payload)
        header = bytes([0x80 | opcode]) + (bytes([n]) if n < 126 else bytes([126]) + struct.pack(">H", n))
        with self.lock:
            sock.sendall(header + payload)

    def _send(self, sock, message):
        try:
            self._send_raw(sock, 0x1, json.dumps(message).encode())
        except OSError:
            pass

    def _broadcast(self, message):
        for s in list(self.sockets):
            self._send(s, message)

    # ---------- execution ----------
    def _execute(self, pid, prompt, number):
        time.sleep(0.05)
        self.executing = True
        self._broadcast({"type": "execution_start", "data": {"prompt_id": pid, "timestamp": int(time.time() * 1000)}})
        self._broadcast({"type": "execution_cached", "data": {"nodes": [], "prompt_id": pid, "timestamp": 0}})
        outputs = {}
        seed = next((n["inputs"]["seed"] for n in prompt.values() if "seed" in n.get("inputs", {})), 0)
        for node_id, node in prompt.items():
            self._broadcast({"type": "executing", "data": {"node": node_id, "display_node": node_id, "prompt_id": pid}})
            if node.get("class_type") == "KSampler":
                steps = int(node["inputs"].get("steps", 4))
                for step in range(1, steps + 1):
                    time.sleep(self.step_delay)
                    if self.die_on_prompt == number and step == 2:
                        self.executing = False
                        threading.Thread(target=self.stop, daemon=True).start()
                        return
                    self._broadcast({"type": "progress", "data": {"value": step, "max": steps, "prompt_id": pid, "node": node_id}})
            if self.fail_on_prompt == number:
                self.history[pid] = {"prompt": [number, pid, prompt, {}, []], "outputs": {},
                                     "status": {"status_str": "error", "completed": False, "messages": []}}
                self._broadcast({"type": "execution_error", "data": {
                    "prompt_id": pid, "node_id": node_id, "node_type": node["class_type"], "executed": [],
                    "exception_message": "fake failure", "exception_type": "RuntimeError", "traceback": []}})
                self.executing = False
                return
            if node.get("class_type") == "SaveImage":
                color = tuple((seed * k) % 256 for k in (37, 91, 173))
                buf = io.BytesIO()
                Image.new("RGB", (64, 48), color).save(buf, "PNG")
                name = f"{node['inputs'].get('filename_prefix', 'ComfyUI')}_{len(self.files) + 1:05}_.png".replace("/", "_")
                self.files[name] = buf.getvalue()
                outputs[node_id] = {"images": [{"filename": name, "subfolder": "", "type": "output"}]}
                self._broadcast({"type": "executed", "data": {"node": node_id, "display_node": node_id,
                                                              "output": outputs[node_id], "prompt_id": pid}})
            if node.get("class_type") == "PreviewAny":
                outputs[node_id] = {"text": ["fake text"]}
        self.history[pid] = {"prompt": [number, pid, prompt, {}, list(outputs)], "outputs": outputs,
                             "status": {"status_str": "success", "completed": True, "messages": []}, "meta": {}}
        self.executing = False
        self._broadcast({"type": "execution_success", "data": {"prompt_id": pid, "timestamp": int(time.time() * 1000)}})
        self._broadcast({"type": "executing", "data": {"node": None, "display_node": None, "prompt_id": pid}})
