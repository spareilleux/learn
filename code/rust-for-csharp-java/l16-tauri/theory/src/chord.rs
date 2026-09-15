use std::fmt;
use std::str::FromStr;

use crate::{Note, TheoryError};

/// A chord tone: letters above the root, semitones above the root, interval name.
type Tone = (usize, u8, &'static str);

const ROOT: Tone = (0, 0, "1");
const SECOND: Tone = (1, 2, "2");
const MINOR_THIRD: Tone = (2, 3, "b3");
const MAJOR_THIRD: Tone = (2, 4, "3");
const FOURTH: Tone = (3, 5, "4");
const FLAT_FIFTH: Tone = (4, 6, "b5");
const FIFTH: Tone = (4, 7, "5");
const SHARP_FIFTH: Tone = (4, 8, "#5");
const DIMINISHED_SEVENTH: Tone = (6, 9, "bb7");
const MINOR_SEVENTH: Tone = (6, 10, "b7");
const MAJOR_SEVENTH: Tone = (6, 11, "7");

/// The chord qualities the explorer understands.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Quality {
    Major,
    Minor,
    Diminished,
    Augmented,
    Sus2,
    Sus4,
    Dominant7,
    Major7,
    Minor7,
    HalfDiminished7,
    Diminished7,
}

impl Quality {
    pub const ALL: [Quality; 11] = [
        Quality::Major,
        Quality::Minor,
        Quality::Diminished,
        Quality::Augmented,
        Quality::Sus2,
        Quality::Sus4,
        Quality::Dominant7,
        Quality::Major7,
        Quality::Minor7,
        Quality::HalfDiminished7,
        Quality::Diminished7,
    ];

    /// The suffix written after the root: `m7` in `Am7`.
    pub fn suffix(self) -> &'static str {
        match self {
            Quality::Major => "",
            Quality::Minor => "m",
            Quality::Diminished => "dim",
            Quality::Augmented => "aug",
            Quality::Sus2 => "sus2",
            Quality::Sus4 => "sus4",
            Quality::Dominant7 => "7",
            Quality::Major7 => "maj7",
            Quality::Minor7 => "m7",
            Quality::HalfDiminished7 => "m7b5",
            Quality::Diminished7 => "dim7",
        }
    }

    /// A readable name: `minor seventh`.
    pub fn name(self) -> &'static str {
        match self {
            Quality::Major => "major",
            Quality::Minor => "minor",
            Quality::Diminished => "diminished",
            Quality::Augmented => "augmented",
            Quality::Sus2 => "suspended second",
            Quality::Sus4 => "suspended fourth",
            Quality::Dominant7 => "dominant seventh",
            Quality::Major7 => "major seventh",
            Quality::Minor7 => "minor seventh",
            Quality::HalfDiminished7 => "half-diminished seventh",
            Quality::Diminished7 => "diminished seventh",
        }
    }

    fn tones(self) -> &'static [Tone] {
        match self {
            Quality::Major => &[ROOT, MAJOR_THIRD, FIFTH],
            Quality::Minor => &[ROOT, MINOR_THIRD, FIFTH],
            Quality::Diminished => &[ROOT, MINOR_THIRD, FLAT_FIFTH],
            Quality::Augmented => &[ROOT, MAJOR_THIRD, SHARP_FIFTH],
            Quality::Sus2 => &[ROOT, SECOND, FIFTH],
            Quality::Sus4 => &[ROOT, FOURTH, FIFTH],
            Quality::Dominant7 => &[ROOT, MAJOR_THIRD, FIFTH, MINOR_SEVENTH],
            Quality::Major7 => &[ROOT, MAJOR_THIRD, FIFTH, MAJOR_SEVENTH],
            Quality::Minor7 => &[ROOT, MINOR_THIRD, FIFTH, MINOR_SEVENTH],
            Quality::HalfDiminished7 => &[ROOT, MINOR_THIRD, FLAT_FIFTH, MINOR_SEVENTH],
            Quality::Diminished7 => &[ROOT, MINOR_THIRD, FLAT_FIFTH, DIMINISHED_SEVENTH],
        }
    }
}

/// A chord: a spelled root and a quality.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Chord {
    pub root: Note,
    pub quality: Quality,
}

impl Chord {
    pub const fn new(root: Note, quality: Quality) -> Chord {
        Chord { root, quality }
    }

    /// The chord tones, spelled from the root: `Bbm7` gives `Bb Db F Ab`.
    pub fn notes(&self) -> Vec<Note> {
        self.quality
            .tones()
            .iter()
            .map(|&(steps, semitones, _)| self.root.spell_above(steps, semitones))
            .collect()
    }

    /// The interval names of the chord tones: `1 b3 5 b7`.
    pub fn intervals(&self) -> Vec<&'static str> {
        self.quality
            .tones()
            .iter()
            .map(|&(_, _, name)| name)
            .collect()
    }

    /// The set of pitch classes as a 12-bit mask (bit 0 is C).
    pub fn pitch_class_mask(&self) -> u16 {
        self.notes()
            .iter()
            .fold(0, |mask, note| mask | 1 << note.pitch_class())
    }

    /// The same chord `semitones` higher (or lower, if negative).
    ///
    /// The new root uses the most common spelling for its pitch class:
    /// flats, except for F#.
    pub fn transpose(&self, semitones: i32) -> Chord {
        const ROOTS: [&str; 12] = [
            "C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B",
        ];
        let pitch_class = (i32::from(self.root.pitch_class()) + semitones).rem_euclid(12);
        let root = ROOTS[pitch_class as usize]
            .parse()
            .expect("the table only holds valid notes");
        Chord::new(root, self.quality)
    }
}

impl FromStr for Chord {
    type Err = TheoryError;

    fn from_str(symbol: &str) -> Result<Chord, TheoryError> {
        let symbol = symbol.trim();
        if symbol.is_empty() {
            return Err(TheoryError::Empty);
        }
        let (root, suffix) = Note::parse_prefix(symbol)?;
        let quality = Quality::ALL
            .into_iter()
            .find(|quality| quality.suffix() == suffix)
            .ok_or_else(|| TheoryError::UnknownQuality {
                symbol: symbol.to_string(),
                suffix: suffix.to_string(),
            })?;
        Ok(Chord::new(root, quality))
    }
}

impl fmt::Display for Chord {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}{}", self.root, self.quality.suffix())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn spelled(symbol: &str) -> String {
        let chord: Chord = symbol.parse().unwrap();
        let notes: Vec<String> = chord.notes().iter().map(Note::to_string).collect();
        notes.join(" ")
    }

    #[test]
    fn spells_chords_with_the_right_letters() {
        assert_eq!(spelled("C"), "C E G");
        assert_eq!(spelled("Bbm7"), "Bb Db F Ab");
        assert_eq!(spelled("F#"), "F# A# C#");
        assert_eq!(spelled("C#m"), "C# E G#");
        assert_eq!(spelled("Bdim7"), "B D F Ab");
        assert_eq!(spelled("Ebaug"), "Eb G B");
        assert_eq!(spelled("Gm7b5"), "G Bb Db F");
        assert_eq!(spelled("Dsus4"), "D G A");
    }

    #[test]
    fn every_quality_round_trips() {
        for quality in Quality::ALL {
            let symbol = format!("Ab{}", quality.suffix());
            assert_eq!(symbol.parse::<Chord>().unwrap().to_string(), symbol);
        }
    }

    #[test]
    fn reports_what_is_wrong() {
        assert_eq!("  ".parse::<Chord>(), Err(TheoryError::Empty));
        assert_eq!(
            "Hm7".parse::<Chord>().unwrap_err().to_string(),
            "`Hm7` is not a note (expected A to G, then # or b)"
        );
        assert_eq!(
            "Cm9".parse::<Chord>().unwrap_err().to_string(),
            "unknown chord quality `m9` in `Cm9`"
        );
    }

    #[test]
    fn transposes_with_common_spellings() {
        let chord: Chord = "Am7".parse().unwrap();
        assert_eq!(chord.transpose(1).to_string(), "Bbm7");
        assert_eq!(chord.transpose(-3).to_string(), "F#m7");
        assert_eq!(chord.transpose(12).to_string(), "Am7");
    }

    #[test]
    fn mask_ignores_spelling() {
        let sharp: Chord = "F#".parse().unwrap();
        let flat: Chord = "Gb".parse().unwrap();
        assert_eq!(sharp.pitch_class_mask(), flat.pitch_class_mask());
    }
}
