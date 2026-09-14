package lessons.l06;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;
import java.util.function.UnaryOperator;
import org.junit.jupiter.api.Test;

/** Lesson 6 exercise solutions. */
class SolutionsTest {

    static UnaryOperator<String> pipeline(List<UnaryOperator<String>> steps) {
        return steps.stream().reduce(UnaryOperator.identity(), (f, g) -> s -> g.apply(f.apply(s)));
    }

    @Test
    void exercise1Pipeline() {
        UnaryOperator<String> clean = pipeline(List.of(String::strip, String::toLowerCase, s -> s.replace(' ', '-')));
        assertEquals("hello-java-world", clean.apply("  Hello Java World "));
        assertEquals("unchanged", pipeline(List.of()).apply("unchanged"));
    }

    @Test
    void exercise2CountWithoutMutation() {
        List<String> words = List.of("a", "lambda", "is", "not", "a", "delegate");
        long longWords = words.stream().filter(w -> w.length() > 3).count();
        assertEquals(2, longWords);
    }

    interface Subscription extends AutoCloseable {
        @Override
        void close(); // no checked exception, unlike AutoCloseable.close()
    }

    static class PriceFeed {
        private final List<Consumer<Double>> listeners = new ArrayList<>();

        Subscription subscribe(Consumer<Double> listener) {
            listeners.add(listener);
            return () -> listeners.remove(listener);
        }

        void publish(double price) {
            List.copyOf(listeners).forEach(listener -> listener.accept(price));
        }
    }

    @Test
    void exercise3Subscription() {
        var feed = new PriceFeed();
        var received = new ArrayList<Double>();
        try (Subscription subscription = feed.subscribe(received::add)) {
            feed.publish(1.0);
        }
        feed.publish(2.0);
        assertEquals(List.of(1.0), received);
    }
}
