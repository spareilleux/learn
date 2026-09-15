# solutions/l01_ex1_order.py
DISCOUNT = 0.9  # 10% off from 11 items


def with_tax(price: float) -> float:
    return price + price * 0.15


def line_total(price: float, quantity: int) -> float:
    total = with_tax(price) * quantity
    return total * DISCOUNT if quantity > 10 else total


def parse_row(row: str) -> tuple[str, float, int]:
    # The CSV gives text: convert it once, at the border
    product, price, quantity = row.split(",")
    return product, float(price), int(quantity)


if __name__ == "__main__":
    for row in ["capo,9.99,2", "strings,12.50,1", "picks,0.50,50"]:
        product, price, quantity = parse_row(row)
        print(product, f"{line_total(price, quantity):.2f}")
