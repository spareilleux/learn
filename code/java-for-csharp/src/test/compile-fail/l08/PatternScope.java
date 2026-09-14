class Scope {
    static int length(Object value) {
        if (value instanceof String s || value == null) {
            return s.length();
        }
        return 0;
    }
}
// expect: compiler.err.cant.resolve.location
