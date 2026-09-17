"""pipeline.py against a fake ComfyUI server: queueing, a rejected prompt, polling, downloading, and ffmpeg."""
import io
import json
import math
import os
import shutil
import sys
import tempfile
import threading
import unittest
import wave
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from types import SimpleNamespace
from urllib.parse import parse_qs, urlparse

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE))
import pipeline  # noqa: E402


def sine_wav(seconds=5.0, rate=44100, amplitude=0.1):
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(b"".join(int(amplitude * 32767 * math.sin(2 * math.pi * 440 * i / rate)).to_bytes(2, "little", signed=True)
                               for i in range(int(seconds * rate))))
    return buffer.getvalue()


class FakeComfy(BaseHTTPRequestHandler):
    """Answers like ComfyUI 0.36.0: /prompt, then /history empty twice, then a finished entry, and /view."""
    state = {}

    def log_message(self, *args):
        pass

    def _json(self, code, body):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        prompt = body["prompt"]
        if "99" in prompt:
            return self._json(400, {"error": {"type": "prompt_outputs_failed_validation", "message": "Prompt outputs failed validation"},
                                    "node_errors": {"99": {"class_type": "KSampler", "errors": [
                                        {"message": "Value not in list", "details": "sampler_name: 'nope' not in [...]"}]}}})
        self.state["prompt"] = body
        self.state["polls"] = 0
        self._json(200, {"prompt_id": body["prompt_id"], "number": 0, "node_errors": {}})

    def do_GET(self):
        url = urlparse(self.path)
        if url.path.startswith("/history/"):
            prompt_id = url.path.rsplit("/", 1)[1]
            self.state["polls"] += 1
            if self.state["polls"] < 3:
                return self._json(200, {})
            return self._json(200, {prompt_id: {
                "status": {"status_str": "success", "completed": True, "messages": [["execution_start", {}], ["execution_success", {}]]},
                "outputs": {"10": {"audio": [{"filename": "ace_00001.flac", "subfolder": "l15", "type": "output"}]}}}})
        if url.path == "/view":
            query = parse_qs(url.query)
            assert query["filename"] == ["ace_00001.flac"] and query["subfolder"] == ["l15"] and query["type"] == ["output"]
            data = self.state["wav"]
            self.send_response(200)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        self._json(404, {})


class PipelineTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        FakeComfy.state = {"wav": sine_wav()}
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), FakeComfy)
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.url = f"http://127.0.0.1:{cls.server.server_address[1]}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()

    def args(self, workflow, out, sets=(), bitrate=""):
        return SimpleNamespace(server=self.url, workflow=str(workflow), set=list(sets), out=str(out), lufs=-16.0,
                               bitrate=bitrate, timeout=10, poll=0.01)

    def test_parse_set(self):
        self.assertEqual(pipeline.parse_set("5.seed=42"), ("5", "seed", 42))
        self.assertEqual(pipeline.parse_set("5.tags=acoustic guitar, warm"), ("5", "tags", "acoustic guitar, warm"))
        self.assertEqual(pipeline.parse_set("5.generate_audio_codes=false"), ("5", "generate_audio_codes", False))
        self.assertEqual(pipeline.parse_set('5.keyscale="C major"'), ("5", "keyscale", "C major"))
        with self.assertRaises(ValueError):
            pipeline.parse_set("seed=42")

    def test_run_downloads_the_saved_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "out"
            lines = []
            code = pipeline.run(self.args(HERE / "workflows" / "15-ace-step.api.json", out, ["5.seed=7", "8.seed=7"]), lines.append)
            self.assertEqual(code, 0)
            sent = FakeComfy.state["prompt"]
            self.assertEqual(sent["prompt"]["5"]["inputs"]["seed"], 7)
            self.assertRegex(sent["prompt_id"], r"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
            self.assertEqual((out / "ace_00001.flac").read_bytes(), FakeComfy.state["wav"])
            self.assertEqual(lines[0], "queued")
            self.assertRegex(lines[1], r"^success after \d+\.\d s$")
            self.assertTrue(lines[2].startswith("node 10: l15/ace_00001.flac -> "))

    def test_rejected_prompt_prints_node_errors(self):
        with tempfile.TemporaryDirectory() as tmp:
            workflow = Path(tmp) / "bad.api.json"
            workflow.write_text(json.dumps({"99": {"class_type": "KSampler", "inputs": {}}}))
            lines = []
            self.assertEqual(pipeline.run(self.args(workflow, Path(tmp) / "out"), lines.append), 2)
            self.assertEqual(lines, ["rejected: Prompt outputs failed validation",
                                     "  node 99 (KSampler): Value not in list: sampler_name: 'nope' not in [...]"])

    def test_unknown_node_in_set(self):
        with self.assertRaises(ValueError):
            pipeline.apply_sets({"1": {"inputs": {}}}, ["2.seed=1"])

    @unittest.skipIf(not (os.environ.get("FFMPEG") or shutil.which("ffmpeg")), "no ffmpeg")
    def test_encode_normalizes_to_minus_16_lufs(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "quiet.wav"
            source.write_bytes(sine_wav(amplitude=0.05))
            before, after = pipeline.encode(source, Path(tmp) / "quiet.opus", lufs=-16.0, bitrate="64k")
            self.assertLess(before, -25.0)
            self.assertAlmostEqual(after, -16.0, delta=1.0)
            self.assertGreater((Path(tmp) / "quiet.opus").stat().st_size, 1000)


if __name__ == "__main__":
    unittest.main()
