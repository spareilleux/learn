"""Fixture discovery must not execute evidence or vendored directories."""
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import check


class ModuleDiscoveryTests(unittest.TestCase):
    def test_only_module_id_directories_are_discovered(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            for name in ["psychohistory/psy-003", "evidence/batch50-2026-10-25-c",
                         "fixtures/computer-science", "functional-composition/vendor"]:
                (root / name).mkdir(parents=True)
            with patch.object(check, "HERE", root):
                self.assertEqual(check.modules(), [root / "psychohistory/psy-003"])

    def test_incomplete_module_is_kept_for_missing_file_validation(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            module = root / "audio-engineering/aud-001"
            module.mkdir(parents=True)
            with patch.object(check, "HERE", root):
                self.assertEqual(check.modules(), [module])


if __name__ == "__main__":
    unittest.main()
