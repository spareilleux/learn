package dev.learn.music;

import java.util.List;
import java.util.Locale;

/** The seven modes of the major scale, as semitones above the root. */
public enum Mode {
    IONIAN(0, 2, 4, 5, 7, 9, 11),
    DORIAN(0, 2, 3, 5, 7, 9, 10),
    PHRYGIAN(0, 1, 3, 5, 7, 8, 10),
    LYDIAN(0, 2, 4, 6, 7, 9, 11),
    MIXOLYDIAN(0, 2, 4, 5, 7, 9, 10),
    AEOLIAN(0, 2, 3, 5, 7, 8, 10),
    LOCRIAN(0, 1, 3, 5, 6, 8, 10);

    private final List<Integer> intervals;

    Mode(Integer... intervals) {
        this.intervals = List.of(intervals);
    }

    public List<Integer> intervals() {
        return intervals;
    }

    /** Parses {@code dorian}, {@code Dorian} or {@code DORIAN}; {@code major} and {@code minor} are aliases. */
    public static Mode parse(String name) {
        return switch (name.toLowerCase(Locale.ROOT)) {
            case "major" -> IONIAN;
            case "minor" -> AEOLIAN;
            default -> {
                try {
                    yield valueOf(name.toUpperCase(Locale.ROOT));
                } catch (IllegalArgumentException e) {
                    throw new IllegalArgumentException("unknown mode: " + name);
                }
            }
        };
    }

    public String label() {
        return name().toLowerCase(Locale.ROOT);
    }
}
