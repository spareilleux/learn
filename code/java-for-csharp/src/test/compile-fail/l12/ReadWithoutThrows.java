import java.nio.file.Files;
import java.nio.file.Path;

class Notes {
    static String read(Path path) {
        return Files.readString(path);
    }
}
// expect: compiler.err.unreported.exception.need.to.catch.or.throw
