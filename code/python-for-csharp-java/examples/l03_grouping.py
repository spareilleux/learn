# examples/l03_grouping.py
from collections import Counter, defaultdict
from itertools import groupby

CHORDS = [
    ("C", "major"),
    ("A", "minor"),
    ("G", "dominant 7"),
    ("E", "minor"),
    ("D", "major"),
    ("F", "major 7"),
]

# GroupBy with a dict of lists: defaultdict creates the list the first time a key is used
by_quality: defaultdict[str, list[str]] = defaultdict(list)
for root, quality in CHORDS:
    by_quality[quality].append(root)
print(dict(by_quality))

# Count per key
counts = Counter(quality for _, quality in CHORDS)
print(counts.most_common(2), counts["minor"], counts["diminished"])

# itertools.groupby groups consecutive items only, so the data must be sorted by the same key first
print([(quality, len(list(group))) for quality, group in groupby(CHORDS, key=lambda chord: chord[1])])
ordered = sorted(CHORDS, key=lambda chord: chord[1])
print([(quality, [root for root, _ in group]) for quality, group in groupby(ordered, key=lambda chord: chord[1])])

# A comprehension runs at once; a generator expression runs when it is consumed, and only once
roots = (root for root, _ in CHORDS)
print(list(roots), list(roots))
