# examples/l04_varargs.py
from typing import Any


def chord(root: str, *intervals: int, **options: Any) -> str:
    # intervals is a tuple of the extra positional arguments, options a dict of the extra keyword arguments
    return f"{root} {intervals} {options}"


print(chord("C"))
print(chord("C", 4, 7, 11, voicing="drop 2", inversion=1))

shape = [4, 7]
settings = {"voicing": "open"}
print(chord("A", *shape, **settings))  # * and ** unpack a sequence and a dict into arguments


def logged(*args: Any, **kwargs: Any) -> str:
    print("forwarding", args, kwargs)
    return chord(*args, **kwargs)  # forward everything, whatever the signature


print(logged("G", 4, 7, 10, inversion=2))
