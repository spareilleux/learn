"""analyze.py on a signal whose answer is known, and wer.py's arithmetic."""
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import analyze  # noqa: E402
import wer  # noqa: E402


class KeyProfileTest(unittest.TestCase):
    def test_profiles_find_their_own_key(self):
        self.assertEqual(analyze.key_scores(analyze.MAJOR)[0][1], "C major")
        self.assertEqual(analyze.key_scores(np.roll(analyze.MINOR, 9))[0][1], "A minor")
        self.assertEqual(analyze.key_scores(np.roll(analyze.MAJOR, 2))[0][1], "D major")

    def test_chord_templates(self):
        chroma = np.zeros(12)
        chroma[[2, 5, 9, 0]] = 1  # D F A C
        self.assertEqual(analyze.chord_name(chroma)[1], "Dm7")
        chroma = np.zeros(12)
        chroma[[7, 11, 2, 5]] = 1  # G B D F
        self.assertEqual(analyze.chord_name(chroma)[1], "G7")


@unittest.skipIf(importlib.util.find_spec("librosa") is None, "librosa is not installed")
class SyntheticSignalTest(unittest.TestCase):
    def test_c_major_at_120_bpm(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = str(Path(tmp) / "synth.wav")
            analyze.synth(path)
            result = analyze.analyze(path)
            self.assertEqual(result["key"], "C major")
            self.assertAlmostEqual(result["duration"], 16.0, delta=0.05)
            # Tempo octaves are a known ambiguity: accept 60, 120 or 240 within 3 %.
            self.assertTrue(any(abs(result["bpm"] - t) / t < 0.03 for t in (60, 120, 240)), result["bpm"])


class WerTest(unittest.TestCase):
    def test_identical_after_normalization(self):
        self.assertEqual(wer.wer("Bienvenue dans la leçon quinze.", "bienvenue dans la leçon quinze"), 0.0)
        self.assertEqual(wer.wer("C'est l'accord de sol", "C’est l’accord de sol !"), 0.0)

    def test_substitution_deletion_insertion(self):
        self.assertEqual(wer.word_errors("un deux trois quatre", "un deux troie quatre"), (1, 4))
        self.assertEqual(wer.word_errors("un deux trois quatre", "un trois quatre"), (1, 4))
        self.assertEqual(wer.word_errors("un deux trois quatre", "un deux trois quatre cinq"), (1, 4))
        self.assertEqual(wer.wer("a b", ""), 1.0)


if __name__ == "__main__":
    unittest.main()
