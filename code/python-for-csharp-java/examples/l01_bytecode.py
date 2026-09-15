# examples/l01_bytecode.py
import dis


def with_tax(price: float) -> float:
    return price + price * rate


rate = 0.15
dis.dis(with_tax)  # the bytecode that CPython compiled from the function, like ildasm shows IL
