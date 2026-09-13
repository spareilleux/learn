class VarWithoutInitializer {
    void run() {
        var total;
        total = 42;
    }
}
// expect: compiler.err.cant.infer.local.var.type
