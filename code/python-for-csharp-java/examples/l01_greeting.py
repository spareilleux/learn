# examples/l01_greeting.py
print(f"loading l01_greeting, __name__ = {__name__!r}")


def greet(name: str) -> str:
    return f"Hello, {name}!"


# True only when this file is the program, not when another file imports it
if __name__ == "__main__":
    print(greet("script"))
