# examples/l04_closures.py
from collections.abc import Callable


def make_counter() -> Callable[[], int]:
    count = 0

    def increment() -> int:
        nonlocal count  # assign to the variable of the enclosing function, not to a new local one
        count += 1
        return count

    return increment


counter = make_counter()
print(counter(), counter(), counter())

# A closure captures the variable, not its value at the time: the three lambdas see the last value of i
transposers: list[Callable[[int], int]] = [lambda note: note + i for i in range(3)]
print([transpose(10) for transpose in transposers])

# lambda is an expression that holds one expression; def is needed for statements
by_length: Callable[[list[str]], int] = lambda notes: len(notes)
print(sorted([["C", "E", "G", "B"], ["A", "C", "E"]], key=by_length))
