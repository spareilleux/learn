import java.io.IOException;

class Parser {
    static int parse(String text) {
        try {
            return Integer.parseInt(text);
        } catch (IOException e) {
            return -1;
        }
    }
}
// expect: compiler.err.except.never.thrown.in.try
