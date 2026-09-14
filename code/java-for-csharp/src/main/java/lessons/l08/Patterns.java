package lessons.l08;

import java.util.List;
import java.util.Map;

/** Lesson 8: instanceof patterns, switch over any type, null and unnamed variables. */
public class Patterns {

    static String classify(Object value) {
        return switch (value) {
            case null -> "null";
            case Integer i when i < 0 -> "negative int " + i;
            case Integer i -> "int " + i;
            case String s when s.isBlank() -> "blank string";
            case String s -> "string of length " + s.length();
            case int[] array -> "int array of length " + array.length;
            case List<?> list -> "list of " + list.size();
            default -> "something else: " + value.getClass().getSimpleName();
        };
    }

    static int lengthOrZero(Object value) {
        // The pattern variable is in scope wherever the match is certain.
        if (!(value instanceof String text)) {
            return 0;
        }
        return text.length();
    }

    enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES }

    static String color(Suit suit) {
        // Several constants in one case, and no default: the enum switch is exhaustive.
        return switch (suit) {
            case HEARTS, DIAMONDS -> "red";
            case CLUBS, SPADES -> "black";
        };
    }

    public static void main(String[] args) {
        for (Object value : new Object[] {null, -4, 42, " ", "pattern", new int[3], List.of(1, 2), 3.5}) {
            System.out.println(classify(value));
        }

        Object value = "matched";
        if (value instanceof String s && s.length() > 3) {
            System.out.println("long string: " + s);
        }
        System.out.println(lengthOrZero("four") + " " + lengthOrZero(4));
        System.out.println(color(Suit.HEARTS) + " " + color(Suit.SPADES));

        // Unnamed variables (Java 22): _ for what you don't use.
        Map<String, Integer> scores = Map.of("ada", 3);
        scores.forEach((_, score) -> System.out.println("score " + score));
        try {
            Integer.parseInt("x");
        } catch (NumberFormatException _) {
            System.out.println("not a number");
        }
    }
}
