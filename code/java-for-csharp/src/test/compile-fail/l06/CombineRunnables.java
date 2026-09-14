class Combine {
    static void run() {
        Runnable hello = () -> System.out.print("hello ");
        Runnable world = () -> System.out.println("world");
        Runnable both = hello + world;
    }
}
// expect: compiler.err.operator.cant.be.applied.1
