# errors/l03_unhashable.py
voicings = {("x", 3, 2, 0, 1, 0): "C major"}  # a tuple of hashable items can be a key
print(voicings[("x", 3, 2, 0, 1, 0)])

names = {["x", 3, 2, 0, 1, 0]: "C major"}  # a list can't: it could change after being stored
