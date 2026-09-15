package dev.learn.music;

import java.util.List;

/** A triad built on one degree of a scale. */
public record Chord(Note root, Quality quality, List<Note> notes) {

    public enum Quality {
        MAJOR(""), MINOR("m"), DIMINISHED("dim"), AUGMENTED("aug");

        private final String suffix;

        Quality(String suffix) {
            this.suffix = suffix;
        }

        public String suffix() {
            return suffix;
        }

        static Quality of(int third, int fifth) {
            if (third == 4 && fifth == 7) return MAJOR;
            if (third == 3 && fifth == 7) return MINOR;
            if (third == 3 && fifth == 6) return DIMINISHED;
            if (third == 4 && fifth == 8) return AUGMENTED;
            throw new IllegalArgumentException("not a triad: third " + third + ", fifth " + fifth);
        }
    }

    public Chord {
        notes = List.copyOf(notes);
    }

    public String symbol() {
        return root.sharpName() + quality.suffix();
    }

    @Override
    public String toString() {
        return symbol();
    }
}
