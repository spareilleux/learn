package dev.learn.spring.l05;

import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

@Table("voicing")
public record Voicing(@Id Long id, String symbol, int fret) {
    public static Voicing newVoicing(String symbol, int fret) {
        return new Voicing(null, symbol, fret);
    }
}
