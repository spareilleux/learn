package dev.learn.reactor.l02;

import dev.learn.music.Chord;
import dev.learn.music.Mode;
import dev.learn.music.Scale;
import java.util.List;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public class Operators {

    public static void main(String[] args) {
        Flux<Mode> modes = Flux.fromArray(Mode.values());

        // map and filter are Select and Where.
        List<String> minorModes = modes
                .filter(mode -> Scale.of("C", mode.label()).triads().getFirst().quality() == Chord.Quality.MINOR)
                .map(Mode::label)
                .collectList()
                .block();
        System.out.println("modes with a minor tonic chord: " + minorModes);

        // flatMapIterable is SelectMany over a collection; distinct and count are what LINQ calls them.
        Mono<Long> distinctChords = modes
                .flatMapIterable(mode -> Scale.of("C", mode.label()).triads())
                .map(Chord::symbol)
                .distinct()
                .count();
        System.out.println("distinct triads in the seven modes on C: " + distinctChords.block());

        // zip pairs two sequences element by element, like Enumerable.Zip.
        Flux<String> degrees = Flux.just("I", "ii", "iii", "IV", "V", "vi", "vii°");
        Flux<Chord> chords = Flux.fromIterable(Scale.of("G", "major").triads());
        System.out.println(Flux.zip(degrees, chords, (degree, chord) -> degree + "=" + chord)
                .take(4)
                .collectList()
                .block());

        // reduce is Aggregate; a Flux of Monos is merged with flatMap, like await Task.WhenAll.
        Mono<String> progression = Flux.just("C", "A", "D", "G")
                .flatMap(root -> Mono.fromCallable(() -> Scale.of(root, "major").triads().getFirst().symbol()))
                .reduce((left, right) -> left + " " + right);
        System.out.println("progression: " + progression.block());

        // Errors are signals too: the sequence stops at the first one.
        Flux.just("C", "H", "D")
                .map(root -> Scale.of(root, "major").root())
                .subscribe(
                        root -> System.out.println("onNext " + root),
                        error -> System.out.println("onError " + error.getMessage()),
                        () -> System.out.println("onComplete"));

        // null is not a value in Reactor: a mapper that returns null fails the sequence.
        Mono.just("C")
                .map(root -> (String) null)
                .subscribe(
                        value -> System.out.println("onNext " + value),
                        // The message names the lambda's generated class, whose address changes from run to run.
                        error -> System.out.println("onError " + error.getClass().getSimpleName() + ": "
                                + error.getMessage().replaceAll("/0x[0-9a-f]+", "/0x...")));

        // Empty is how Reactor says "no value": defaultIfEmpty and switchIfEmpty handle it.
        Mono<String> favourite = Mono.justOrEmpty(System.getenv("NO_SUCH_VARIABLE_FOR_THE_LESSON"));
        System.out.println("empty Mono blocks to: " + favourite.block());
        System.out.println("defaultIfEmpty: " + favourite.defaultIfEmpty("ionian").block());
    }
}
