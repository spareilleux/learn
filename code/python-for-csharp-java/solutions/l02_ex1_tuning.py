# solutions/l02_ex1_tuning.py
STANDARD = ("E", "A", "D", "G", "B", "E")


def retune_in_place(strings: list[str], notes: tuple[str, ...]) -> None:
    # Slice assignment replaces the items of the caller's list instead of rebinding the parameter
    strings[:] = notes


def retuned(notes: tuple[str, ...]) -> list[str]:
    # Or leave the caller's list alone and return a new one
    return list(notes)


if __name__ == "__main__":
    tuning = ["D", "A", "D", "G", "A", "D"]
    alias = tuning
    retune_in_place(tuning, STANDARD)
    print(alias, alias is tuning)
    print(retuned(("D", "G", "D", "G", "B", "D")))
