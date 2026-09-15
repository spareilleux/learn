package dev.learn.scales.exercises;

import static org.junit.jupiter.api.Assertions.assertEquals;

import dev.learn.music.Note;
import dev.learn.scales.NoteSpeller;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

class Exercise2SpellersByNameTest {

    @Configuration
    static class Spellers {

        @Bean
        NoteSpeller sharps() {
            return NoteSpeller.sharps();
        }

        @Bean
        NoteSpeller flats() {
            return NoteSpeller.flats();
        }

        @Bean
        SpellingChooser chooser(Map<String, NoteSpeller> byName, List<NoteSpeller> all) {
            return new SpellingChooser(byName, all);
        }
    }

    // Map<String, T> is keyed by bean name, like [FromKeyedServices("flats")]; List<T> is IEnumerable<T>.
    record SpellingChooser(Map<String, NoteSpeller> byName, List<NoteSpeller> all) {

        String name(Note note, String spelling) {
            NoteSpeller speller = byName.get(spelling);
            if (speller == null) {
                throw new IllegalArgumentException("unknown spelling: " + spelling + ", expected one of " + byName.keySet());
            }
            return speller.name(note);
        }
    }

    @Test
    void chooseASpellerByBeanName() {
        try (var context = new AnnotationConfigApplicationContext(Spellers.class)) {
            SpellingChooser chooser = context.getBean(SpellingChooser.class);
            Note aSharp = Note.parse("A#");
            assertEquals("A#", chooser.name(aSharp, "sharps"));
            assertEquals("Bb", chooser.name(aSharp, "flats"));
            assertEquals(2, chooser.all().size());
            assertEquals("[sharps, flats]", chooser.byName().keySet().toString());
        }
    }
}
