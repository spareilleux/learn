package dev.learn.broken.ambiguous;

import dev.learn.scales.NoteSpeller;
import dev.learn.scales.ScaleService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

// Two NoteSpeller beans and a constructor that asks for one: .NET would silently take the last registration.
@Configuration
@Import(ScaleService.class)
public class TwoSpellersApplication {

    @Bean
    NoteSpeller sharpSpeller() {
        return NoteSpeller.sharps();
    }

    @Bean
    NoteSpeller flatSpeller() {
        return NoteSpeller.flats();
    }
}
