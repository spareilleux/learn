package dev.learn.reactor.l02;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.learn.music.Chord;
import dev.learn.music.Note;
import dev.learn.music.Scale;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class ExercisesTest {

    // Exercise 1: the eager version throws when it is called; the deferred one fails when it is subscribed to.
    static Flux<String> eagerTriads(String root, String mode) {
        return Flux.fromIterable(Scale.of(root, mode).triads()).map(Chord::symbol);
    }

    static Flux<String> lazyTriads(String root, String mode) {
        return Flux.defer(() -> Flux.fromIterable(Scale.of(root, mode).triads())).map(Chord::symbol);
    }

    @Test
    void exercise1WhereTheErrorHappens() {
        var thrown = assertThrows(IllegalArgumentException.class, () -> eagerTriads("H", "major"));
        assertEquals("unknown note: H", thrown.getMessage());

        Flux<String> assembled = lazyTriads("H", "major");
        StepVerifier.create(assembled).expectErrorMessage("unknown note: H").verify();
    }

    // Exercise 2: the first three keys of the circle of fifths whose major scale contains F#.
    static Mono<List<String>> keysWithFSharp() {
        Note fSharp = Note.parse("F#");
        return Flux.just("C", "G", "D", "A", "E", "B")
                .filter(root -> Scale.of(root, "major").notes().contains(fSharp))
                .take(3)
                .collectList();
    }

    @Test
    void exercise2KeysWithFSharp() {
        StepVerifier.create(keysWithFSharp())
                .expectNext(List.of("G", "D", "A"))
                .verifyComplete();
    }

    // Exercise 3: a metronome that plays a four-chord progression, one chord every 500 ms, twice.
    static Flux<String> metronome(List<String> progression) {
        return Flux.interval(Duration.ofMillis(500))
                .map(beat -> progression.get((int) (beat % progression.size())))
                .take(progression.size() * 2L);
    }

    @Test
    void exercise3MetronomeInVirtualTime() {
        Duration took = StepVerifier.withVirtualTime(() -> metronome(List.of("C", "Am", "F", "G")))
                .expectSubscription()
                .expectNoEvent(Duration.ofMillis(500))
                .expectNext("C")
                .thenAwait(Duration.ofMillis(1500))
                .expectNext("Am", "F", "G")
                .thenAwait(Duration.ofSeconds(2))
                .expectNext("C", "Am", "F", "G")
                .verifyComplete();
        assertTrue(took.compareTo(Duration.ofSeconds(1)) < 0, "four virtual seconds took " + took);
    }
}
