---
title: 18. Tauri state, events and channels
description: Data that outlives a command with manage and State, messages from Rust to the page with events, and streams of results with channels — a cancellable search in the chord explorer, compared with DI singletons, messengers, IProgress and Electron's webContents.send.
sidebar:
  order: 18
---

Full example: [`l16-tauri/src-tauri/src/state.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs) and [`ui/main.js`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/ui/main.js).

Lesson 17's commands were functions of their arguments. A real application also needs data that lives between two calls, and messages that Rust sends without being asked: a list that changed, a search that progresses.

## What you already know

| Need | Tauri | .NET | Java | Electron |
|---|---|---|---|---|
| One shared object for the app | [`Builder::manage`](https://docs.rs/tauri/2.11.5/tauri/struct.Builder.html#method.manage) + [`State<T>`](https://docs.rs/tauri/2.11.5/tauri/struct.State.html) | a singleton in [dependency injection](https://learn.microsoft.com/dotnet/core/extensions/dependency-injection) | a Spring singleton bean | a variable in the main process |
| Tell every window something happened | [`Emitter::emit`](https://docs.rs/tauri/2.11.5/tauri/trait.Emitter.html#method.emit) + [`listen`](https://v2.tauri.app/reference/javascript/api/namespaceevent/#listen) | [`WeakReferenceMessenger`](https://learn.microsoft.com/dotnet/communitytoolkit/mvvm/messenger) | [`ApplicationEventPublisher`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/context/ApplicationEventPublisher.html) | [`webContents.send`](https://www.electronjs.org/docs/latest/api/web-contents#contentssendchannel-args) |
| Stream results of one call | [`ipc::Channel<T>`](https://docs.rs/tauri/2.11.5/tauri/ipc/struct.Channel.html) | [`IProgress<T>`](https://learn.microsoft.com/dotnet/api/system.iprogress-1), [`IAsyncEnumerable<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.iasyncenumerable-1) | [`Flow.Publisher`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Flow.Publisher.html), Reactor's `Flux` | a [`MessagePort`](https://www.electronjs.org/docs/latest/tutorial/message-ports) |

## Managed state

The explorer keeps the favourite chords in memory. The state is an ordinary type (from [`src-tauri/src/state.rs`, lines 14-16](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs#L14-L16)):

```rust
/// The favourite chord symbols, shared by every window.
#[derive(Default)]
pub struct Favorites(Mutex<Vec<String>>);
```

It is registered once, when the application is built (lesson 17's `setup`):

```rust
builder
    .manage(state::Favorites::default())
    .manage(state::SearchControl::default())
```

and a command asks for it by adding a `State<'_, Favorites>` parameter, which Tauri fills in instead of reading it from the JSON (from [`src-tauri/src/state.rs`, lines 24-27](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs#L24-L27)):

```rust
#[tauri::command]
pub fn favorites(favorites: State<'_, Favorites>) -> Vec<String> {
    favorites.0.lock().unwrap().clone()
}
```

Four rules follow from how it works ([state management](https://v2.tauri.app/develop/state-management/)):

- **State is found by type**, like a service registered by its type in .NET. Two lists of strings need two types: `Favorites` and `RecentChords`, not two `Mutex<Vec<String>>`. Registering the same type twice stops the application at startup; the assertion in `Builder::manage`:

```rust
assert!(
  self.state.set(state),
  "state for type '{type_name}' is already being managed",
);
```

- **Commands run on several threads** (lesson 17), so the state must be `Send + Sync` and anything mutable goes behind a [`Mutex`](https://doc.rust-lang.org/std/sync/struct.Mutex.html), an [`RwLock`](https://doc.rust-lang.org/std/sync/struct.RwLock.html) or an atomic (lesson 12). There is no dispatcher to hide it, as there is none in an ASP.NET Core singleton. Tauri wraps the state in an `Arc` itself.
- **Forgetting `manage` is not a compile error.** The type is only looked up when the command is called, and the call is rejected (from the test `state_that_was_never_managed_rejects_the_call` in [`src-tauri/tests/ipc.rs`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/ipc.rs)):

```text
recent_chords -> "state not managed for field `recent` on command `recent_chords`. You must call `.manage()` before using this command"
```

  Tauri's guide, in its section on mismatched types, says that the wrong type gives a panic at run time. For a command, in Tauri 2.11.5, the promise rejects and the application keeps running; outside commands, `Manager::state` does panic, and `try_state` returns an `Option` instead.
- **Outside a command**, [`Manager::state`](https://docs.rs/tauri/2.11.5/tauri/trait.Manager.html#method.state) or [`try_state`](https://docs.rs/tauri/2.11.5/tauri/trait.Manager.html#method.try_state) reads it from the `App` or an `AppHandle`, for example in `setup` or in a thread.

### A `MutexGuard` across `.await`

In an `async` command, the rules of lesson 13 apply: a [`std::sync::MutexGuard`](https://doc.rust-lang.org/std/sync/struct.MutexGuard.html) is not `Send`, and Tauri needs the future to be `Send` to run it on its runtime ([`compile_fail` doctest](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/compile_fail.rs)):

```rust
use std::sync::Mutex;

async fn save(_list: &[String]) {}

#[tauri::command]
async fn add_favorite(
    favorites: tauri::State<'_, Mutex<Vec<String>>>,
    symbol: String,
) -> Result<(), String> {
    let mut list = favorites.lock().unwrap();
    list.push(symbol);
    save(&list).await;
    Ok(())
}
```

```text
error: future cannot be sent between threads safely
   --> examples\e18_guard_across_await.rs:5:1
    |
  5 | #[tauri::command]
    | ^^^^^^^^^^^^^^^^^ future returned by `add_favorite` is not `Send`
...
    = help: within `impl Future<Output = Result<(), std::string::String>>`, the trait `std::marker::Send` is not implemented for `std::sync::MutexGuard<'_, Vec<std::string::String>>`
note: future is not `Send` as this value is used across an await
   --> examples\e18_guard_across_await.rs:12:17
    |
 10 |     let mut list = favorites.lock().unwrap();
    |         -------- has type `std::sync::MutexGuard<'_, Vec<std::string::String>>` which is not `Send`
 11 |     list.push(symbol);
 12 |     save(&list).await;
    |                 ^^^^^ await occurs here, with `mut list` maybe used later
```

The usual fix is to copy what you need and release the lock before the `.await`, in a block. Tauri's guide, quoting tokio's, keeps the standard `Mutex` as the default and reserves [`tokio::sync::Mutex`](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html) for a guard that really must live across an `.await`.

And because `State<'_, T>` borrows, an `async` command that takes it must return a `Result`, the rule seen in lesson 17 for `&str`:

```rust
use std::sync::Mutex;

#[tauri::command]
async fn favorites(favorites: tauri::State<'_, Mutex<Vec<String>>>) -> Vec<String> {
    favorites.lock().unwrap().clone()
}
```

```text
error[E0277]: async commands that contain references as inputs must return a `Result`
 --> examples\e18_async_state.rs:4:72
  |
4 | async fn favorites(favorites: tauri::State<'_, Mutex<Vec<String>>>) -> Vec<String> {
  |                                                                        ^^^ the trait `AsyncCommandMustReturnResult` is not implemented for `Vec<std::string::String>`
```

## Events: Rust tells the page

When a favourite is added, every window that shows the list must update, including the ones that did not ask. The command emits an **event** after changing the state (from [`src-tauri/src/state.rs`, lines 29-49](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs#L29-L49)):

```rust
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
```

- An [`AppHandle`](https://docs.rs/tauri/2.11.5/tauri/struct.AppHandle.html) parameter, like `State`, is supplied by Tauri. It is generic over the runtime so that the mock tests can call the same command.
- `emit` sends to every webview; [`emit_to`](https://docs.rs/tauri/2.11.5/tauri/trait.Emitter.html#method.emit_to) targets one window by its label.
- The payload is a snapshot taken under the lock, then emitted once the lock is released: never hold a lock while calling out, the rule you know from `lock` in C# and `synchronized` in Java.
- `?` works on `emit` because `CommandError` implements `From<tauri::Error>` (lesson 17).

The page subscribes once, at startup, with [`listen`](https://v2.tauri.app/reference/javascript/api/namespaceevent/#listen) (from [`ui/main.js`, lines 168-170](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/ui/main.js#L168-L170)):

```js
// Every window receives favorites-changed, whichever window changed the list
await listen("favorites-changed", (event) => showFavorites(event.payload));
showFavorites(await invoke("favorites"));
```

and `toggleFavorite` ignores the command's result: the event updates the list, in this window and in the others. What the page received, captured in the window:

```text
toggle_favorite returned ["Am"]; listener got {"event":"favorites-changed","id":2,"payload":["Am"]}
```

Rust code can listen too, through the [`Listener`](https://docs.rs/tauri/2.11.5/tauri/trait.Listener.html) trait, which is how the mock test checks the event without a webview (from [`src-tauri/tests/ipc.rs`, lines 124-135](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/ipc.rs#L124-L135)):

```rust
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
```

```text
favorites-changed payload: ["Bb7"]
```

The payload must be `Serialize` **and** `Clone`, because it may go to several targets; passing a reference, `&snapshot`, satisfies `Clone` without copying the list. A payload type without `Clone`:

```rust
use tauri::{AppHandle, Emitter};

#[derive(serde::Serialize)]
struct Favorites {
    symbols: Vec<String>,
}

#[tauri::command]
fn announce(app: AppHandle) -> Result<(), String> {
    let payload = Favorites { symbols: vec!["Am".into()] };
    app.emit("favorites-changed", payload).map_err(|e| e.to_string())
}
```

```text
error[E0277]: the trait bound `Favorites: Clone` is not satisfied
   --> examples\e18_emit_not_clone.rs:11:35
    |
 11 |     app.emit("favorites-changed", payload).map_err(|e| e.to_string())
    |         ----                      ^^^^^^^ the trait `Clone` is not implemented for `Favorites`
    |         |
    |         required by a bound introduced by this call
    |
note: required by a bound in `emit`
   --> C:\Users\spare\.cargo\registry\src\index.crates.io-1949cf8c6b5b557f\tauri-2.11.5\src\lib.rs:946:26
    |
946 |   fn emit<S: Serialize + Clone>(&self, event: &str, payload: S) -> Result<()> {
    |                          ^^^^^ required by this bound in `Emitter::emit`
help: consider annotating `Favorites` with `#[derive(Clone)]`
```

Event names are strings, and nothing checks that the page listens to the name Rust emits: a typo is silent, as with a messenger keyed by string. The [Tauri guide](https://v2.tauri.app/develop/calling-frontend/) adds two limits: events are "not designed for low latency or high throughput situations", and their payloads are always JSON strings.

## Channels: a stream for one call

The explorer's voicing search tries 7.5 million fingerings and finds its results over a second. The page wants them as they come, with a progress bar and a *Cancel* button. An event would reach every window, and would need an identifier to tell two searches apart; a **channel** belongs to one call. The page creates it and passes it as an argument (from [`ui/main.js`, lines 99-128](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/ui/main.js#L99-L128)):

```js
const onEvent = new Channel();
onEvent.onmessage = (message) => {
  switch (message.event) {
    case "voicings":
      for (const frets of message.data.frets) {
        if (list.children.length < MAX_LISTED) {
          const item = document.createElement("li");
          item.textContent = frets;
          list.append(item);
        }
      }
      break;
    case "progress":
      $("progress").value = message.data.done / message.data.total;
      break;
    case "finished": {
      const { found, elapsedMs, cancelled } = message.data;
      const shown = Math.min(found, MAX_LISTED);
      status.textContent = `${found} voicings in ${elapsedMs} ms${cancelled ? " (cancelled)" : ""}, ${shown} shown`;
      break;
    }
  }
};

try {
  await invoke("find_voicings", {
    symbol: $("chord-input").value,
    maxSpan: Number($("span-select").value),
    onEvent,
  });
```

The command receives it as a [`Channel<SearchEvent>`](https://docs.rs/tauri/2.11.5/tauri/ipc/struct.Channel.html). The messages are one Rust enum, serialized with an [adjacent tag](https://serde.rs/enum-representations.html#adjacently-tagged) so that JavaScript can `switch` on `event` (from [`src-tauri/src/state.rs`, lines 51-72](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs#L51-L72)):

```rust
/// What `find_voicings` streams to the frontend, in order.
#[derive(Clone, Serialize)]
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
        elapsed_ms: u128,
        cancelled: bool,
    },
}
```

```rust
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
```

- The channel is a parameter like any other, and `Channel` is `Send`: it moves into the `spawn_blocking` closure, and the search sends from its blocking thread.
- `theory::find_voicings` knows nothing about Tauri: it takes a closure called after each batch (the fret positions of the low E string, 14 of them), the same shape as an `IProgress<T>` passed to a .NET method.
- The promise of `invoke` resolves when the command returns, after the last message.

The messages the page received for `Bbm7` with a span of 3 frets, in a debug build, with the time since the call (shortened: the messages between 379 ms and 1032 ms are removed):

```text
invoke resolved with 16 after 1114 ms, 17 messages
77 ms {"event":"voicings","data":{"frets":["x-1-3-1-2-1","x-1-3-1-2-4","x-1-3-3-2-4","x-x-8-10-9-9"]}}
78 ms {"event":"progress","data":{"done":1,"total":14}}
152 ms {"event":"progress","data":{"done":2,"total":14}}
227 ms {"event":"progress","data":{"done":3,"total":14}}
305 ms {"event":"progress","data":{"done":4,"total":14}}
379 ms {"event":"progress","data":{"done":5,"total":14}}
1032 ms {"event":"progress","data":{"done":13,"total":14}}
1113 ms {"event":"progress","data":{"done":14,"total":14}}
1114 ms {"event":"finished","data":{"found":16,"elapsedMs":1110,"cancelled":false}}
```

The messages arrive in order, about 75 ms apart, while the search runs: "designed to be fast and deliver ordered data", in the words of the [guide](https://v2.tauri.app/develop/calling-frontend/#channels).

### Cancelling

*Cancel* calls another command, which sets a flag in managed state (from [`src-tauri/src/state.rs`, lines 18-22](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs#L18-L22)):

```rust
/// Lets `cancel_search` stop the search started by `find_voicings`.
#[derive(Default)]
pub struct SearchControl {
    cancel: Arc<AtomicBool>,
}
```

```rust
#[tauri::command]
pub fn cancel_search(control: State<'_, SearchControl>) {
    control.cancel.store(true, Ordering::Relaxed);
}
```

The search checks the [`AtomicBool`](https://doc.rust-lang.org/std/sync/atomic/type.AtomicBool.html) between two batches: it is the `CancellationToken` of .NET, or Java's `Thread.interrupt` checked by hand, without either's support in the libraries. The `Arc` lets the blocking thread keep the flag, because a `State` cannot leave the command. A search for `C` with a span of 4, cancelled 300 ms after it started:

```text
cancelled search resolved with 19 after 381 ms
{"event":"progress","data":{"done":5,"total":14}}
{"event":"finished","data":{"found":19,"elapsedMs":378,"cancelled":true}}
```

The search stopped after its fifth batch, the one running when the flag was set, and returned the 19 voicings found so far. One flag for the whole application is enough for one search at a time; exercise 2 handles several.

## Event or channel?

| | Event | Channel |
|---|---|---|
| Recipients | every listener, in every window (or one target with `emit_to`) | the call that created it |
| Created by | Rust, at any time | the page, for one `invoke` |
| Identified by | a string name | the argument itself |
| Fits | "something changed": favourites, settings, a file saved | "here is the next part": progress, search results, a download |
| Guide's warning | not for low latency or high throughput | designed for ordered, fast streaming |

## Key takeaways

- `manage` registers one value per type; commands receive it with `State<'_, T>`. Mutable state needs a `Mutex`, an `RwLock` or atomics, because commands run on several threads.
- A forgotten `manage` is found at run time, when the command is called: the promise rejects with `state not managed`.
- Release locks before emitting or awaiting: a `std::sync::MutexGuard` across `.await` does not compile in a command.
- Events broadcast named JSON messages to every window; payloads must be `Serialize + Clone`, and names are not checked.
- A channel streams ordered messages to the one call that created it; move it into the worker thread, and cancel with a shared `AtomicBool`.

## Exercises

1. Remember the last five chords spelled, most recent first, without duplicates: after `C`, `Am`, `F`, `G`, `Am`, `Dm`, `E7` and an invalid `Hm`, a command `recent_chords` returns `["E7", "Dm", "Am", "G", "F"]`.

<details>
<summary>Solution</summary>

A new state type, so that it does not clash with `Favorites`, and a command that spells and remembers (from [`src-tauri/tests/l18_solutions.rs`, lines 17-39](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/l18_solutions.rs#L17-L39)):

```rust
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
```

A [`VecDeque`](https://doc.rust-lang.org/std/collections/struct.VecDeque.html) adds at the front cheaply. `Hm` never reaches the list, because `?` returns before the lock is taken. Registering it needs `.manage(RecentChords::default())`; the test checks the expected list through the mock runtime.

</details>

2. With one `SearchControl`, *Cancel* stops whichever search is running, and starting a second search resets the flag of the first. Change the state so that each search has its own flag and `cancel_search` takes the search's identifier.

<details>
<summary>Solution</summary>

A map from identifier to flag (from [`src-tauri/tests/l18_solutions.rs`, lines 58-86](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/l18_solutions.rs#L58-L86)):

```rust
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
```

`find_voicings` would call `start` before `spawn_blocking`, send the identifier as the channel's first message (a `Started { id }` variant) so that the page knows what to cancel, and call `finish` when the search ends, cancelled or not. The test starts two searches, cancels the second, checks that only its flag is set, and that cancelling a finished search returns `false`.

</details>

3. For each need, choose an event or a channel, and say why: a settings window changes the theme of every other window; a command copies a folder and reports each file copied; the backend notices that a file opened in the app changed on disk.

<details>
<summary>Solution</summary>

- **Theme**: an event. Every window must react, including the ones that did not start anything, and it is a single small message.
- **Folder copy**: a channel. The progress belongs to the call that started the copy, arrives in order and can be frequent; two copies at once would each have their own channel.
- **File changed on disk**: an event. Nobody called a command, so there is no channel to send on: Rust starts the conversation, from a file watcher thread holding an `AppHandle`.

</details>

## Sources

- [Tauri 2 — State management](https://v2.tauri.app/develop/state-management/)
- [Tauri 2 — Calling the frontend from Rust](https://v2.tauri.app/develop/calling-frontend/): events and channels
- [docs.rs — `Emitter`](https://docs.rs/tauri/2.11.5/tauri/trait.Emitter.html), [`Listener`](https://docs.rs/tauri/2.11.5/tauri/trait.Listener.html), [`ipc::Channel`](https://docs.rs/tauri/2.11.5/tauri/ipc/struct.Channel.html)
- [Tauri JavaScript API — `event`](https://v2.tauri.app/reference/javascript/api/namespaceevent/) and [`core.Channel`](https://v2.tauri.app/reference/javascript/api/namespacecore/#channelt)
- [serde — Enum representations](https://serde.rs/enum-representations.html)
- [tokio — Which kind of mutex should you use?](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html#which-kind-of-mutex-should-you-use)
