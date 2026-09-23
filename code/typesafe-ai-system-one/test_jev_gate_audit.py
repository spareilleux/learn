from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

import jev_benchmark
import jev_gate_audit


class JevGateAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.cases = jev_benchmark.load_corpus()["cases"]

    def test_high_confidence_wrong_support_survives_095(self) -> None:
        result = jev_gate_audit.sweep(jev_gate_audit.synthetic_response(self.cases), self.cases)
        row = next(row for row in result["thresholds"] if row["threshold"] == 0.95)
        self.assertEqual(row["accepted_supported"], 1)
        self.assertEqual(row["false_supports"], 1)
        self.assertEqual(row["reviewed"], 11)
        self.assertFalse(result["authority_granted"])
        self.assertFalse(result["provider_called"])

    def test_refuses_incomplete_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "receipt.json"
            path.write_text(json.dumps({"status": "in-progress", "completed": []}), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "incomplete"):
                jev_gate_audit.load_completed_batch(path, self.cases)

    def test_refuses_complete_receipt_without_matching_request_digests(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "receipt.json"
            path.write_text(json.dumps({"status": "complete", "requests": [], "completed": []}), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "not bound"):
                jev_gate_audit.load_completed_batch(path, self.cases)


if __name__ == "__main__":
    unittest.main()
