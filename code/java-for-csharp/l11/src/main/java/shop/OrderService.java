package shop;

import java.time.Clock;
import java.util.List;
import org.jspecify.annotations.Nullable;

public final class OrderService {

    private final Inventory inventory;
    private final PaymentGateway gateway;
    private final Clock clock;
    private final PriceCalculator calculator = new PriceCalculator();

    // Clock is injected where .NET code injects TimeProvider.
    public OrderService(Inventory inventory, PaymentGateway gateway, Clock clock) {
        this.inventory = inventory;
        this.gateway = gateway;
        this.clock = clock;
    }

    public Receipt place(String customer, List<Item> items, @Nullable String couponCode) {
        for (Item item : items) {
            if (!inventory.inStock(item.sku(), item.quantity())) {
                throw new IllegalStateException("out of stock: " + item.sku());
            }
        }
        long total = calculator.totalCents(items, couponCode);
        PaymentResult payment = gateway.charge(customer, total);
        String transactionId = payment.transactionId();
        if (!payment.approved() || transactionId == null) {
            throw new IllegalStateException("payment declined for " + customer);
        }
        return new Receipt(customer, total, transactionId, clock.instant());
    }
}
