# examples/l02_arguments.py
def add_capo(strings: list[str]) -> None:
    strings.append("capo")  # changes the caller's list: the parameter names the same object


def retune(strings: list[str]) -> None:
    strings = ["D", "A", "D", "G", "A", "D"]  # binds the local name to a new list; the caller sees nothing
    print("inside retune:", strings)


tuning = ["E", "A", "D", "G", "B", "E"]
add_capo(tuning)
print("after add_capo:", tuning)
retune(tuning)
print("after retune:  ", tuning)
