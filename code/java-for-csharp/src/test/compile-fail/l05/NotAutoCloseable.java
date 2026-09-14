class Session {
    void end() {}

    static void run() {
        try (var session = new Session()) {
            System.out.println("working");
        }
    }
}
// expect: compiler.err.prob.found.req
