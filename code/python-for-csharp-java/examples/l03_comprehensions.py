# examples/l03_comprehensions.py
CHORDS = [
    ("C", "major", ["C", "E", "G"]),
    ("A", "minor", ["A", "C", "E"]),
    ("G", "dominant 7", ["G", "B", "D", "F"]),
    ("E", "minor", ["E", "G", "B"]),
    ("D", "major", ["D", "F#", "A"]),
    ("F", "major 7", ["F", "A", "C", "E"]),
]

# Where + Select, filter + map
minor = [f"{root}m" for root, quality, _ in CHORDS if quality == "minor"]
print(minor)

# ToDictionary, Collectors.toMap
sizes = {root: len(notes) for root, _, notes in CHORDS}
print(sizes)

# SelectMany + Distinct, flatMap + distinct: two for clauses, in the order of nested loops
all_notes = sorted({note for _, _, notes in CHORDS for note in notes})
print(all_notes)

# Any, All, Sum, Max: functions that consume a generator expression
print(any(len(notes) == 4 for _, _, notes in CHORDS), all("E" in notes for _, _, notes in CHORDS))
print(sum(len(notes) for _, _, notes in CHORDS))
print(max(CHORDS, key=lambda chord: len(chord[2])))  # the first of the largest

# OrderByDescending + ThenBy: one key, a tuple, compared item by item
for root, quality, notes in sorted(CHORDS, key=lambda chord: (-len(chord[2]), chord[0])):
    print(f"{root:<2} {quality:<11} {' '.join(notes)}")

# zip pairs items up, and enumerate numbers them
tuning = ["E", "A", "D", "G", "B", "E"]
for number, (string, note) in enumerate(zip([6, 5, 4, 3, 2, 1], tuning, strict=True), start=1):
    print(f"{number}:{string}{note}", end=" ")
print()
