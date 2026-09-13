package lessons;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;

/**
 * Runs every lesson example and compares what it prints with the output quoted in the lesson.
 * {@code src/test/expected/l02/Boxing.txt} holds the expected output of {@code lessons.l02.Boxing}.
 */
class ExamplesTest {

    private static final Path EXPECTED = Path.of("src/test/expected");

    @TestFactory
    Stream<DynamicTest> examplesPrintTheOutputShownInTheLessons() throws IOException {
        return Files.walk(EXPECTED)
                .filter(p -> p.toString().endsWith(".txt"))
                .sorted()
                .map(p -> DynamicTest.dynamicTest(className(p), () -> check(p)));
    }

    private static String className(Path expected) {
        var relative = EXPECTED.relativize(expected).toString().replace('\\', '/');
        return "lessons." + relative.substring(0, relative.length() - ".txt".length()).replace('/', '.');
    }

    private static void check(Path expected) throws Exception {
        var main = Class.forName(className(expected)).getMethod("main", String[].class);
        var buffer = new ByteArrayOutputStream();
        var original = System.out;
        System.setOut(new PrintStream(buffer, true, StandardCharsets.UTF_8));
        try {
            main.invoke(null, (Object) new String[0]);
        } finally {
            System.setOut(original);
        }
        assertEquals(normalize(Files.readString(expected)), normalize(buffer.toString(StandardCharsets.UTF_8)));
    }

    private static String normalize(String s) {
        return s.replace("\r\n", "\n").strip();
    }
}
