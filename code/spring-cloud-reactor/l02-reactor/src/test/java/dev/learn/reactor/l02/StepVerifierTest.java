package dev.learn.reactor.l02;

import static org.junit.jupiter.api.Assertions.assertThrows;

import dev.learn.music.Chord;
import dev.learn.music.Scale;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class StepVerifierTest {

    static Flux<String> triads(String root, String mode) {
        return Flux.defer(() -> Flux.fromIterable(Scale.of(root, mode).triads())).map(Chord::symbol);
    }

    @Test
    void expectEachSignalInOrder() {
        StepVerifier.create(triads("A", "minor"))
                .expectNext("Am", "Bdim", "C")
                .expectNextCount(3)
                .expectNext("G")
                .verifyComplete();
    }

    @Test
    void errorsAreSignalsToExpect() {
        StepVerifier.create(triads("H", "minor"))
                .expectErrorMessage("unknown note: H")
                .verify();
    }

    @Test
    void failureMessage() {
        AssertionError failure = assertThrows(AssertionError.class, () ->
                StepVerifier.create(triads("D", "dorian"))
                        .expectNext("Dm", "Em", "F#")
                        .verifyComplete());
        Expected.check("stepverifier-failure", failure.getMessage());
    }

    // A chord service that answers slowly for some roots; the durations are virtual.
    static Mono<String> slowTonic(String root, long millis) {
        return Mono.delay(Duration.ofMillis(millis)).map(tick -> Scale.of(root, "major").triads().getFirst().symbol());
    }

    @Test
    void flatMapEmitsInCompletionOrder() {
        // Without virtual time, this test would wait 300 ms of real time.
        StepVerifier.withVirtualTime(() -> Flux.just("C", "F", "G")
                        .flatMap(root -> slowTonic(root, root.equals("C") ? 300 : 100)))
                .thenAwait(Duration.ofMillis(300))
                .expectNext("F", "G", "C")
                .verifyComplete();
    }

    @Test
    void concatMapKeepsTheSourceOrder() {
        StepVerifier.withVirtualTime(() -> Flux.just("C", "F", "G")
                        .concatMap(root -> slowTonic(root, root.equals("C") ? 300 : 100)))
                .expectSubscription()
                .expectNoEvent(Duration.ofMillis(300))
                .expectNext("C")
                .thenAwait(Duration.ofMillis(200))
                .expectNext("F", "G")
                .verifyComplete();
    }

    @Test
    void assertionsOnCollectedValues() {
        StepVerifier.create(triads("E", "phrygian").collectList())
                .assertNext(chords -> {
                    if (!chords.equals(List.of("Em", "F", "G", "Am", "Bdim", "C", "Dm"))) {
                        throw new AssertionError(chords.toString());
                    }
                })
                .verifyComplete();
    }
}
