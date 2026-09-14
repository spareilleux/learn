import java.util.concurrent.Callable;
import java.util.function.Supplier;

class Scheduler {
    static void schedule(Supplier<String> job) {}

    static void schedule(Callable<String> job) {}

    static void run() {
        schedule(() -> "report");
    }
}
// expect: compiler.err.ref.ambiguous
