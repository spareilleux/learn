"""The runner against the fake server: success, server down mid-run, memory rule refusal, resume, no server."""
import contextlib
import io
import json
import os
import shutil
import socket
import tempfile
import unittest

from PIL import Image

from runner.__main__ import main
from tests.fake_server import GIB, FakeComfy

WORKFLOW = {
    "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "tiny.safetensors"}},
    "6": {"class_type": "CLIPTextEncode", "inputs": {"text": "a guitar neck", "clip": ["4", 1]}},
    "10": {"class_type": "LoadImage", "inputs": {"image": "placeholder.png"}},
    "3": {"class_type": "KSampler", "inputs": {"seed": 0, "steps": 4, "cfg": 7.0, "model": ["4", 0], "positive": ["6", 0]}},
    "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": "test/neck", "images": ["3", 0]}},
}


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class RunnerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="galab-test-")
        self.models = os.path.join(self.tmp, "models")
        os.makedirs(os.path.join(self.models, "checkpoints"))
        with open(os.path.join(self.models, "checkpoints", "tiny.safetensors"), "wb") as f:
            f.write(b"\x00" * 1024)
        with open(os.path.join(self.tmp, "wf.api.json"), "w") as f:
            json.dump(WORKFLOW, f)
        Image.new("RGB", (8, 8), (200, 10, 10)).save(os.path.join(self.tmp, "input.png"))
        self.experiment = os.path.join(self.tmp, "exp.json")
        with open(self.experiment, "w") as f:
            json.dump({
                "id": "t-grid", "title": "test grid", "written": "2026-09-16",
                "hypothesis": "h", "prediction": "p", "workflow": "wf.api.json",
                "seeds": [1, 2], "seed_paths": ["3.seed"],
                "fixed": {"10.image": {"input": "photo"}},
                "prepare": [{"name": "photo", "kind": "file", "src": "input.png"}],
                "axes": [{"name": "cfg", "path": "3.cfg", "values": [4.0, 7.0]}],
            }, f)
        self.out = os.path.join(self.tmp, "out")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def run_cli(self, url, *extra):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = main(["run", self.experiment, "--server", url, "--models-dir", self.models, "--out", self.out,
                         "--poll-interval", "0.05", "--free-wait", "0", *extra])
        return code, buf.getvalue()

    def results(self):
        with open(os.path.join(self.out, "results.json"), encoding="utf-8") as f:
            return json.load(f)

    def test_success_records_everything(self):
        with FakeComfy(models={"checkpoints": ["tiny.safetensors"]}) as server:
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 0, log)
        self.assertEqual(len(server.prompts), 4)
        r = self.results()
        self.assertEqual(r["server"]["comfyui_version"], "0.36.0")
        self.assertEqual(r["server"]["comfyui_commit"], "ee71d5c4993f29086b27fde1629a945ae48425bf")
        self.assertEqual([i["status"] for i in r["items"]], ["done"] * 4)
        item = r["items"][0]
        self.assertEqual(item["models"][0]["name"], "tiny.safetensors")
        self.assertEqual(item["models"][0]["bytes"], 1024)
        self.assertEqual(item["models"][0]["sha256"], "5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef")
        self.assertEqual(item["seed"], 1)
        self.assertEqual(item["params"]["3.cfg"], 4.0)
        self.assertGreater(item["wall_time_s"], 0)
        self.assertGreaterEqual(item["memory"]["samples"], 1)
        # 2 GB used before the prompt, 5 GB while the fake server "executes": a slow machine may miss that window
        self.assertIn(item["memory"]["peak_vram_used_bytes"], (2 * GIB, 5 * GIB))
        self.assertEqual(max(i["memory"]["peak_vram_used_bytes"] for i in r["items"]), 5 * GIB)
        self.assertEqual(item["steps_seen"], 4)
        out = item["outputs"][0]
        self.assertTrue(os.path.isfile(os.path.join(self.out, out["thumb"])))
        for path in (os.path.join(self.out, out["thumb"]), os.path.join(self.out, "sheet.webp")):
            with Image.open(path) as image:
                self.assertEqual(image.format, "WEBP")
        # The prepared input was uploaded once and the prompt names it by content hash.
        self.assertEqual(len(server.uploads), 1)
        self.assertTrue(server.prompts[0]["prompt"]["10"]["inputs"]["image"].startswith("galab-"))
        # Every submitted prompt carries the item's seed, and the item keys differ.
        self.assertEqual([p["prompt"]["3"]["inputs"]["seed"] for p in server.prompts], [1, 2, 1, 2])
        self.assertEqual(len({i["key"] for i in r["items"]}), 4)

    def test_server_down_mid_run_then_resume(self):
        port = free_port()
        server = FakeComfy(port=port, models={"checkpoints": ["tiny.safetensors"]}, die_on_prompt=3)
        with server:
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 3, log)
        self.assertIn("server went away", log)
        states = [i["status"] for i in self.results()["items"]]
        self.assertEqual(states, ["done", "done", "interrupted", "pending"])
        with FakeComfy(port=port, models={"checkpoints": ["tiny.safetensors"]}) as again:
            code, log = self.run_cli(again.url)
        self.assertEqual(code, 0, log)
        self.assertEqual(len(again.prompts), 2)  # only the two items not done
        self.assertIn("resuming: 2 item(s) already done", log)
        self.assertEqual([i["status"] for i in self.results()["items"]], ["done"] * 4)
        self.assertEqual(len(self.results()["runs"]), 2)

    def test_memory_rule_refuses_before_submitting(self):
        with FakeComfy(ram_free=6 * GIB, models={"checkpoints": ["tiny.safetensors"]}) as server:
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 4, log)
        self.assertEqual(server.prompts, [])
        first = self.results()["items"][0]
        self.assertEqual(first["status"], "could_not_run")
        self.assertIn("memory rule", first["error"])
        self.assertIn("6.00 GB of free RAM", first["error"])

    def test_vram_floor(self):
        with FakeComfy(vram_free=4 * GIB, models={"checkpoints": ["tiny.safetensors"]}) as server:
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 4, log)
        self.assertIn("free VRAM", self.results()["items"][0]["error"])

    def test_resume_skips_done_items(self):
        with FakeComfy(models={"checkpoints": ["tiny.safetensors"]}) as server:
            self.assertEqual(self.run_cli(server.url)[0], 0)
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 0, log)
        self.assertEqual(len(server.prompts), 4)
        self.assertIn("4 item(s) already done", log)

    def test_changed_parameter_is_a_new_item(self):
        with FakeComfy(models={"checkpoints": ["tiny.safetensors"]}) as server:
            self.assertEqual(self.run_cli(server.url)[0], 0)
            with open(self.experiment) as f:
                data = json.load(f)
            data["axes"][0]["values"] = [4.0, 8.0]
            with open(self.experiment, "w") as f:
                json.dump(data, f)
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 0, log)
        self.assertEqual(len(server.prompts), 6)  # cfg 8.0 with two seeds

    def test_missing_model_is_recorded_not_submitted(self):
        with FakeComfy(models={"checkpoints": ["other.safetensors"]}) as server:
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 0, log)
        self.assertEqual(server.prompts, [])
        self.assertTrue(all(i["status"] == "could_not_run" for i in self.results()["items"]))
        self.assertIn("on the server", self.results()["items"][0]["error"])

    def test_execution_error_marks_item_failed(self):
        with FakeComfy(models={"checkpoints": ["tiny.safetensors"]}, fail_on_prompt=2) as server:
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 5, log)
        self.assertEqual([i["status"] for i in self.results()["items"]], ["done", "failed", "done", "done"])
        self.assertIn("fake failure", self.results()["items"][1]["error"])

    def test_no_server_is_never_started(self):
        code, log = self.run_cli(f"http://127.0.0.1:{free_port()}")
        self.assertEqual(code, 3)
        self.assertIn("never starts one", log)
        self.assertFalse(os.path.exists(os.path.join(self.out, "results.json")))


if __name__ == "__main__":
    unittest.main()
