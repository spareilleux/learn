package dev.learn.music;

import java.util.List;
import java.util.Locale;

/** A pitch class, 0 for C to 11 for B, whatever the octave. */
public record Note(int pitchClass) {

    private static final List<String> SHARPS = List.of("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B");
    private static final List<String> FLATS = List.of("C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B");

    public Note {
        if (pitchClass < 0 || pitchClass > 11) {
            throw new IllegalArgumentException("pitch class must be between 0 and 11: " + pitchClass);
        }
    }

    /** Parses a note name such as {@code C}, {@code F#} or {@code Bb}. */
    public static Note parse(String name) {
        String normalized = name.isEmpty()
                ? name
                : name.substring(0, 1).toUpperCase(Locale.ROOT) + name.substring(1).toLowerCase(Locale.ROOT);
        int index = SHARPS.indexOf(normalized);
        if (index < 0) {
            index = FLATS.indexOf(normalized);
        }
        if (index < 0) {
            throw new IllegalArgumentException("unknown note: " + name);
        }
        return new Note(index);
    }

    public Note transpose(int semitones) {
        return new Note(Math.floorMod(pitchClass + semitones, 12));
    }

    public String sharpName() {
        return SHARPS.get(pitchClass);
    }

    public String flatName() {
        return FLATS.get(pitchClass);
    }

    @Override
    public String toString() {
        return sharpName();
    }
}
