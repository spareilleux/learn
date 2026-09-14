package lessons.l09;

import java.time.Duration;
import java.util.ArrayList;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

/** Lesson 9: platform threads, virtual threads and executors. */
public class Threads {

    public static void main(String[] args) throws InterruptedException, ExecutionException {
        // A platform thread wraps an operating system thread, like new Thread(...) in .NET.
        Thread platform = Thread.ofPlatform().name("platform-1").start(() -> System.out.println("hello from a platform thread"));
        platform.join();

        // A virtual thread is scheduled by the JVM onto a few carrier threads.
        Thread virtual = Thread.ofVirtual().name("virtual-1").start(() -> {
            Thread current = Thread.currentThread();
            System.out.println(current.getName() + " isVirtual=" + current.isVirtual() + " daemon=" + current.isDaemon());
        });
        virtual.join();

        // One virtual thread per task: blocking calls are cheap, so there is no async/await.
        long start = System.nanoTime();
        var results = new ArrayList<Future<Integer>>();
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 10_000; i++) {
                int id = i;
                results.add(executor.submit(() -> {
                    Thread.sleep(Duration.ofSeconds(1));
                    return id;
                }));
            }
        } // close() waits for every task, like await Task.WhenAll(...)
        long sum = 0;
        for (Future<Integer> result : results) {
            sum += result.get();
        }
        Duration elapsed = Duration.ofNanos(System.nanoTime() - start);
        System.out.println("10,000 tasks slept 1 s each; sum of ids = " + sum);
        System.out.println("finished in under 5 s: " + (elapsed.compareTo(Duration.ofSeconds(5)) < 0));

        // An exception inside a task is kept in its Future and rethrown, wrapped, by get().
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            Future<Integer> failing = executor.submit(() -> Integer.parseInt("forty-two"));
            try {
                failing.get();
            } catch (ExecutionException e) {
                System.out.println("get() threw " + e.getClass().getSimpleName() + " caused by " + e.getCause());
            }
        }
    }
}
