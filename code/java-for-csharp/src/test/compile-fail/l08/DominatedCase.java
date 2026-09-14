class Texts {
    static String kind(Object value) {
        return switch (value) {
            case CharSequence cs -> "text";
            case String s -> "string";
            default -> "other";
        };
    }
}
// expect: compiler.err.pattern.dominated
