# solutions/l04_ex3_retry.py
import functools
from collections.abc import Callable


def retry[**P, R](
    times: int, exceptions: tuple[type[Exception], ...] = (Exception,)
) -> Callable[[Callable[P, R]], Callable[P, R]]:
    def decorate(func: Callable[P, R]) -> Callable[P, R]:
        @functools.wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            for attempt in range(1, times + 1):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    if attempt == times:
                        raise
                    print(f"{func.__name__}: attempt {attempt} failed ({e}), retrying")
            raise AssertionError("unreachable")  # the loop always returns or raises

        return wrapper

    return decorate


if __name__ == "__main__":
    answers = iter([ConnectionError("refused"), TimeoutError("slow"), "nomic-embed-text"])

    @retry(times=3, exceptions=(ConnectionError, TimeoutError))
    def embedder_model(endpoint: str) -> str:
        answer = next(answers)
        if isinstance(answer, Exception):
            raise answer
        return f"{endpoint}: {answer}"

    print(embedder_model("http://localhost:11434"))
    print(embedder_model.__name__)
