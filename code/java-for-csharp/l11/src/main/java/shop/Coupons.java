package shop;

import java.util.Map;
import org.jspecify.annotations.Nullable;

public final class Coupons {

    private static final Map<String, Integer> PERCENT_OFF = Map.of("TEN", 10, "HALF", 50);

    private Coupons() {}

    // @Nullable says what C# says with int?: callers must handle the missing case.
    public static @Nullable Integer percentOff(String code) {
        return PERCENT_OFF.get(code);
    }
}
