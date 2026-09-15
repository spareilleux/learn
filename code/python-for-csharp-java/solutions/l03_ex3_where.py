# solutions/l03_ex3_where.py
import operator
from collections.abc import Callable
from typing import Any

# One entry per operator, longest first, so that ">=" is found before ">"
NUMERIC: dict[str, Callable[[float, float], bool]] = {
    ">=": operator.ge,
    "<=": operator.le,
    ">": operator.gt,
    "<": operator.lt,
}
TEXT: dict[str, Callable[[str, str], bool]] = {"!=": operator.ne, "=": operator.eq}


def parse_where(clause: str) -> tuple[str, str, str]:
    for op in [*NUMERIC, *TEXT]:
        if op in clause:
            field, value = clause.split(op, 1)
            return field.strip(), op, value.strip().strip("'\"")
    raise ValueError(f"no operator in {clause!r}")


def matches(actual: Any, op: str, value: str) -> bool:
    if actual is None:
        return False
    if op in TEXT:
        return TEXT[op](str(actual), value)
    try:
        return NUMERIC[op](float(actual), float(value))
    except (ValueError, TypeError):
        return False


def where(beliefs: list[dict[str, Any]], clause: str) -> list[dict[str, Any]]:
    field, op, value = parse_where(clause)
    return [belief for belief in beliefs if matches(belief.get(field), op, value)]


if __name__ == "__main__":
    beliefs: list[dict[str, Any]] = [
        {"name": "a", "confidence": 0.9, "truth": "T"},
        {"name": "b", "confidence": 0.4, "truth": "U"},
        {"name": "c", "truth": "C"},
        {"name": "d", "confidence": "high", "truth": "T"},
    ]
    for clause in ["confidence >= 0.5", "truth != T", "truth = 'T'"]:
        print(clause, "->", [belief["name"] for belief in where(beliefs, clause)])
