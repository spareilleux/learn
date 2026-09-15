use std::fmt;
use std::str::FromStr;

use crate::TheoryError;

/// The seven letter names, in order from C.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Letter {
    C,
    D,
    E,
    F,
    G,
    A,
    B,
}

impl Letter {
    const ALL: [Letter; 7] = [
        Letter::C,
        Letter::D,
        Letter::E,
        Letter::F,
        Letter::G,
        Letter::A,
        Letter::B,
    ];

    /// The pitch class of the letter without accidental (C = 0, D = 2, …, B = 11).
    pub fn natural_pitch_class(self) -> u8 {
        [0, 2, 4, 5, 7, 9, 11][self as usize]
    }

    /// The letter `steps` letters above this one: `C.plus(2)` is `E`.
    pub fn plus(self, steps: usize) -> Letter {
        Letter::ALL[(self as usize + steps) % 7]
    }

    fn from_char(c: char) -> Option<Letter> {
        Letter::ALL
            .into_iter()
            .find(|letter| format!("{letter:?}").starts_with(c))
    }
}

/// A spelled note: a letter and an accidental (-1 is one flat, +2 a double sharp).
///
/// `F#` and `Gb` are different notes with the same pitch class.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Note {
    pub letter: Letter,
    pub accidental: i8,
}

impl Note {
    pub const fn new(letter: Letter, accidental: i8) -> Note {
        Note { letter, accidental }
    }

    /// The pitch class, from 0 (C) to 11 (B).
    pub fn pitch_class(self) -> u8 {
        (i16::from(self.letter.natural_pitch_class()) + i16::from(self.accidental)).rem_euclid(12)
            as u8
    }

    /// The note `semitones` above this one, written with the letter `steps` letters above.
    ///
    /// A major third above `Bb` is two letters up (`D`) and four semitones up: `D`.
    /// A minor third above `B` is `D` too, but a minor third above `C#` is `E`, not `F`.
    pub fn spell_above(self, steps: usize, semitones: u8) -> Note {
        let letter = self.letter.plus(steps);
        let target = (self.pitch_class() + semitones) % 12;
        let mut accidental =
            (i16::from(target) - i16::from(letter.natural_pitch_class())).rem_euclid(12) as i8;
        if accidental > 6 {
            accidental -= 12;
        }
        Note { letter, accidental }
    }

    /// Splits `text` into a leading note and the rest: `"Bbm7"` gives `(Bb, "m7")`.
    pub(crate) fn parse_prefix(text: &str) -> Result<(Note, &str), TheoryError> {
        let mut chars = text.chars();
        let letter = chars
            .next()
            .and_then(Letter::from_char)
            .ok_or_else(|| TheoryError::InvalidNote(text.to_string()))?;
        let rest = chars.as_str();
        let sharps = rest.chars().take_while(|&c| c == '#').count();
        let flats = rest.chars().take_while(|&c| c == 'b').count();
        let (accidental, len) = match (sharps, flats) {
            (0, 0) => (0, 0),
            (n, 0) if n <= 2 => (n as i8, n),
            (0, n) if n <= 2 => (-(n as i8), n),
            _ => return Err(TheoryError::InvalidNote(text.to_string())),
        };
        Ok((Note::new(letter, accidental), &rest[len..]))
    }
}

impl FromStr for Note {
    type Err = TheoryError;

    fn from_str(text: &str) -> Result<Note, TheoryError> {
        match Note::parse_prefix(text.trim())? {
            (note, "") => Ok(note),
            _ => Err(TheoryError::InvalidNote(text.to_string())),
        }
    }
}

impl fmt::Display for Note {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let symbol = if self.accidental < 0 { "b" } else { "#" };
        write!(
            f,
            "{:?}{}",
            self.letter,
            symbol.repeat(self.accidental.unsigned_abs().into())
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_and_prints_notes() {
        for text in ["C", "F#", "Bb", "Ebb", "G##"] {
            assert_eq!(text.parse::<Note>().unwrap().to_string(), text);
        }
    }

    #[test]
    fn rejects_what_is_not_a_note() {
        for text in ["", "H", "c", "C#b", "Cbbb", "C7"] {
            assert!(text.parse::<Note>().is_err(), "{text} should be rejected");
        }
    }

    #[test]
    fn enharmonic_notes_share_a_pitch_class() {
        let sharp: Note = "F#".parse().unwrap();
        let flat: Note = "Gb".parse().unwrap();
        assert_ne!(sharp, flat);
        assert_eq!(sharp.pitch_class(), flat.pitch_class());
        assert_eq!("Cb".parse::<Note>().unwrap().pitch_class(), 11);
    }

    #[test]
    fn spells_by_letter_then_semitones() {
        let c_sharp: Note = "C#".parse().unwrap();
        assert_eq!(c_sharp.spell_above(2, 3).to_string(), "E");
        assert_eq!(c_sharp.spell_above(2, 4).to_string(), "E#");
        let b_flat: Note = "Bb".parse().unwrap();
        assert_eq!(b_flat.spell_above(2, 4).to_string(), "D");
    }
}
