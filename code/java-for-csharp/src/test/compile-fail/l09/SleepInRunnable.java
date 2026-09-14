import java.util.concurrent.Executors;

class Sleeper {
    static void run() {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            executor.submit(() -> {
                Thread.sleep(100);
            });
        }
    }
}
// expect: compiler.err.unreported.exception.need.to.catch.or.throw
