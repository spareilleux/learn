package dev.learn.reactor.l03;

import dev.learn.music.Scale;
import java.time.Duration;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

public class ThreadHops {

    /** The thread's name without its number: parallel-3 and parallel-7 are the same pool. */
    static String thread() {
        return Thread.currentThread().getName().replaceAll("-\\d+$", "");
    }

    static <T> T step(String name, T value) {
        System.out.println("  " + name + " on " + thread());
        return value;
    }

    public static void main(String[] args) {
        System.out.println("no scheduler:");
        Flux.just("C").map(root -> step("map", root)).subscribe(root -> step("subscriber", root));

        // publishOn moves everything below it to another scheduler, like ConfigureAwait with a custom context.
        System.out.println("publishOn(parallel):");
        Flux.just("C")
                .map(root -> step("map above publishOn", root))
                .publishOn(Schedulers.parallel())
                .map(root -> step("map below publishOn", root))
                .blockLast();

        // subscribeOn moves the subscription, so the source and everything up to the first publishOn.
        System.out.println("subscribeOn(boundedElastic):");
        Mono.fromCallable(() -> step("callable", Scale.of("D", "dorian")))
                .map(scale -> step("map", scale))
                .subscribeOn(Schedulers.boundedElastic())
                .block();

        // Where subscribeOn is written doesn't matter; where publishOn is written does.
        System.out.println("both, subscribeOn written last:");
        Flux.just("C")
                .map(root -> step("map A", root))
                .publishOn(Schedulers.parallel())
                .map(root -> step("map B", root))
                .subscribeOn(Schedulers.boundedElastic())
                .blockLast();

        // Time-based operators pick a scheduler for you: Mono.delay emits on parallel().
        System.out.println("Mono.delay:");
        Mono.delay(Duration.ofMillis(1)).map(tick -> step("map after delay", tick)).block();
        step("block() returned", "");
    }
}
