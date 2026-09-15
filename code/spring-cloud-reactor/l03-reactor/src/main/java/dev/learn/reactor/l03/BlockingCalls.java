package dev.learn.reactor.l03;

import dev.learn.music.Scale;
import java.time.Duration;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

public class BlockingCalls {

    /** Stands for a JDBC query or a blocking HTTP client: 20 ms of waiting. */
    static Scale slowLookup(String root, String mode) {
        try {
            Thread.sleep(20);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
        return Scale.of(root, mode);
    }

    static String thread() {
        return Thread.currentThread().getName().replaceAll("-\\d+$", "");
    }

    public static void main(String[] args) {
        // block() inside a pipeline that runs on parallel(): Reactor refuses to wait there.
        try {
            Mono.delay(Duration.ofMillis(1))
                    .map(tick -> Mono.fromCallable(() -> slowLookup("D", "dorian")).subscribeOn(Schedulers.boundedElastic()).block())
                    .block();
        } catch (IllegalStateException e) {
            System.out.println("nested block(): " + e.getMessage().replaceAll("parallel-\\d+", "parallel-N"));
        }

        // The fix: flatMap to a publisher of its own, subscribed on boundedElastic(), the scheduler for blocking work.
        Scale scale = Mono.delay(Duration.ofMillis(1))
                .flatMap(tick -> Mono.fromCallable(() -> slowLookup("D", "dorian")).subscribeOn(Schedulers.boundedElastic()))
                .block();
        System.out.println("flatMap and boundedElastic: " + scale.notes());
    }
}
