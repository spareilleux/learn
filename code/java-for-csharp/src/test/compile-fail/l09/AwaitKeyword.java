import java.util.concurrent.CompletableFuture;

class Client {
    static CompletableFuture<String> fetch() {
        return CompletableFuture.completedFuture("ok");
    }

    static String body() {
        return await fetch();
    }
}
// expect: compiler.err.expected
