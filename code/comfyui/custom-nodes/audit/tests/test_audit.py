"""Runs audit.py on a fixture and on the GA pack, and compares the reports with expected/.

    python -m unittest discover -s code/comfyui/custom-nodes/audit/tests -v
    UPDATE=1 python -m unittest discover -s code/comfyui/custom-nodes/audit/tests    # rewrites expected/*.txt
"""

import io
import os
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
import audit  # noqa: E402

CASES = {
    "suspicious_pack": HERE / "fixtures" / "suspicious_pack",
    "ga": HERE.parent / "ga",
}


class AuditTest(unittest.TestCase):
    def test_reports(self):
        for name, folder in CASES.items():
            with self.subTest(pack=name):
                out = io.StringIO()
                audit.report(folder, 5, out)
                path = HERE / "expected" / f"{name}.txt"
                if os.environ.get("UPDATE") == "1":
                    path.parent.mkdir(exist_ok=True)
                    path.write_text(out.getvalue(), encoding="utf-8", newline="\n")
                else:
                    self.assertEqual(out.getvalue(), path.read_text(encoding="utf-8"))

    def test_nothing_is_imported(self):
        audit.audit_pack(CASES["suspicious_pack"])
        self.assertFalse(any("suspicious_pack" in name for name in sys.modules))


if __name__ == "__main__":
    unittest.main()
