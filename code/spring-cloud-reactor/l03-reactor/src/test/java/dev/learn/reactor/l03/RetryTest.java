package dev.learn.reactor.l03;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;
import reactor.util.retry.Retry;

class RetryTest {

    @Test
    void backoffWaitsLongerEachTime() {
        var calls = new AtomicInteger();
        // Polly's AddRetry with MaxRetryAttempts = 3, Delay = 100 ms, BackoffType = Exponential, UseJitter = false.
        StepVerifier.withVirtualTime(() -> Mono.error(new IllegalStateException("scale service unavailable"))
                        .doOnSubscribe(subscription -> calls.incrementAndGet())
                        .retryWhen(Retry.backoff(3, Duration.ofMillis(100)).jitter(0)))
                .expectSubscription()
                .expectNoEvent(Duration.ofMillis(100 + 200 + 400))
                .consumeErrorWith(error -> Expected.check("retries-exhausted",
                        error.getClass().getName() + ": " + error.getMessage() + "\ncaused by " + error.getCause()
                                + "\nsubscriptions: " + calls.get()))
                .verify();
    }
}
