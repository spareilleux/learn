class IntIsNotBoolean {
    void run(int count) {
        if (count) {
            System.out.println("some");
        }
    }
}
// expect: compiler.err.prob.found.req
