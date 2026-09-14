package lessons.l09;

import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.IntStream;

/** Lesson 9: parallel streams, Java's PLINQ. */
public class ParallelStreams {

    static boolean isPrime(int n) {
        if (n < 2) {
            return false;
        }
        for (int d = 2; (long) d * d <= n; d++) {
            if (n % d == 0) {
                return false;
            }
        }
        return true;
    }

    public static void main(String[] args) {
        // parallel() is AsParallel(); the result is the same as the sequential one.
        long sequential = IntStream.rangeClosed(1, 2_000_000).filter(ParallelStreams::isPrime).count();
        long parallel = IntStream.rangeClosed(1, 2_000_000).parallel().filter(ParallelStreams::isPrime).count();
        System.out.println("primes up to 2,000,000: " + sequential + " sequential, " + parallel + " parallel");

        // Unlike PLINQ without AsOrdered(), collecting keeps the encounter order.
        List<Integer> squares = IntStream.rangeClosed(1, 10).parallel().map(x -> x * x).boxed().toList();
        System.out.println("squares: " + squares);

        // forEach runs in whatever order the threads reach the elements; forEachOrdered restores it.
        var ordered = new StringBuilder();
        IntStream.rangeClosed(1, 10).parallel().forEachOrdered(x -> ordered.append(x).append(' '));
        System.out.println("forEachOrdered: " + ordered.toString().strip());

        // reduce needs a true identity: 0 for addition. Sequentially, a wrong identity is added once.
        int wrongIdentitySequential = IntStream.rangeClosed(1, 4).reduce(10, Integer::sum);
        int rightIdentityParallel = IntStream.rangeClosed(1, 4).parallel().reduce(0, Integer::sum);
        System.out.println("reduce(10) sequential: " + wrongIdentitySequential + ", reduce(0) parallel: " + rightIdentityParallel);

        // Parallel streams run on the common ForkJoinPool, shared by the whole JVM.
        Set<String> threads = ConcurrentHashMap.newKeySet();
        IntStream.rangeClosed(1, 2_000_000).parallel().filter(n -> {
            threads.add(Thread.currentThread().getName());
            return isPrime(n);
        }).count();
        System.out.println("caller thread took part: " + threads.contains(Thread.currentThread().getName()));
        System.out.println("common pool workers took part: " + threads.stream().anyMatch(t -> t.startsWith("ForkJoinPool.commonPool-worker-")));
    }
}
