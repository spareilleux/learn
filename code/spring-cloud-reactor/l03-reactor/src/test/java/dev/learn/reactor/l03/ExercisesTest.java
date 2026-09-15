package dev.learn.reactor.l03;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.learn.music.Scale;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Function;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;
import reactor.util.context.Context;
import reactor.util.retry.Retry;

class ExercisesTest {

    // Exercise 1: retry what may succeed later (the service is down), not what never will (an unknown note).
    static Mono<Scale> resilientLookup(Mono<Scale> lookup) {
        return lookup.retryWhen(Retry.backoff(3, Duration.ofMillis(100))
                .jitter(0)
                .filter(error -> error instanceof IllegalStateException));
    }

    static Mono<Scale> lookupThatFailsTwice(AtomicInteger calls) {
        return Mono.fromCallable(() -> {
            if (calls.incrementAndGet() < 3) {
                throw new IllegalStateException("scale service unavailable");
            }
            return Scale.of("A", "minor");
        });
    }

    @Test
    void exercise1TransientFailuresAreRetried() {
        var calls = new AtomicInteger();
        StepVerifier.withVirtualTime(() -> resilientLookup(lookupThatFailsTwice(calls)))
                .expectSubscription()
                .expectNoEvent(Duration.ofMillis(300))
                .expectNextMatches(scale -> scale.notes().getFirst().sharpName().equals("A"))
                .verifyComplete();
        assertEquals(3, calls.get());
    }

    @Test
    void exercise1PermanentFailuresAreNot() {
        var calls = new AtomicInteger();
        StepVerifier.create(resilientLookup(Mono.fromCallable(() -> {
                    calls.incrementAndGet();
                    return Scale.of("H", "minor");
                })))
                .expectErrorMessage("unknown note: H")
                .verify(Duration.ofSeconds(1));
        assertEquals(1, calls.get());
    }

    // Exercise 2: look up several scales concurrently with a blocking call, without blocking a parallel() thread.
    static Flux<String> tonics(Flux<String> roots, Function<String, Scale> blockingLookup) {
        return roots
                .publishOn(Schedulers.parallel())
                .flatMapSequential(root -> Mono.fromCallable(() -> blockingLookup.apply(root))
                        .subscribeOn(Schedulers.boundedElastic()), 4)
                .map(scale -> scale.triads().getFirst().symbol());
    }

    @Test
    void exercise2BlockingCallsOnBoundedElastic() {
        var running = new AtomicInteger();
        var mostAtOnce = new AtomicInteger();
        Function<String, Scale> lookup = root -> {
            mostAtOnce.accumulateAndGet(running.incrementAndGet(), Math::max);
            try {
                return BlockingCalls.slowLookup(root, "major");
            } finally {
                running.decrementAndGet();
            }
        };
        // BlockHound is active in this JVM: a Thread.sleep on a parallel() thread would fail the test.
        StepVerifier.create(tonics(Flux.just("C", "G", "D", "A", "E", "B", "F#", "C#"), lookup))
                .expectNext("C", "G", "D", "A", "E", "B", "F#", "C#")
                .verifyComplete();
        // The results keep their order, while up to four calls ran at the same time.
        assertTrue(mostAtOnce.get() > 1 && mostAtOnce.get() <= 4, "calls at once: " + mostAtOnce.get());
    }

    // Exercise 3: a request id put in the context at the edge, read deep inside.
    static Mono<String> logLine(String message) {
        return Mono.deferContextual(context -> Mono.just("[" + context.getOrDefault("requestId", "no-request") + "] " + message));
    }

    static Mono<String> handle(String root) {
        return Mono.fromCallable(() -> Scale.of(root, "major"))
                .publishOn(Schedulers.parallel())
                .flatMap(scale -> logLine("looked up " + scale.root()));
    }

    @Test
    void exercise3RequestIdInTheContext() {
        StepVerifier.create(handle("Eb").contextWrite(Context.of("requestId", "req-42")))
                .expectNext("[req-42] looked up D#")
                .verifyComplete();
        StepVerifier.create(handle("Eb"))
                .expectNext("[no-request] looked up D#")
                .verifyComplete();
    }
}
