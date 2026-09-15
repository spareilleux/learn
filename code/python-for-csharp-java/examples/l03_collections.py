# examples/l03_collections.py
tuning = ["E", "A", "D", "G", "B", "E"]  # list: a growable array, like List<T> and ArrayList
c_major = ("C", "E", "G")  # tuple: a fixed sequence that can't be changed
intervals = {"C": 0, "E": 4, "G": 7}  # dict: a hash table that keeps insertion order
open_notes = set(tuning)  # set: a hash set, without duplicates

tuning.append("A")
print(tuning, len(tuning), tuning.count("E"))
print(c_major[1], "G" in c_major, c_major + ("B",))

intervals["B"] = 11
print(intervals, intervals.get("D"), intervals.get("D", -1))
for note, semitones in intervals.items():
    print(f"{note}: {semitones}", end="  ")
print()

print(len(open_notes), sorted(open_notes), "B" in open_notes)
print(sorted(open_notes & {"C", "E", "G"}), sorted(open_notes - {"E"}))

# Collections compare by value
print([1, 2] == [1, 2], (1, 2) == (1, 2), {"a": 1, "b": 2} == {"b": 2, "a": 1})

# Unpacking
first, *middle, last = tuning
print(first, middle, last)
root, third, fifth = c_major
third, fifth = fifth, third  # a swap, through a tuple
print(root, third, fifth)
