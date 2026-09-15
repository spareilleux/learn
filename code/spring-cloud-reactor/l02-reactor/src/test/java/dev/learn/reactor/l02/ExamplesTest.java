package dev.learn.reactor.l02;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;

/** Runs every example of the lesson and compares what it prints with {@code expected/<Example>.txt}. */
class ExamplesTest {

    @TestFactory
    Stream<DynamicTest> examplesPrintWhatTheLessonShows() {
        return Stream.of(AssemblyAndSubscription.class, Operators.class, Signals.class)
                .map(example -> DynamicTest.dynamicTest(example.getSimpleName(), () -> run(example)));
    }

    private static void run(Class<?> example) throws Exception {
        var buffer = new ByteArrayOutputStream();
        var out = System.out;
        var err = System.err;
        var capture = new PrintStream(buffer, true, StandardCharsets.UTF_8);
        System.setOut(capture);
        System.setErr(capture);
        try {
            example.getMethod("main", String[].class).invoke(null, (Object) new String[0]);
        } finally {
            System.setOut(out);
            System.setErr(err);
        }
        Expected.check(example.getSimpleName(), buffer.toString(StandardCharsets.UTF_8));
    }
}
