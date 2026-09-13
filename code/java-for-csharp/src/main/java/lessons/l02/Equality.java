package lessons.l02;

/** Lesson 2: == compares references for objects, including boxed numbers and strings. */
public class Equality {
    public static void main(String[] args) {
        Integer a = 127;
        Integer b = 127;
        Integer c = 128;
        Integer d = 128;
        System.out.println(a == b);
        System.out.println(c == d);
        System.out.println(c.equals(d));

        String literal = "hello";
        String sameLiteral = "hello";
        String built = new StringBuilder("hel").append("lo").toString();
        System.out.println(literal == sameLiteral);
        System.out.println(literal == built);
        System.out.println(literal.equals(built));

        // Unboxing a null Integer throws.
        Integer missing = null;
        try {
            int value = missing;
            System.out.println(value);
        } catch (NullPointerException e) {
            System.out.println("NullPointerException: " + e.getMessage());
        }
    }
}
