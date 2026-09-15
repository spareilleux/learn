package dev.learn.reactor.l02;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/** Compares an output with {@code expected/<name>.txt}, the text quoted in the lesson. {@code -Dupdate.expected=true} rewrites the file. */
final class Expected {

    private Expected() {}

    static void check(String name, String actual) {
        Path file = Path.of("expected", name + ".txt");
        String normalized = actual.replace("\r\n", "\n").strip() + "\n";
        try {
            if (Boolean.getBoolean("update.expected")) {
                Files.createDirectories(file.getParent());
                Files.writeString(file, normalized, StandardCharsets.UTF_8);
            }
            assertEquals(Files.readString(file, StandardCharsets.UTF_8).replace("\r\n", "\n"), normalized, file.toString());
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
