package lessons.l09;

import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.LongAdder;
import java.util.concurrent.locks.ReentrantLock;

/** Lesson 9: locks, atomics and concurrent collections. */
public class SharedState {

    static final int TASKS = 1_000;
    static final int INCREMENTS = 1_000;

    static class Counter {
        private int value;

        // synchronized is C#'s lock (this); every object has a monitor.
        synchronized void increment() {
            value++;
        }

        synchronized int value() {
            return value;
        }
    }

    static class Account {
        private final ReentrantLock lock = new ReentrantLock();
        private long balance;

        // An explicit lock, with try/finally where C# uses a lock statement.
        void deposit(long amount) {
            lock.lock();
            try {
                balance += amount;
            } finally {
                lock.unlock();
            }
        }

        long balance() {
            lock.lock();
            try {
                return balance;
            } finally {
                lock.unlock();
            }
        }
    }

    static void runTasks(Runnable body) {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int t = 0; t < TASKS; t++) {
                executor.submit(() -> {
                    for (int i = 0; i < INCREMENTS; i++) {
                        body.run();
                    }
                });
            }
        }
    }

    public static void main(String[] args) {
        var counter = new Counter();
        runTasks(counter::increment);
        System.out.println("synchronized: " + counter.value());

        var atomic = new AtomicInteger();
        runTasks(atomic::incrementAndGet);
        System.out.println("AtomicInteger: " + atomic.get());

        var adder = new LongAdder();
        runTasks(adder::increment);
        System.out.println("LongAdder: " + adder.sum());

        var account = new Account();
        runTasks(() -> account.deposit(1));
        System.out.println("ReentrantLock: " + account.balance());

        // merge is atomic per key, like ConcurrentDictionary.AddOrUpdate.
        var words = List.of("to", "be", "or", "not", "to", "be");
        var counts = new ConcurrentHashMap<String, Integer>();
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int copy = 0; copy < 100; copy++) {
                for (String word : words) {
                    executor.submit(() -> counts.merge(word, 1, Integer::sum));
                }
            }
        }
        Map<String, Integer> sorted = new TreeMap<>(counts);
        System.out.println("word counts: " + sorted);
    }
}
