# tests/test_l04.py
import pytest

from l04_ex1_add_note import add_note
from l04_ex2_transposers import make_transposers, make_transposers_with_a_factory
from l04_ex3_retry import retry


def test_each_call_gets_its_own_list() -> None:
    assert add_note("C") == ["C"]
    assert add_note("E") == ["E"]


def test_each_transposer_keeps_its_own_interval() -> None:
    expected = ["E", "F", "F#", "G"]
    assert [t("E") for t in make_transposers(4)] == expected
    assert [t("E") for t in make_transposers_with_a_factory(4)] == expected


def test_retry_gives_up_after_the_last_attempt() -> None:
    attempts: list[int] = []

    @retry(times=2, exceptions=(ConnectionError,))
    def always_refused() -> str:
        attempts.append(len(attempts) + 1)
        raise ConnectionError("refused")

    with pytest.raises(ConnectionError):
        always_refused()
    assert attempts == [1, 2]


def test_retry_does_not_catch_other_exceptions() -> None:
    @retry(times=5, exceptions=(ConnectionError,))
    def broken() -> str:
        raise KeyError("model")

    with pytest.raises(KeyError):
        broken()
