//! Lesson 18: managed state, events and channels.

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Instant;

use serde::Serialize;
use tauri::ipc::Channel;
use tauri::{AppHandle, Emitter, Runtime, State};
use theory::{Chord, SearchOptions, Voicing};
use ts_rs::TS;

use crate::commands::CommandError;

/// The favourite chord symbols, shared by every window.
#[derive(Default)]
pub struct Favorites(Mutex<Vec<String>>);

impl Favorites {
    /// Replaces the list, for example with the favourites saved by a previous run.
    pub fn replace(&self, symbols: Vec<String>) {
        *self.0.lock().unwrap() = symbols;
    }
}

/// Lets `cancel_search` stop the search started by `find_voicings`.
#[derive(Default)]
pub struct SearchControl {
    cancel: Arc<AtomicBool>,
}

#[tauri::command]
pub fn favorites(favorites: State<'_, Favorites>) -> Vec<String> {
    favorites.0.lock().unwrap().clone()
}

/// Adds or removes a favourite, then tells every window with a `favorites-changed` event.
#[tauri::command]
pub fn toggle_favorite<R: Runtime>(
    app: AppHandle<R>,
    favorites: State<'_, Favorites>,
    symbol: &str,
) -> Result<Vec<String>, CommandError> {
    let symbol = symbol.parse::<Chord>()?.to_string();
    let snapshot = {
        let mut list = favorites.0.lock().unwrap();
        match list.iter().position(|favorite| *favorite == symbol) {
            Some(index) => {
                list.remove(index);
            }
            None => list.push(symbol),
        }
        list.clone()
    }; // the lock is released here, before talking to the webviews
    app.emit("favorites-changed", &snapshot)?;
    Ok(snapshot)
}

/// What `find_voicings` streams to the frontend, in order.
#[derive(Clone, Serialize, TS)]
#[ts(export)]
#[serde(
    tag = "event",
    content = "data",
    rename_all = "camelCase",
    rename_all_fields = "camelCase"
)]
pub enum SearchEvent {
    Voicings {
        frets: Vec<String>,
    },
    Progress {
        done: usize,
        total: usize,
    },
    Finished {
        found: usize,
        // ts-rs maps u128 to `bigint`, but serde_json writes a plain JSON number
        #[ts(type = "number")]
        elapsed_ms: u128,
        cancelled: bool,
    },
}

/// Searches every voicing of a chord on a blocking thread and streams the results.
#[tauri::command]
pub async fn find_voicings(
    symbol: String,
    max_span: u8,
    control: State<'_, SearchControl>,
    on_event: Channel<SearchEvent>,
) -> Result<usize, CommandError> {
    let chord: Chord = symbol.parse()?;
    let options = SearchOptions {
        max_span,
        ..SearchOptions::default()
    };
    let cancel = Arc::clone(&control.cancel);
    cancel.store(false, Ordering::Relaxed);

    let found = tauri::async_runtime::spawn_blocking(move || {
        let started = Instant::now();
        let voicings = theory::find_voicings(&chord, &options, &cancel, |progress, batch| {
            if !batch.is_empty() {
                let frets = batch.iter().map(Voicing::to_string).collect();
                // A send fails only if the webview is gone: nothing left to tell
                let _ = on_event.send(SearchEvent::Voicings { frets });
            }
            let _ = on_event.send(SearchEvent::Progress {
                done: progress.done,
                total: progress.total,
            });
        });
        let _ = on_event.send(SearchEvent::Finished {
            found: voicings.len(),
            elapsed_ms: started.elapsed().as_millis(),
            cancelled: cancel.load(Ordering::Relaxed),
        });
        voicings.len()
    })
    .await?;
    Ok(found)
}

#[tauri::command]
pub fn cancel_search(control: State<'_, SearchControl>) {
    control.cancel.store(true, Ordering::Relaxed);
}
