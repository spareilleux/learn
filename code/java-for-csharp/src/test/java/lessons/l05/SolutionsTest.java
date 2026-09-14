package lessons.l05;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.OptionalInt;
import java.util.function.Function;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Lesson 5 exercise solutions. */
class SolutionsTest {

    @FunctionalInterface
    interface ThrowingFunction<T, R> {
        R apply(T value) throws Exception;
    }

    static <T, R> Function<T, R> unchecked(ThrowingFunction<T, R> function) {
        return value -> {
            try {
                return function.apply(value);
            } catch (IOException e) {
                throw new UncheckedIOException(e);
            } catch (RuntimeException e) {
                throw e;
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        };
    }

    @Test
    void exercise1CheckedExceptionsInLambdas(@TempDir Path dir) throws IOException {
        Path a = Files.writeString(dir.resolve("a.txt"), "alpha");
        Path b = Files.writeString(dir.resolve("b.txt"), "beta");
        assertEquals(List.of("alpha", "beta"), Stream.of(a, b).map(unchecked(Files::readString)).toList());

        var e = assertThrows(UncheckedIOException.class,
                () -> Stream.of(dir.resolve("missing.txt")).map(unchecked(Files::readString)).toList());
        assertInstanceOf(NoSuchFileException.class, e.getCause());
    }

    static OptionalInt parsePort(String text) {
        try {
            int port = Integer.parseInt(text);
            return port >= 0 && port <= 65535 ? OptionalInt.of(port) : OptionalInt.empty();
        } catch (NumberFormatException e) {
            return OptionalInt.empty();
        }
    }

    @Test
    void exercise2ParsePort() {
        assertEquals(9090, parsePort("9090").orElse(8080));
        assertEquals(8080, parsePort("http").orElse(8080));
        assertEquals(8080, parsePort("70000").orElse(8080));
    }

    record Resource(String name, List<String> log) implements AutoCloseable {
        @Override
        public void close() {
            log.add("close " + name);
            throw new IllegalStateException("close " + name);
        }
    }

    @Test
    void exercise3SuppressedOrder() {
        var log = new ArrayList<String>();
        var e = assertThrows(IllegalArgumentException.class, () -> {
            try (var first = new Resource("first", log);
                    var second = new Resource("second", log)) {
                throw new IllegalArgumentException("body " + first.name() + " " + second.name());
            }
        });
        assertEquals("body first second", e.getMessage());
        assertEquals(List.of("close second", "close first"), log);
        assertEquals(List.of("close second", "close first"),
                Arrays.stream(e.getSuppressed()).map(Throwable::getMessage).toList());
    }
}
