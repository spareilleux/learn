import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

class Reader {
    static String read(Path path) {
        try {
            return Files.readString(path);
        } catch (Exception e) {
            return "";
        } catch (IOException e) {
            return "I/O error";
        }
    }
}
// expect: compiler.err.except.already.caught
