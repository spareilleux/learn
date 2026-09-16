//! Chord Explorer: a Tauri window over the `theory` crate.
//!
//! `commands` is lesson 17 (calling Rust from the UI), `state` is lesson 18
//! (managed state, events and channels). `run` adds lesson 20's plugins and, for
//! lesson 21's end-to-end tests, an optional WebDriver server.

pub mod commands;
pub mod state;

#[cfg(doctest)]
mod compile_fail;

use tauri::{AppHandle, Builder, Listener, Manager, Runtime};
use tauri_plugin_store::StoreExt;

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

/// The store file, in the app's data folder, that keeps the favourites between runs.
const STORE_FILE: &str = "favorites.json";
const FAVORITES_KEY: &str = "favorites";

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let builder = setup(tauri::Builder::default())
        // Lesson 20: plugins. Their commands still need permissions in a capability
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_store::Builder::new().build());

    // Lesson 21: absent from normal builds, so the shipped app opens no WebDriver port
    #[cfg(feature = "webdriver")]
    let builder = builder.plugin(tauri_plugin_wdio_webdriver::init());

    builder
        .setup(|app| restore_favorites(app.handle()))
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

/// Loads the saved favourites into the managed state, then saves them again each time
/// `toggle_favorite` announces a change (lesson 18's event). This is Rust code, so no
/// capability is involved: permissions only restrict what the webview may call.
fn restore_favorites<R: Runtime>(app: &AppHandle<R>) -> Result<(), Box<dyn std::error::Error>> {
    let store = app.store(STORE_FILE)?;
    if let Some(saved) = store.get(FAVORITES_KEY) {
        let symbols: Vec<String> = serde_json::from_value(saved).unwrap_or_default();
        app.state::<state::Favorites>().replace(symbols);
    }
    app.listen("favorites-changed", move |event| {
        if let Ok(symbols) = serde_json::from_str::<serde_json::Value>(event.payload()) {
            store.set(FAVORITES_KEY, symbols);
        }
    });
    Ok(())
}
