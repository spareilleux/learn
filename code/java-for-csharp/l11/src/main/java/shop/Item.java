package shop;

public record Item(String sku, int quantity, long unitPriceCents) {

    public Item {
        if (quantity <= 0) {
            throw new IllegalArgumentException("quantity must be positive for " + sku + ": " + quantity);
        }
    }

    public long lineTotalCents() {
        return quantity * unitPriceCents;
    }
}
