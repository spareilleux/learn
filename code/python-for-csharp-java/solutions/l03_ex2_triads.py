# solutions/l03_ex2_triads.py
from collections import defaultdict

type Chord = tuple[str, str, list[str]]

CHORDS: list[Chord] = [
    ("C", "major", ["C", "E", "G"]),
    ("A", "minor", ["A", "C", "E"]),
    ("G", "dominant 7", ["G", "B", "D", "F"]),
    ("E", "minor", ["E", "G", "B"]),
    ("D", "major", ["D", "F#", "A"]),
    ("F", "major 7", ["F", "A", "C", "E"]),
]


def triad_roots_by_quality(chords: list[Chord]) -> dict[str, list[str]]:
    groups: defaultdict[str, list[str]] = defaultdict(list)
    for root, quality, notes in chords:
        if len(notes) == 3:
            groups[quality].append(root)
    return {quality: groups[quality] for quality in sorted(groups)}


if __name__ == "__main__":
    print(triad_roots_by_quality(CHORDS))
