package dev.learn.scales.reactive;

import dev.learn.music.Chord;
import dev.learn.music.Mode;
import dev.learn.music.Scale;
import java.util.List;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class ScaleCatalog {

    public record ScaleView(String root, String mode, List<String> notes, List<String> chords) {

        static ScaleView of(Scale scale) {
            return new ScaleView(scale.root().sharpName(), scale.mode().label(),
                    scale.notes().stream().map(note -> note.sharpName()).toList(),
                    scale.triads().stream().map(Chord::symbol).toList());
        }
    }

    // fromCallable: an unknown note becomes an error signal when someone subscribes, not an exception in the controller.
    public Mono<ScaleView> describe(String root, String mode) {
        return Mono.fromCallable(() -> ScaleView.of(Scale.of(root, mode)));
    }

    public Flux<ScaleView> allModes(String root) {
        return Flux.fromArray(Mode.values()).concatMap(mode -> describe(root, mode.label()));
    }
}
