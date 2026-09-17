"""Every experiment file: its written hypothesis and prediction, 10 to 20 items, and workflows its paths fit.

With COMFYUI_DIR set to a ComfyUI checkout (v0.36.0), every class_type and input name of the lab's workflows is
also checked against ComfyUI's source and the GA node pack's (tests/node_schema.py).
"""
import glob
import json
import os
import re
import unittest

from runner.experiment import Experiment, apply_sets
from runner.models import referenced_models
from tests.node_schema import schemas

LAB = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPERIMENTS = sorted(glob.glob(os.path.join(LAB, "experiments", "*.yaml")))
WORKFLOWS = sorted(glob.glob(os.path.join(LAB, "workflows", "*.api.json")))
GA_NODES = os.path.join(LAB, "..", "custom-nodes", "ga")
# Models the course uses (lessons 1 to 8) or that an experiment names as planned and not downloaded.
COURSE_MODELS = {
    "sd_xl_base_1.0.safetensors", "xinsir_controlnet_union_sdxl_promax.safetensors",
    "sdxl_inpainting_0.1_unet_fp16.safetensors", "pixel-art-xl.safetensors", "z_image_turbo_bf16.safetensors",
    "z_image_turbo_int8_convrot.safetensors", "z_image_turbo_nvfp4.safetensors", "qwen_3_4b.safetensors",
    "qwen_3_4b_fp8_mixed.safetensors", "z_image_ae.safetensors",
}
PLANNED = {"RealESRGAN_x4plus.pth": "09-diagram-upscale", "wan2.2_ti2v_5B_fp16.safetensors": "10-neck-video",
           "umt5_xxl_fp8_e4m3fn_scaled.safetensors": "10-neck-video", "wan2.2_vae.safetensors": "10-neck-video",
           # downloaded by the Atlas lane (G:/comfyui/models/checkpoints), under a licence the run must accept
           "hunyuan3d-dit-v2_fp16.safetensors": "11-image-to-3d"}


class ExperimentFilesTest(unittest.TestCase):
    def test_eleven_experiments_numbered(self):
        names = [os.path.basename(p) for p in EXPERIMENTS]
        self.assertEqual(len(names), 11)
        self.assertEqual([n[:2] for n in names], [f"{i:02}" for i in range(1, 12)])

    def test_each_experiment(self):
        for path in EXPERIMENTS:
            with self.subTest(os.path.basename(path)):
                exp = Experiment(path)
                self.assertEqual(exp.id, os.path.basename(path)[:-5])
                self.assertRegex(str(exp.data["written"]), r"^\d{4}-\d{2}-\d{2}$")
                self.assertGreater(len(exp.data["hypothesis"]), 150)
                self.assertIn("Written before any run", exp.data["prediction"])
                self.assertTrue(re.search(r"\d", exp.data["prediction"]), "a prediction needs numbers")
                items = exp.items()
                self.assertGreaterEqual(len(items), 10)
                self.assertLessEqual(len(items), 20)
                keys = set()
                for item in items:
                    _, wf = exp.workflow(item["workflow"])
                    sets = {k: ("x.png" if isinstance(v, dict) else v) for k, v in item["sets"].items()}
                    prompt = apply_sets(wf, sets, item["workflow"])
                    keys.add(json.dumps(prompt, sort_keys=True))
                    for folder, name in referenced_models(prompt):
                        if name not in COURSE_MODELS:
                            self.assertEqual(PLANNED.get(name), exp.id, f"{name} is not a course model")
                            if exp.id == "11-image-to-3d":
                                self.assertTrue(any(name in lic["models"] for lic in exp.licences),
                                                f"{name} needs a licence entry")
                    for spec in exp.data.get("analysis") or []:
                        if "node" in spec and spec["kind"] != "stats":
                            self.assertIn(spec["node"], prompt, f"analysis node {spec['node']}")
                self.assertEqual(len(keys), len(items), "two items submit the same prompt")
                for step in exp.prepare:
                    if "src" in step:
                        self.assertTrue(os.path.isfile(exp.resolve(step["src"])), step["src"])

    def test_workflows_link_to_existing_outputs(self):
        for path in WORKFLOWS:
            with self.subTest(os.path.basename(path)):
                with open(path, encoding="utf-8") as f:
                    wf = json.load(f)
                self.assertTrue(any(n["class_type"] in ("SaveImage", "SaveAnimatedWEBP", "SaveGLB") for n in wf.values()))
                for node_id, node in wf.items():
                    for name, value in node["inputs"].items():
                        if isinstance(value, list) and len(value) == 2 and isinstance(value[1], int):
                            self.assertIn(value[0], wf, f"node {node_id}.{name} links to missing node {value[0]}")

    def test_generator_output_is_committed(self):
        import subprocess
        import sys
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            script = os.path.join(LAB, "workflows", "make_workflows.py")
            with open(script, encoding="utf-8") as f:
                source = f.read()
            code = source.replace(
                'HERE = os.path.dirname(os.path.abspath(__file__))', f'HERE = {tmp!r}')
            subprocess.run([sys.executable, "-c", code], check=True)
            import importlib.util
            spec = importlib.util.spec_from_file_location("make_3d_workflows",
                                                          os.path.join(LAB, "workflows", "make_3d_workflows.py"))
            make_3d = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(make_3d)
            make_3d.main(tmp, tmp)
            for path in WORKFLOWS + [os.path.join(LAB, "tests", "ci", "mesh-cpu.api.json")]:
                with open(path, encoding="utf-8") as a, open(os.path.join(tmp, os.path.basename(path)), encoding="utf-8") as b:
                    self.assertEqual(a.read(), b.read(), os.path.basename(path))

    @unittest.skipUnless(os.environ.get("COMFYUI_DIR"), "set COMFYUI_DIR to a ComfyUI checkout")
    def test_nodes_and_inputs_exist_in_comfyui_source(self):
        roots = [os.environ["COMFYUI_DIR"]]
        if os.path.isdir(GA_NODES):
            roots.append(GA_NODES)
        known = schemas(roots)
        for path in WORKFLOWS + [os.path.join(LAB, "tests", "ci", "mesh-cpu.api.json")]:
            with open(path, encoding="utf-8") as f:
                wf = json.load(f)
            for node_id, node in wf.items():
                with self.subTest(f"{os.path.basename(path)} {node_id} {node['class_type']}"):
                    self.assertIn(node["class_type"], known)
                    self.assertLessEqual(set(node["inputs"]), known[node["class_type"]])


if __name__ == "__main__":
    unittest.main()
