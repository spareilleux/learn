import java.util.concurrent.CompletableFuture;

class Results {
    static String name() {
        return CompletableFuture.supplyAsync(() -> "Ada").get();
    }
}
// expect: compiler.err.unreported.exception.need.to.catch.or.throw
