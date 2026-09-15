# examples/l02_objects.py
def with_tax(price: float) -> float:
    return price * 1.15


# Numbers, text, None, functions and classes are all objects, and every object has a type
for value in [42, 3.5, "capo", None, with_tax, int, type]:
    print(type(value))

print(isinstance(True, int), True + True)  # bool is a subclass of int
print(2**100)  # an int has no fixed size, so it never overflows
print(with_tax.__name__, with_tax.__annotations__)
