# tests/test_l03.py
from typing import Any

import pytest

from l03_ex1_tensor import tensor_summary
from l03_ex2_triads import CHORDS, triad_roots_by_quality
from l03_ex3_where import where


def test_tensor_summary_counts_missing_configs_as_unknown() -> None:
    summary = tensor_summary([{"tensorConfig": "C_T"}, {}, {}])
    assert summary["tensor_distribution"] == {"C_T": 1, "U_U": 2}
    assert summary["hunch_count"] == 0


def test_triads_are_grouped_by_quality_in_order() -> None:
    assert triad_roots_by_quality(CHORDS) == {"major": ["C", "D"], "minor": ["A", "E"]}


BELIEFS: list[dict[str, Any]] = [
    {"name": "a", "confidence": 0.9, "truth": "T"},
    {"name": "b", "confidence": 0.4, "truth": "U"},
    {"name": "c", "truth": "C"},
    {"name": "d", "confidence": "high", "truth": "T"},
]


@pytest.mark.parametrize(
    ("clause", "names"),
    [
        ("confidence >= 0.5", ["a"]),
        ("confidence < 0.5", ["b"]),
        ("truth = T", ["a", "d"]),
        ("truth != 'T'", ["b", "c"]),
    ],
)
def test_where(clause: str, names: list[str]) -> None:
    assert [belief["name"] for belief in where(BELIEFS, clause)] == names
