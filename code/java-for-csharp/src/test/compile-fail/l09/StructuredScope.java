import java.util.concurrent.StructuredTaskScope;

class Fanout {
    static String both() throws InterruptedException {
        try (var scope = StructuredTaskScope.open()) {
            var user = scope.fork(() -> "ada");
            var order = scope.fork(() -> 42);
            scope.join();
            return user.get() + " " + order.get();
        }
    }
}
// expect: compiler.err.is.preview
