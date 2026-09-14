import java.nio.file.Files;
import java.nio.file.Path;

class Config {
    static String load() {
        return Files.readString(Path.of("app.properties"));
    }
}
// expect: compiler.err.unreported.exception.need.to.catch.or.throw
