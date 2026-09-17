#!/usr/bin/env python3
"""Lesson 15: measure a batch's outputs against what its runs asked for.

    python measure.py RUNS.json OUT_DIR [--chords NAME...]

For each run folder: the file's format (sample rate, channels, length), a SHA-256 of its decoded samples (two
files with the same hash hold the same audio, whatever their container metadata), and, for ACE-Step runs, the
key and tempo that analyze.py estimates next to the keyscale and bpm the run asked for.
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
import soundfile

sys.path.insert(0, str(Path(__file__).resolve().parent))
import analyze  # noqa: E402

ENHARMONIC = {"C#": "C#", "Db": "C#", "D#": "Eb", "Eb": "Eb", "F#": "F#", "Gb": "F#", "G#": "Ab", "Ab": "Ab", "A#": "Bb", "Bb": "Bb"}


def same_key(a, b):
    ra, ma = a.split()
    rb, mb = b.split()
    return ENHARMONIC.get(ra, ra) == ENHARMONIC.get(rb, rb) and ma == mb


def relative(key):
    """C major <-> A minor: the key that shares the same notes."""
    root, mode = key.split()
    i = analyze.NOTES.index(ENHARMONIC.get(root, root))
    return f"{analyze.NOTES[(i + 9) % 12]} minor" if mode == "major" else f"{analyze.NOTES[(i + 3) % 12]} major"


def requested(item):
    values = {}
    for assignment in item.get("set", []):
        target, _, raw = assignment.partition("=")
        try:
            values[target] = json.loads(raw)
        except json.JSONDecodeError:
            values[target] = raw
    return values


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("runs")
    parser.add_argument("out")
    parser.add_argument("--chords", nargs="*", default=[])
    args = parser.parse_args(argv)
    for item in json.loads(Path(args.runs).read_text(encoding="utf-8")):
        files = sorted(Path(args.out, item["name"]).glob("*.flac"))
        if not files:
            print(f"{item['name']}: no file")
            continue
        path = files[0]
        data, rate = soundfile.read(path, dtype="float32", always_2d=True)
        digest = hashlib.sha256(np.ascontiguousarray(data).tobytes()).hexdigest()[:16]
        line = f"{item['name']}: {rate} Hz, {data.shape[1]} ch, {len(data) / rate:.2f} s, samples {digest}, peak {np.abs(data).max():.2f}"
        want = requested(item)
        if "5.keyscale" in want:
            a = analyze.analyze(str(path))
            key_ok = "yes" if same_key(a["key"], want["5.keyscale"]) else ("relative" if same_key(a["key"], relative(want["5.keyscale"])) else "no")
            ratio = a["bpm"] / want["5.bpm"]
            line += (f" | asked {want['5.keyscale']}, {want['5.bpm']} BPM; heard {a['key']} (r={a['key_r']:.2f}), {a['bpm']:.1f} BPM"
                     f" | key {key_ok}, tempo ratio {ratio:.2f}")
        print(line, flush=True)
        if item["name"] in args.chords:
            for time, name, r in analyze.bars(str(path)):
                print(f"    {time:6.2f} s  {name:6} r={r:.2f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
