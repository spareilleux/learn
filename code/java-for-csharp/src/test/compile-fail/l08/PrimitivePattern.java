class Bytes {
    static String fits(int value) {
        return switch (value) {
            case byte b -> "fits in a byte";
            default -> "needs an int";
        };
    }
}
// expect: compiler.err.preview.feature.disabled.plural
