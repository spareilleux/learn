class Anything {
    static String describe(Object value) {
        return switch (value) {
            case String s -> "string";
            case Object o -> "object";
            default -> "unreachable";
        };
    }
}
// expect: compiler.err.unconditional.pattern.and.default
