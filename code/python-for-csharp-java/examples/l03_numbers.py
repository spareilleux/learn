# examples/l03_numbers.py
import math
from decimal import ROUND_HALF_UP, Decimal

# Integer division rounds toward negative infinity, and % takes the sign of the divisor
print(7 // 2, -7 // 2, -7 % 2)
print(int(-7 / 2), math.fmod(-7, 2))  # truncation, as C# and Java divide
print(7 / 2, 6 / 2)  # / always gives a float

print(2**64, (2**64).bit_length())
print(0.1 + 0.2, 0.1 + 0.2 == 0.3, math.isclose(0.1 + 0.2, 0.3))

# round() rounds half to even, and a float literal is rarely the decimal it looks like
print(round(2.5), round(3.5), round(2.675, 2), Decimal(2.675))

# Lesson 1's picks: 50 at 0.50, plus 15% tax, minus 10%
total = (0.50 + 0.50 * 0.15) * 50 * 0.9  # the formula of lesson 1
print(total, f"{total:.2f}")
exact = (Decimal("0.50") + Decimal("0.50") * Decimal("0.15")) * 50 * Decimal("0.9")
print(exact, exact.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP), Decimal("0.1") + Decimal("0.2"))
