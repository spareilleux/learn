//! Calls the commands through Tauri's IPC layer with the mock runtime: no window,
//! no webview, but the same argument parsing and JSON serialization as the app.

mod common;

use std::sync::{Mutex, mpsc};
use std::time::Duration;

use common::{invoke, launch};
use serde_json::json;
use tauri::test::{MockRuntime, mock_builder};
use tauri::{App, Listener, State, WebviewWindow};

fn app() -> (App<MockRuntime>, WebviewWindow<MockRuntime>) {
    launch(chord_explorer_lib::setup(mock_builder()))
}

#[test]
fn spell_chord_resolves_with_a_camel_case_object() {
    let (_app, webview) = app();
    let chord = invoke(&webview, "spell_chord", json!({ "symbol": "Bbm7" }));
    println!("spell_chord Bbm7 -> {}", chord.clone().unwrap());
    assert_eq!(
        chord,
        Ok(json!({
            "symbol": "Bbm7",
            "qualityName": "minor seventh",
            "notes": ["Bb", "Db", "F", "Ab"],
            "intervals": ["1", "b3", "5", "b7"]
        }))
    );
}

#[test]
fn a_theory_error_rejects_with_kind_and_message() {
    let (_app, webview) = app();
    let error = invoke(&webview, "spell_chord", json!({ "symbol": "Cm9" }));
    println!("spell_chord Cm9 -> {}", error.clone().unwrap_err());
    assert_eq!(
        error,
        Err(json!({ "kind": "unknownQuality", "message": "unknown chord quality `m9` in `Cm9`" }))
    );
}

#[test]
fn argument_errors_come_from_tauri() {
    let (_app, webview) = app();
    for (cmd, args) in [
        ("spell_chord", json!({})),
        ("spell_chord", json!({ "symbol": 42 })),
        ("count_voicings", json!({ "symbol": 42 })),
        (
            "diatonic_chords",
            json!({ "tonic_note": "C", "mode": "major" }),
        ),
        (
            "diatonic_chords",
            json!({ "tonicNote": "C", "mode": "dorian" }),
        ),
        ("transpose_chord", json!({ "symbol": "C" })),
        (
            "transpose_chord",
            json!({ "symbol": "C", "semitones": 1.5 }),
        ),
        (
            "transpose_chord",
            json!({ "symbol": "C", "semitones": "2" }),
        ),
        ("play_chord", json!({ "symbol": "C" })),
    ] {
        let error = invoke(&webview, cmd, args).expect_err("the call is rejected");
        println!("{cmd} -> {error}");
        assert!(error.is_string());
    }
}

#[test]
fn diatonic_chords_uses_camel_case_arguments() {
    let (_app, webview) = app();
    let chords = invoke(
        &webview,
        "diatonic_chords",
        json!({ "tonicNote": "Eb", "mode": "minor" }),
    )
    .unwrap();
    let symbols: Vec<&str> = chords
        .as_array()
        .unwrap()
        .iter()
        .map(|chord| chord["symbol"].as_str().unwrap())
        .collect();
    assert_eq!(symbols, ["Ebm", "Fdim", "Gb", "Abm", "Bbm", "Cb", "Db"]);
}

#[test]
fn favorites_live_in_managed_state() {
    let (_app, webview) = app();
    assert_eq!(invoke(&webview, "favorites", json!({})), Ok(json!([])));
    invoke(&webview, "toggle_favorite", json!({ "symbol": " Am " })).unwrap();
    invoke(&webview, "toggle_favorite", json!({ "symbol": "G7" })).unwrap();
    assert_eq!(
        invoke(&webview, "favorites", json!({})),
        Ok(json!(["Am", "G7"]))
    );
    invoke(&webview, "toggle_favorite", json!({ "symbol": "Am" })).unwrap();
    assert_eq!(invoke(&webview, "favorites", json!({})), Ok(json!(["G7"])));
}

#[tauri::command]
fn recent_chords(recent: State<'_, Mutex<Vec<String>>>) -> Vec<String> {
    recent.lock().unwrap().clone()
}

#[test]
fn state_that_was_never_managed_rejects_the_call() {
    // No .manage(Mutex::new(Vec::<String>::new())) on this builder
    let (_app, webview) =
        launch(mock_builder().invoke_handler(tauri::generate_handler![recent_chords]));
    let error = invoke(&webview, "recent_chords", json!({})).unwrap_err();
    println!("recent_chords -> {error}");
    assert!(error.as_str().unwrap().starts_with("state not managed"));
}

#[test]
fn toggle_favorite_emits_an_event() {
    let (app, webview) = app();
    let (sender, received) = mpsc::channel();
    app.listen("favorites-changed", move |event| {
        sender.send(event.payload().to_string()).unwrap();
    });
    invoke(&webview, "toggle_favorite", json!({ "symbol": "Bb7" })).unwrap();
    let payload = received.recv_timeout(Duration::from_secs(5)).unwrap();
    println!("favorites-changed payload: {payload}");
    assert_eq!(payload, r#"["Bb7"]"#);
}

#[test]
fn async_commands_resolve_too() {
    let (_app, webview) = app();
    let found = invoke(&webview, "count_voicings", json!({ "symbol": "C" })).unwrap();
    assert!(found.as_u64().unwrap() > 0);
}
