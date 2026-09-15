use std::fmt;
use std::sync::atomic::{AtomicBool, Ordering};

use crate::Chord;

/// Standard guitar tuning as pitch classes, from the low E string to the high E string.
pub const STANDARD_TUNING: [u8; 6] = [4, 9, 2, 7, 11, 4];

/// A fingering: one fret per string from low E to high E, `None` for a muted string.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Voicing(pub [Option<u8>; 6]);

impl fmt::Display for Voicing {
    /// `x-3-2-0-1-0` for the open C chord.
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let frets: Vec<String> = self
            .0
            .iter()
            .map(|fret| fret.map_or("x".to_string(), |n| n.to_string()))
            .collect();
        write!(f, "{}", frets.join("-"))
    }
}

/// Limits for [`find_voicings`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SearchOptions {
    /// Highest fret considered.
    pub max_fret: u8,
    /// Largest distance between the lowest and highest fretted notes (open strings excluded).
    pub max_span: u8,
    /// Fewest strings that must sound.
    pub min_strings: usize,
}

impl Default for SearchOptions {
    fn default() -> Self {
        SearchOptions {
            max_fret: 12,
            max_span: 3,
            min_strings: 4,
        }
    }
}

/// How far a search has got: `done` positions of the low E string out of `total`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Progress {
    pub done: usize,
    pub total: usize,
}

/// Finds every root-position voicing of `chord` in standard tuning, by brute force.
///
/// A voicing qualifies when it sounds every chord tone and nothing else, its lowest
/// note is the root, its muted strings are all on the bass side, and its fretted
/// notes fit in `max_span`.
///
/// The search tries each position of the low E string in turn (muted, open, fret 1…)
/// and calls `on_batch` after each one with the progress and the voicings it found.
/// When `cancel` becomes `true`, it stops after the current batch.
pub fn find_voicings(
    chord: &Chord,
    options: &SearchOptions,
    cancel: &AtomicBool,
    mut on_batch: impl FnMut(Progress, &[Voicing]),
) -> Vec<Voicing> {
    let target = chord.pitch_class_mask();
    let root = chord.root.pitch_class();
    // Every string is muted or on a fret from 0 to max_fret
    let choices: Vec<Option<u8>> = std::iter::once(None)
        .chain((0..=options.max_fret).map(Some))
        .collect();
    let per_string = choices.len();
    let upper_combinations = per_string.pow(5);

    let mut found = Vec::new();
    for (done, &low) in choices.iter().enumerate() {
        if cancel.load(Ordering::Relaxed) {
            break;
        }
        let mut batch = Vec::new();
        for index in 0..upper_combinations {
            let mut frets = [low, None, None, None, None, None];
            let mut rest = index;
            for fret in frets.iter_mut().skip(1) {
                *fret = choices[rest % per_string];
                rest /= per_string;
            }
            let voicing = Voicing(frets);
            if qualifies(&voicing, target, root, options) {
                batch.push(voicing);
            }
        }
        on_batch(
            Progress {
                done: done + 1,
                total: per_string,
            },
            &batch,
        );
        found.extend(batch);
    }
    found
}

fn qualifies(voicing: &Voicing, target: u16, root: u8, options: &SearchOptions) -> bool {
    let frets = &voicing.0;
    // Muted strings only below the sounding ones
    let first_sounding = match frets.iter().position(Option::is_some) {
        Some(position) => position,
        None => return false,
    };
    if frets[first_sounding..].iter().any(Option::is_none) {
        return false;
    }
    if frets.len() - first_sounding < options.min_strings {
        return false;
    }

    let mut mask = 0u16;
    let (mut lowest, mut highest) = (u8::MAX, 0);
    for (string, fret) in frets.iter().enumerate().skip(first_sounding) {
        let fret = fret.expect("strings above the first sounding one sound");
        mask |= 1 << ((STANDARD_TUNING[string] + fret) % 12);
        if fret > 0 {
            lowest = lowest.min(fret);
            highest = highest.max(fret);
        }
    }
    let bass = (STANDARD_TUNING[first_sounding] + frets[first_sounding].unwrap_or(0)) % 12;
    let span_ok = highest == 0 || highest - lowest <= options.max_span;
    mask == target && bass == root && span_ok
}

#[cfg(test)]
mod tests {
    use super::*;

    fn search(symbol: &str) -> Vec<String> {
        let chord: Chord = symbol.parse().unwrap();
        let cancel = AtomicBool::new(false);
        find_voicings(&chord, &SearchOptions::default(), &cancel, |_, _| {})
            .iter()
            .map(Voicing::to_string)
            .collect()
    }

    #[test]
    fn finds_the_open_chords() {
        assert!(search("C").contains(&"x-3-2-0-1-0".to_string()));
        assert!(search("Am").contains(&"x-0-2-2-1-0".to_string()));
        assert!(search("E").contains(&"0-2-2-1-0-0".to_string()));
        assert!(search("G").contains(&"3-2-0-0-0-3".to_string()));
    }

    #[test]
    fn every_result_is_a_root_position_voicing() {
        let chord: Chord = "Bbm7".parse().unwrap();
        let cancel = AtomicBool::new(false);
        let voicings = find_voicings(&chord, &SearchOptions::default(), &cancel, |_, _| {});
        assert!(!voicings.is_empty());
        let target = chord.pitch_class_mask();
        for voicing in &voicings {
            assert!(qualifies(
                voicing,
                target,
                chord.root.pitch_class(),
                &SearchOptions::default()
            ));
        }
    }

    #[test]
    fn rejects_muted_strings_between_sounding_ones() {
        // x-3-x-0-1-0 sounds C, G, C, E: right notes, unplayable muting
        let voicing = Voicing([None, Some(3), None, Some(0), Some(1), Some(0)]);
        let chord: Chord = "C".parse().unwrap();
        let options = SearchOptions {
            min_strings: 3,
            ..SearchOptions::default()
        };
        assert!(!qualifies(&voicing, chord.pitch_class_mask(), 0, &options));
    }

    #[test]
    fn reports_every_batch_and_stops_when_cancelled() {
        let chord: Chord = "C".parse().unwrap();
        let options = SearchOptions {
            max_fret: 5,
            ..SearchOptions::default()
        };
        let cancel = AtomicBool::new(false);
        let mut batches = Vec::new();
        find_voicings(&chord, &options, &cancel, |progress, _| {
            batches.push(progress.done);
            if progress.done == 3 {
                cancel.store(true, Ordering::Relaxed);
            }
        });
        assert_eq!(batches, [1, 2, 3]);
    }
}
