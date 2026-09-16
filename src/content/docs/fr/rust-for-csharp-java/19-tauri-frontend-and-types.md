---
title: 19. Le frontend Tauri, Vite et des types générés depuis Rust
description: Un frontend TypeScript empaqueté par Vite à côté du JavaScript sans build des leçons 16 à 18, le rechargement à chaud sous tauri dev, et des types TypeScript générés depuis les structs Rust avec ts-rs — ce qu'ils vérifient, le u128 devenu bigint, et ce qu'apporte tauri-specta — comparés aux clients OpenAPI générés pour ASP.NET Core et Spring.
sidebar:
  order: 19
---

Exemple complet : [`l16-tauri/frontend/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/frontend), [`vite.config.ts`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/vite.config.ts) et [`src-tauri/tauri.vite.conf.json`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.vite.conf.json).

Les leçons 16 à 18 utilisaient une page sans étape de build : `ui/main.js` lit `window.__TAURI__` et appelle `invoke("spell_chord", { symbol })`. Rien ne vérifie ce nom, cet argument, ni la forme de ce qui revient. La leçon 17 en a montré la conséquence : `invoke("spell_chrod")` s'exécute, et ne se rejette que lorsque l'utilisateur clique.

Cette leçon garde le côté Rust inchangé et donne au même explorateur un second frontend, en TypeScript, empaqueté par [Vite](https://vite.dev/), avec des types générés depuis les structs Rust.

## Ce que vous connaissez déjà

| Besoin | Tauri | ASP.NET Core | Spring | Electron |
|---|---|---|---|---|
| Chaîne d'outils du frontend | n'importe quel bundler ; [Vite](https://v2.tauri.app/start/frontend/vite/) est le choix documenté par défaut | les [modèles SPA](https://learn.microsoft.com/aspnet/core/client-side/spa/intro) (Vite pour React et Vue) | un projet frontend séparé | [Electron Forge](https://www.electronforge.io/) avec Vite ou webpack |
| Serveur de dev + rechargement | `tauri dev` démarre Vite, puis l'application sur `devUrl` | le proxy SPA | `npm run dev` + un proxy | `electron-forge start` |
| Types partagés avec le backend | [ts-rs](https://docs.rs/ts-rs/12.0.1/ts_rs/) ou [tauri-specta](https://docs.rs/tauri-specta/2.0.0-rc.25/tauri_specta/) | [NSwag](https://learn.microsoft.com/aspnet/core/tutorials/getting-started-with-nswag) ou un client généré depuis [OpenAPI](https://learn.microsoft.com/aspnet/core/fundamentals/openapi/overview) | [OpenAPI Generator](https://openapi-generator.tech/) | importés directement : les deux processus sont en TypeScript ou JavaScript |

La différence avec OpenAPI : il n'y a pas de contrat HTTP au milieu. Le générateur lit directement les types Rust, au moment de `cargo test`.

## Deux frontends, un seul cœur Rust

Le cours React monte un projet Vite de zéro ([React (Vite), leçon 1](../../react-vite/01-vite-project/)) ; ici, Vite n'a qu'à s'accorder avec Tauri sur trois choses : l'adresse du serveur de dev, le dossier de sortie du build, et les commandes qui les produisent.

Le cours garde `ui/` tel quel et ajoute `frontend/`. Plutôt que de modifier `tauri.conf.json`, un second fichier en remplace la section `build` ; `tauri dev` et `tauri build` fusionnent un fichier passé avec [`--config`](https://v2.tauri.app/reference/cli/#dev) par-dessus la configuration principale (extrait de [`src-tauri/tauri.vite.conf.json`, lignes 1-11](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.vite.conf.json#L1-L11)) :

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

- `devUrl` : pendant `tauri dev`, la fenêtre charge le serveur de dev de Vite au lieu des fichiers ;
- `frontendDist` : ce que `tauri build` embarque dans le binaire, la sortie de Vite ;
- `beforeDevCommand` et `beforeBuildCommand` : la CLI Tauri les lance d'abord, si bien qu'une seule commande démarre tout ;
- `withGlobalTauri: false` : plus de `window.__TAURI__`. Le TypeScript importe [`@tauri-apps/api`](https://www.npmjs.com/package/@tauri-apps/api), et Vite n'empaquette que ce qu'il utilise.

Les scripts du `package.json` donnent à chaque frontend sa commande : `npx tauri dev` ouvre toujours `ui/`, `npm run dev:vite` lance `tauri dev --config src-tauri/tauri.vite.conf.json`.

Le côté Vite suit le [guide Tauri](https://v2.tauri.app/start/frontend/vite/) (extrait de [`vite.config.ts`, lignes 5-25](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/vite.config.ts#L5-L25)) :

```ts
export default defineConfig({
  root: "frontend",
  // Garder la sortie de Cargo visible quand tauri dev lance Vite
  clearScreen: false,
  server: {
    // Doit correspondre à build.devUrl dans src-tauri/tauri.vite.conf.json
    port: 5173,
    strictPort: true,
    watch: {
      // Les changements Rust sont surveillés par la CLI Tauri, pas par Vite
      ignored: ["**/src-tauri/**", "**/target/**"],
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
    // WebView2 est Chromium ; WKWebView et WebKitGTK sont WebKit (cibles tirées du guide Tauri)
    target: process.env.TAURI_ENV_PLATFORM === "windows" ? "chrome105" : "safari13",
    minify: !process.env.TAURI_ENV_DEBUG,
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
  },
```

`strictPort` compte : si le port 5173 est pris, Vite choisirait 5174 en silence et la fenêtre ne chargerait rien. Les variables `TAURI_ENV_*` sont définies par la CLI Tauri quand elle lance `beforeBuildCommand`, pour que le bundle cible la webview de la plateforme en cours de build : le build Windows peut utiliser des fonctionnalités que WebView2 possède et que Safari 13 n'a pas.

Le build lance d'abord `tsc`, puis Vite. Ici, c'est `tauri build` qui l'a lancé sous Windows, donc `TAURI_ENV_PLATFORM` valait `windows` :

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

7,61 kB de JavaScript pour toute la page, API Tauri comprise : c'est ce qui est embarqué dans le binaire. Sur le runner Ubuntu de la CI, le même build ciblait `safari13` et donnait `index-CXi5Pk96.js   7.67 kB │ gzip: 3.13 kB` : autre cible, autre bundle.

## `tauri dev` et le rechargement à chaud

`npm run dev:vite` démarre Vite, l'attend, puis compile et lance l'application :

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

Deux observateurs tournent côte à côte, et ce qui se passe lors d'une modification dépend de celui qui la voit. Mesuré avec la fenêtre ouverte, un accord saisi dans le champ, et un favori ajouté :

| Fichier modifié | Observateur | Ce qui s'est passé | Conservé |
|---|---|---|---|
| `frontend/src/styles.css` | Vite | `[vite] (client) hmr update /src/styles.css` : le nouveau style s'est appliqué sans rechargement | l'état de la page (l'accord saisi) et l'état Rust |
| `frontend/src/main.ts` | Vite | `[vite] (client) page reload src/main.ts` : la page s'est rechargée | seulement l'état Rust : les favoris étaient toujours là, le champ était revenu à sa valeur par défaut |
| `src-tauri/capabilities/export.json` | CLI Tauri | `File src-tauri\capabilities\export.json changed. Rebuilding application...`, une compilation (9,73 s) et un redémarrage | rien de ce qui était en mémoire |

C'est la deuxième ligne qu'il faut retenir. Un module sans gestionnaire HMR, comme `main.ts`, recharge la page ; des frameworks comme React ajoutent des gestionnaires qui conservent l'état des composants ([React (Vite), leçon 1](../../react-vite/01-vite-project/#hot-module-replacement-and-fast-refresh)). Le processus Rust ne redémarre pas, donc son état géré survit : une application Tauri garde naturellement les données importantes côté Rust.

## Des types générés depuis Rust

[ts-rs](https://github.com/Aleph-Alpha/ts-rs) (12.0.1, MIT) ajoute un derive `TS`. À côté de `Serialize`, il décrit la même struct en TypeScript (extrait de [`src-tauri/src/commands.rs`, lignes 9-13](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/commands.rs#L9-L13)) :

```rust
/// Un accord tel que le reçoit le frontend : des chaînes prêtes à afficher.
#[derive(Debug, Serialize, TS)]
#[serde(rename_all = "camelCase")]
#[ts(export)]
pub struct ChordView {
```

`#[ts(export)]` génère un test, `export_bindings_chordview`, qui écrit le fichier quand `cargo test` s'exécute. Le dossier vient d'une variable d'environnement que Cargo définit pour tout le workspace (extrait de [`.cargo/config.toml`, lignes 1-3](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/.cargo/config.toml#L1-L3)) :

```toml
# ts-rs écrit ici les déclarations TypeScript quand `cargo test` lance ses tests d'export
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

Le résultat tient compte des attributs de serde, `rename_all` compris (extrait de [`frontend/src/bindings/ChordView.ts`, lignes 1-6](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/bindings/ChordView.ts#L1-L6)) :

```ts
// This file was generated by [ts-rs](https://github.com/Aleph-Alpha/ts-rs). Do not edit this file manually.

/**
 * Un accord tel que le reçoit le frontend : des chaînes prêtes à afficher.
 */
export type ChordView = { symbol: string, qualityName: string, notes: Array<string>, intervals: Array<string>, };
```

Le commentaire de documentation est devenu du JSDoc, que l'éditeur affiche au survol. Le `SearchEvent` de la leçon 18, un enum avec `tag` et `content`, devient une union discriminée (extrait de [`frontend/src/bindings/SearchEvent.ts`, ligne 6](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/bindings/SearchEvent.ts#L6)) :

```ts
export type SearchEvent = { "event": "voicings", "data": { frets: Array<string>, } } | { "event": "progress", "data": { done: number, total: number, } } | { "event": "finished", "data": { found: number, elapsedMs: number, cancelled: boolean, } };
```

et un `switch` sur `event` restreint le type de `data` dans chaque branche, comme un `switch` sur une hiérarchie scellée en C# ou en Java (extrait de [`frontend/src/main.ts`, lignes 120-132](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts#L120-L132)) :

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

Les fichiers générés sont commités. Le frontend se construit alors sans Rust, et la CI lance `cargo test` puis échoue si `git status` montre un binding modifié : une modification Rust qui oublie de régénérer ne peut pas être fusionnée.

### Ce que les types attrapent

Un fichier avec trois erreurs :

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

La deuxième erreur vient d'un enum Rust : `ScaleMode` a deux variantes, donc son type TypeScript est `"major" | "minor"`.

### Le `u128` devenu `bigint`

Le premier `SearchEvent` généré ne disait pas `elapsedMs: number`, il disait `elapsedMs: bigint`. En Rust, le champ est un `u128`, issu de [`Duration::as_millis`](https://doc.rust-lang.org/std/time/struct.Duration.html#method.as_millis), et ts-rs traduit par défaut `i64`, `u64`, `i128` et `u128` en `bigint`. Un calcul sur ce champ ne compile alors plus :

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

C'est le type qui était faux, pas le code : [serde_json](https://docs.rs/serde_json/) écrit un `u128` comme un simple nombre JSON, et `JSON.parse` donne un `number`, jamais un `bigint`. Le type généré décrivait une valeur qui n'arrive jamais. Deux corrections : `TS_RS_LARGE_INT = "number"` dans la section `[env]` pour tous les grands entiers, ou une surcharge sur le champ, celle qu'utilise le cours (extrait de [`src-tauri/src/state.rs`, lignes 76-82](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/state.rs#L76-L82)) :

```rust
    Finished {
        found: usize,
        // ts-rs traduit u128 en `bigint`, mais serde_json écrit un simple nombre JSON
        #[ts(type = "number")]
        elapsed_ms: u128,
        cancelled: bool,
    },
```

Un `number` est exact jusqu'à 2<sup>53</sup> − 1, ce qui suffit largement pour des millisecondes. Pour des identifiants ou des montants qui peuvent dépasser, sérialisez-les en chaînes côté Rust et typez-les `string`.

La leçon se généralise : un générateur traduit des types, pas le comportement du sérialiseur. Chaque fois qu'un type généré et un attribut serde ne sont pas d'accord, faites confiance au JSON et vérifiez le type.

## Ce que ts-rs ne vérifie pas

ts-rs décrit des valeurs, pas des commandes. Le nom `"spell_chord"` et le nom d'argument `symbol` restent des chaînes. Le cours les rassemble dans un seul module, une fonction typée par commande, pour qu'une faute de frappe ne puisse exister qu'à un seul endroit (extrait de [`frontend/src/api.ts`, lignes 11-19](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/api.ts#L11-L19)) :

```ts
export const chordQualities = () => invoke<QualityView[]>("chord_qualities");

export const spellChord = (symbol: string) => invoke<ChordView>("spell_chord", { symbol });

export const transposeChord = (symbol: string, semitones: number) =>
  invoke<ChordView>("transpose_chord", { symbol, semitones });

export const diatonicChords = (tonicNote: string, mode: ScaleMode) =>
  invoke<ChordView[]>("diatonic_chords", { tonicNote, mode });
```

`invoke<ChordView>` est un cast : TypeScript lui fait confiance. Si `spell_chord` renvoyait autre chose, ou était renommée, `tsc` passerait quand même. Ce sont les tests de bout en bout de la leçon 21 qui l'attrapent.

[tauri-specta](https://github.com/specta-rs/tauri-specta) comble ce manque : un attribut `#[specta::specta]` à côté de `#[tauri::command]`, et il génère les fonctions de commande elles-mêmes, avec leurs noms et les types de leurs arguments, ainsi que des événements typés. Où il en est au 2026-09-16 :

| | ts-rs | tauri-specta |
|---|---|---|
| Version | 12.0.1, stable (2026-01-31) | 2.0.0-rc.25 (2026-05-08) ; des release candidates depuis 2.0.0-rc.1 en octobre 2023 |
| Tauri | indépendant de Tauri | la v2 demande specta 2, lui aussi en release candidate ; la 1.x stable ne prend en charge que Tauri v1 |
| Génère | des types | des types, des wrappers de commandes, des événements |
| Quand | `cargo test` | quand le code Rust appelle son exporteur, par exemple au démarrage dans les builds debug (*à vérifier*) |
| Étoiles sur GitHub | 1 878 | 797 |

Le cours utilise ts-rs parce qu'il est stable et ne touche pas à l'enregistrement des commandes. tauri-specta offre la vérification la plus forte, et il n'a pas été essayé sur ce projet (*à vérifier*) : une release candidate qui dure depuis presque trois ans est une décision à prendre en connaissance de cause, pas un choix par défaut.

## À retenir

- Un second frontend ne demande aucun changement côté Rust : `--config` fusionne un fichier par-dessus `tauri.conf.json`, ici `devUrl`, `frontendDist` et les deux `before*Command`.
- `tauri dev` fait tourner deux observateurs : Vite recharge la page ou la met à jour à chaud, et la CLI Tauri recompile et redémarre l'application. Un rechargement de la page conserve l'état Rust.
- ts-rs dérive des types TypeScript des structs Rust, attributs serde compris ; commitez-les et laissez la CI vérifier qu'ils sont à jour.
- Un type généré peut être faux : le `bigint` par défaut de ts-rs pour les entiers de 64 et 128 bits ne correspond pas à ce qu'envoie serde_json.
- Les types ne vérifient ni les noms de commandes ni les noms d'arguments : gardez les appels à `invoke` dans un seul module, ou utilisez tauri-specta en acceptant une release candidate.

## Exercices

1. `QualityView` a deux champs, `suffix` et `name`. Ajoutez `interval_count: u64` côté Rust, lancez `cargo test`, et prédisez le type TypeScript de `intervalCount` avant d'ouvrir le fichier. Faites-en ensuite un `number` sans attribut sur le champ.

<details>
<summary>Solution</summary>

ts-rs écrit `interval_count: bigint`. Deux surprises en une ligne : `u64` fait partie des grands entiers qui deviennent `bigint` par défaut, et le nom garde son tiret bas, parce que `QualityView` n'a pas de `#[serde(rename_all = "camelCase")]` et que ts-rs suit serde.

Sans toucher au champ, changez la valeur par défaut pour tout le workspace dans `.cargo/config.toml` :

```toml
[env]
TS_RS_EXPORT_DIR = { value = "frontend/src/bindings", relative = true }
TS_RS_LARGE_INT = "number"
```

`cargo test` écrit alors `interval_count: number`. Le type n'est honnête que tant que la valeur reste sous 2<sup>53</sup>, ce qui est le cas d'un nombre d'intervalles.

</details>

2. Un collègue renomme la commande Rust `spell_chord` en `spell` et met à jour `generate_handler!`. Lesquels de ces éléments échouent : `cargo test`, `tsc`, les tests Vitest avec `mockIPC`, l'application quand on clique sur *Spell* ?

<details>
<summary>Solution</summary>

- `cargo test` : échoue seulement si un test Rust appelle `spell_chord` par son nom, comme les tests IPC du cours dans `src-tauri/tests/` ; sinon il passe.
- `tsc` : passe. `invoke<ChordView>("spell_chord", …)` est une chaîne et un cast.
- Vitest avec `mockIPC` : passe, puisque le mock répond à n'importe quel nom qu'on lui donne (leçon 21).
- L'application : se rejette avec `Command spell_chord not found`.

Seul un test qui lance la vraie application, ou les wrappers générés par tauri-specta, attraperaient le renommage avant un utilisateur.

</details>

3. Pourquoi le cours commite-t-il `frontend/src/bindings/` au lieu de l'ignorer et de le générer avant chaque build ?

<details>
<summary>Solution</summary>

- Le frontend peut alors être construit, vérifié par le typage et testé sans chaîne d'outils Rust : `npm run web:build` n'a besoin que de Node.
- Une pull request montre la modification TypeScript à côté de la modification Rust, si bien qu'un relecteur voit ce que le frontend va recevoir.
- Le prix est de les garder synchronisés, ce que la CI impose : après `cargo test`, un fichier modifié dans `frontend/src/bindings` fait échouer le job.

</details>

## Sources

- [Tauri 2 — Vite](https://v2.tauri.app/start/frontend/vite/) et [Configuration du frontend](https://v2.tauri.app/start/frontend/)
- [Tauri 2 — Référence de la CLI, `dev` et `build`](https://v2.tauri.app/reference/cli/) : l'option `--config`
- [API JavaScript de Tauri — `core`](https://v2.tauri.app/reference/javascript/api/namespacecore/)
- [Vite — Configurer Vite](https://vite.dev/config/) et [API HMR](https://vite.dev/guide/api-hmr)
- [Documentation de ts-rs 12.0.1](https://docs.rs/ts-rs/12.0.1/ts_rs/) : `TS_RS_EXPORT_DIR`, `TS_RS_LARGE_INT`, `#[ts(type = "…")]`
- [tauri-specta](https://github.com/specta-rs/tauri-specta) et sa [documentation 2.0.0-rc.25](https://docs.rs/tauri-specta/2.0.0-rc.25/tauri_specta/)
- [MDN — `Number.MAX_SAFE_INTEGER`](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER)
