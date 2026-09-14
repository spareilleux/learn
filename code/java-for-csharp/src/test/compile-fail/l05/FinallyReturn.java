class Totals {
    static int total() {
        try {
            return 1;
        } finally {
            return 2;
        }
    }
}
// expect-warning: compiler.warn.finally.cannot.complete
