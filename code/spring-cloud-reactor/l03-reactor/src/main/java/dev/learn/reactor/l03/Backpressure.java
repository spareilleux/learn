package dev.learn.reactor.l03;

import java.util.ArrayList;
import java.util.List;
import org.reactivestreams.Subscription;
import reactor.core.publisher.BaseSubscriber;
import reactor.core.publisher.Flux;
import reactor.core.scheduler.Schedulers;

public class Backpressure {

    /** A subscriber that asks for {@code batch} elements, then for more only if {@code askForMore}. */
    static final class Batches<T> extends BaseSubscriber<T> {
        private final int batch;
        private final boolean askForMore;
        private int received;

        Batches(int batch, boolean askForMore) {
            this.batch = batch;
            this.askForMore = askForMore;
        }

        @Override
        protected void hookOnSubscribe(Subscription subscription) {
            request(batch);
        }

        @Override
        protected void hookOnNext(T value) {
            System.out.println("  got " + value);
            received++;
            if (askForMore && received % batch == 0) {
                request(batch);
            }
        }

        @Override
        protected void hookOnError(Throwable error) {
            System.out.println("  error " + error.getClass().getSimpleName() + ": " + error.getMessage());
        }
    }

    public static void main(String[] args) {
        List<String> progression = List.of("Dm7", "G7", "Cmaj7", "A7", "Dm7", "G7");

        // The subscriber pulls: the source never sends more than was requested.
        System.out.println("a subscriber that requests 2 at a time:");
        Flux.fromIterable(progression)
                .doOnRequest(n -> System.out.println("  source asked for " + n))
                .subscribe(new Batches<>(2, true));

        // limitRate splits a large demand into batches, and asks again when 75% of a batch has arrived.
        System.out.println("limitRate(10) under an unbounded subscriber, first 25 elements:");
        Flux.range(1, 1_000)
                .doOnRequest(n -> System.out.println("  source asked for " + n))
                .limitRate(10)
                .take(25, false)
                .blockLast();

        // publishOn keeps a queue between two threads, and fills it by asking for 256 elements.
        System.out.println("publishOn:");
        Flux.range(1, 3)
                .doOnRequest(n -> System.out.println("  source asked for " + n))
                .publishOn(Schedulers.single())
                .blockLast();

        // A source that ignores demand needs a strategy: buffer (up to a size), drop, or keep the latest.
        System.out.println("onBackpressureDrop, subscriber requests 3:");
        var dropped = new ArrayList<Integer>();
        Flux.range(1, 10)
                .onBackpressureDrop(dropped::add)
                .subscribe(new Batches<>(3, false));
        System.out.println("  dropped " + dropped);

        // The overflow error waits behind the buffered elements: the subscriber sees it after draining them.
        System.out.println("onBackpressureBuffer(3), subscriber requests 1:");
        var slow = new Batches<Integer>(1, false);
        Flux.range(1, 10)
                .onBackpressureBuffer(3)
                .subscribe(slow);
        System.out.println("  subscriber now requests 10 more");
        slow.request(10);
    }
}
