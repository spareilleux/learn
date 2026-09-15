# tests/test_l02.py
from pathlib import Path

import pytest

import l02_ex3_governance
from l02_ex1_tuning import STANDARD, retune_in_place, retuned
from l02_ex2_label import label


def test_retune_in_place_changes_the_callers_list() -> None:
    tuning = ["D", "A", "D", "G", "A", "D"]
    alias = tuning
    retune_in_place(tuning, STANDARD)
    assert alias == ["E", "A", "D", "G", "B", "E"]


def test_retuned_returns_a_new_list() -> None:
    notes = ("D", "G", "D", "G", "B", "D")
    assert retuned(notes) == list(notes)


def test_zero_is_not_unknown() -> None:
    assert [label(None), label(0), label(3)] == ["quantity unknown", "out of stock", "3 in stock"]


def test_the_lookup_happens_when_beliefs_are_listed(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    # The import at the top of this file succeeded without a governance folder
    beliefs = tmp_path / "state" / "beliefs"
    beliefs.mkdir(parents=True)
    (beliefs / "b.belief.json").write_text("{}", encoding="utf-8")
    (beliefs / "a.belief.json").write_text("{}", encoding="utf-8")
    monkeypatch.setenv("DEMERZEL_ROOT", str(tmp_path))
    assert l02_ex3_governance.list_beliefs() == ["a.belief.json", "b.belief.json"]
