# errors/l04_capture.py
from collections.abc import Callable

# A default value is evaluated when each lambda is created, so i=i stores the current value of i
transposers: list[Callable[[int], int]] = [lambda note, i=i: note + i for i in range(3)]
print([transpose(10) for transpose in transposers])
