package dev.learn.music;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class ScaleTest {

    @Test
    void cMajorHasTheSevenDiatonicTriads() {
        var scale = Scale.of("C", "major");
        assertEquals("[C, D, E, F, G, A, B]", scale.notes().toString());
        assertEquals("[C, Dm, Em, F, G, Am, Bdim]", scale.triads().toString());
    }

    @Test
    void dDorianUsesTheNotesOfCMajor() {
        assertEquals("[D, E, F, G, A, B, C]", Scale.of("d", "Dorian").notes().toString());
    }

    @Test
    void flatsAndSharpsNameTheSamePitchClass() {
        assertEquals(Note.parse("C#"), Note.parse("Db"));
        assertEquals("Bb", Note.parse("A#").flatName());
    }

    @Test
    void unknownNamesAreRejected() {
        assertEquals("unknown note: H", assertThrows(IllegalArgumentException.class, () -> Note.parse("H")).getMessage());
        assertEquals("unknown mode: blues", assertThrows(IllegalArgumentException.class, () -> Mode.parse("blues")).getMessage());
    }
}
