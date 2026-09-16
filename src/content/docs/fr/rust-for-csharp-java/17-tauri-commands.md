---
title: 17. Commandes Tauri, appeler Rust depuis l'interface
description: "#[tauri::command] et invoke — arguments et valeurs de retour via serde, des erreurs que le frontend sait lire, ce que Tauri vérifie à la compilation et à l'exécution, et le thread sur lequel tourne une commande — comparés aux commandes WPF, aux contrôleurs et à l'IPC d'Electron."
sidebar:
  order: 17
---

Exemple complet : [`l16-tauri/src-tauri/src/commands.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs) et [`ui/main.js`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/ui/main.js) ; les tests de [`src-tauri/tests/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/src-tauri/tests) appellent chaque commande à travers la couche IPC de Tauri (`cargo test -p chord-explorer`).

## Ce que vous connaissez déjà

Une **commande** est une fonction Rust que la page appelle par son nom, avec des arguments JSON, et dont le résultat revient sous forme de promesse JavaScript. Elle est plus proche d'une API web que d'une commande WPF :

| | Tauri | WPF | ASP.NET Core / Spring | Electron |
|---|---|---|---|---|
| Déclarée avec | [`#[tauri::command]`](https://docs.rs/tauri/2.11.5/tauri/attr.command.html) | [`ICommand`](https://learn.microsoft.com/dotnet/api/system.windows.input.icommand) sur le view model | une action de contrôleur, [`@RestController`](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller.html) | [`ipcMain.handle`](https://www.electronjs.org/docs/latest/api/ipc-main#ipcmainhandlechannel-listener) |
| Enregistrée avec | [`generate_handler!`](https://docs.rs/tauri/2.11.5/tauri/macro.generate_handler.html) | un binding XAML | le routage | le nom du canal |
| Appelée avec | [`invoke`](https://v2.tauri.app/reference/javascript/api/namespacecore/#invoke) | un clic sur un bouton lié | `fetch` | `ipcRenderer.invoke` derrière [`contextBridge`](https://www.electronjs.org/docs/latest/api/context-bridge) |
| Format des données | JSON via [serde](https://serde.rs/) | objets .NET, même processus | JSON | [clonage structuré](https://developer.mozilla.org/docs/Web/API/Web_Workers_API/Structured_clone_algorithm) |
| Erreurs | une promesse rejetée qui porte votre erreur sérialisée | exceptions | code de statut + [`ProblemDetails`](https://learn.microsoft.com/aspnet/core/web-api/handle-errors) | une promesse rejetée avec une nouvelle `Error` |

La page et le code Rust vivent dans des processus différents (leçon 16) : il n'y a ni objet partagé ni référence, chaque argument est désérialisé à l'arrivée et chaque résultat sérialisé au départ.

## Une première commande

Extrait de [`src-tauri/src/commands.rs`, lignes 95-99](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L95-L99) :

```rust
#[tauri::command]
pub fn spell_chord(symbol: &str) -> Result<ChordView, CommandError> {
    let chord: Chord = symbol.parse()?;
    Ok(chord.into())
}
```

L'attribut génère la plomberie : lire `symbol` dans le JSON de la requête, appeler la fonction, sérialiser le `Result`. La fonction elle-même reste une fonction Rust ordinaire, que vous pouvez appeler et tester directement.

Chaque commande est enregistrée une fois, dans un seul `generate_handler!` (appeler `invoke_handler` deux fois ne garde que la dernière liste). L'application du cours le fait dans une fonction `setup` que les tests réutilisent (extrait de [`src-tauri/src/lib.rs`, lignes 17-33](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L17-L33)) :

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

`setup` est générique sur le [`Runtime`](https://docs.rs/tauri/2.11.5/tauri/trait.Runtime.html) : l'application passe le vrai (`tauri::Builder::default()`, WebView2 et compagnie), les tests passent [`tauri::test::mock_builder()`](https://docs.rs/tauri/2.11.5/tauri/test/fn.mock_builder.html).

La page appelle la commande par son nom. Avec `withGlobalTauri` (leçon 16), `invoke` se trouve sur `window.__TAURI__.core` (extrait de [`ui/main.js`, lignes 16-25](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/ui/main.js#L16-L25)) :

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

Ce que la promesse renvoie, capturé dans la fenêtre en cours d'exécution grâce au protocole des outils de développement de WebView2 :

```text
spell_chord {"symbol":"Bbm7"} resolved: {"symbol":"Bbm7","qualityName":"minor seventh","notes":["Bb","Db","F","Ab"],"intervals":["1","b3","5","b7"]}
```

## Arguments

Les arguments arrivent dans un seul objet JSON dont les clés sont les noms des paramètres **en camelCase** : `tonic_note` en Rust devient `tonicNote` en JavaScript ([appeler Rust](https://v2.tauri.app/develop/calling-rust/#passing-arguments)). Le type de chaque paramètre implémente [`Deserialize`](https://docs.rs/serde/latest/serde/trait.Deserialize.html), donc un enum fonctionne aussi bien qu'une chaîne ou un nombre (extrait de [`src-tauri/src/commands.rs`, lignes 67-73](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L67-L73)) :

```rust
/// `"major"` ou `"minor"` en JSON.
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

Quand le JSON ne correspond pas, la commande ne s'exécute jamais : Tauri rejette l'appel avec un message qui nomme la commande et l'argument. Les vrais rejets, relevés dans la fenêtre :

```text
diatonic_chords {"tonic_note":"C","mode":"major"} rejected (string): "invalid args `tonicNote` for command `diatonic_chords`: command diatonic_chords missing required key tonicNote"
diatonic_chords {"tonicNote":"C","mode":"dorian"} rejected (string): "invalid args `mode` for command `diatonic_chords`: unknown variant `dorian`, expected `major` or `minor`"
transpose_chord {"symbol":"C","semitones":"2"} rejected (string): "invalid args `semitones` for command `transpose_chord`: invalid type: string \"2\", expected i32"
play_chord {"symbol":"C"} rejected (string): "Command play_chord not found"
```

Le premier est l'erreur classique : des clés en snake_case côté JavaScript. Une commande synchrone peut prendre un `&str`, emprunté à la requête, sans copie. En JavaScript, tous les nombres sont des doubles, mais serde vérifie le type Rust : `1.5` pour un `i32` échoue aussi (``invalid type: floating point `1.5`, expected i32``).

## Valeurs de retour

Le type de retour doit implémenter [`Serialize`](https://docs.rs/serde/latest/serde/trait.Serialize.html). Les commandes du cours renvoient de petites structs faites pour la page plutôt que les types de `theory`, comme un contrôleur renvoie des DTO plutôt que des entités du domaine (extrait de [`src-tauri/src/commands.rs`, lignes 8-27](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L8-L27)) :

```rust
/// Un accord tel que le reçoit le frontend : des chaînes prêtes à afficher.
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

Tauri renomme les arguments en camelCase, mais serde sérialise les valeurs de retour telles quelles : sans `#[serde(rename_all = "camelCase")]`, la page recevrait `quality_name`.

Oublier `Serialize` est une erreur de compilation, mais pas une erreur lisible ([doctest `compile_fail`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/compile_fail.rs)) :

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

Le message ne dit jamais `Serialize`. Le trait manquant, [`IpcResponse`](https://docs.rs/tauri/2.11.5/tauri/ipc/trait.IpcResponse.html), est implémenté pour tout `T: Serialize` : quand une erreur mentionne `IpcResponse` ou `blocking_kind`, vérifiez le `derive` du type de retour.

## Erreurs

Une commande qui renvoie `Result<T, E>` résout la promesse avec `T` ou la rejette avec `E`, et `E` doit lui aussi être sérialisable. `String` fonctionne, mais perd la nature de l'erreur. Les commandes du cours utilisent un seul type d'erreur avec un `kind` lisible par la machine, dans l'esprit de `ProblemDetails` (extrait de [`src-tauri/src/commands.rs`, lignes 36-56](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L36-L56)) :

```rust
/// L'erreur qu'une commande en échec envoie au frontend, où la promesse se rejette avec
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

Ce sont les implémentations de `From` qui font fonctionner `?` dans les commandes (leçon 6) : `symbol.parse()?` transforme une `TheoryError` en `CommandError`. Dans la fenêtre :

```text
spell_chord {"symbol":"Cm9"} rejected (object): {"kind":"unknownQuality","message":"unknown chord quality `m9` in `Cm9`"}
spell_chord {"symbol":""} rejected (object): {"kind":"empty","message":"empty chord symbol"}
instanceof Error: false, kind: unknownQuality
```

Deux conséquences côté JavaScript :

- La valeur de rejet est l'erreur sérialisée elle-même, **pas** une `Error` JavaScript : pas de pile d'appels, et `error.message` n'existe que parce que `CommandError` a un champ `message`.
- Quand Tauri refuse l'appel avant que votre fonction s'exécute (commande inconnue, arguments invalides), le rejet est une **chaîne**. La première version de l'explorateur affichait `undefined: undefined` dans ces cas ; la page passe désormais par un seul utilitaire (extrait de [`ui/main.js`, lignes 10-14](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/ui/main.js#L10-L14)) :

```js
// Un invoke rejeté donne notre CommandError, { kind, message }, ou une simple chaîne
// quand Tauri refuse lui-même l'appel (commande inconnue, arguments invalides)
function describe(error) {
  return typeof error === "string" ? error : `${error.kind}: ${error.message}`;
}
```

Une panique dans une commande n'est pas une valeur d'erreur : c'est un bug. Gardez `unwrap` pour les invariants, comme à la leçon 6, et renvoyez `Err` pour tout ce que l'utilisateur peut provoquer.

## Où s'exécute une commande

C'est le point qu'un développeur WPF ne doit pas deviner. D'après le [guide Tauri](https://v2.tauri.app/develop/calling-rust/#async-commands) : les commandes sans `async` s'exécutent sur le **thread principal**, sauf si elles sont déclarées avec `#[tauri::command(async)]` ; les commandes `async` s'exécutent sur le runtime asynchrone de Tauri, un runtime tokio (leçon 13).

L'explorateur propose la même recherche des deux façons (extrait de [`src-tauri/src/commands.rs`, lignes 129-149](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L129-L149)) :

```rust
/// Une commande synchrone : Tauri l'exécute sur le thread principal.
#[tauri::command]
pub fn count_voicings_blocking(symbol: &str) -> Result<usize, CommandError> {
    log_thread("count_voicings_blocking");
    let chord: Chord = symbol.parse()?;
    Ok(count(&chord))
}

/// Une commande async : Tauri l'exécute sur son runtime asynchrone, et la recherche,
/// gourmande en CPU, part dans le pool de threads bloquants.
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

Le terminal qui exécute `tauri dev` affiche :

```text
count_voicings_blocking runs on thread "main"
count_voicings runs on thread "tokio-rt-worker"
count_voicings (search) runs on thread "tokio-rt-worker"
```

La recherche essaie 7,5 millions de doigtés et prend environ une seconde dans un build debug. Mesuré dans la fenêtre, deux fois chacune, avec une deuxième commande envoyée 100 ms après la première et un timer JavaScript de 10 ms qui tourne pendant ce temps :

```text
count_voicings_blocking: 27 voicings in 1058 ms; chord_qualities sent 100 ms later answered after 958 ms; longest gap between 10 ms JavaScript timer ticks: 12 ms
count_voicings: 27 voicings in 1078 ms; chord_qualities sent 100 ms later answered after 2 ms; longest gap between 10 ms JavaScript timer ticks: 12 ms
```

Et une boucle PowerShell qui envoie [`WM_NULL`](https://learn.microsoft.com/windows/win32/winmsg/wm-null) à la fenêtre avec [`SendMessageTimeout`](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-sendmessagetimeoutw) pendant chaque appel :

```text
blocking call: 1062 ms
window 'Chord Explorer': 64 WM_NULL probes, slowest answer 945 ms
async call: 1095 ms
window 'Chord Explorer': 95 WM_NULL probes, slowest answer 4 ms
```

Ce qui gèle n'est pas ce qu'attend un développeur WPF :

- La **page** continue de tourner : son timer JavaScript n'a jamais manqué un tick, parce que la webview est un autre processus.
- La **fenêtre native** ne répond plus à ses messages pendant presque une seconde : impossible de la déplacer, de la redimensionner ou de la fermer. Windows marque une fenêtre *Ne répond pas* au bout de cinq secondes de ce régime ([`IsHungAppWindow`](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-ishungappwindow)).
- Toutes les **autres commandes** attendent : `chord_qualities` a mis 958 ms au lieu de 2, parce que le thread principal traite les requêtes IPC.

La règle est la même que pour le [`Dispatcher`](https://learn.microsoft.com/dotnet/api/system.windows.threading.dispatcher) de WPF ou le thread d'application de JavaFX : rien de lent sur le thread principal. Avec Tauri, cela veut dire `async` pour tout ce qui attend ou calcule, et [`spawn_blocking`](https://docs.rs/tauri/2.11.5/tauri/async_runtime/fn.spawn_blocking.html) pour le travail CPU, afin qu'il n'occupe pas non plus un des workers du runtime (exercice 3).

## Ce que la macro vérifie

Comme `#[tauri::command]` génère du code, certaines erreurs sont détectées à la compilation, avec des messages qui viennent de Tauri plutôt que du langage. Chacune ci-dessous est un [doctest `compile_fail`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/compile_fail.rs).

Une commande `async` avec un argument emprunté, comme `&str`, doit renvoyer un `Result` ([tauri#2533](https://github.com/tauri-apps/tauri/issues/2533)) :

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

Le même code signale aussi une `E0597` (`__tauri_message__` does not live long enough) qui pointe sur l'attribut : corrigez la première erreur, la seconde disparaît. Prendre `String` au lieu de `&str` est l'autre correction, celle qu'utilise `count_voicings`.

Une commande `pub` à la **racine** de la crate entre en conflit avec les macros que génère `#[tauri::command]`. Les commandes de l'explorateur sont `pub` parce qu'elles vivent dans les modules `commands` et `state`, où c'est permis :

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

Ce que la macro ne vérifie **pas** : le nom de la commande en JavaScript. `invoke("spell_chrod")` compile, s'exécute et se rejette avec `Command spell_chrod not found`. La leçon 19 génère des types TypeScript à partir des signatures Rust pour combler ce manque.

## Tester les commandes sans fenêtre

`tauri::test` fournit un runtime simulé : pas de fenêtre, pas de webview, mais la même couche IPC, donc un test voit exactement le JSON que recevrait la page (extrait de [`src-tauri/tests/ipc.rs`, lignes 34-43](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/ipc.rs#L34-L43)) :

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

L'utilitaire `invoke` construit une [`InvokeRequest`](https://docs.rs/tauri/2.11.5/tauri/webview/struct.InvokeRequest.html) et la passe à [`get_ipc_response`](https://docs.rs/tauri/2.11.5/tauri/test/fn.get_ipc_response.html) ([`tests/common/mod.rs`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/common/mod.rs)). La documentation de Tauri marque ce module comme instable. La leçon 21 va plus loin, avec des tests WebDriver de la vraie fenêtre.

La requête porte aussi l'URL de la page, et c'est elle que les capabilities vérifient (leçon 20). Windows et Android servent les fichiers embarqués via `http://tauri.localhost`, les autres systèmes via `tauri://localhost` ; avec la mauvaise, chaque appel est refusé par ``spell_chord not allowed. Plugin not found``. La première version de cette leçon codait en dur l'origine de Windows, et la CI l'a trouvé sur les runners macOS et Linux.

:::caution[Sous Windows, les tests ont d'abord refusé de démarrer]
Le premier `cargo test` a compilé, puis s'est arrêté avant d'exécuter le moindre test :

```text
error: test failed, to rerun pass `-p chord-explorer --test ipc`

Caused by:
  process didn't exit successfully: `…\target\debug\deps\ipc-0265b791147e99f3.exe --nocapture --test-threads 1` (exit code: 0xc0000139, STATUS_ENTRYPOINT_NOT_FOUND)
```

`tauri-build` embarque un manifeste d'application Windows, qui demande la version 6 des Common Controls, dans les **binaires** de l'application seulement ; les exécutables de test chargent l'ancienne version, à laquelle il manque une fonction dont Tauri a besoin. Le ticket, [tauri#13419](https://github.com/tauri-apps/tauri/issues/13419), est ouvert depuis mai 2025. Le [`build.rs`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/build.rs) de l'explorateur embarque le même manifeste dans les exécutables de test avec `cargo:rustc-link-arg-tests` : une variante du contournement qu'un mainteneur de Tauri a publié dans le ticket, qui remplace le manifeste de tauri-build pour toutes les cibles.
:::

## À retenir

- Une commande est une fonction Rust marquée `#[tauri::command]`, enregistrée dans un seul `generate_handler!` et appelée depuis la page avec `invoke(name, args)`, qui renvoie une promesse.
- Les arguments sont des objets JSON à clés camelCase, désérialisés par serde ; les résultats sont sérialisés par serde tels quels, renommez donc vous-même leurs champs.
- Renvoyez `Result<T, E>` avec un `E` sérialisable qui porte un `kind` ; gérez en JavaScript à la fois vos objets d'erreur et les chaînes d'erreur de Tauri.
- Les commandes synchrones s'exécutent sur le thread principal et bloquent la fenêtre native et toutes les autres commandes ; utilisez des commandes `async`, et `spawn_blocking` pour le travail CPU.
- La macro transforme certaines erreurs en erreurs de compilation aux messages inhabituels ; les noms de commandes ne sont vérifiés qu'à l'exécution.

## Exercices

1. Ajoutez une commande `scale_notes` qui prend une tonique et un mode et renvoie les notes de la gamme sous forme de chaînes : `F` majeur donne `["F", "G", "A", "Bb", "C", "D", "E"]`. Que reçoit la page pour la tonique `H` ?

<details>
<summary>Solution</summary>

Extrait de [`src-tauri/tests/l17_solutions.rs`, lignes 12-19](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/l17_solutions.rs#L12-L19) :

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

L'implémentation `From<ScaleMode> for Mode` de `commands.rs` fournit `mode.into()`. Pour `H`, la promesse se rejette avec la `CommandError` :

```text
scale_notes H -> {"kind":"invalidNote","message":"`H` is not a note (expected A to G, then # or b)"}
```

Dans l'application, la commande serait aussi ajoutée à `generate_handler!` ; le test de la solution l'enregistre sur sa propre application simulée.

</details>

2. Prédisez avec quoi chaque appel se rejette, puis vérifiez avec les sorties ci-dessus : `invoke("transpose_chord", { symbol: "C" })`, `invoke("transpose_chord", { symbol: "C", semitones: 1.5 })`, `invoke("spell_chord", { symbol: 42 })`.

<details>
<summary>Solution</summary>

Tauri refuse les trois avant que la fonction s'exécute, donc chaque rejet est une chaîne :

```text
transpose_chord -> "invalid args `semitones` for command `transpose_chord`: command transpose_chord missing required key semitones"
transpose_chord -> "invalid args `semitones` for command `transpose_chord`: invalid type: floating point `1.5`, expected i32"
spell_chord -> "invalid args `symbol` for command `spell_chord`: invalid type: integer `42`, expected a borrowed string"
```

`semitones` manque dans le premier appel. JavaScript n'a qu'un type de nombre, mais serde vérifie que `1.5` tient dans un `i32`. Pour `42`, le message dit *expected a borrowed string* parce que le paramètre est un `&str` ; `count_voicings`, qui prend un `String`, dit `expected a string`.

</details>

3. Que changerait-il si `count_voicings` faisait la recherche directement dans la fonction `async`, sans `spawn_blocking` ? Sur quel thread s'exécuterait-elle ?

<details>
<summary>Solution</summary>

Elle s'exécuterait sur un des threads workers du runtime asynchrone, comme le montre ce test (extrait de [`src-tauri/tests/l17_solutions.rs`, lignes 43-49](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/l17_solutions.rs#L43-L49)) :

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

La fenêtre resterait réactive, puisque ce n'est pas le thread principal. Mais une fonction `async` qui calcule pendant une seconde sans atteindre de `.await` monopolise son worker pendant toute cette seconde (leçon 13) : avec quelques recherches simultanées, toutes les autres commandes `async`, et chaque message de canal, attendent un worker libre. `spawn_blocking` déplace le calcul vers un pool séparé prévu pour le travail bloquant, et laisse les workers aux tâches qui attendent.

</details>

## Sources

- [Tauri 2 — Appeler Rust depuis le frontend](https://v2.tauri.app/develop/calling-rust/)
- [docs.rs — `tauri::command`](https://docs.rs/tauri/2.11.5/tauri/attr.command.html), [`generate_handler!`](https://docs.rs/tauri/2.11.5/tauri/macro.generate_handler.html) et [`tauri::test`](https://docs.rs/tauri/2.11.5/tauri/test/index.html)
- [API JavaScript de Tauri — `core.invoke`](https://v2.tauri.app/reference/javascript/api/namespacecore/#invoke)
- [serde — Attributs](https://serde.rs/attributes.html)
- [Electron — Communication inter-processus](https://www.electronjs.org/docs/latest/tutorial/ipc)
- [tauri#13419 — `STATUS_ENTRYPOINT_NOT_FOUND` à l'exécution de `cargo test` sous Windows](https://github.com/tauri-apps/tauri/issues/13419)
