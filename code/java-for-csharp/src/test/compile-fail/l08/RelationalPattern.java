class Signs {
    static String sign(int n) {
        return switch (n) {
            case < 0 -> "negative";
            case 0 -> "zero";
            default -> "positive";
        };
    }
}
// expect: compiler.err.illegal.start.of.type
