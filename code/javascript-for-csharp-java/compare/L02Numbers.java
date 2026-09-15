// Lesson 2, the Java side: java L02Numbers.java (Java 25)
import java.math.BigInteger;

void main() {
    IO.println("0.1 + 0.2              " + (0.1 + 0.2));
    IO.println("7 / 2                  " + (7 / 2));
    IO.println("7.0 / 2                " + (7.0 / 2));
    IO.println("1.0 / 0                " + (1.0 / 0));
    IO.println("NaN == NaN             " + (Double.NaN == Double.NaN));
    int zero = 0;
    try {
        IO.println(1 / zero);
    } catch (ArithmeticException e) {
        IO.println("1 / zero               " + e);
    }
    int max = Integer.MAX_VALUE;
    IO.println("Integer.MAX_VALUE + 1  " + (max + 1));
    IO.println("Long.MAX_VALUE         " + Long.MAX_VALUE);
    IO.println("BigInteger 2^64        " + BigInteger.TWO.pow(64));
    IO.println("\"1\" + 2                " + ("1" + 2));
    IO.println("guitar emoji .length() " + "🎸".length());
    IO.println("-0.0 == 0.0            " + (-0.0 == 0.0));
}
