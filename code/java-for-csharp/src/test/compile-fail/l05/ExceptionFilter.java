class Filters {
    static int parse(String text) {
        try {
            return Integer.parseInt(text);
        } catch (NumberFormatException e) when (text.isBlank()) {
            return 0;
        }
    }
}
// expect: compiler.err.expected
