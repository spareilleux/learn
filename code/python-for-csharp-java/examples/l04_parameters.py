# examples/l04_parameters.py
NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


# note is positional-only (before /), semitones can be passed either way, and flats is keyword-only (after *)
def transpose(note: str, /, semitones: int = 0, *, flats: bool = False) -> str:
    result = NOTES[(NOTES.index(note) + semitones) % 12]
    if flats and result.endswith("#"):
        return NOTES[NOTES.index(result) + 1] + "b"
    return result


print(transpose("E"))
print(transpose("E", 3), transpose("E", semitones=3))
print(transpose("A", 1, flats=True))


def describe(root: str, quality: str = "major", seventh: str | None = None) -> str:
    return f"{root} {quality}" + (f" with a {seventh} seventh" if seventh else "")


# Keyword arguments can skip the parameters that have a default, in any order
print(describe("G", seventh="minor"))
print(describe(seventh="major", root="C"))
