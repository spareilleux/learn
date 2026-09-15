# tests/test_l01.py
import pytest

from l01_ex1_order import line_total, parse_row


def test_parse_row_converts_the_text() -> None:
    assert parse_row("strings,12.50,1") == ("strings", 12.5, 1)


def test_parse_row_refuses_a_price_that_is_not_a_number() -> None:
    with pytest.raises(ValueError, match="could not convert string to float"):
        parse_row("capo,nine,2")


def test_the_discount_starts_at_eleven_items() -> None:
    assert line_total(1.0, 10) == pytest.approx(11.5)
    assert line_total(1.0, 11) == pytest.approx(11.385)
