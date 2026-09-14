package lessons.l07;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.BiFunction;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Lesson 7 exercise solutions. */
class SolutionsTest {

    record Order(String customer, String product, int quantity) {}

    static final List<Order> ORDERS = List.of(
            new Order("ada", "keyboard", 1),
            new Order("alan", "mouse", 2),
            new Order("ada", "monitor", 2),
            new Order("grace", "mouse", 1),
            new Order("alan", "cable", 5));

    static String bestSeller(List<Order> orders) {
        return orders.stream()
                .collect(Collectors.groupingBy(Order::product, Collectors.summingInt(Order::quantity)))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElseThrow();
    }

    @Test
    void exercise1BestSeller() {
        assertEquals("cable", bestSeller(ORDERS));
    }

    static List<String> topWords(String text, int n) {
        return Arrays.stream(text.toLowerCase().split("\\W+"))
                .filter(w -> !w.isEmpty())
                .collect(Collectors.groupingBy(w -> w, Collectors.counting()))
                .entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue(Comparator.reverseOrder())
                        .thenComparing(Map.Entry.comparingByKey()))
                .limit(n)
                .map(e -> e.getKey() + "=" + e.getValue())
                .toList();
    }

    @Test
    void exercise2TopWords() {
        assertEquals(List.of("be=2", "to=2", "not=1"), topWords("To be, or not to be.", 3));
    }

    static <A, B, R> List<R> zip(List<A> first, List<B> second, BiFunction<A, B, R> combine) {
        return IntStream.range(0, Math.min(first.size(), second.size()))
                .mapToObj(i -> combine.apply(first.get(i), second.get(i)))
                .toList();
    }

    @Test
    void exercise3Zip() {
        assertEquals(List.of("keyboardx1", "mousex2"), zip(List.of("keyboard", "mouse", "cable"), List.of(1, 2), (p, q) -> p + "x" + q));
    }
}
