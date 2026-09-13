package lessons;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Stream;
import javax.tools.Diagnostic;
import javax.tools.DiagnosticCollector;
import javax.tools.JavaFileObject;
import javax.tools.ToolProvider;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;

/**
 * Compiles every snippet a lesson shows as rejected and checks that javac reports the diagnostic the lesson quotes.
 * Each file starts with one or more {@code // expect: <diagnostic key>} lines, for example
 * {@code // expect: compiler.err.cant.resolve.location}. {@code // expect-warning: <key>} checks a warning
 * instead; a snippet with only expected warnings must still compile. Snippets can use the lesson examples, which are
 * on the class path.
 */
class CompileFailTest {

    private static final Path SNIPPETS = Path.of("src/test/compile-fail");

    @TestFactory
    Stream<DynamicTest> snippetsProduceTheDiagnosticsShownInTheLessons() throws IOException {
        return Files.walk(SNIPPETS)
                .filter(p -> p.toString().endsWith(".java"))
                .sorted()
                .map(p -> DynamicTest.dynamicTest(SNIPPETS.relativize(p).toString(), () -> check(p)));
    }

    private static void check(Path snippet) throws IOException {
        var lines = Files.readAllLines(snippet);
        var errors = keys(lines, "// expect: ");
        var warnings = keys(lines, "// expect-warning: ");
        assertFalse(errors.isEmpty() && warnings.isEmpty(), "no // expect line in " + snippet);

        var out = Files.createTempDirectory("compile-fail");
        var diagnostics = new DiagnosticCollector<JavaFileObject>();
        var compiler = ToolProvider.getSystemJavaCompiler();
        try (var files = compiler.getStandardFileManager(diagnostics, Locale.ENGLISH, null)) {
            var options = List.of("--release", "25", "-Xlint:all", "-cp", "target/classes", "-d", out.toString());
            var ok = compiler.getTask(null, files, diagnostics, options, null, files.getJavaFileObjects(snippet)).call();
            var reported = diagnostics.getDiagnostics().stream()
                    .map(d -> d.getKind() + " " + d.getCode() + ": " + d.getMessage(Locale.ENGLISH))
                    .toList();
            for (var key : errors) {
                assertTrue(
                        diagnostics.getDiagnostics().stream()
                                .anyMatch(d -> d.getKind() == Diagnostic.Kind.ERROR && key.equals(d.getCode())),
                        "expected error " + key + " but javac reported " + reported);
            }
            for (var key : warnings) {
                assertTrue(
                        diagnostics.getDiagnostics().stream()
                                .anyMatch(d -> d.getKind() != Diagnostic.Kind.ERROR && key.equals(d.getCode())),
                        "expected warning " + key + " but javac reported " + reported);
            }
            if (errors.isEmpty()) {
                assertTrue(ok, "a snippet with only expected warnings must compile: " + reported);
            }
        }
    }

    private static List<String> keys(List<String> lines, String prefix) {
        var keys = new ArrayList<String>();
        for (var line : lines) {
            if (line.startsWith(prefix)) {
                keys.add(line.substring(prefix.length()).strip());
            }
        }
        return keys;
    }
}
