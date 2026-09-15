package dev.learn.scales;

import dev.learn.music.Chord;
import dev.learn.music.Scale;
import java.util.List;
import org.springframework.stereotype.Service;

// @Service is a @Component: component scanning registers it as a singleton, with no AddSingleton call.
@Service
public class ScaleService {

    private final NoteSpeller speller;

    // A single constructor needs no @Autowired: Spring injects its parameters, like the .NET container.
    public ScaleService(NoteSpeller speller) {
        this.speller = speller;
    }

    public ScaleView describe(String root, String mode) {
        Scale scale = Scale.of(root, mode);
        List<String> notes = scale.notes().stream().map(speller::name).toList();
        List<String> chords = scale.triads().stream().map(this::symbol).toList();
        return new ScaleView(speller.name(scale.root()), scale.mode().label(), notes, chords);
    }

    private String symbol(Chord chord) {
        return speller.name(chord.root()) + chord.quality().suffix();
    }

    public record ScaleView(String root, String mode, List<String> notes, List<String> chords) {}
}
