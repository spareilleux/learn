class Tally {
    private Integer count = 0;

    void increment() {
        synchronized (count) {
            count++;
        }
    }
}
// expect-warning: compiler.warn.attempt.to.synchronize.on.instance.of.value.based.class
