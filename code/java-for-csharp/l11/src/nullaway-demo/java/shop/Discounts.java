package shop;

public final class Discounts {

    private Discounts() {}

    // Compiles with javac; NullAway rejects both lines that use the @Nullable result.
    public static int percentOrZero(String code) {
        return Coupons.percentOff(code);
    }

    public static String describe(String code) {
        return Coupons.percentOff(code).toString() + "% off";
    }
}
