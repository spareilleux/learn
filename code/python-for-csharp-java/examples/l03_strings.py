# examples/l03_strings.py
import re

chord = "Cmaj7"
print(chord[0], chord[-1], chord[1:4], len(chord))  # a str is a sequence of characters
print("maj" in chord, chord.startswith("C"), chord.upper())

notes = "C,E,G,B".split(",")
print(notes, " - ".join(notes))

price, quantity = 9.99, 2
print(f"{quantity} x {price:.2f} = {price * quantity:>8.2f}")
print(f"{quantity=}, {price * quantity=:.3f}")  # = prints the expression too

# A raw string keeps backslashes as they are, which is what a regular expression needs
version = re.compile(r"^v(\d+)\.(\d+)$")
match = version.match("v3.14")
print(match.groups() if match else None)
