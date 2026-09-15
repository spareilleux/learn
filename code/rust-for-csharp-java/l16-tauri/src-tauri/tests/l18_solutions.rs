//! Solutions to the exercises of lesson 18, each registered on its own mock app.

mod common;

use std::collections::{HashMap, VecDeque};
use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};
use std::sync::{Arc, Mutex};

use chord_explorer_lib::commands::{ChordView, CommandError};
use common::{invoke, launch};
use serde_json::json;
use tauri::State;
use tauri::test::mock_builder;
use theory::Chord;

// Exercise 1: remember the last five chords spelled
#[derive(Default)]
struct RecentChords(Mutex<VecDeque<String>>);

const RECENT: usize = 5;

#[tauri::command]
fn spell_and_remember(
    recent: State<'_, RecentChords>,
    symbol: &str,
) -> Result<ChordView, CommandError> {
    let chord: Chord = symbol.parse()?;
    let symbol = chord.to_string();
    let mut list = recent.0.lock().unwrap();
    list.retain(|previous| *previous != symbol);
    list.push_front(symbol);
    list.truncate(RECENT);
    Ok(chord.into())
}

#[tauri::command]
fn recent_chords(recent: State<'_, RecentChords>) -> Vec<String> {
    recent.0.lock().unwrap().iter().cloned().collect()
}

#[test]
fn exercise_1_recent_chords() {
    let (_app, webview) = launch(
        mock_builder()
            .manage(RecentChords::default())
            .invoke_handler(tauri::generate_handler![spell_and_remember, recent_chords]),
    );
    for symbol in ["C", "Am", "F", "G", "Am", "Dm", "E7", "Hm"] {
        let _ = invoke(&webview, "spell_and_remember", json!({ "symbol": symbol }));
    }
    assert_eq!(
        invoke(&webview, "recent_chords", json!({})),
        Ok(json!(["E7", "Dm", "Am", "G", "F"]))
    );
}

// Exercise 2: one cancellation flag per search, so that two searches don't share one
#[derive(Default)]
struct Searches {
    next_id: AtomicU32,
    running: Mutex<HashMap<u32, Arc<AtomicBool>>>,
}

impl Searches {
    fn start(&self) -> (u32, Arc<AtomicBool>) {
        let id = self.next_id.fetch_add(1, Ordering::Relaxed);
        let flag = Arc::new(AtomicBool::new(false));
        self.running.lock().unwrap().insert(id, Arc::clone(&flag));
        (id, flag)
    }

    fn finish(&self, id: u32) {
        self.running.lock().unwrap().remove(&id);
    }
}

#[tauri::command]
fn cancel_search(searches: State<'_, Searches>, id: u32) -> bool {
    match searches.running.lock().unwrap().get(&id) {
        Some(flag) => {
            flag.store(true, Ordering::Relaxed);
            true
        }
        None => false,
    }
}

#[test]
fn exercise_2_cancel_one_search_among_two() {
    let (app, webview) = launch(
        mock_builder()
            .manage(Searches::default())
            .invoke_handler(tauri::generate_handler![cancel_search]),
    );
    let searches: State<'_, Searches> = tauri::Manager::state(&app);
    let (first, first_flag) = searches.start();
    let (second, second_flag) = searches.start();

    assert_eq!(
        invoke(&webview, "cancel_search", json!({ "id": second })),
        Ok(json!(true))
    );
    assert!(!first_flag.load(Ordering::Relaxed));
    assert!(second_flag.load(Ordering::Relaxed));

    searches.finish(first);
    assert_eq!(
        invoke(&webview, "cancel_search", json!({ "id": first })),
        Ok(json!(false))
    );
}
