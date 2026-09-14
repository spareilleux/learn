class Tally {
    private int count;

    void increment() {
        synchronized (count) {
            count++;
        }
    }
}
// expect: compiler.err.type.found.req
