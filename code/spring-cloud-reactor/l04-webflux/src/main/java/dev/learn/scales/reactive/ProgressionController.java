package dev.learn.scales.reactive;

import dev.learn.music.Chord;
import dev.learn.music.Scale;
import java.time.Duration;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
class ProgressionController {

    /** I–vi–IV–V, as scale degrees counted from 0. */
    private static final List<Integer> DEGREES = List.of(0, 5, 3, 4);

    private final Duration beat;

    ProgressionController(@Value("${progressions.beat:500ms}") Duration beat) {
        this.beat = beat;
    }

    // Server-sent events: one event per beat, then the stream ends.
    @GetMapping("/progressions/{root}")
    Flux<ServerSentEvent<String>> progression(@PathVariable String root) {
        return Flux.defer(() -> {
            List<Chord> triads = Scale.of(root, "major").triads();
            return Flux.interval(beat)
                    .take(DEGREES.size())
                    .map(beatNumber -> ServerSentEvent.<String>builder()
                            .id(String.valueOf(beatNumber + 1))
                            .event("chord")
                            .data(triads.get(DEGREES.get(beatNumber.intValue())).symbol())
                            .build());
        });
    }
}
