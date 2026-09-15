//! Chord, scale and guitar voicing logic for the chord explorer of lessons 16 to 18.
//!
//! Nothing here knows about Tauri, JSON or windows: the desktop app in
//! `src-tauri` only translates between this API and the frontend.

mod chord;
mod note;
mod scale;
mod voicing;

pub use chord::{Chord, Quality};
pub use note::{Letter, Note};
pub use scale::{Mode, diatonic_chords, scale_notes};
pub use voicing::{Progress, STANDARD_TUNING, SearchOptions, Voicing, find_voicings};

use std::fmt;

/// Errors returned when parsing notes and chord symbols.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TheoryError {
    /// The symbol was empty or only whitespace.
    Empty,
    /// The text does not start with a note name such as `C`, `F#` or `Bb`.
    InvalidNote(String),
    /// The note was valid but the rest of the symbol is not a known quality.
    UnknownQuality { symbol: String, suffix: String },
}

impl fmt::Display for TheoryError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            TheoryError::Empty => write!(f, "empty chord symbol"),
            TheoryError::InvalidNote(text) => {
                write!(f, "`{text}` is not a note (expected A to G, then # or b)")
            }
            TheoryError::UnknownQuality { symbol, suffix } => {
                write!(f, "unknown chord quality `{suffix}` in `{symbol}`")
            }
        }
    }
}

impl std::error::Error for TheoryError {}
