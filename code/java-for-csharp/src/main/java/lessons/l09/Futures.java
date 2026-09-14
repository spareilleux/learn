package lessons.l09;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/** Lesson 9: CompletableFuture as Java's Task, and cancellation by interruption. */
public class Futures {

    static String fetchUser(int id) {
        return "user-" + id;
    }

    static int fetchScore(String user) {
        return user.length() * 10;
    }

    public static void main(String[] args) throws Exception {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            // supplyAsync is Task.Run; thenApply is the code after an await.
            CompletableFuture<Integer> score = CompletableFuture
                    .supplyAsync(() -> fetchUser(7), executor)
                    .thenApply(Futures::fetchScore);
            System.out.println("score: " + score.join());

            // thenCombine waits for two independent futures, like await Task.WhenAll(a, b).
            var name = CompletableFuture.supplyAsync(() -> "Ada", executor);
            var year = CompletableFuture.supplyAsync(() -> 1815, executor);
            System.out.println(name.thenCombine(year, (n, y) -> n + " was born in " + y).join());

            // allOf completes when every future has; the results are read afterwards.
            List<CompletableFuture<String>> users = List.of(1, 2, 3).stream()
                    .map(id -> CompletableFuture.supplyAsync(() -> fetchUser(id), executor))
                    .toList();
            CompletableFuture.allOf(users.toArray(CompletableFuture[]::new)).join();
            System.out.println(users.stream().map(CompletableFuture::join).toList());

            // Failures: join() wraps in CompletionException, get() in ExecutionException.
            CompletableFuture<Integer> failing = CompletableFuture.supplyAsync(() -> Integer.parseInt("x"), executor);
            try {
                failing.join();
            } catch (CompletionException e) {
                System.out.println("join: " + e.getCause().getClass().getSimpleName());
            }
            try {
                failing.get();
            } catch (ExecutionException e) {
                System.out.println("get: " + e.getCause().getClass().getSimpleName());
            }
            System.out.println("recovered: " + failing.exceptionally(e -> -1).join());

            // A timeout on the future itself, like Task.WaitAsync(TimeSpan).
            var slow = CompletableFuture.supplyAsync(() -> sleepThenReturn(1_000), executor);
            try {
                slow.get(50, TimeUnit.MILLISECONDS);
            } catch (TimeoutException e) {
                System.out.println("timed out after 50 ms");
            }
            // cancel(true) completes the CompletableFuture but does not interrupt the task behind it.
            System.out.println("slow cancelled: " + slow.cancel(true));

            // Cancellation: there is no CancellationToken; cancel(true) interrupts the thread running the task.
            var started = new CountDownLatch(1);
            var stopped = new CountDownLatch(1);
            var worker = executor.submit(() -> {
                started.countDown();
                try {
                    Thread.sleep(60_000);
                    return "finished";
                } catch (InterruptedException e) {
                    System.out.println("worker interrupted while sleeping");
                    stopped.countDown();
                    throw e;
                }
            });
            started.await();
            worker.cancel(true);
            stopped.await();
            System.out.println("cancelled: " + worker.isCancelled() + ", state: " + worker.state());
        } // close() still waits for the slow task, which was never interrupted
    }

    static int sleepThenReturn(int millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.out.println("slow task interrupted");
            return -1;
        }
        System.out.println("slow task ran to the end");
        return millis;
    }
}
