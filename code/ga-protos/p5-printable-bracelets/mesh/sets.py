"""Names to pitch classes, out of GA's own catalog.

``data/ga-sets.json`` is written by ``scripts/ga-sets.ts`` from a GA clone at a pinned commit; this module only reads it.
A bracelet is named ``"<root> <ga id>"``: ``C major-triad``, ``A Minor.Natural``, ``Eb dominant-7``.
"""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "data" / "ga-sets.json"

NATURALS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
NOTE_NAMES = ("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")


def note_to_pitch_class(note: str) -> int:
    pc = NATURALS[note[0].upper()]
    for accidental in note[1:]:
        pc += 1 if accidental == "#" else -1 if accidental in "b♭" else 0
    return pc % 12


@lru_cache(maxsize=1)
def ga_sets() -> dict:
    return json.loads(DATA.read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def by_id() -> dict[str, list[int]]:
    sets = ga_sets()
    return {entry["id"]: list(entry["intervals"]) for entry in sets["chords"] + sets["scales"]}


def resolve(name: str) -> tuple[int, ...]:
    """``"C major-triad"`` -> ``(0, 4, 7)``. The root may be any note name GA writes."""
    root_name, _, set_id = name.partition(" ")
    if not set_id:
        raise ValueError(f"a bracelet is named '<root> <ga id>', not {name!r}")
    intervals = by_id().get(set_id)
    if intervals is None:
        raise ValueError(f"{set_id!r} is not in GA's catalog")
    root = note_to_pitch_class(root_name)
    return tuple(sorted((root + i) % 12 for i in intervals))


def spell(pitch_classes: tuple[int, ...]) -> str:
    return " ".join(NOTE_NAMES[pc] for pc in pitch_classes)
