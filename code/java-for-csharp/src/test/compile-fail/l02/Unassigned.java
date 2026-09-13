class Unassigned {
    int run(boolean flag) {
        int result;
        if (flag) {
            result = 1;
        }
        return result;
    }
}
// expect: compiler.err.var.might.not.have.been.initialized
