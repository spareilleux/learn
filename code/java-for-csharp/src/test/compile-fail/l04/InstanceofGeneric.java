import java.util.List;

class Checks {
    boolean isNames(Object value) {
        return value instanceof List<String>;
    }
}
// expect: compiler.err.instanceof.reifiable.not.safe
