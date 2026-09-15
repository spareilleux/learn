# examples/l04_decorators.py
import functools
from collections.abc import Callable


# A decorator is a function that receives a function and returns the one that replaces it
def log_calls[**P, R](func: Callable[P, R]) -> Callable[P, R]:
    @functools.wraps(func)  # copies __name__, __doc__ and the rest from func to wrapper
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        result = func(*args, **kwargs)
        print(f"{func.__name__}{args} -> {result!r}")
        return result

    return wrapper


@log_calls  # the same as: interval = log_calls(interval)
def interval(low: str, high: str) -> int:
    notes = ["C", "D", "E", "F", "G", "A", "B"]
    return notes.index(high) - notes.index(low)


interval("C", "G")
print(interval.__name__)

# A decorator runs once, when def runs: this registry is filled at import time, before any call
AGENTS: dict[str, Callable[[str], str]] = {}


def agent(name: str) -> Callable[[Callable[[str], str]], Callable[[str], str]]:
    print(f"agent({name!r}) is called")

    def register(handler: Callable[[str], str]) -> Callable[[str], str]:
        print(f"registering {handler.__name__} as {name!r}")
        AGENTS[name] = handler
        return handler

    return register


@agent(name="governance")  # agent(name=...) returns the decorator, which then receives the function
def governance_handler(text: str) -> str:
    return f"governance: {text}"


print("registered:", list(AGENTS))
print(AGENTS["governance"]("show beliefs"))


# functools.cache keeps every result, keyed by the arguments
@functools.cache
def fibonacci(n: int) -> int:
    return n if n < 2 else fibonacci(n - 1) + fibonacci(n - 2)


print(fibonacci(90), fibonacci.cache_info())
