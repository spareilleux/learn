package lessons.l05;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;

/** Lesson 5: checked and unchecked exceptions, multi-catch and causes. */
public class Checked {

    // The throws clause is part of the signature: callers must catch or declare IOException.
    static String readConfig(Path path) throws IOException {
        return Files.readString(path);
    }

    static int parsePort(String text) {
        // NumberFormatException is unchecked: nothing forces the caller to handle it.
        return Integer.parseInt(text);
    }

    static String loadOrWrap(Path path) {
        try {
            return readConfig(path);
        } catch (IOException e) {
            // Wrap in an unchecked exception and keep the original as the cause.
            throw new UncheckedIOException("cannot load " + path.getFileName(), e);
        }
    }

    public static void main(String[] args) {
        try {
            readConfig(Path.of("missing.properties"));
        } catch (NoSuchFileException e) {
            System.out.println("NoSuchFileException: " + e.getMessage());
        } catch (IOException e) {
            System.out.println("other I/O error: " + e);
        }

        for (String text : new String[] {"8080", "http"}) {
            try {
                System.out.println("port " + parsePort(text));
            } catch (NumberFormatException | NullPointerException e) {
                System.out.println(e.getClass().getSimpleName() + ": " + e.getMessage());
            }
        }

        try {
            loadOrWrap(Path.of("missing.properties"));
        } catch (UncheckedIOException e) {
            System.out.println(e.getMessage());
            System.out.println("caused by " + e.getCause().getClass().getSimpleName());
        }
    }
}
