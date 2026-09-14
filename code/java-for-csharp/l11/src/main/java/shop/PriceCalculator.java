package shop;

import java.util.List;
import org.jspecify.annotations.Nullable;

public final class PriceCalculator {

    static final int BULK_QUANTITY = 10;

    public long totalCents(List<Item> items, @Nullable String couponCode) {
        long total = 0;
        for (Item item : items) {
            long line = item.lineTotalCents();
            if (item.quantity() >= BULK_QUANTITY) {
                line -= line * 5 / 100;
            }
            total += line;
        }
        if (couponCode != null) {
            Integer percent = Coupons.percentOff(couponCode);
            if (percent == null) {
                throw new IllegalArgumentException("unknown coupon: " + couponCode);
            }
            total -= total * percent / 100;
        }
        return total;
    }
}
