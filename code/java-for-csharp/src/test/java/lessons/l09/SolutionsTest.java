package lessons.l09;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.Semaphore;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Function;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Lesson 9 exercise solutions. */
class SolutionsTest {

    static <T, R> List<R> fetchAll(List<T> inputs, Function<T, R> fetch) throws InterruptedException, ExecutionException {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            List<Callable<R>> calls = inputs.stream().<Callable<R>>map(input -> () -> fetch.apply(input)).toList();
            List<R> results = new ArrayList<>();
            for (Future<R> future : executor.invokeAll(calls)) {
                results.add(future.get());
            }
            return results;
        }
    }

    static String slowUpperCase(String s) {
        try {
            Thread.sleep(200);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return s.toUpperCase();
    }

    @Test
    void exercise1WhenAll() throws Exception {
        var inputs = IntStream.range(0, 100).mapToObj(i -> "item" + i).toList();
        long start = System.nanoTime();
        var results = fetchAll(inputs, SolutionsTest::slowUpperCase);
        var elapsed = Duration.ofNanos(System.nanoTime() - start);
        assertEquals(inputs.stream().map(String::toUpperCase).toList(), results);
        assertTrue(elapsed.compareTo(Duration.ofSeconds(5)) < 0, "took " + elapsed);
    }

    static <T, R> List<R> mapThrottled(List<T> inputs, int maxConcurrency, Function<T, R> work)
            throws InterruptedException, ExecutionException {
        var permits = new Semaphore(maxConcurrency);
        return fetchAll(inputs, input -> {
            try {
                permits.acquire();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException(e);
            }
            try {
                return work.apply(input);
            } finally {
                permits.release();
            }
        });
    }

    @Test
    void exercise2Throttle() throws Exception {
        var running = new AtomicInteger();
        var maxSeen = new AtomicInteger();
        var results = mapThrottled(List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 3, n -> {
            maxSeen.accumulateAndGet(running.incrementAndGet(), Math::max);
            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            running.decrementAndGet();
            return n * n;
        });
        assertEquals(List.of(1, 4, 9, 16, 25, 36, 49, 64, 81, 100), results);
        assertTrue(maxSeen.get() <= 3, "max concurrency " + maxSeen.get());
    }

    static final class Account {
        final int id;
        long balance;

        Account(int id, long balance) {
            this.id = id;
            this.balance = balance;
        }
    }

    // Lock the account with the smaller id first, so two opposite transfers can't wait for each other.
    static void transfer(Account from, Account to, long amount) {
        Account first = from.id < to.id ? from : to;
        Account second = first == from ? to : from;
        synchronized (first) {
            synchronized (second) {
                from.balance -= amount;
                to.balance += amount;
            }
        }
    }

    @Test
    void exercise3NoDeadlock() {
        var a = new Account(1, 1_000_000);
        var b = new Account(2, 1_000_000);
        assertTimeoutPreemptively(Duration.ofSeconds(20), () -> {
            try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
                for (int i = 0; i < 10_000; i++) {
                    long amount = ThreadLocalRandom.current().nextLong(1, 10);
                    boolean forward = i % 2 == 0;
                    executor.submit(() -> {
                        if (forward) {
                            transfer(a, b, amount);
                        } else {
                            transfer(b, a, amount);
                        }
                    });
                }
            }
        });
        synchronized (a) {
            synchronized (b) {
                assertEquals(2_000_000, a.balance + b.balance);
            }
        }
    }
}
