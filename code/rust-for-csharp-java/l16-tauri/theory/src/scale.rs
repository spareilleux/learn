use crate::{Chord, Note, Quality};

/// Major, or natural minor.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Mode {
    Major,
    Minor,
}

impl Mode {
    fn semitones(self) -> [u8; 7] {
        match self {
            Mode::Major => [0, 2, 4, 5, 7, 9, 11],
            Mode::Minor => [0, 2, 3, 5, 7, 8, 10],
        }
    }
}

/// The seven notes of the scale, one per letter: F major has `Bb`, not `A#`.
pub fn scale_notes(tonic: Note, mode: Mode) -> Vec<Note> {
    mode.semitones()
        .iter()
        .enumerate()
        .map(|(steps, &semitones)| tonic.spell_above(steps, semitones))
        .collect()
}

/// The triad built on each degree of the scale: C major gives `C Dm Em F G Am Bdim`.
pub fn diatonic_chords(tonic: Note, mode: Mode) -> Vec<Chord> {
    let notes = scale_notes(tonic, mode);
    (0..7)
        .map(|degree| {
            let root = notes[degree];
            let above =
                |n: usize| (12 + notes[(degree + n) % 7].pitch_class() - root.pitch_class()) % 12;
            let quality = match (above(2), above(4)) {
                (4, 7) => Quality::Major,
                (3, 7) => Quality::Minor,
                (3, 6) => Quality::Diminished,
                (4, 8) => Quality::Augmented,
                other => unreachable!("major and natural minor triads only, got {other:?}"),
            };
            Chord::new(root, quality)
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn symbols(tonic: &str, mode: Mode) -> String {
        let chords = diatonic_chords(tonic.parse().unwrap(), mode);
        chords
            .iter()
            .map(Chord::to_string)
            .collect::<Vec<_>>()
            .join(" ")
    }

    #[test]
    fn diatonic_triads() {
        assert_eq!(symbols("C", Mode::Major), "C Dm Em F G Am Bdim");
        assert_eq!(symbols("F#", Mode::Major), "F# G#m A#m B C# D#m E#dim");
        assert_eq!(symbols("A", Mode::Minor), "Am Bdim C Dm Em F G");
        assert_eq!(symbols("Eb", Mode::Minor), "Ebm Fdim Gb Abm Bbm Cb Db");
    }

    #[test]
    fn one_letter_per_degree() {
        let notes = scale_notes("F".parse().unwrap(), Mode::Major);
        let text: Vec<String> = notes.iter().map(Note::to_string).collect();
        assert_eq!(text, ["F", "G", "A", "Bb", "C", "D", "E"]);
    }
}
