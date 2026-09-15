package dev.learn.scales;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// A @Configuration class holds factory methods, like services.AddSingleton<INoteSpeller>(sp => ...).
@Configuration
class SpellingConfiguration {

    @Bean
    NoteSpeller noteSpeller(ScalesProperties properties) {
        return switch (properties.spelling()) {
            case SHARPS -> NoteSpeller.sharps();
            case FLATS -> NoteSpeller.flats();
        };
    }
}
