"""Offline negative control: structured publication checks need no model call.

The corpus is composed from a pinned source seam, not real Gaia receipts.
This classifier is a comparison baseline, not an authorization mechanism.
"""

import json
from pathlib import Path
import unittest


CORPUS = Path(__file__).with_name("gaia-structured-evidence-corpus.json")


def classify(checks):
    if not isinstance(checks, list) or not checks:
        raise ValueError("At least one required check is needed")
    missing = False
    for check in checks:
        if not isinstance(check, dict) or not isinstance(check.get("field"), str):
            raise ValueError("Every check needs a field")
        if "expected" not in check:
            raise ValueError("Every check needs an expected value")
        if "observed" not in check or check["observed"] is None:
            missing = True
        elif check["observed"] != check["expected"]:
            return "contradicted"
    return "insufficient" if missing else "supported"


class GaiaStructuredEvidenceTests(unittest.TestCase):
    def test_pinned_scenarios(self):
        corpus = json.loads(CORPUS.read_text(encoding="utf-8"))
        self.assertEqual(corpus["labels"], ["supported", "contradicted", "insufficient"])
        self.assertEqual(len(corpus["cases"]), 9)
        self.assertEqual(len({case["id"] for case in corpus["cases"]}), 9)
        for case in corpus["cases"]:
            with self.subTest(case=case["id"]):
                self.assertEqual(classify(case["checks"]), case["expected"])

    def test_missing_does_not_hide_a_known_conflict(self):
        self.assertEqual(classify([
            {"field": "a", "expected": "A"},
            {"field": "b", "expected": "B", "observed": "C"},
        ]), "contradicted")

    def test_empty_or_malformed_checks_fail_closed(self):
        for checks in ([], [{"expected": "A", "observed": "A"}], [{"field": "a"}]):
            with self.subTest(checks=checks):
                with self.assertRaises(ValueError):
                    classify(checks)


if __name__ == "__main__":
    unittest.main()
