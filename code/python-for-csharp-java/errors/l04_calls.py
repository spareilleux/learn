# errors/l04_calls.py
from collections.abc import Callable


def transpose(note: str, /, semitones: int = 0, *, flats: bool = False) -> str:
    return note


calls: list[Callable[[], str]] = [
    lambda: transpose(),
    lambda: transpose("E", 3, True),
    lambda: transpose(note="E"),
    lambda: transpose("E", 3, semitones=4),
    lambda: transpose("E", octave=2),
]
for call in calls:
    try:
        call()
    except TypeError as e:
        print(e)
