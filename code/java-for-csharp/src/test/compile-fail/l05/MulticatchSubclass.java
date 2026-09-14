import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

class Loader {
    static String load(Path path) {
        try {
            return Files.readString(path);
        } catch (FileNotFoundException | IOException e) {
            return "";
        }
    }
}
// expect: compiler.err.multicatch.types.must.be.disjoint
