"""HTTP calls to a ComfyUI server, on urllib. Every network failure becomes ServerDown."""
import http.client
import json
import os
import socket
import urllib.error
import urllib.parse
import urllib.request
import uuid


class ServerDown(Exception):
    pass


class PromptRejected(Exception):
    def __init__(self, body):
        super().__init__(json.dumps(body)[:2000])
        self.body = body


class Comfy:
    def __init__(self, base_url, timeout=30.0):
        self.base = base_url.rstrip("/")
        self.timeout = timeout

    def _open(self, request):
        try:
            return urllib.request.urlopen(request, timeout=self.timeout)
        except urllib.error.HTTPError:
            raise
        except (urllib.error.URLError, ConnectionError, http.client.HTTPException, socket.timeout, OSError) as e:
            raise ServerDown(f"{request.full_url}: {e}") from e

    def _read(self, request):
        with self._open(request) as r:
            try:
                return r.read()
            except (ConnectionError, http.client.HTTPException, socket.timeout, OSError) as e:
                raise ServerDown(f"{request.full_url}: {e}") from e

    def get_json(self, path):
        return json.loads(self._read(urllib.request.Request(self.base + path)))

    def get_bytes(self, path):
        return self._read(urllib.request.Request(self.base + path))

    def post_json(self, path, body):
        data = json.dumps(body).encode()
        req = urllib.request.Request(self.base + path, data=data, headers={"Content-Type": "application/json"})
        try:
            raw = self._read(req)
        except urllib.error.HTTPError as e:
            text = e.read()
            try:
                parsed = json.loads(text)
            except ValueError:
                parsed = {"status": e.code, "body": text.decode("utf-8", "replace")}
            raise PromptRejected(parsed) from e
        return json.loads(raw) if raw.strip() else {}

    def system_stats(self):
        return self.get_json("/system_stats")

    def models(self, folder):
        try:
            return self.get_json("/models/" + urllib.parse.quote(folder))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            raise

    def submit(self, prompt, client_id, prompt_id):
        return self.post_json("/prompt", {"prompt": prompt, "client_id": client_id, "prompt_id": prompt_id})

    def history(self, prompt_id):
        return self.get_json("/history/" + urllib.parse.quote(prompt_id)).get(prompt_id)

    def view(self, filename, subfolder, kind):
        query = urllib.parse.urlencode({"filename": filename, "subfolder": subfolder, "type": kind})
        return self.get_bytes("/view?" + query)

    def free(self):
        self.post_json("/free", {"unload_models": True, "free_memory": True})

    def upload_image(self, path, name):
        """POST /upload/image with overwrite, so the same name always holds the same bytes."""
        boundary = uuid.uuid4().hex
        with open(path, "rb") as f:
            content = f.read()
        parts = [
            f'--{boundary}\r\nContent-Disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n'.encode(),
            f'--{boundary}\r\nContent-Disposition: form-data; name="type"\r\n\r\ninput\r\n'.encode(),
            f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{name}"\r\n'
            f"Content-Type: image/png\r\n\r\n".encode() + content + b"\r\n",
            f"--{boundary}--\r\n".encode(),
        ]
        req = urllib.request.Request(self.base + "/upload/image", data=b"".join(parts),
                                     headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
        try:
            body = json.loads(self._read(req))
        except urllib.error.HTTPError as e:
            raise PromptRejected({"upload": os.path.basename(path), "status": e.code}) from e
        return body["name"] if not body.get("subfolder") else body["subfolder"] + "/" + body["name"]

    def ws_url(self, client_id):
        parts = urllib.parse.urlsplit(self.base)
        scheme = "wss" if parts.scheme == "https" else "ws"
        return f"{scheme}://{parts.netloc}/ws?clientId={client_id}"
