package dev.learn.music;

import java.util.ArrayList;
import java.util.List;

/** The notes of a mode built on a root, and the triads on each of its degrees. */
public record Scale(Note root, Mode mode, List<Note> notes) {

    public Scale {
        notes = List.copyOf(notes);
    }

    public static Scale of(Note root, Mode mode) {
        return new Scale(root, mode, mode.intervals().stream().map(root::transpose).toList());
    }

    /** Parses both names, for example {@code Scale.of("D", "dorian")}. */
    public static Scale of(String root, String mode) {
        return of(Note.parse(root), Mode.parse(mode));
    }

    /** Stacks thirds on each degree: C ionian gives C, Dm, Em, F, G, Am, Bdim. */
    public List<Chord> triads() {
        var chords = new ArrayList<Chord>();
        for (int degree = 0; degree < notes.size(); degree++) {
            Note first = notes.get(degree);
            Note third = notes.get((degree + 2) % notes.size());
            Note fifth = notes.get((degree + 4) % notes.size());
            var quality = Chord.Quality.of(distance(first, third), distance(first, fifth));
            chords.add(new Chord(first, quality, List.of(first, third, fifth)));
        }
        return chords;
    }

    private static int distance(Note from, Note to) {
        return Math.floorMod(to.pitchClass() - from.pitchClass(), 12);
    }
}
