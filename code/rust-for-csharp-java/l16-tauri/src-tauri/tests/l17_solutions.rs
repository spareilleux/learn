//! Solutions to the exercises of lesson 17, each command registered on its own mock app.

mod common;

use chord_explorer_lib::commands::{CommandError, ScaleMode};
use common::{invoke, launch};
use serde_json::json;
use tauri::test::mock_builder;
use theory::Note;

// Exercise 1: a command that returns the notes of a scale
#[tauri::command]
fn scale_notes(tonic_note: &str, mode: ScaleMode) -> Result<Vec<String>, CommandError> {
    let tonic: Note = tonic_note.parse()?;
    Ok(theory::scale_notes(tonic, mode.into())
        .iter()
        .map(Note::to_string)
        .collect())
}

#[test]
fn exercise_1_scale_notes() {
    let (_app, webview) =
        launch(mock_builder().invoke_handler(tauri::generate_handler![scale_notes]));
    assert_eq!(
        invoke(
            &webview,
            "scale_notes",
            json!({ "tonicNote": "F", "mode": "major" })
        ),
        Ok(json!(["F", "G", "A", "Bb", "C", "D", "E"]))
    );
    let error = invoke(
        &webview,
        "scale_notes",
        json!({ "tonicNote": "H", "mode": "minor" }),
    );
    println!("scale_notes H -> {}", error.clone().unwrap_err());
    assert_eq!(error.unwrap_err()["kind"], "invalidNote");
}

// Exercise 3: CPU-bound work directly in an async command, without spawn_blocking
#[tauri::command]
async fn search_thread() -> String {
    std::thread::current()
        .name()
        .unwrap_or("unnamed")
        .to_string()
}

#[test]
fn exercise_3_async_commands_run_on_runtime_workers() {
    let (_app, webview) =
        launch(mock_builder().invoke_handler(tauri::generate_handler![search_thread]));
    let thread = invoke(&webview, "search_thread", json!({})).unwrap();
    println!("an async command runs on {thread}");
    assert_eq!(thread, "tokio-rt-worker");
}
