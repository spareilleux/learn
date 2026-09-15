"""GuitarAlchemist/ga's iconic chords as JSON, for lessons 2 and 3 of the PostgreSQL and Aurora course.

Usage: python extract_chords.py <checkout of GuitarAlchemist/ga>

The file of the course comes from Common/GA.Business.Config/IconicChords.yaml at commit 32f143c (2026-09-15):

    git clone https://github.com/GuitarAlchemist/ga
    git -C ga checkout 32f143c

Writes iconic_chords.json next to this script: one JSON array, one object per chord, with the keys of the YAML
file in the same order. Requires PyYAML.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent


def main() -> None:
    source = Path(sys.argv[1]) / "Common" / "GA.Business.Config" / "IconicChords.yaml"
    chords = yaml.safe_load(source.read_text(encoding="utf-8"))["IconicChords"]
    target = HERE / "iconic_chords.json"
    target.write_text(json.dumps(chords, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
    print(f"{len(chords)} chords written to {target.name}")


if __name__ == "__main__":
    main()
