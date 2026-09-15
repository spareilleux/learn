# errors/l01_order.py
def with_tax(price: float) -> float:
    return price + price * 0.15


def line_total(product: str, price: float, quantity: int) -> float:
    if quantity > 10:
        return with_tax(price) * quantity * discount  # discount is defined nowhere
    return with_tax(price) * quantity


# The prices come from a CSV file, where everything is text
print("capo", line_total("capo", 9.99, 2))
print("strings", line_total("strings", "12.50", 1))
print("picks", line_total("picks", 0.5, 50))
