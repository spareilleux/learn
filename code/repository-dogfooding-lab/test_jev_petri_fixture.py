from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent / "typesafe-ai-system-one"))

import jev_benchmark  # noqa: E402
import jev_gate_audit  # noqa: E402


class JevPetriFixtureTests(unittest.TestCase):
    def test_fixture_is_bound_to_the_synthetic_wrong_support(self) -> None:
        fixture = json.loads((ROOT / "jev-petri-fixture.json").read_text(encoding="utf-8"))
        cases = jev_benchmark.load_corpus()["cases"]
        case = next(case for case in cases if case["id"] == fixture["case_id"])
        answer = jev_gate_audit.synthetic_response(cases)["answers"][case["id"]]

        self.assertEqual("synthetic-not-live", fixture["kind"])
        self.assertEqual(case["expected"], fixture["expected"])
        self.assertEqual(answer["choice"], fixture["jev_choice"])
        self.assertEqual(answer["confidence"], fixture["jev_confidence"])
        self.assertGreaterEqual(fixture["jev_confidence"], 0.95)
        self.assertNotEqual("supported", fixture["expected"])
        self.assertFalse(fixture["verified_evidence"])
        self.assertFalse(fixture["implementation_authority"])


if __name__ == "__main__":
    unittest.main()
