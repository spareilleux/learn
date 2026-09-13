class SwitchNotExhaustive {
    String describe(int code) {
        return switch (code) {
            case 200 -> "OK";
            case 404 -> "Not Found";
        };
    }
}
// expect: compiler.err.not.exhaustive
