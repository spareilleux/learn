"""The runner on a workflow that saves .glb files, against the fake server: hashes, counts, copies, licence gate."""
import contextlib
import io
import json
import os
import shutil
import tempfile
import unittest

from runner.__main__ import main
from runner.experiment import sha256_file
from tests.fake_server import FakeComfy

WORKFLOW = {
    "1": {"class_type": "ImageOnlyCheckpointLoader", "inputs": {"ckpt_name": "tiny3d.safetensors"}},
    "2": {"class_type": "LoadImage", "inputs": {"image": "placeholder.png"}},
    "3": {"class_type": "KSampler", "inputs": {"seed": 0, "steps": 3, "cfg": 5.0, "model": ["1", 0]}},
    "9": {"class_type": "SaveGLB", "inputs": {"mesh": ["3", 0], "filename_prefix": "3d/galab"}},
}


class Runner3DTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="galab-3d-test-")
        self.models = os.path.join(self.tmp, "models")
        os.makedirs(os.path.join(self.models, "checkpoints"))
        with open(os.path.join(self.models, "checkpoints", "tiny3d.safetensors"), "wb") as f:
            f.write(b"\x01" * 2048)
        with open(os.path.join(self.tmp, "wf.api.json"), "w") as f:
            json.dump(WORKFLOW, f)
        self.experiment = os.path.join(self.tmp, "exp.json")
        with open(self.experiment, "w") as f:
            json.dump({
                "id": "t-3d", "title": "test meshes", "written": "2026-09-16", "hypothesis": "h", "prediction": "p",
                "workflow": "wf.api.json", "seeds": [1, 2], "seed_paths": ["3.seed"],
                "axes": [{"name": "steps", "path": "3.steps", "values": [3]}],
                "analysis": [{"kind": "mesh", "node": "9", "object_axis": "steps",
                              "reference": {"3": [1.0, 0.5, 0.2]}}],
                "licences": [{"id": "tiny-community", "name": "Tiny 3D Community Licence",
                              "url": "https://example.invalid/licence", "models": ["tiny3d.safetensors"]}],
            }, f)
        self.out = os.path.join(self.tmp, "out")
        self.meshes = os.path.join(self.tmp, "learn-lab", "comfyui", "3d", "t-3d")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def run_cli(self, url, *extra):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = main(["run", self.experiment, "--server", url, "--models-dir", self.models, "--out", self.out,
                         "--meshes", self.meshes, "--poll-interval", "0.05", "--free-wait", "0", *extra])
        return code, buf.getvalue()

    def results(self):
        with open(os.path.join(self.out, "results.json"), encoding="utf-8") as f:
            return json.load(f)

    def test_licence_not_accepted_submits_nothing(self):
        with FakeComfy(models={"checkpoints": ["tiny3d.safetensors"]}) as server:
            code, log = self.run_cli(server.url)
        self.assertEqual(code, 0, log)
        self.assertEqual(server.prompts, [])
        r = self.results()
        self.assertEqual([i["status"] for i in r["items"]], ["could_not_run"] * 2)
        self.assertIn("--accept-licence tiny-community", r["items"][0]["error"])
        self.assertEqual(r["licences"][0]["id"], "tiny-community")
        self.assertFalse(os.path.exists(self.meshes))

    def test_glb_outputs_measured_and_kept_outside_the_results(self):
        with FakeComfy(models={"checkpoints": ["tiny3d.safetensors"]}) as server:
            code, log = self.run_cli(server.url, "--accept-licence", "tiny-community")
        self.assertEqual(code, 0, log)
        self.assertEqual(len(server.prompts), 2)
        r = self.results()
        self.assertEqual(r["runs"][-1]["accepted_licences"], ["tiny-community"])
        closed, opened = (i["outputs"][0] for i in r["items"])  # seed 1: closed box, seed 2: no top face
        for out in (closed, opened):
            path = out["file"]
            self.assertTrue(os.path.isabs(path) and os.path.isfile(path), path)
            self.assertEqual(os.path.dirname(os.path.abspath(path)), os.path.abspath(self.meshes))
            self.assertEqual(sha256_file(path), out["sha256"])
            self.assertEqual(out["subfolder"], "3d")
            self.assertTrue(os.path.isfile(os.path.join(self.out, out["thumb"])))
        self.assertEqual((closed["glb"]["triangles"], closed["glb"]["vertices"]), (12, 8))
        self.assertTrue(closed["glb"]["topology"]["watertight"])
        self.assertEqual(closed["glb"]["bbox"]["sorted_ratios"], [1.0, 0.5, 0.25])
        self.assertEqual(closed["glb"]["materials"], 1)
        self.assertEqual(opened["glb"]["triangles"], 10)
        self.assertEqual(opened["glb"]["topology"]["boundary_edges"], 4)
        self.assertFalse(opened["glb"]["topology"]["watertight"])
        self.assertFalse(any(name.endswith(".glb") for _, _, files in os.walk(self.out) for name in files))
        self.assertTrue(os.path.isfile(os.path.join(self.out, "sheet.webp")))
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(main(["analyze", self.experiment, "--out", self.out]), 0)
        with open(os.path.join(self.out, "analysis.json"), encoding="utf-8") as f:
            entry = json.load(f)["analyses"][0]
        self.assertEqual(entry["summary"]["meshes"], 2)
        self.assertEqual(entry["summary"]["watertight"], 1)
        self.assertEqual([row["boundary_edges"] for row in entry["rows"]], [0, 4])
        self.assertEqual(entry["rows"][0]["ratio_differences"], [0.0, 0.0, 0.05])

    def test_outputs_located_in_a_local_output_folder(self):
        local = os.path.join(self.tmp, "comfy-output")
        with FakeComfy(models={"checkpoints": ["tiny3d.safetensors"]}) as server:
            code, log = self.run_cli(server.url, "--accept-licence", "tiny-community", "--comfyui-output", local)
        self.assertEqual(code, 0, log)
        self.assertEqual({o["fetched"] for i in self.results()["items"] for o in i["outputs"]}, {"downloaded"})
        # A new fake server writes the same names and bytes; put them where a local server would have saved them.
        os.makedirs(os.path.join(local, "3d"))
        for name, data in server.files.items():
            with open(os.path.join(local, "3d", name), "wb") as f:
                f.write(data)
        shutil.rmtree(self.out)
        with FakeComfy(models={"checkpoints": ["tiny3d.safetensors"]}) as again:
            code, log = self.run_cli(again.url, "--accept-licence", "tiny-community", "--comfyui-output", local)
        self.assertEqual(code, 0, log)
        self.assertEqual({o["fetched"] for i in self.results()["items"] for o in i["outputs"]}, {"located"})


if __name__ == "__main__":
    unittest.main()
