"""validate.py: the lesson's workflows and every run of runs/ pass; broken copies fail with the server's reasons."""
import copy
import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE))
import pipeline  # noqa: E402
import validate  # noqa: E402

INFO = json.loads((HERE / "data" / "object_info.audio.json").read_text(encoding="utf-8"))


def load(name):
    return json.loads((HERE / "workflows" / name).read_text(encoding="utf-8"))


class ValidateTest(unittest.TestCase):
    def test_every_run_is_valid(self):
        for runs in sorted((HERE / "runs").glob("*.json")):
            items = json.loads(runs.read_text(encoding="utf-8"))
            if not isinstance(items, list) or not items or "workflow" not in items[0]:
                continue
            for item in items:
                workflow = pipeline.apply_sets(json.loads((runs.parent / item["workflow"]).read_text(encoding="utf-8")), item["set"])
                self.assertEqual(validate.check(workflow, INFO), [], f"{runs.name}: {item['name']}")

    def test_dynamic_combo(self):
        workflow = load("15-cpu-empty-audio.api.json")
        workflow["3"]["inputs"]["format"] = "mp3"
        self.assertEqual(validate.check(workflow, INFO), ["node 3 (SaveAudioAdvanced) format.quality: required input is missing"])
        workflow["3"]["inputs"]["format.quality"] = "nope"
        self.assertEqual(len(validate.check(workflow, INFO)), 1)
        workflow["3"]["inputs"]["format.quality"] = "V0"
        self.assertEqual(validate.check(workflow, INFO), [])

    def test_broken_workflow(self):
        workflow = copy.deepcopy(load("15-ace-step.api.json"))
        workflow["5"]["inputs"]["keyscale"] = "H major"
        workflow["5"]["inputs"]["bpm"] = 400
        workflow["8"]["inputs"]["latent_image"] = ["3", 0]
        del workflow["7"]
        errors = validate.check(workflow, INFO)
        self.assertEqual(errors, [
            "node 5 (TextEncodeAceStepAudio1.5) bpm: 400 is outside [10, 300]",
            "node 5 (TextEncodeAceStepAudio1.5) keyscale: 'H major' is not one of 34 options",
            "node 8 (KSampler) latent_image: expects LATENT, node 3 output 0 is VAE",
        ])


if __name__ == "__main__":
    unittest.main()
