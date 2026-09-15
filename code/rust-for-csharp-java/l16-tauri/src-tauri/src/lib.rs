//! Chord Explorer: a Tauri window over the `theory` crate.
//!
//! `commands` is lesson 17 (calling Rust from the UI), `state` is lesson 18
//! (managed state, events and channels).

pub mod commands;
pub mod state;

#[cfg(doctest)]
mod compile_fail;

use tauri::{Builder, Runtime};

/// Registers the managed state and every command.
///
/// Generic over the runtime so that the tests can use Tauri's mock runtime.
pub fn setup<R: Runtime>(builder: Builder<R>) -> Builder<R> {
    builder
        .manage(state::Favorites::default())
        .manage(state::SearchControl::default())
        .invoke_handler(tauri::generate_handler![
            commands::chord_qualities,
            commands::spell_chord,
            commands::transpose_chord,
            commands::diatonic_chords,
            commands::count_voicings_blocking,
            commands::count_voicings,
            state::favorites,
            state::toggle_favorite,
            state::find_voicings,
            state::cancel_search,
        ])
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    setup(tauri::Builder::default())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
