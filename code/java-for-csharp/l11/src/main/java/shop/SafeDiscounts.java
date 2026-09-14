package shop;

import java.util.Objects;

// Exercise 3: the Discounts methods rewritten so that NullAway accepts them.
public final class SafeDiscounts {

    private SafeDiscounts() {}

    public static int percentOrZero(String code) {
        return Objects.requireNonNullElse(Coupons.percentOff(code), 0);
    }

    public static String describe(String code) {
        Integer percent = Coupons.percentOff(code);
        return percent == null ? "no discount" : percent + "% off";
    }
}
