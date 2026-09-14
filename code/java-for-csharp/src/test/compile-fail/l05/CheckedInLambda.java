import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

class Configs {
    static List<String> loadAll(List<Path> paths) {
        return paths.stream().map(path -> Files.readString(path)).toList();
    }
}
// expect: compiler.err.unreported.exception.need.to.catch.or.throw
