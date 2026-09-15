//! The snippets that lessons 17 and 18 show being rejected, as `compile_fail` doctests:
//! `cargo test --doc` checks that each one still fails to compile.
//!
//! Lesson 17, a return type that is not serializable:
//!
//! ```compile_fail
//! struct Chord {
//!     symbol: String,
//! }
//!
//! #[tauri::command]
//! fn spell_chord(symbol: String) -> Chord {
//!     Chord { symbol }
//! }
//!
//! fn main() {
//!     let _ = tauri::Builder::default().invoke_handler(tauri::generate_handler![spell_chord]);
//! }
//! ```
//!
//! Lesson 17, an async command that borrows its argument and does not return a `Result`:
//!
//! ```compile_fail
//! #[tauri::command]
//! async fn count_voicings(symbol: &str) -> usize {
//!     symbol.len()
//! }
//!
//! fn main() {
//!     let _ = tauri::Builder::default().invoke_handler(tauri::generate_handler![count_voicings]);
//! }
//! ```
//!
//! Lesson 17, a `pub` command at the root of the crate:
//!
//! ```compile_fail
//! #[tauri::command]
//! pub fn spell_chord(symbol: String) -> String {
//!     symbol
//! }
//!
//! fn main() {
//!     let _ = tauri::Builder::default().invoke_handler(tauri::generate_handler![spell_chord]);
//! }
//! ```
//!
//! Lesson 18, an async command that takes `State` and does not return a `Result`:
//!
//! ```compile_fail
//! use std::sync::Mutex;
//!
//! #[tauri::command]
//! async fn favorites(favorites: tauri::State<'_, Mutex<Vec<String>>>) -> Vec<String> {
//!     favorites.lock().unwrap().clone()
//! }
//!
//! fn main() {
//!     let _ = tauri::Builder::default().invoke_handler(tauri::generate_handler![favorites]);
//! }
//! ```
//!
//! Lesson 18, a `MutexGuard` held across an `.await`:
//!
//! ```compile_fail
//! use std::sync::Mutex;
//!
//! async fn save(_list: &[String]) {}
//!
//! #[tauri::command]
//! async fn add_favorite(
//!     favorites: tauri::State<'_, Mutex<Vec<String>>>,
//!     symbol: String,
//! ) -> Result<(), String> {
//!     let mut list = favorites.lock().unwrap();
//!     list.push(symbol);
//!     save(&list).await;
//!     Ok(())
//! }
//!
//! fn main() {
//!     let _ = tauri::Builder::default().invoke_handler(tauri::generate_handler![add_favorite]);
//! }
//! ```
//!
//! Lesson 18, an event payload that is not `Clone`:
//!
//! ```compile_fail
//! use tauri::{AppHandle, Emitter};
//!
//! #[derive(serde::Serialize)]
//! struct Favorites {
//!     symbols: Vec<String>,
//! }
//!
//! #[tauri::command]
//! fn announce(app: AppHandle) -> Result<(), String> {
//!     let payload = Favorites { symbols: vec!["Am".into()] };
//!     app.emit("favorites-changed", payload).map_err(|e| e.to_string())
//! }
//!
//! fn main() {
//!     let _ = tauri::Builder::default().invoke_handler(tauri::generate_handler![announce]);
//! }
//! ```
