package shop;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;

class PriceCalculatorTest {

    private PriceCalculator calculator;
    private int testsRunOnThisInstance;

    // Runs before each test, on a new instance: the constructor of an xUnit test class.
    @BeforeEach
    void setUp() {
        calculator = new PriceCalculator();
        testsRunOnThisInstance++;
    }

    @Test
    void sumsLineTotals() {
        var items = List.of(new Item("pen", 2, 150), new Item("pad", 1, 400));
        assertEquals(700, calculator.totalCents(items, null));
        assertEquals(1, testsRunOnThisInstance);
    }

    @Test
    @DisplayName("an unknown coupon is rejected with its code in the message")
    void unknownCoupon() {
        var items = List.of(new Item("pen", 1, 150));
        var e = assertThrows(IllegalArgumentException.class, () -> calculator.totalCents(items, "FREE"));
        assertEquals("unknown coupon: FREE", e.getMessage());
        assertEquals(1, testsRunOnThisInstance);
    }

    // [Theory] with [InlineData]: one test per row.
    @ParameterizedTest(name = "{0} pens at 100 cents cost {1}")
    @CsvSource({
        "1,  100",
        "9,  900",
        "10, 950",
        "20, 1900",
    })
    void bulkDiscountStartsAtTen(int quantity, long expectedCents) {
        assertEquals(expectedCents, calculator.totalCents(List.of(new Item("pen", quantity, 100)), null));
    }

    // [MemberData]: arguments built by a static method.
    static Stream<Arguments> coupons() {
        return Stream.of(Arguments.of("TEN", 900), Arguments.of("HALF", 500));
    }

    @ParameterizedTest
    @MethodSource("coupons")
    void couponsTakeAPercentageOff(String code, long expectedCents) {
        assertEquals(expectedCents, calculator.totalCents(List.of(new Item("book", 1, 1000)), code));
    }

    // Nested classes group tests and share the outer setup.
    @Nested
    class InvalidItems {

        @Test
        void zeroQuantityIsRejected() {
            var e = assertThrows(IllegalArgumentException.class, () -> new Item("pen", 0, 100));
            assertEquals("quantity must be positive for pen: 0", e.getMessage());
        }
    }
}
