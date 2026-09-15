# examples/l03_slicing.py
tuning = ["E", "A", "D", "G", "B", "E"]
print(tuning[1:3], tuning[:2], tuning[4:], tuning[-2:], tuning[::2], tuning[::-1])
print(tuning[10:], tuning[-100:2])  # a slice outside the list is empty or shortened, never an error

bass = tuning[:3]  # a slice is a new list
bass[0] = "D"
print(bass, tuning)

tuning[3:] = ["G", "A", "D"]  # slice assignment replaces part of the list in place
print(tuning)
del tuning[0]
print(tuning)
