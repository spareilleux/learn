package dev.learn.reactor.l03;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;
import reactor.core.publisher.Mono;

public class ErrorsAndRetries {

    /** A scale service that fails until its third call. */
    static Mono<String> flakyLookup(AtomicInteger calls) {
        return Mono.fromCallable(() -> {
            int call = calls.incrementAndGet();
            System.out.println("  call " + call);
            if (call < 3) {
                throw new IllegalStateException("scale service unavailable");
            }
            return "D dorian";
        });
    }

    public static void main(String[] args) {
        // retry(n) subscribes again: the Mono is a recipe, so the call runs again too.
        System.out.println("retry(2):");
        System.out.println("  result: " + flakyLookup(new AtomicInteger()).retry(2).block());

        System.out.println("retry(1):");
        try {
            flakyLookup(new AtomicInteger()).retry(1).block();
        } catch (IllegalStateException e) {
            System.out.println("  block() threw " + e.getMessage());
        }

        // onErrorReturn is a catch that returns a value; onErrorResume switches to another publisher.
        System.out.println("fallbacks:");
        Mono<String> failing = Mono.error(new IllegalStateException("scale service unavailable"));
        System.out.println("  onErrorReturn: " + failing.onErrorReturn("C ionian").block());
        System.out.println("  onErrorResume: " + failing.onErrorResume(e -> Mono.just("cached: " + e.getMessage())).block());

        // onErrorMap is catch-and-wrap; doOnError only looks.
        try {
            failing.doOnError(e -> System.out.println("  doOnError saw: " + e.getMessage()))
                    .onErrorMap(e -> new RuntimeException("lookup failed", e))
                    .block();
        } catch (RuntimeException e) {
            System.out.println("  onErrorMap: " + e.getMessage() + ", caused by " + e.getCause().getMessage());
        }

        // timeout is a signal too: here a 5-second call is cut at 50 ms and replaced.
        System.out.println("timeout:");
        String answer = Mono.delay(Duration.ofSeconds(5)).map(tick -> "too late")
                .timeout(Duration.ofMillis(50), Mono.just("timed out, default scale"))
                .block();
        System.out.println("  " + answer);
    }
}
