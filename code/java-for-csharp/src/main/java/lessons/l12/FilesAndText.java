package lessons.l12;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.Charset;
import java.nio.charset.MalformedInputException;
import java.nio.charset.StandardCharsets;
import java.nio.file.DirectoryNotEmptyException;
import java.nio.file.FileAlreadyExistsException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.Locale;
import java.util.stream.Stream;

/** Lesson 12: java.nio.file, where C# has File, Directory and Path, and text formatting with a locale. */
public class FilesAndText {

    public static void main(String[] args) throws IOException {
        Path dir = Files.createTempDirectory("l12");
        try {
            run(dir);
        } finally {
            try (Stream<Path> paths = Files.walk(dir)) {
                paths.sorted(Comparator.reverseOrder()).forEach(FilesAndText::delete);
            }
        }
    }

    static void run(Path dir) throws IOException {
        // Files.writeString is File.WriteAllText; UTF-8 is the default charset since JDK 18.
        System.out.println("default charset: " + Charset.defaultCharset());
        Path notes = dir.resolve("notes.txt");
        Files.writeString(notes, "pen\npad\nink\n");
        System.out.println("readAllLines: " + Files.readAllLines(notes));

        // Files.lines is File.ReadLines, but it holds the file open until the stream is closed.
        try (Stream<String> lines = Files.lines(notes)) {
            System.out.println("lines starting with p: " + lines.filter(line -> line.startsWith("p")).count());
        }

        // The exceptions are checked, and more specific than IOException.
        try {
            Files.readString(dir.resolve("missing.txt"));
        } catch (NoSuchFileException e) {
            System.out.println("NoSuchFileException: " + dir.relativize(Path.of(e.getFile())));
        }
        try {
            Files.createDirectory(dir);
        } catch (FileAlreadyExistsException e) {
            System.out.println("createDirectory: FileAlreadyExistsException");
        }
        Files.createDirectories(dir);
        System.out.println("createDirectories: no exception");
        try {
            Files.delete(dir);
        } catch (DirectoryNotEmptyException e) {
            System.out.println("delete: DirectoryNotEmptyException");
        }

        // Invalid UTF-8: Files.readString throws, new String replaces the byte.
        Path broken = Files.write(dir.resolve("broken.txt"), new byte[] {'A', (byte) 0xFF, 'B'});
        try {
            Files.readString(broken);
        } catch (MalformedInputException e) {
            System.out.println("MalformedInputException: " + e.getMessage());
        }
        String replaced = new String(Files.readAllBytes(broken), StandardCharsets.UTF_8);
        System.out.println("new String: " + replaced.chars().mapToObj(c -> String.format("U+%04X", c)).toList());

        // String.format uses the default locale, like CurrentCulture; pass one to get a fixed result.
        System.out.println("France: " + String.format(Locale.FRANCE, "%.2f", 1234.5));
        System.out.println("ROOT: " + String.format(Locale.ROOT, "%.2f", 1234.5));
        System.out.println("Turkish lower case has a dotless i: " + "TITLE".toLowerCase(Locale.forLanguageTag("tr")).equals("tıtle"));
    }

    private static void delete(Path path) {
        try {
            Files.delete(path);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
