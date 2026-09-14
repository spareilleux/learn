class Clicks {
    static int count() throws InterruptedException {
        int count = 0;
        Thread worker = Thread.ofVirtual().start(() -> count++);
        worker.join();
        return count;
    }
}
// expect: compiler.err.cant.ref.non.effectively.final.var
