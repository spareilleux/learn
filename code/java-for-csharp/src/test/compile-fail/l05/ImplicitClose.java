import java.io.BufferedReader;
import java.io.StringReader;

class FirstLine {
    static String firstLine(String text) {
        try (BufferedReader reader = new BufferedReader(new StringReader(text))) {
            return reader.readLine();
        }
    }
}
// expect: compiler.err.unreported.exception.implicit.close
// expect: compiler.err.unreported.exception.need.to.catch.or.throw
