---
title: 17. Comandos de Tauri, llamar a Rust desde la interfaz
description: "#[tauri::command] e invoke — argumentos y valores de retorno a través de serde, errores que el frontend puede leer, lo que Tauri comprueba al compilar y en ejecución, y el hilo en el que se ejecuta un comando — comparado con los comandos de WPF, los controladores y el IPC de Electron."
sidebar:
  order: 17
---

Ejemplo completo: [`l16-tauri/src-tauri/src/commands.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs) y [`ui/main.js`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/ui/main.js); los tests de [`src-tauri/tests/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/src-tauri/tests) llaman a cada comando a través de la capa IPC de Tauri (`cargo test -p chord-explorer`).

## Lo que ya conoces

Un **comando** es una función Rust que la página llama por su nombre, con argumentos JSON, y cuyo resultado vuelve como una promesa JavaScript. Se parece más a una API web que a un comando de WPF:

| | Tauri | WPF | ASP.NET Core / Spring | Electron |
|---|---|---|---|---|
| Se declara con | [`#[tauri::command]`](https://docs.rs/tauri/2.11.5/tauri/attr.command.html) | [`ICommand`](https://learn.microsoft.com/dotnet/api/system.windows.input.icommand) en el view model | una acción de controlador, [`@RestController`](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller.html) | [`ipcMain.handle`](https://www.electronjs.org/docs/latest/api/ipc-main#ipcmainhandlechannel-listener) |
| Se registra con | [`generate_handler!`](https://docs.rs/tauri/2.11.5/tauri/macro.generate_handler.html) | un binding XAML | el enrutamiento | el nombre del canal |
| Se llama con | [`invoke`](https://v2.tauri.app/reference/javascript/api/namespacecore/#invoke) | un clic en un botón enlazado | `fetch` | `ipcRenderer.invoke` detrás de [`contextBridge`](https://www.electronjs.org/docs/latest/api/context-bridge) |
| Formato de datos | JSON a través de [serde](https://serde.rs/) | objetos .NET, mismo proceso | JSON | [clonado estructurado](https://developer.mozilla.org/docs/Web/API/Web_Workers_API/Structured_clone_algorithm) |
| Errores | una promesa rechazada con tu error serializado | excepciones | código de estado + [`ProblemDetails`](https://learn.microsoft.com/aspnet/core/web-api/handle-errors) | una promesa rechazada con un `Error` nuevo |

La página y el código Rust viven en procesos distintos (lección 16), así que no hay objeto compartido ni referencia: cada argumento se deserializa al llegar y cada resultado se serializa al salir.

## Un primer comando

De [`src-tauri/src/commands.rs`, líneas 95-99](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L95-L99):

```rust
#[tauri::command]
pub fn spell_chord(symbol: &str) -> Result<ChordView, CommandError> {
    let chord: Chord = symbol.parse()?;
    Ok(chord.into())
}
```

El atributo genera el pegamento: leer `symbol` del JSON de la petición, llamar a la función, serializar el `Result`. La función en sí sigue siendo una función Rust normal que puedes llamar y probar directamente.

Cada comando se registra una sola vez, en un único `generate_handler!` (llamar dos veces a `invoke_handler` conserva solo la última lista). La aplicación del curso lo hace en una función `setup` que reutilizan los tests (de [`src-tauri/src/lib.rs`, líneas 17-33](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L17-L33)):

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

`setup` es genérica sobre el [`Runtime`](https://docs.rs/tauri/2.11.5/tauri/trait.Runtime.html): la aplicación pasa el real (`tauri::Builder::default()`, WebView2 y compañía), los tests pasan [`tauri::test::mock_builder()`](https://docs.rs/tauri/2.11.5/tauri/test/fn.mock_builder.html).

La página llama al comando por su nombre. Con `withGlobalTauri` (lección 16), `invoke` está en `window.__TAURI__.core` (de [`ui/main.js`, líneas 16-25](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/ui/main.js#L16-L25)):

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

Con qué se resuelve la promesa, capturado en la ventana en ejecución mediante el protocolo de herramientas de desarrollo de WebView2:

```text
spell_chord {"symbol":"Bbm7"} resolved: {"symbol":"Bbm7","qualityName":"minor seventh","notes":["Bb","Db","F","Ab"],"intervals":["1","b3","5","b7"]}
```

## Argumentos

Los argumentos llegan como un único objeto JSON cuyas claves son los nombres de los parámetros **en camelCase**: `tonic_note` en Rust es `tonicNote` en JavaScript ([llamar a Rust](https://v2.tauri.app/develop/calling-rust/#passing-arguments)). El tipo de cada parámetro implementa [`Deserialize`](https://docs.rs/serde/latest/serde/trait.Deserialize.html), así que un enum funciona igual que una cadena o un número (de [`src-tauri/src/commands.rs`, líneas 67-73](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L67-L73)):

```rust
/// `"major"` o `"minor"` en JSON.
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

Cuando el JSON no encaja, el comando nunca se ejecuta: Tauri rechaza la llamada con un mensaje que nombra el comando y el argumento. Los rechazos reales, desde la ventana:

```text
diatonic_chords {"tonic_note":"C","mode":"major"} rejected (string): "invalid args `tonicNote` for command `diatonic_chords`: command diatonic_chords missing required key tonicNote"
diatonic_chords {"tonicNote":"C","mode":"dorian"} rejected (string): "invalid args `mode` for command `diatonic_chords`: unknown variant `dorian`, expected `major` or `minor`"
transpose_chord {"symbol":"C","semitones":"2"} rejected (string): "invalid args `semitones` for command `transpose_chord`: invalid type: string \"2\", expected i32"
play_chord {"symbol":"C"} rejected (string): "Command play_chord not found"
```

El primero es el error clásico: claves en snake_case en JavaScript. Un comando síncrono puede recibir `&str`, prestado de la petición, sin copiar. En JavaScript todos los números son doubles, pero serde comprueba el tipo Rust: `1.5` para un `i32` también falla (``invalid type: floating point `1.5`, expected i32``).

## Valores de retorno

El tipo de retorno debe implementar [`Serialize`](https://docs.rs/serde/latest/serde/trait.Serialize.html). Los comandos del curso devuelven pequeños structs hechos para la página en lugar de los tipos de `theory`, como un controlador devuelve DTO en lugar de entidades de dominio (de [`src-tauri/src/commands.rs`, líneas 8-27](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L8-L27)):

```rust
/// Un acorde tal como lo recibe el frontend: cadenas listas para mostrar.
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

Tauri renombra los argumentos a camelCase, pero serde serializa los valores de retorno tal cual: sin `#[serde(rename_all = "camelCase")]`, la página recibiría `quality_name`.

Olvidar `Serialize` es un error de compilación, pero no uno legible ([doctest `compile_fail`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/compile_fail.rs)):

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

El mensaje nunca dice `Serialize`. El trait que falta, [`IpcResponse`](https://docs.rs/tauri/2.11.5/tauri/ipc/trait.IpcResponse.html), está implementado para todo `T: Serialize`: cuando un error menciona `IpcResponse` o `blocking_kind`, revisa el `derive` del tipo de retorno.

## Errores

Un comando que devuelve `Result<T, E>` resuelve la promesa con `T` o la rechaza con `E`, y `E` también debe ser serializable. `String` funciona, pero pierde el tipo de error. Los comandos del curso usan un único tipo de error con un `kind` legible por máquina, en el espíritu de `ProblemDetails` (de [`src-tauri/src/commands.rs`, líneas 36-56](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L36-L56)):

```rust
/// El error que un comando fallido envía al frontend, donde la promesa se rechaza con
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

Las implementaciones de `From` son las que hacen funcionar `?` en los comandos (lección 6): `symbol.parse()?` convierte un `TheoryError` en un `CommandError`. En la ventana:

```text
spell_chord {"symbol":"Cm9"} rejected (object): {"kind":"unknownQuality","message":"unknown chord quality `m9` in `Cm9`"}
spell_chord {"symbol":""} rejected (object): {"kind":"empty","message":"empty chord symbol"}
instanceof Error: false, kind: unknownQuality
```

Dos consecuencias para el lado JavaScript:

- El valor del rechazo es el propio error serializado, **no** un `Error` de JavaScript: sin traza de pila, y `error.message` existe solo porque `CommandError` tiene un campo `message`.
- Cuando Tauri rechaza la llamada antes de que se ejecute tu función (comando desconocido, argumentos inválidos), el rechazo es una **cadena**. La primera versión del explorador mostraba `undefined: undefined` en esos casos; ahora la página pasa por una única función auxiliar (de [`ui/main.js`, líneas 10-14](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/ui/main.js#L10-L14)):

```js
// Un invoke rechazado da nuestro CommandError, { kind, message }, o una simple cadena
// cuando es Tauri quien rechaza la llamada (comando desconocido, argumentos inválidos)
function describe(error) {
  return typeof error === "string" ? error : `${error.kind}: ${error.message}`;
}
```

Un panic dentro de un comando no es un valor de error: es un bug. Reserva `unwrap` para los invariantes, como en la lección 6, y devuelve `Err` para todo lo que el usuario pueda provocar.

## Dónde se ejecuta un comando

Esta es la parte que un desarrollador WPF no debe adivinar. Según la [guía de Tauri](https://v2.tauri.app/develop/calling-rust/#async-commands): los comandos sin `async` se ejecutan en el **hilo principal**, salvo que se declaren con `#[tauri::command(async)]`; los comandos `async` se ejecutan en el runtime asíncrono de Tauri, un runtime tokio (lección 13).

El explorador tiene la misma búsqueda de las dos formas (de [`src-tauri/src/commands.rs`, líneas 129-149](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L129-L149)):

```rust
/// Un comando síncrono: Tauri lo ejecuta en el hilo principal.
#[tauri::command]
pub fn count_voicings_blocking(symbol: &str) -> Result<usize, CommandError> {
    log_thread("count_voicings_blocking");
    let chord: Chord = symbol.parse()?;
    Ok(count(&chord))
}

/// Un comando async: Tauri lo ejecuta en su runtime asíncrono, y la búsqueda,
/// intensiva en CPU, va al pool de hilos bloqueantes.
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

La terminal que ejecuta `tauri dev` imprime:

```text
count_voicings_blocking runs on thread "main"
count_voicings runs on thread "tokio-rt-worker"
count_voicings (search) runs on thread "tokio-rt-worker"
```

La búsqueda prueba 7,5 millones de digitaciones y tarda más o menos un segundo en una compilación debug. Medido en la ventana, dos veces cada una, con un segundo comando enviado 100 ms después del primero y un temporizador JavaScript de 10 ms corriendo mientras tanto:

```text
count_voicings_blocking: 27 voicings in 1058 ms; chord_qualities sent 100 ms later answered after 958 ms; longest gap between 10 ms JavaScript timer ticks: 12 ms
count_voicings: 27 voicings in 1078 ms; chord_qualities sent 100 ms later answered after 2 ms; longest gap between 10 ms JavaScript timer ticks: 12 ms
```

Y un bucle de PowerShell que envía [`WM_NULL`](https://learn.microsoft.com/windows/win32/winmsg/wm-null) a la ventana con [`SendMessageTimeout`](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-sendmessagetimeoutw) durante cada llamada:

```text
blocking call: 1062 ms
window 'Chord Explorer': 64 WM_NULL probes, slowest answer 945 ms
async call: 1095 ms
window 'Chord Explorer': 95 WM_NULL probes, slowest answer 4 ms
```

Lo que se congela no es lo que espera un desarrollador WPF:

- La **página** sigue funcionando: su temporizador JavaScript no perdió ni un tic, porque el webview es otro proceso.
- La **ventana nativa** no responde a sus mensajes durante casi un segundo: no se puede mover, redimensionar ni cerrar. Windows marca una ventana como *No responde* tras cinco segundos así ([`IsHungAppWindow`](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-ishungappwindow)).
- Todos los **demás comandos** esperan: `chord_qualities` necesitó 958 ms en lugar de 2, porque el hilo principal atiende las peticiones IPC.

La regla es la misma que con el [`Dispatcher`](https://learn.microsoft.com/dotnet/api/system.windows.threading.dispatcher) de WPF o el hilo de aplicación de JavaFX: nada lento en el hilo principal. En Tauri, eso significa `async` para todo lo que espera o calcula, y [`spawn_blocking`](https://docs.rs/tauri/2.11.5/tauri/async_runtime/fn.spawn_blocking.html) para el trabajo intensivo de CPU, para que tampoco ocupe uno de los workers del runtime (ejercicio 3).

## Lo que comprueba la macro

Como `#[tauri::command]` genera código, algunos errores se detectan al compilar, con mensajes que vienen de Tauri y no del lenguaje. Cada uno de los siguientes es un [doctest `compile_fail`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/src/compile_fail.rs).

Un comando `async` con un argumento prestado, como `&str`, debe devolver un `Result` ([tauri#2533](https://github.com/tauri-apps/tauri/issues/2533)):

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

El mismo código también informa de un `E0597` (`__tauri_message__` no vive lo suficiente) que apunta al atributo: corrige el primer error y el segundo desaparece. Recibir `String` en lugar de `&str` es la otra solución, y la que usa `count_voicings`.

Un comando `pub` en la **raíz** del crate choca con las macros que genera `#[tauri::command]`. Los comandos del explorador son `pub` porque viven en los módulos `commands` y `state`, donde está permitido:

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

Lo que la macro **no** comprueba: el nombre del comando en JavaScript. `invoke("spell_chrod")` compila, se ejecuta y se rechaza con `Command spell_chrod not found`. La lección 19 estudia cómo generar tipos TypeScript a partir de las firmas Rust para cerrar ese hueco.

## Probar comandos sin ventana

`tauri::test` proporciona un runtime simulado: sin ventana ni webview, pero con la misma capa IPC, así que un test ve exactamente el JSON que recibiría la página (de [`src-tauri/tests/ipc.rs`, líneas 34-43](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/ipc.rs#L34-L43)):

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

La función auxiliar `invoke` construye un [`InvokeRequest`](https://docs.rs/tauri/2.11.5/tauri/webview/struct.InvokeRequest.html) y lo pasa a [`get_ipc_response`](https://docs.rs/tauri/2.11.5/tauri/test/fn.get_ipc_response.html) ([`tests/common/mod.rs`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/common/mod.rs)). La documentación de Tauri marca el módulo como inestable. La lección 21 va más allá, con tests WebDriver de la ventana real.

La petición también lleva la URL de la página, y es contra ella que las capabilities comprueban la llamada (lección 20). Windows y Android sirven los archivos incrustados por `http://tauri.localhost`, y los demás sistemas por `tauri://localhost`; con la equivocada, cada llamada se rechaza con ``spell_chord not allowed. Plugin not found``. La primera versión de esta lección fijaba el origen de Windows, y la CI lo encontró en los runners de macOS y Linux.

:::caution[En Windows, los tests al principio no arrancaban]
El primer `cargo test` compiló y luego se detuvo antes de ejecutar un solo test:

```text
error: test failed, to rerun pass `-p chord-explorer --test ipc`

Caused by:
  process didn't exit successfully: `…\target\debug\deps\ipc-0265b791147e99f3.exe --nocapture --test-threads 1` (exit code: 0xc0000139, STATUS_ENTRYPOINT_NOT_FOUND)
```

`tauri-build` integra un manifiesto de aplicación de Windows, que pide la versión 6 de los Common Controls, solo en los **binarios** de la aplicación; los ejecutables de test cargan la versión antigua, a la que le falta una función que Tauri necesita. La incidencia, [tauri#13419](https://github.com/tauri-apps/tauri/issues/13419), está abierta desde mayo de 2025. El [`build.rs`](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/build.rs) del explorador integra el mismo manifiesto en los ejecutables de test con `cargo:rustc-link-arg-tests`: una variante de la solución que un mantenedor de Tauri publicó en la incidencia, la cual sustituye el manifiesto de tauri-build para todos los targets.
:::

## Puntos clave

- Un comando es una función Rust marcada con `#[tauri::command]`, registrada en un único `generate_handler!` y llamada desde la página con `invoke(name, args)`, que devuelve una promesa.
- Los argumentos son objetos JSON con claves en camelCase, deserializados con serde; los resultados se serializan con serde tal cual, así que renombra tú sus campos.
- Devuelve `Result<T, E>` con un `E` serializable que lleve un `kind`; en JavaScript, trata tanto tus objetos de error como las cadenas de error de Tauri.
- Los comandos síncronos se ejecutan en el hilo principal y bloquean la ventana nativa y todos los demás comandos; usa comandos `async`, y `spawn_blocking` para el trabajo intensivo de CPU.
- La macro convierte algunos errores en errores de compilación con mensajes inusuales; los nombres de los comandos solo se comprueban en ejecución.

## Ejercicios

1. Añade un comando `scale_notes` que reciba una tónica y un modo y devuelva las notas de la escala como cadenas: `F` mayor da `["F", "G", "A", "Bb", "C", "D", "E"]`. ¿Qué recibe la página con la tónica `H`?

<details>
<summary>Solución</summary>

De [`src-tauri/tests/l17_solutions.rs`, líneas 12-19](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/l17_solutions.rs#L12-L19):

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

La implementación `From<ScaleMode> for Mode` de `commands.rs` proporciona `mode.into()`. Para `H`, la promesa se rechaza con el `CommandError`:

```text
scale_notes H -> {"kind":"invalidNote","message":"`H` is not a note (expected A to G, then # or b)"}
```

En la aplicación, el comando también se añadiría a `generate_handler!`; el test de la solución lo registra en su propia aplicación simulada.

</details>

2. Predice con qué se rechaza cada llamada y luego compáralo con las salidas de arriba: `invoke("transpose_chord", { symbol: "C" })`, `invoke("transpose_chord", { symbol: "C", semitones: 1.5 })`, `invoke("spell_chord", { symbol: 42 })`.

<details>
<summary>Solución</summary>

Tauri rechaza las tres antes de que se ejecute la función, así que cada rechazo es una cadena:

```text
transpose_chord -> "invalid args `semitones` for command `transpose_chord`: command transpose_chord missing required key semitones"
transpose_chord -> "invalid args `semitones` for command `transpose_chord`: invalid type: floating point `1.5`, expected i32"
spell_chord -> "invalid args `symbol` for command `spell_chord`: invalid type: integer `42`, expected a borrowed string"
```

En la primera llamada falta `semitones`. JavaScript solo tiene un tipo numérico, pero serde comprueba que `1.5` quepa en un `i32`. Para `42`, el mensaje dice *expected a borrowed string* porque el parámetro es `&str`; `count_voicings`, que recibe un `String`, dice `expected a string`.

</details>

3. ¿Qué cambiaría si `count_voicings` ejecutara la búsqueda directamente en la función `async`, sin `spawn_blocking`? ¿En qué hilo se ejecutaría?

<details>
<summary>Solución</summary>

Se ejecutaría en uno de los hilos worker del runtime asíncrono, como muestra este test (de [`src-tauri/tests/l17_solutions.rs`, líneas 43-49](https://github.com/spareilleux/learn/blob/373237a/code/rust-for-csharp-java/l16-tauri/src-tauri/tests/l17_solutions.rs#L43-L49)):

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

La ventana seguiría respondiendo, porque no es el hilo principal. Pero una función `async` que calcula durante un segundo sin llegar a un `.await` retiene su worker todo ese segundo (lección 13): con unas cuantas búsquedas a la vez, todos los demás comandos `async`, y todos los mensajes de canal, esperan un worker libre. `spawn_blocking` lleva el cálculo a un pool aparte pensado para el trabajo bloqueante, y deja los workers a las tareas que esperan.

</details>

## Fuentes

- [Tauri 2 — Calling Rust from the frontend](https://v2.tauri.app/develop/calling-rust/)
- [docs.rs — `tauri::command`](https://docs.rs/tauri/2.11.5/tauri/attr.command.html), [`generate_handler!`](https://docs.rs/tauri/2.11.5/tauri/macro.generate_handler.html) y [`tauri::test`](https://docs.rs/tauri/2.11.5/tauri/test/index.html)
- [API JavaScript de Tauri — `core.invoke`](https://v2.tauri.app/reference/javascript/api/namespacecore/#invoke)
- [serde — Attributes](https://serde.rs/attributes.html)
- [Electron — Inter-Process Communication](https://www.electronjs.org/docs/latest/tutorial/ipc)
- [tauri#13419 — `STATUS_ENTRYPOINT_NOT_FOUND` al ejecutar `cargo test` en Windows](https://github.com/tauri-apps/tauri/issues/13419)
