@FunctionalInterface
interface Handler {
    void handle(String message);

    void close();
}
// expect: compiler.err.bad.functional.intf.anno.1
