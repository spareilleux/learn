class Increments {
    static void run() {
        var increment = (int x) -> x + 1;
    }
}
// expect: compiler.err.cant.infer.local.var.type
