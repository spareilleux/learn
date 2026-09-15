package dev.learn.scales;

import dev.learn.music.Note;

/** Names a note with sharps (A#) or flats (Bb). */
public interface NoteSpeller {

    String name(Note note);

    static NoteSpeller sharps() {
        return Note::sharpName;
    }

    static NoteSpeller flats() {
        return Note::flatName;
    }
}
