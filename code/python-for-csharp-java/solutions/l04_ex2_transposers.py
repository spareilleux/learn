# solutions/l04_ex2_transposers.py
import functools
from collections.abc import Callable

NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def transpose(semitones: int, note: str) -> str:
    return NOTES[(NOTES.index(note) + semitones) % 12]


def make_transposers(count: int) -> list[Callable[[str], str]]:
    # partial stores the value of semitones now, when each function is created
    return [functools.partial(transpose, semitones) for semitones in range(count)]


def make_transposers_with_a_factory(count: int) -> list[Callable[[str], str]]:
    def by(semitones: int) -> Callable[[str], str]:
        return lambda note: transpose(semitones, note)  # each call of by has its own semitones

    return [by(semitones) for semitones in range(count)]


if __name__ == "__main__":
    print([t("E") for t in make_transposers(4)])
    print([t("E") for t in make_transposers_with_a_factory(4)])
