package lessons.l12;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.HashSet;
import java.util.List;
import java.util.TreeSet;

/** Lesson 12: BigDecimal, where C# has decimal. */
public class Decimals {

    public static void main(String[] args) {
        // The double constructor keeps the binary approximation; valueOf and the string constructor don't.
        System.out.println("new BigDecimal(0.1): " + new BigDecimal(0.1));
        System.out.println("BigDecimal.valueOf(0.1): " + BigDecimal.valueOf(0.1));
        System.out.println("new BigDecimal(\"0.1\"): " + new BigDecimal("0.1"));

        // Methods instead of operators. The scale is kept, as with decimal.
        System.out.println("10.50 + 0.5 = " + new BigDecimal("10.50").add(new BigDecimal("0.5")));
        System.out.println("1.10 * 3 = " + new BigDecimal("1.10").multiply(BigDecimal.valueOf(3)));

        // equals compares the scale too; compareTo doesn't.
        var two = new BigDecimal("2.0");
        var twoPointZeroZero = new BigDecimal("2.00");
        System.out.println("2.0 equals 2.00: " + two.equals(twoPointZeroZero));
        System.out.println("2.0 compareTo 2.00: " + two.compareTo(twoPointZeroZero));
        System.out.println("HashSet size: " + new HashSet<>(List.of(two, twoPointZeroZero)).size());
        System.out.println("TreeSet size: " + new TreeSet<>(List.of(two, twoPointZeroZero)).size());

        // Division needs a scale or a precision when the result doesn't terminate.
        try {
            BigDecimal.ONE.divide(BigDecimal.valueOf(3));
        } catch (ArithmeticException e) {
            System.out.println("ArithmeticException: " + e.getMessage());
        }
        System.out.println("1 / 3, scale 4: " + BigDecimal.ONE.divide(BigDecimal.valueOf(3), 4, RoundingMode.HALF_EVEN));
        System.out.println("1 / 3, DECIMAL128: " + BigDecimal.ONE.divide(BigDecimal.valueOf(3), MathContext.DECIMAL128));

        // There is no default rounding mode.
        var price = new BigDecimal("2.345");
        try {
            price.setScale(2);
        } catch (ArithmeticException e) {
            System.out.println("ArithmeticException: " + e.getMessage());
        }
        System.out.println("HALF_EVEN: " + price.setScale(2, RoundingMode.HALF_EVEN) + ", HALF_UP: " + price.setScale(2, RoundingMode.HALF_UP));
        // Math.round on a double rounds halves up, towards positive infinity.
        System.out.println("Math.round(2.5): " + Math.round(2.5) + ", Math.round(-2.5): " + Math.round(-2.5));

        // toString can switch to scientific notation.
        var thousand = new BigDecimal("1000.00").stripTrailingZeros();
        System.out.println("toString: " + thousand + ", toPlainString: " + thousand.toPlainString());
    }
}
