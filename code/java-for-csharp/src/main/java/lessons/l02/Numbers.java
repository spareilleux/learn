package lessons.l02;

/** Lesson 2: primitive numbers, overflow, and the missing unsigned types. */
public class Numbers {
    public static void main(String[] args) {
        // Integer overflow wraps silently, as in unchecked C#.
        int max = Integer.MAX_VALUE;
        System.out.println(max + 1);

        // Math.*Exact is Java's `checked`.
        try {
            System.out.println(Math.addExact(max, 1));
        } catch (ArithmeticException e) {
            System.out.println("ArithmeticException: " + e.getMessage());
        }

        // byte is signed: -128..127. There is no unsigned byte.
        byte b = (byte) 200;
        System.out.println(b);
        System.out.println(Byte.toUnsignedInt(b));

        // Unsigned views of int and long exist as static methods.
        int allOnes = -1;
        System.out.println(Integer.toUnsignedString(allOnes));
        System.out.println(Integer.divideUnsigned(allOnes, 2));

        // Integer division by zero throws; floating-point division does not.
        System.out.println(1.0 / 0);
        try {
            System.out.println(1 / zero());
        } catch (ArithmeticException e) {
            System.out.println("ArithmeticException: " + e.getMessage());
        }

        // char is a UTF-16 code unit, and arithmetic promotes it to int.
        char c = 'a';
        System.out.println(c + 1);
        System.out.println((char) (c + 1));
    }

    private static int zero() {
        return 0;
    }
}
