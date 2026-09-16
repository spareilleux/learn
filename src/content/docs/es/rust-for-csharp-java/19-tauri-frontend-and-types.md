---
title: 19. El frontend de Tauri, Vite y tipos generados desde Rust
description: Un frontend TypeScript empaquetado por Vite junto al JavaScript sin build de las lecciones 16 a 18, la recarga en caliente con tauri dev y tipos TypeScript generados desde los structs Rust con ts-rs — lo que comprueban, el u128 que se volvió bigint y lo que añade tauri-specta — comparados con los clientes OpenAPI generados para ASP.NET Core y Spring.
sidebar:
  order: 19
---

Ejemplo completo: [`l16-tauri/frontend/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/frontend), [`vite.config.ts`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/vite.config.ts) y [`src-tauri/tauri.vite.conf.json`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.vite.conf.json).

Las lecciones 16 a 18 usaban una página sin paso de build: `ui/main.js` lee `window.__TAURI__` y llama a `invoke("spell_chord", { symbol })`. Nada comprueba ese nombre, ese argumento ni la forma de lo que vuelve. La lección 17 mostró la consecuencia: `invoke("spell_chrod")` se ejecuta, y solo se rechaza cuando el usuario hace clic.

Esta lección deja el lado Rust sin cambios y da al mismo explorador un segundo frontend, en TypeScript, empaquetado por [Vite](https://vite.dev/), con tipos generados a partir de los structs Rust.

## Lo que ya conoces

| Necesidad | Tauri | ASP.NET Core | Spring | Electron |
|---|---|---|---|---|
| Herramientas del frontend | cualquier bundler; [Vite](https://v2.tauri.app/start/frontend/vite/) es la opción documentada por defecto | las [plantillas SPA](https://learn.microsoft.com/aspnet/core/client-side/spa/intro) (Vite para React y Vue) | un proyecto frontend aparte | [Electron Forge](https://www.electronforge.io/) con Vite o webpack |
| Servidor de desarrollo + recarga | `tauri dev` arranca Vite y luego la aplicación sobre `devUrl` | el proxy SPA | `npm run dev` + un proxy | `electron-forge start` |
| Tipos compartidos con el backend | [ts-rs](https://docs.rs/ts-rs/12.0.1/ts_rs/) o [tauri-specta](https://docs.rs/tauri-specta/2.0.0-rc.25/tauri_specta/) | [NSwag](https://learn.microsoft.com/aspnet/core/tutorials/getting-started-with-nswag) o un cliente generado desde [OpenAPI](https://learn.microsoft.com/aspnet/core/fundamentals/openapi/overview) | [OpenAPI Generator](https://openapi-generator.tech/) | importados directamente: los dos procesos están en TypeScript o JavaScript |

La diferencia con OpenAPI: no hay contrato HTTP en medio. El generador lee directamente los tipos Rust, al ejecutar `cargo test`.

## Dos frontends, un único núcleo Rust

El curso de React monta un proyecto Vite desde cero ([React (Vite), lección 1](../../react-vite/01-vite-project/)); aquí Vite solo tiene que ponerse de acuerdo con Tauri en tres cosas: la dirección del servidor de desarrollo, la carpeta de salida del build y los comandos que los producen.

El curso conserva `ui/` tal cual y añade `frontend/`. En lugar de editar `tauri.conf.json`, un segundo archivo sobrescribe su sección `build`; `tauri dev` y `tauri build` fusionan un archivo pasado con [`--config`](https://v2.tauri.app/reference/cli/#dev) sobre la configuración principal (de [`src-tauri/tauri.vite.conf.json`, líneas 1-11](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.vite.conf.json#L1-L11)):

```json
{
  "build": {
    "devUrl": "http://localhost:5173",
    "frontendDist": "../frontend/dist",
    "beforeDevCommand": "npm run web:dev",
    "beforeBuildCommand": "npm run web:build"
  },
  "app": {
    "withGlobalTauri": false
  }
}
```

- `devUrl`: durante `tauri dev`, la ventana carga el servidor de desarrollo de Vite en lugar de archivos;
- `frontendDist`: lo que `tauri build` incrusta en el binario, la salida de Vite;
- `beforeDevCommand` y `beforeBuildCommand`: la CLI de Tauri los ejecuta primero, así que un único comando lo arranca todo;
- `withGlobalTauri: false`: se acabó `window.__TAURI__`. El TypeScript importa [`@tauri-apps/api`](https://www.npmjs.com/package/@tauri-apps/api), y Vite empaqueta solo lo que usa.

Los scripts de `package.json` dan a cada frontend su comando: `npx tauri dev` sigue abriendo `ui/`, `npm run dev:vite` ejecuta `tauri dev --config src-tauri/tauri.vite.conf.json`.

El lado Vite sigue la [guía de Tauri](https://v2.tauri.app/start/frontend/vite/) (de [`vite.config.ts`, líneas 5-25](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/vite.config.ts#L5-L25)):

```ts
export default defineConfig({
  root: "frontend",
  // Mantener visible la salida de Cargo cuando tauri dev ejecuta Vite
  clearScreen: false,
  server: {
    // Debe coincidir con build.devUrl de src-tauri/tauri.vite.conf.json
    port: 5173,
    strictPort: true,
    watch: {
      // Los cambios en Rust los vigila la CLI de Tauri, no Vite
      ignored: ["**/src-tauri/**", "**/target/**"],
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
    // WebView2 es Chromium; WKWebView y WebKitGTK son WebKit (targets de la guía de Tauri)
    target: process.env.TAURI_ENV_PLATFORM === "windows" ? "chrome105" : "safari13",
    minify: !process.env.TAURI_ENV_DEBUG,
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
  },
```

`strictPort` importa: si el 5173 está ocupado, Vite elegiría en silencio el 5174 y la ventana no cargaría nada. La CLI de Tauri define las variables `TAURI_ENV_*` cuando ejecuta `beforeBuildCommand`, así que el bundle apunta al webview de la plataforma que se está compilando: el build de Windows puede usar funciones que WebView2 tiene y Safari 13 no.

El build ejecuta primero `tsc` y luego Vite. Aquí lo ejecutó `tauri build` en Windows, así que `TAURI_ENV_PLATFORM` valía `windows`:

```text
> chord-explorer@0.1.0 web:build
> tsc && vite build

vite v8.3.0 building client environment for production...
transforming...
✓ 12 modules transformed.
rendering chunks...
computing gzip size...
frontend/dist/index.html                 2.41 kB │ gzip: 0.81 kB
frontend/dist/assets/index-Ctb_ps3-.css  1.34 kB │ gzip: 0.66 kB
frontend/dist/assets/index-MdGAJN8k.js   7.61 kB │ gzip: 3.10 kB

✓ built in 182ms
```

7,61 kB de JavaScript para toda la página, API de Tauri incluida: eso es lo que se incrusta en el binario. En el runner Ubuntu de la CI, el mismo build apuntó a `safari13` y dio `index-CXi5Pk96.js   7.67 kB │ gzip: 3.13 kB`: otro target, otro bundle.

## `tauri dev` y la recarga en caliente

`npm run dev:vite` arranca Vite, lo espera, y luego compila y ejecuta la aplicación:

```text
     Running BeforeDevCommand (`npm run web:dev`)

> chord-explorer@0.1.0 web:dev
> vite

  VITE v8.3.0  ready in 202 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
     Running DevCommand (`cargo  run --no-default-features --color always --`)
        Info Watching C:\Users\spare\source\repos\learn\code\rust-for-csharp-java\l16-tauri\src-tauri for changes...
        Info Watching C:\Users\spare\source\repos\learn\code\rust-for-csharp-java\l16-tauri\theory for changes...
```

Dos vigilantes de archivos funcionan en paralelo, y lo que pasa con un cambio depende de cuál lo detecta. Medido con la ventana abierta, un acorde escrito en el campo de texto y un favorito añadido:

| Archivo editado | Vigilante | Qué pasó | Se conservó |
|---|---|---|---|
| `frontend/src/styles.css` | Vite | `[vite] (client) hmr update /src/styles.css`: el nuevo estilo se aplicó sin recarga | el estado de la página (el acorde escrito) y el estado Rust |
| `frontend/src/main.ts` | Vite | `[vite] (client) page reload src/main.ts`: la página se recargó | solo el estado Rust: los favoritos seguían ahí, el campo de texto había vuelto a su valor por defecto |
| `src-tauri/capabilities/export.json` | CLI de Tauri | `File src-tauri\capabilities\export.json changed. Rebuilding application...`, una compilación (9,73 s) y un reinicio | nada en memoria |

La segunda fila es la que hay que recordar. Un módulo sin handler HMR, como `main.ts`, recarga la página; frameworks como React añaden handlers que conservan el estado de los componentes ([React (Vite), lección 1](../../react-vite/01-vite-project/#hot-module-replacement-and-fast-refresh)). El proceso Rust no se reinicia, así que su estado gestionado sobrevive: una aplicación Tauri conserva de forma natural en el lado Rust los datos que importan.

## Tipos generados desde Rust

[ts-rs](https://github.com/Aleph-Alpha/ts-rs) (12.0.1, MIT) añade un derive `TS`. Junto a `Serialize`, describe el mismo struct en TypeScript (de [`src-tauri/src/commands.rs`, líneas 9-13](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L9-L13)):

```rust
/// Un acorde tal como lo recibe el frontend: cadenas listas para mostrar.
#[derive(Debug, Serialize, TS)]
#[serde(rename_all = "camelCase")]
#[ts(export)]
pub struct ChordView {
```

`#[ts(export)]` genera un test, `export_bindings_chordview`, que escribe el archivo cuando se ejecuta `cargo test`. La carpeta viene de una variable de entorno que Cargo define para todo el workspace (de [`.cargo/config.toml`, líneas 1-3](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/.cargo/config.toml#L1-L3)):

```toml
# ts-rs escribe aquí las declaraciones TypeScript cuando `cargo test` ejecuta sus tests de exportación
[env]
TS_RS_EXPORT_DIR = { value = "frontend/src/bindings", relative = true }
```

```text
test commands::export_bindings_chordview ... ok
test commands::export_bindings_qualityview ... ok
test commands::export_bindings_commanderror ... ok
test state::export_bindings_searchevent ... ok
test commands::export_bindings_scalemode ... ok
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.04s
```

El resultado tiene en cuenta los atributos de serde, `rename_all` incluido (de [`frontend/src/bindings/ChordView.ts`, líneas 1-6](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/bindings/ChordView.ts#L1-L6)):

```ts
// This file was generated by [ts-rs](https://github.com/Aleph-Alpha/ts-rs). Do not edit this file manually.

/**
 * Un acorde tal como lo recibe el frontend: cadenas listas para mostrar.
 */
export type ChordView = { symbol: string, qualityName: string, notes: Array<string>, intervals: Array<string>, };
```

El comentario de documentación se convirtió en JSDoc, así que el editor lo muestra al pasar el ratón. El `SearchEvent` de la lección 18, un enum con `tag` y `content`, se convierte en una unión discriminada (de [`frontend/src/bindings/SearchEvent.ts`, línea 6](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/bindings/SearchEvent.ts#L6)):

```ts
export type SearchEvent = { "event": "voicings", "data": { frets: Array<string>, } } | { "event": "progress", "data": { done: number, total: number, } } | { "event": "finished", "data": { found: number, elapsedMs: number, cancelled: boolean, } };
```

y un `switch` sobre `event` estrecha `data` en cada rama, como un `switch` sobre una jerarquía sellada en C# o Java (de [`frontend/src/main.ts`, líneas 120-132](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts#L120-L132)):

```ts
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
          progress.value = message.data.done / message.data.total;
          break;
```

Los archivos generados se incluyen en el repositorio. Así el frontend se compila sin Rust, y la CI ejecuta `cargo test` y falla si `git status` muestra un binding modificado: un cambio en Rust que olvida regenerarlos no se puede fusionar.

### Lo que detectan los tipos

Un archivo con tres errores:

```ts
import * as api from "./api";
import type { SearchEvent } from "./bindings/SearchEvent";

const chord = await api.spellChord("Am7");
console.log(chord.quality);

await api.diatonicChords("C", "dorian");

export function count(message: SearchEvent) {
  return message.event === "progress" ? message.data.frets.length : 0;
}
```

```text
frontend/src/mistakes.ts(5,19): error TS2339: Property 'quality' does not exist on type 'ChordView'.
frontend/src/mistakes.ts(7,31): error TS2345: Argument of type '"dorian"' is not assignable to parameter of type 'ScaleMode'.
frontend/src/mistakes.ts(10,54): error TS2339: Property 'frets' does not exist on type '{ done: number; total: number; }'.
```

El segundo error viene de un enum Rust: `ScaleMode` tiene dos variantes, así que su tipo TypeScript es `"major" | "minor"`.

### El `u128` que se volvió `bigint`

El primer `SearchEvent` generado no decía `elapsedMs: number`, decía `elapsedMs: bigint`. En Rust el campo es un `u128`, que viene de [`Duration::as_millis`](https://doc.rust-lang.org/std/time/struct.Duration.html#method.as_millis), y ts-rs convierte por defecto `i64`, `u64`, `i128` y `u128` en `bigint`. Un cálculo con él deja entonces de compilar:

```ts
import type { SearchEvent } from "./bindings/SearchEvent";

export function seconds(message: SearchEvent) {
  if (message.event === "finished") {
    return message.data.elapsedMs / 1000;
  }
  return 0;
}
```

```text
frontend/src/pitfall.ts(5,12): error TS2365: Operator '/' cannot be applied to types 'bigint' and 'number'.
```

El que estaba mal era el tipo, no el código: [serde_json](https://docs.rs/serde_json/) escribe un `u128` como un número JSON normal, y `JSON.parse` da un `number`, nunca un `bigint`. El tipo generado describía un valor que nunca llega. Dos soluciones: `TS_RS_LARGE_INT = "number"` en la sección `[env]` para todos los enteros grandes, o una sustitución en el campo, la que usa el curso (de [`src-tauri/src/state.rs`, líneas 76-82](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs#L76-L82)):

```rust
    Finished {
        found: usize,
        // ts-rs convierte u128 en `bigint`, pero serde_json escribe un número JSON normal
        #[ts(type = "number")]
        elapsed_ms: u128,
        cancelled: bool,
    },
```

Un `number` es exacto hasta 2<sup>53</sup> − 1, más que suficiente para milisegundos. Para identificadores o importes que puedan superarlo, serialízalos como cadenas en el lado Rust y dales el tipo `string`.

La lección se generaliza: un generador traduce tipos, no el comportamiento del serializador. Cuando un tipo generado y un atributo de serde no coinciden, fíate del JSON y revisa el tipo.

## Lo que ts-rs no comprueba

ts-rs describe valores, no comandos. El nombre `"spell_chord"` y el nombre del argumento `symbol` siguen siendo cadenas. El curso los reúne en un único módulo, una función tipada por comando, para que una errata solo pueda estar en un sitio (de [`frontend/src/api.ts`, líneas 11-19](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/api.ts#L11-L19)):

```ts
export const chordQualities = () => invoke<QualityView[]>("chord_qualities");

export const spellChord = (symbol: string) => invoke<ChordView>("spell_chord", { symbol });

export const transposeChord = (symbol: string, semitones: number) =>
  invoke<ChordView>("transpose_chord", { symbol, semitones });

export const diatonicChords = (tonicNote: string, mode: ScaleMode) =>
  invoke<ChordView[]>("diatonic_chords", { tonicNote, mode });
```

`invoke<ChordView>` es un cast: TypeScript se fía de él. Si `spell_chord` devolviera otra cosa, o cambiara de nombre, `tsc` seguiría pasando. Los tests end-to-end de la lección 21 son los que lo detectan.

[tauri-specta](https://github.com/specta-rs/tauri-specta) cierra el hueco: un atributo `#[specta::specta]` junto a `#[tauri::command]`, y genera las propias funciones de los comandos, con sus nombres y los tipos de sus argumentos, además de eventos tipados. Su situación a 2026-09-16:

| | ts-rs | tauri-specta |
|---|---|---|
| Versión | 12.0.1, estable (2026-01-31) | 2.0.0-rc.25 (2026-05-08); release candidates desde la 2.0.0-rc.1 en octubre de 2023 |
| Tauri | independiente de Tauri | la v2 necesita specta 2, también release candidate; la 1.x estable solo admite Tauri v1 |
| Genera | tipos | tipos, funciones envoltorio para los comandos, eventos |
| Cuándo | `cargo test` | cuando el código Rust llama a su exportador, por ejemplo al arrancar en los builds debug (*por verificar*) |
| Estrellas en GitHub | 1878 | 797 |

El curso usa ts-rs porque es estable y no toca el registro de los comandos. tauri-specta es la comprobación más fuerte, y no se ha probado en este proyecto (*por verificar*): una release candidate que dura casi tres años es una decisión que hay que tomar a sabiendas, no una opción por defecto.

## Puntos clave

- Un segundo frontend no requiere ningún cambio en el lado Rust: `--config` fusiona un archivo sobre `tauri.conf.json`, aquí `devUrl`, `frontendDist` y los dos `before*Command`.
- `tauri dev` ejecuta dos vigilantes: Vite recarga o actualiza en caliente la página, y la CLI de Tauri recompila y reinicia la aplicación. Una recarga de la página conserva el estado Rust.
- ts-rs deriva tipos TypeScript de los structs Rust, atributos de serde incluidos; inclúyelos en el repositorio y deja que la CI compruebe que están al día.
- Un tipo generado puede estar mal: el `bigint` que ts-rs usa por defecto para los enteros de 64 y 128 bits no corresponde a lo que envía serde_json.
- Los tipos no comprueban los nombres de los comandos ni de los argumentos: mantén las llamadas a `invoke` en un único módulo, o usa tauri-specta y acepta una release candidate.

## Ejercicios

1. `QualityView` tiene dos campos, `suffix` y `name`. Añade `interval_count: u64` en el lado Rust, ejecuta `cargo test` y predice el tipo TypeScript de `intervalCount` antes de abrir el archivo. Después conviértelo en `number` sin poner un atributo en el campo.

<details>
<summary>Solución</summary>

ts-rs escribe `interval_count: bigint`. Dos sorpresas en una línea: `u64` es uno de los enteros grandes que por defecto pasan a `bigint`, y el nombre conserva su guion bajo, porque `QualityView` no tiene `#[serde(rename_all = "camelCase")]` y ts-rs sigue a serde.

Sin tocar el campo, cambia el valor por defecto para todo el workspace en `.cargo/config.toml`:

```toml
[env]
TS_RS_EXPORT_DIR = { value = "frontend/src/bindings", relative = true }
TS_RS_LARGE_INT = "number"
```

Entonces `cargo test` escribe `interval_count: number`. El tipo es fiel solo mientras el valor quede por debajo de 2<sup>53</sup>, y un número de intervalos lo cumple.

</details>

2. Un compañero renombra el comando Rust `spell_chord` a `spell` y actualiza `generate_handler!`. ¿Cuáles de estos fallan: `cargo test`, `tsc`, los tests Vitest con `mockIPC`, la aplicación al hacer clic en *Spell*?

<details>
<summary>Solución</summary>

- `cargo test`: falla solo si un test Rust llama a `spell_chord` por su nombre, como los tests IPC del curso en `src-tauri/tests/`; si no, pasa.
- `tsc`: pasa. `invoke<ChordView>("spell_chord", …)` es una cadena y un cast.
- Vitest con `mockIPC`: pasa, porque el mock responde a cualquier nombre que reciba (lección 21).
- La aplicación: se rechaza con `Command spell_chord not found`.

Solo un test que ejecute la aplicación real, o las funciones envoltorio generadas por tauri-specta, detectaría el cambio de nombre antes que un usuario.

</details>

3. ¿Por qué el curso incluye `frontend/src/bindings/` en el repositorio en lugar de ignorarlo y generarlo antes de cada build?

<details>
<summary>Solución</summary>

- Así el frontend se puede compilar, comprobar con el sistema de tipos y probar sin toolchain de Rust: `npm run web:build` solo necesita Node.
- Una pull request muestra el cambio TypeScript junto al cambio Rust, así que quien revisa ve lo que recibirá el frontend.
- El coste es mantenerlos sincronizados, y la CI lo impone: después de `cargo test`, un archivo modificado en `frontend/src/bindings` hace fallar el job.

</details>

## Fuentes

- [Tauri 2 — Vite](https://v2.tauri.app/start/frontend/vite/) y [Frontend configuration](https://v2.tauri.app/start/frontend/)
- [Tauri 2 — CLI reference, `dev` y `build`](https://v2.tauri.app/reference/cli/): la opción `--config`
- [API JavaScript de Tauri — `core`](https://v2.tauri.app/reference/javascript/api/namespacecore/)
- [Vite — Configuring Vite](https://vite.dev/config/) y [HMR API](https://vite.dev/guide/api-hmr)
- [Documentación de ts-rs 12.0.1](https://docs.rs/ts-rs/12.0.1/ts_rs/): `TS_RS_EXPORT_DIR`, `TS_RS_LARGE_INT`, `#[ts(type = "…")]`
- [tauri-specta](https://github.com/specta-rs/tauri-specta) y su [documentación 2.0.0-rc.25](https://docs.rs/tauri-specta/2.0.0-rc.25/tauri_specta/)
- [MDN — `Number.MAX_SAFE_INTEGER`](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER)
