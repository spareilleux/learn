---
title: 17. Tauri commands, calling Rust from the UI
description: "#[tauri::command] and invoke — arguments and return values through serde, errors the frontend can read, what Tauri checks at compile time and at run time, and the thread a command runs on — compared with WPF commands, controllers and Electron's IPC."
sidebar:
  order: 17
---

Full example: [`l16-tauri/src-tauri/src/commands.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs) and [`ui/main.js`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/ui/main.js); the tests in [`src-tauri/tests/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/src-tauri/tests) call every command through Tauri's IPC layer (`cargo test -p chord-explorer`).

## What you already know

A **command** is a Rust function that the page calls by name, with JSON arguments, and whose result comes back as a JavaScript promise. It is closer to a web API than to a WPF command:

| | Tauri | WPF | ASP.NET Core / Spring | Electron |
|---|---|---|---|---|
| Declared with | [`#[tauri::command]`](https://docs.rs/tauri/2.11.5/tauri/attr.command.html) | [`ICommand`](https://learn.microsoft.com/dotnet/api/system.windows.input.icommand) on the view model | a controller action, [`@RestController`](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller.html) | [`ipcMain.handle`](https://www.electronjs.org/docs/latest/api/ipc-main#ipcmainhandlechannel-listener) |
| Registered with | [`generate_handler!`](https://docs.rs/tauri/2.11.5/tauri/macro.generate_handler.html) | a XAML binding | routing | the channel name |
| Called with | [`invoke`](https://v2.tauri.app/reference/javascript/api/namespacecore/#invoke) | a click on a bound button | `fetch` | `ipcRenderer.invoke` behind [`contextBridge`](https://www.electronjs.org/docs/latest/api/context-bridge) |
| Data format | JSON through [serde](https://serde.rs/) | .NET objects, same process | JSON | [structured clone](https://developer.mozilla.org/docs/Web/API/Web_Workers_API/Structured_clone_algorithm) |
| Errors | a rejected promise carrying your serialized error | exceptions | status code + [`ProblemDetails`](https://learn.microsoft.com/aspnet/core/web-api/handle-errors) | a rejected promise with a new `Error` |

The page and the Rust code live in different processes (lesson 16), so there is no shared object and no reference: every argument is deserialized when it arrives and every result is serialized when it leaves.

## A first command

From [`src-tauri/src/commands.rs`, lines 95-99](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L95-L99):

```rust
#[tauri::command]
pub fn spell_chord(symbol: &str) -> Result<ChordView, CommandError> {
    let chord: Chord = symbol.parse()?;
    Ok(chord.into())
}
```

The attribute generates the glue: read `symbol` from the request's JSON, call the function, serialize the `Result`. The function itself stays an ordinary Rust function that you can call and test directly.

Every command is registered once, in a single `generate_handler!` (calling `invoke_handler` twice keeps only the last list). The course's app does it in a `setup` function that the tests reuse (from [`src-tauri/src/lib.rs`, lines 17-33](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L17-L33)):

```rust
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
```

`setup` is generic over the [`Runtime`](https://docs.rs/tauri/2.11.5/tauri/trait.Runtime.html): the application passes the real one (`tauri::Builder::default()`, WebView2 and company), the tests pass [`tauri::test::mock_builder()`](https://docs.rs/tauri/2.11.5/tauri/test/fn.mock_builder.html).

The page calls the command by its name. With `withGlobalTauri` (lesson 16), `invoke` is on `window.__TAURI__.core` (from [`ui/main.js`, lines 16-25](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/ui/main.js#L16-L25)):

```js
async function spell(symbol) {
  $("chord-error").textContent = "";
  try {
    const chord = await invoke("spell_chord", { symbol });
    showChord(chord);
  } catch (error) {
    $("chord-output").textContent = "";
    $("chord-error").textContent = describe(error);
  }
}
```

What the promise resolves with, captured in the running window through WebView2's developer tools protocol:

```text
spell_chord {"symbol":"Bbm7"} resolved: {"symbol":"Bbm7","qualityName":"minor seventh","notes":["Bb","Db","F","Ab"],"intervals":["1","b3","5","b7"]}
```

## Arguments

Arguments arrive as one JSON object whose keys are the parameter names **in camelCase**: `tonic_note` in Rust is `tonicNote` in JavaScript ([calling Rust](https://v2.tauri.app/develop/calling-rust/#passing-arguments)). Each parameter's type implements [`Deserialize`](https://docs.rs/serde/latest/serde/trait.Deserialize.html), so an enum works as well as a string or a number (from [`src-tauri/src/commands.rs`, lines 67-73](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L67-L73)):

```rust
/// `"major"` or `"minor"` in JSON.
#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ScaleMode {
    Major,
    Minor,
}
```

```rust
#[tauri::command]
pub fn diatonic_chords(tonic_note: &str, mode: ScaleMode) -> Result<Vec<ChordView>, CommandError> {
    let tonic: Note = tonic_note.parse()?;
    Ok(theory::diatonic_chords(tonic, mode.into())
        .into_iter()
        .map(ChordView::from)
        .collect())
}
```

```js
const chords = await invoke("diatonic_chords", {
  tonicNote: $("tonic-input").value,
  mode: $("mode-select").value,
});
```

When the JSON does not match, the command never runs: Tauri rejects the call with a message that names the command and the argument. The real rejections, from the window:

```text
diatonic_chords {"tonic_note":"C","mode":"major"} rejected (string): "invalid args `tonicNote` for command `diatonic_chords`: command diatonic_chords missing required key tonicNote"
diatonic_chords {"tonicNote":"C","mode":"dorian"} rejected (string): "invalid args `mode` for command `diatonic_chords`: unknown variant `dorian`, expected `major` or `minor`"
transpose_chord {"symbol":"C","semitones":"2"} rejected (string): "invalid args `semitones` for command `transpose_chord`: invalid type: string \"2\", expected i32"
play_chord {"symbol":"C"} rejected (string): "Command play_chord not found"
```

The first one is the classic mistake: snake_case keys in JavaScript. A sync command can take `&str`, borrowed from the request, without copying. JavaScript numbers are all doubles, but serde checks the Rust type: `1.5` for an `i32` fails too (``invalid type: floating point `1.5`, expected i32``).

## Return values

The return type must implement [`Serialize`](https://docs.rs/serde/latest/serde/trait.Serialize.html). The course's commands return small structs made for the page rather than the `theory` types, as a controller returns DTOs rather than domain entities (from [`src-tauri/src/commands.rs`, lines 8-27](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L8-L27)):

```rust
/// A chord as the frontend receives it: strings ready to display.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
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
```

Arguments are renamed to camelCase by Tauri, but return values are serialized by serde as they are: without `#[serde(rename_all = "camelCase")]`, the page would receive `quality_name`.

Forgetting `Serialize` is a compile error, but not a readable one ([`compile_fail` doctest](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/compile_fail.rs)):

```rust
struct Chord {
    symbol: String,
}

#[tauri::command]
fn spell_chord(symbol: String) -> Chord {
    Chord { symbol }
}
```

```text
error[E0599]: the method `blocking_kind` exists for reference `&Chord`, but its trait bounds were not satisfied
   --> examples\e17_not_serialize.rs:5:1
    |
  1 | struct Chord {
    | ------------ doesn't satisfy `Chord: IpcResponse`
...
  5 | #[tauri::command]
    | ^^^^^^^^^^^^^^^^^ method cannot be called on `&Chord` due to unsatisfied trait bounds
...
    = note: the following trait bounds were not satisfied:
            `Chord: IpcResponse`
            which is required by `&Chord: tauri::ipc::private::ResponseKind`
```

The message never says `Serialize`. The missing trait, [`IpcResponse`](https://docs.rs/tauri/2.11.5/tauri/ipc/trait.IpcResponse.html), is implemented for every `T: Serialize`: when an error mentions `IpcResponse` or `blocking_kind`, check the return type's `derive`.

## Errors

A command that returns `Result<T, E>` resolves the promise with `T` or rejects it with `E`, and `E` must be serializable too. `String` works, but loses the kind of error. The course's commands use one error type with a machine-readable `kind`, in the spirit of `ProblemDetails` (from [`src-tauri/src/commands.rs`, lines 36-56](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L36-L56)):

```rust
/// The error a failed command sends to the frontend, where the promise rejects with
/// `{ kind, message }`.
#[derive(Debug, Serialize)]
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
```

The `From` implementations are what make `?` work in the commands (lesson 6): `symbol.parse()?` turns a `TheoryError` into a `CommandError`. In the window:

```text
spell_chord {"symbol":"Cm9"} rejected (object): {"kind":"unknownQuality","message":"unknown chord quality `m9` in `Cm9`"}
spell_chord {"symbol":""} rejected (object): {"kind":"empty","message":"empty chord symbol"}
instanceof Error: false, kind: unknownQuality
```

Two consequences for the JavaScript side:

- The rejection value is the serialized error itself, **not** a JavaScript `Error`: no stack trace, and `error.message` exists only because `CommandError` has a `message` field.
- When Tauri refuses the call before your function runs (unknown command, invalid arguments), the rejection is a **string**. The first version of the explorer displayed `undefined: undefined` for those; the page now goes through one helper (from [`ui/main.js`, lines 10-14](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/ui/main.js#L10-L14)):

```js
// A rejected invoke gives our CommandError, { kind, message }, or a plain string
// when Tauri itself refuses the call (unknown command, invalid arguments)
function describe(error) {
  return typeof error === "string" ? error : `${error.kind}: ${error.message}`;
}
```

A panic inside a command is not an error value: it is a bug. Keep `unwrap` for invariants, as in lesson 6, and return `Err` for everything the user can cause.

## Where a command runs

This is the part a WPF developer must not guess. From the [Tauri guide](https://v2.tauri.app/develop/calling-rust/#async-commands): commands without `async` run on the **main thread**, unless declared with `#[tauri::command(async)]`; `async` commands run on Tauri's async runtime, a tokio runtime (lesson 13).

The explorer has the same search both ways (from [`src-tauri/src/commands.rs`, lines 129-149](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L129-L149)):

```rust
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
```

The terminal running `tauri dev` prints:

```text
count_voicings_blocking runs on thread "main"
count_voicings runs on thread "tokio-rt-worker"
count_voicings (search) runs on thread "tokio-rt-worker"
```

The search tries 7.5 million fingerings and takes about a second in a debug build. Measured in the window, twice each, with a second command sent 100 ms after the first and a 10 ms JavaScript timer running meanwhile:

```text
count_voicings_blocking: 27 voicings in 1058 ms; chord_qualities sent 100 ms later answered after 958 ms; longest gap between 10 ms JavaScript timer ticks: 12 ms
count_voicings: 27 voicings in 1078 ms; chord_qualities sent 100 ms later answered after 2 ms; longest gap between 10 ms JavaScript timer ticks: 12 ms
```

And a PowerShell loop sending [`WM_NULL`](https://learn.microsoft.com/windows/win32/winmsg/wm-null) to the window with [`SendMessageTimeout`](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-sendmessagetimeoutw) during each call:

```text
blocking call: 1062 ms
window 'Chord Explorer': 64 WM_NULL probes, slowest answer 945 ms
async call: 1095 ms
window 'Chord Explorer': 95 WM_NULL probes, slowest answer 4 ms
```

What freezes is not what a WPF developer expects:

- The **page** keeps running: its JavaScript timer never missed a beat, because the webview is another process.
- The **native window** does not answer its messages for almost a second: it cannot be moved, resized or closed. Windows marks a window *Not Responding* after five seconds of this ([`IsHungAppWindow`](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-ishungappwindow)).
- Every **other command** waits: `chord_qualities` needed 958 ms instead of 2, because the main thread handles the IPC requests.

The rule is the same as for the WPF [`Dispatcher`](https://learn.microsoft.com/dotnet/api/system.windows.threading.dispatcher) or the JavaFX application thread: nothing slow on the main thread. In Tauri, that means `async` for anything that waits or computes, and [`spawn_blocking`](https://docs.rs/tauri/2.11.5/tauri/async_runtime/fn.spawn_blocking.html) for CPU-bound work, so that it does not occupy one of the runtime's workers either (exercise 3).

## What the macro checks

Because `#[tauri::command]` generates code, some mistakes are caught at compile time, with messages that come from Tauri rather than from the language. Each one below is a [`compile_fail` doctest](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/compile_fail.rs).

An `async` command with a borrowed argument, such as `&str`, must return a `Result` ([tauri#2533](https://github.com/tauri-apps/tauri/issues/2533)):

```rust
#[tauri::command]
async fn count_voicings(symbol: &str) -> usize {
    symbol.len()
}
```

```text
error[E0277]: async commands that contain references as inputs must return a `Result`
 --> examples\e17_async_borrow.rs:2:42
  |
2 | async fn count_voicings(symbol: &str) -> usize {
  |                                          ^^^^^ the trait `AsyncCommandMustReturnResult` is not implemented for `usize`
  |
help: the trait `AsyncCommandMustReturnResult` is implemented for `Result<A, B>`
```

The same code also reports an `E0597` (`__tauri_message__` does not live long enough) pointing at the attribute: fix the first error, the second goes away. Taking `String` instead of `&str` is the other fix, and the one `count_voicings` uses.

A `pub` command at the **root** of the crate clashes with the macros that `#[tauri::command]` generates. The commands of the explorer are `pub` because they live in the `commands` and `state` modules, where it is allowed:

```rust
#[tauri::command]
pub fn spell_chord(symbol: String) -> String {
    symbol
}
```

```text
error[E0255]: the name `__cmd__spell_chord` is defined multiple times
 --> examples\e17_pub_root.rs:2:8
  |
1 | #[tauri::command]
  | ----------------- previous definition of the macro `__cmd__spell_chord` here
2 | pub fn spell_chord(symbol: String) -> String {
  |        -^^^^^^^^^^
  |        |
  |        `__cmd__spell_chord` reimported here
  |        help: remove unnecessary import
  |
  = note: `__cmd__spell_chord` must be defined only once in the macro namespace of this module
```

What the macro does **not** check: the command's name in JavaScript. `invoke("spell_chrod")` compiles, runs and rejects with `Command spell_chrod not found`. Lesson 19 looks at generating TypeScript types from the Rust signatures to close that gap.

## Testing commands without a window

`tauri::test` provides a mock runtime: no window, no webview, but the same IPC layer, so a test sees exactly the JSON the page would receive (from [`src-tauri/tests/ipc.rs`, lines 34-43](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/ipc.rs#L34-L43)):

```rust
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
```

The `invoke` helper builds an [`InvokeRequest`](https://docs.rs/tauri/2.11.5/tauri/webview/struct.InvokeRequest.html) and passes it to [`get_ipc_response`](https://docs.rs/tauri/2.11.5/tauri/test/fn.get_ipc_response.html) ([`tests/common/mod.rs`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/common/mod.rs)). The module is marked unstable in Tauri's documentation. Lesson 21 goes further, with WebDriver tests of the real window.

:::caution[On Windows, the tests first failed to start]
The first `cargo test` compiled, then stopped before running a single test:

```text
error: test failed, to rerun pass `-p chord-explorer --test ipc`

Caused by:
  process didn't exit successfully: `…\target\debug\deps\ipc-0265b791147e99f3.exe --nocapture --test-threads 1` (exit code: 0xc0000139, STATUS_ENTRYPOINT_NOT_FOUND)
```

`tauri-build` embeds a Windows application manifest, which requests version 6 of the Common Controls, in the application's **binaries** only; test executables load the older version, which lacks a function Tauri needs. The issue, [tauri#13419](https://github.com/tauri-apps/tauri/issues/13419), has been open since May 2025. The explorer's [`build.rs`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/build.rs) embeds the same manifest in the test executables with `cargo:rustc-link-arg-tests`: a variant of the workaround a Tauri maintainer posted in the issue, which replaces tauri-build's manifest for every target.
:::

## Key takeaways

- A command is a Rust function marked `#[tauri::command]`, registered in one `generate_handler!`, and called from the page with `invoke(name, args)`, which returns a promise.
- Arguments are JSON objects with camelCase keys, deserialized with serde; results are serialized with serde as they are, so rename their fields yourself.
- Return `Result<T, E>` with a serializable `E` that carries a `kind`; handle both your error objects and Tauri's error strings in JavaScript.
- Synchronous commands run on the main thread and block the native window and every other command; use `async` commands, and `spawn_blocking` for CPU-bound work.
- The macro turns some mistakes into compile errors with unusual messages; command names are only checked at run time.

## Exercises

1. Add a command `scale_notes` that takes a tonic note and a mode and returns the notes of the scale as strings: `F` major gives `["F", "G", "A", "Bb", "C", "D", "E"]`. What does the page receive for the tonic `H`?

<details>
<summary>Solution</summary>

From [`src-tauri/tests/l17_solutions.rs`, lines 12-19](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/l17_solutions.rs#L12-L19):

```rust
#[tauri::command]
fn scale_notes(tonic_note: &str, mode: ScaleMode) -> Result<Vec<String>, CommandError> {
    let tonic: Note = tonic_note.parse()?;
    Ok(theory::scale_notes(tonic, mode.into())
        .iter()
        .map(Note::to_string)
        .collect())
}
```

```js
const notes = await invoke("scale_notes", { tonicNote: "F", mode: "major" });
```

The `From<ScaleMode> for Mode` implementation in `commands.rs` provides `mode.into()`. For `H`, the promise rejects with the `CommandError`:

```text
scale_notes H -> {"kind":"invalidNote","message":"`H` is not a note (expected A to G, then # or b)"}
```

In the application, the command would also be added to `generate_handler!`; the solution's test registers it on its own mock app.

</details>

2. Predict what each call rejects with, then check against the outputs above: `invoke("transpose_chord", { symbol: "C" })`, `invoke("transpose_chord", { symbol: "C", semitones: 1.5 })`, `invoke("spell_chord", { symbol: 42 })`.

<details>
<summary>Solution</summary>

All three are refused by Tauri before the function runs, so each rejection is a string:

```text
transpose_chord -> "invalid args `semitones` for command `transpose_chord`: command transpose_chord missing required key semitones"
transpose_chord -> "invalid args `semitones` for command `transpose_chord`: invalid type: floating point `1.5`, expected i32"
spell_chord -> "invalid args `symbol` for command `spell_chord`: invalid type: integer `42`, expected a borrowed string"
```

`semitones` is missing in the first call. JavaScript has only one number type, but serde checks that `1.5` fits an `i32`. For `42`, the message says *expected a borrowed string* because the parameter is `&str`; `count_voicings`, which takes a `String`, says `expected a string`.

</details>

3. What would change if `count_voicings` ran the search directly in the `async` function, without `spawn_blocking`? On which thread would it run?

<details>
<summary>Solution</summary>

It would run on one of the async runtime's worker threads, as this test shows (from [`src-tauri/tests/l17_solutions.rs`, lines 43-49](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/l17_solutions.rs#L43-L49)):

```rust
#[tauri::command]
async fn search_thread() -> String {
    std::thread::current()
        .name()
        .unwrap_or("unnamed")
        .to_string()
}
```

```text
an async command runs on "tokio-rt-worker"
```

The window would stay responsive, because it is not the main thread. But an `async` function that computes for a second without reaching an `.await` holds its worker for that whole second (lesson 13): with a few searches at once, every other `async` command, and every channel message, waits for a free worker. `spawn_blocking` moves the computation to a separate pool made for blocking work, and leaves the workers to the tasks that wait.

</details>

## Sources

- [Tauri 2 — Calling Rust from the frontend](https://v2.tauri.app/develop/calling-rust/)
- [docs.rs — `tauri::command`](https://docs.rs/tauri/2.11.5/tauri/attr.command.html), [`generate_handler!`](https://docs.rs/tauri/2.11.5/tauri/macro.generate_handler.html) and [`tauri::test`](https://docs.rs/tauri/2.11.5/tauri/test/index.html)
- [Tauri JavaScript API — `core.invoke`](https://v2.tauri.app/reference/javascript/api/namespacecore/#invoke)
- [serde — Attributes](https://serde.rs/attributes.html)
- [Electron — Inter-Process Communication](https://www.electronjs.org/docs/latest/tutorial/ipc)
- [tauri#13419 — `STATUS_ENTRYPOINT_NOT_FOUND` when running `cargo test` on Windows](https://github.com/tauri-apps/tauri/issues/13419)
