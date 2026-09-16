//! Lesson 17: commands, the Rust functions the frontend calls with `invoke`.

use std::sync::atomic::AtomicBool;

use serde::{Deserialize, Serialize};
use theory::{Chord, Mode, Note, Quality, SearchOptions, TheoryError};
use ts_rs::TS;

/// A chord as the frontend receives it: strings ready to display.
#[derive(Debug, Serialize, TS)]
#[serde(rename_all = "camelCase")]
#[ts(export)]
pub struct ChordView {
    symbol: String,
    quality_name: &'static str,
    notes: Vec<String>,
    intervals: Vec<&'static str>,
}

impl From<Chord> for ChordView {
    fn from(chord: Chord) -> Self {
        ChordView {
            symbol: chord.to_string(),
            quality_name: chord.quality.name(),
            notes: chord.notes().iter().map(Note::to_string).collect(),
            intervals: chord.intervals(),
        }
    }
}

/// A quality for the frontend's help list.
#[derive(Debug, Serialize, TS)]
#[ts(export)]
pub struct QualityView {
    suffix: &'static str,
    name: &'static str,
}

/// The error a failed command sends to the frontend, where the promise rejects with
/// `{ kind, message }`.
#[derive(Debug, Serialize, TS)]
#[ts(export)]
pub struct CommandError {
    kind: &'static str,
    message: String,
}

impl From<TheoryError> for CommandError {
    fn from(error: TheoryError) -> Self {
        let kind = match error {
            TheoryError::Empty => "empty",
            TheoryError::InvalidNote(_) => "invalidNote",
            TheoryError::UnknownQuality { .. } => "unknownQuality",
        };
        CommandError {
            kind,
            message: error.to_string(),
        }
    }
}

impl From<tauri::Error> for CommandError {
    fn from(error: tauri::Error) -> Self {
        CommandError {
            kind: "internal",
            message: error.to_string(),
        }
    }
}

/// `"major"` or `"minor"` in JSON.
#[derive(Debug, Clone, Copy, Deserialize, TS)]
#[serde(rename_all = "lowercase")]
#[ts(export)]
pub enum ScaleMode {
    Major,
    Minor,
}

impl From<ScaleMode> for Mode {
    fn from(mode: ScaleMode) -> Self {
        match mode {
            ScaleMode::Major => Mode::Major,
            ScaleMode::Minor => Mode::Minor,
        }
    }
}

#[tauri::command]
pub fn chord_qualities() -> Vec<QualityView> {
    Quality::ALL
        .iter()
        .map(|quality| QualityView {
            suffix: quality.suffix(),
            name: quality.name(),
        })
        .collect()
}

#[tauri::command]
pub fn spell_chord(symbol: &str) -> Result<ChordView, CommandError> {
    let chord: Chord = symbol.parse()?;
    Ok(chord.into())
}

#[tauri::command]
pub fn transpose_chord(symbol: &str, semitones: i32) -> Result<ChordView, CommandError> {
    let chord: Chord = symbol.parse()?;
    Ok(chord.transpose(semitones).into())
}

#[tauri::command]
pub fn diatonic_chords(tonic_note: &str, mode: ScaleMode) -> Result<Vec<ChordView>, CommandError> {
    let tonic: Note = tonic_note.parse()?;
    Ok(theory::diatonic_chords(tonic, mode.into())
        .into_iter()
        .map(ChordView::from)
        .collect())
}

fn count(chord: &Chord) -> usize {
    let never = AtomicBool::new(false);
    theory::find_voicings(chord, &SearchOptions::default(), &never, |_, _| {}).len()
}

fn log_thread(command: &str) {
    let thread = std::thread::current();
    println!(
        "{command} runs on thread {:?}",
        thread.name().unwrap_or("unnamed")
    );
}

/// A synchronous command: Tauri runs it on the main thread.
#[tauri::command]
pub fn count_voicings_blocking(symbol: &str) -> Result<usize, CommandError> {
    log_thread("count_voicings_blocking");
    let chord: Chord = symbol.parse()?;
    Ok(count(&chord))
}

/// An async command: Tauri runs it on its async runtime, and the CPU-bound
/// search goes to the blocking thread pool.
#[tauri::command]
pub async fn count_voicings(symbol: String) -> Result<usize, CommandError> {
    log_thread("count_voicings");
    let chord: Chord = symbol.parse()?;
    let found = tauri::async_runtime::spawn_blocking(move || {
        log_thread("count_voicings (search)");
        count(&chord)
    })
    .await?;
    Ok(found)
}
