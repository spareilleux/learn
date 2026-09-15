# solutions/l04_ex1_add_note.py
def add_note(note: str, chord: list[str] | None = None) -> list[str]:
    # None is immutable, so the shared default is harmless; the list is created on each call
    if chord is None:
        chord = []
    chord.append(note)
    return chord


if __name__ == "__main__":
    print(add_note("C"), add_note("E"), add_note("G", ["G"]))
