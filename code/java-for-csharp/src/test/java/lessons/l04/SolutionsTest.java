package lessons.l04;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.ArrayList;
import java.util.List;
import java.util.function.IntFunction;
import java.util.function.Supplier;
import org.junit.jupiter.api.Test;

/** Lesson 4 exercise solutions. */
class SolutionsTest {

    static <T> T[] fill(int count, IntFunction<T[]> newArray, Supplier<T> factory) {
        T[] result = newArray.apply(count);
        for (int i = 0; i < count; i++) {
            result[i] = factory.get();
        }
        return result;
    }

    @Test
    void exercise1Fill() {
        StringBuilder[] builders = fill(3, StringBuilder[]::new, StringBuilder::new);
        assertEquals(3, builders.length);
        assertEquals(StringBuilder[].class, builders.getClass());
    }

    static <T> void copy(List<? super T> destination, List<? extends T> source) {
        for (T item : source) {
            destination.add(item);
        }
    }

    @Test
    void exercise2Copy() {
        List<Integer> integers = List.of(1, 2);
        List<Number> numbers = new ArrayList<>(List.of(0.5));
        copy(numbers, integers);
        assertEquals(List.of(0.5, 1, 2), numbers);
    }

    static <T> List<T> ofType(List<?> items, Class<T> type) {
        return items.stream().filter(type::isInstance).map(type::cast).toList();
    }

    @Test
    void exercise3OfType() {
        List<Object> items = List.of(1, "two", List.of("three"), List.of(4));
        assertEquals(List.of("two"), ofType(items, String.class));
        // List.class matches every list, whatever its elements.
        assertEquals(2, ofType(items, List.class).size());
    }
}
