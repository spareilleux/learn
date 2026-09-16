---
title: 20. Sécurité Tauri, capabilities, CSP et plugins
description: Pourquoi une page Tauri ne peut rien appeler qui ne lui ait été accordé — plugins, permissions, capabilities et scopes, les vrais refus et l'export qui fonctionne une fois autorisé, ce que la Content Security Policy bloque dans un build de release et pas sous tauri dev, et pourquoi le code Rust n'est pas restreint — comparés à l'isolation de contexte d'Electron, aux capabilities Android et MSIX, et à la CSP d'un navigateur.
sidebar:
  order: 20
---

Exemple complet : [`l16-tauri/src-tauri/capabilities/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/src-tauri/capabilities), [`src-tauri/src/lib.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs) et [`frontend/src/main.ts`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts).

L'explorateur doit exporter les accords favoris dans un fichier texte choisi par l'utilisateur. Une page web ne sait pas le faire : elle n'a ni boîte de dialogue de fichier qui renvoie un chemin, ni accès au disque. Les plugins de Tauri ajoutent les deux, et le modèle de sécurité de Tauri décide si cette page, dans cette fenêtre, a le droit de s'en servir.

## Ce que vous connaissez déjà

| Idée | Tauri | Electron | Windows / Android | Navigateur |
|---|---|---|---|---|
| La page n'est pas digne de confiance | la webview n'appelle que ce qu'une capability accorde | l'[isolation de contexte](https://www.electronjs.org/docs/latest/tutorial/context-isolation) + un preload qui expose des fonctions choisies | | la politique de même origine |
| Privilèges déclarés | des [capabilities](https://v2.tauri.app/security/capabilities/) qui listent des [permissions](https://v2.tauri.app/security/permissions/) | l'API `contextBridge` du preload | les [capabilities MSIX](https://learn.microsoft.com/windows/uwp/packaging/app-capability-declarations), les [permissions Android](https://developer.android.com/guide/topics/permissions/overview) | |
| Quelles ressources | des [scopes](https://v2.tauri.app/security/scope/) (chemins, URL, programmes) | vos propres vérifications dans le processus principal | le consentement de l'utilisateur, par type de ressource | |
| Ce que la page peut charger | la [CSP](https://v2.tauri.app/security/csp/) de `tauri.conf.json` | une CSP que vous définissez vous-même | | [Content-Security-Policy](https://developer.mozilla.org/docs/Web/HTTP/Guides/CSP) |

L'analogie la plus proche est Electron avec une isolation de contexte bien faite : la page n'obtient jamais Node.js, seulement une liste de fonctions. Dans Tauri, cette liste n'est pas du code que vous écrivez dans un preload, c'est de la configuration que le build vérifie.

## Pourquoi tout refuser par défaut

La [documentation de sécurité](https://v2.tauri.app/security/) de Tauri trace une frontière entre deux parties de l'application. Le cœur Rust est de confiance : c'est votre code, compilé dans le binaire. La webview ne l'est pas : elle exécute du HTML et du JavaScript, et une faille de cross-site scripting, une dépendance npm compromise ou une page distante chargée par erreur s'exécuteraient avec tout ce que la page a le droit d'appeler. Ce que la page peut appeler part donc de zéro, et chaque commande de plugin est refusée tant qu'une capability ne l'accorde pas.

Les capabilities *réduisent l'impact* d'un frontend compromis. Elles ne protègent pas d'un code Rust peu sûr : une commande que vous écrivez peut toujours supprimer n'importe quel fichier que vous la laissez supprimer.

## Les plugins

Un plugin est une crate accompagnée, en général, d'un paquet npm avec son API TypeScript. Le cours en ajoute trois officiels : [dialog](https://v2.tauri.app/plugin/dialog/), [fs](https://v2.tauri.app/plugin/file-system/) et [store](https://v2.tauri.app/plugin/store/) (extrait de [`src-tauri/src/lib.rs`, lignes 43-47](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L43-L47)) :

```rust
    let builder = setup(tauri::Builder::default())
        // Leçon 20 : plugins. Leurs commandes demandent quand même des permissions dans une capability
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_store::Builder::new().build());
```

L'export utilise les deux premiers depuis TypeScript (extrait de [`frontend/src/main.ts`, lignes 87-104](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts#L87-L104)) :

```ts
async function exportFavorites() {
  const status = element("export-status");
  try {
    const path = await save({
      defaultPath: "favorites.txt",
      filters: [{ name: "Text", extensions: ["txt"] }],
    });
    if (path === null) {
      status.textContent = "export cancelled";
      return;
    }
    const symbols = await api.favorites();
    await writeTextFile(path, symbols.join("\n") + "\n");
    status.textContent = `${symbols.length} favorites written to ${path}`;
  } catch (error) {
    status.textContent = api.describe(error);
  }
}
```

[`save`](https://v2.tauri.app/reference/javascript/dialog/#save) et [`writeTextFile`](https://v2.tauri.app/reference/javascript/fs/#writetextfile) sont des appels `invoke` aux commandes `plugin:dialog|save` et `plugin:fs|write_text_file`, exactement comme les commandes de la leçon 17, donc la même couche IPC les vérifie.

## Refusé

Avec les plugins enregistrés et la capability de la leçon 16 inchangée (`core:default` seulement), un clic sur *Export…* sous `tauri dev` affiche :

```text
dialog.save not allowed. Permissions associated with this command: dialog:allow-save, dialog:default
```

Le message est une chaîne, pas le `CommandError` du cours : l'appel n'a jamais atteint le plugin. Il liste aussi les permissions qui autoriseraient la commande. Appeler les deux autres plugins depuis la page, via le protocole des DevTools, donne le même genre de refus :

```text
fs write: rejected (string) "fs.write_text_file not allowed. Permissions associated with this command: fs:allow-app-write, fs:allow-app-write-recursive, fs:allow-appcache-write, fs:allow-appcache-write-recursive, fs:allow-appconfig-write, fs:allow-appconfig-write-recursive, fs:allow-appdata-write, fs:allow-appdata-write-recursive, fs:allow-applocaldata-write, fs:allow-applocaldata-write-recursive, fs:allow-applog-write, fs:allow-applog-write-recursive, fs:allow-audio-write, fs:allow-audio-write-recursive, fs:allow-cache-write, fs:allow-cache-write-recursive, fs:allow-config-write, fs:allow-config-write-recursive, fs:allow-data-write, fs:allow-data-write-recursive, fs:allow-desktop-write, fs:allow-desktop-write-recursive, fs:allow-document-write, fs:allow-document-write-recursive, fs:allow-download-write, fs:allow-download-write-recursive, fs:allow-exe-write, fs:allow-exe-write-recursive, fs:allow-font-write, fs:allow-font-write-recursive, fs:allow-home-write, fs:allow-home-write-recursive, fs:allow-localdata-write, fs:allow-localdata-write-recursive, fs:allow-log-write, fs:allow-log-write-recursive, fs:allow-picture-write, fs:allow-picture-write-recursive, fs:allow-public-write, fs:allow-public-write-recursive, fs:allow-resource-write, fs:allow-resource-write-recursive, fs:allow-runtime-write, fs:allow-runtime-write-recursive, fs:allow-temp-write, fs:allow-temp-write-recursive, fs:allow-template-write, fs:allow-template-write-recursive, fs:allow-video-write, fs:allow-video-write-recursive, fs:allow-write-text-file, fs:write-all, fs:write-files"
store load: rejected (string) "store.load not allowed. Permissions associated with this command: store:allow-load, store:default"
```

La liste de fs montre comment les permissions sont construites : une `allow-<command>` par commande, et des ensembles qui combinent une commande et un scope, comme `fs:allow-appdata-write` (écrire, mais seulement sous le dossier de données de l'application).

Un build de release refuse avec un message plus court, sans la liste :

```text
plugin:store|load: rejected "Command plugin:store|load not allowed by ACL"
plugin:fs|read_text_file: rejected "Command plugin:fs|read_text_file not allowed by ACL"
```

## Une capability pour l'export

Une capability est un fichier JSON (ou TOML) dans `src-tauri/capabilities/` : quelles fenêtres, quelles permissions (extrait de [`src-tauri/capabilities/export.json`, lignes 1-7](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/capabilities/export.json#L1-L7)) :

```json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "export",
  "description": "Lesson 20: export the favourites to a file the user picks",
  "windows": ["main"],
  "permissions": ["dialog:allow-save", "fs:allow-write-text-file"]
}
```

Chaque fichier de ce dossier est activé, sauf si `tauri.conf.json` liste les capabilities par identifiant, et une fenêtre présente dans plusieurs capabilities reçoit toutes leurs permissions : la fenêtre `main` a maintenant `core:default` de `default.json` plus ces deux-là. Le `$schema` est généré au build à partir des plugins réellement enregistrés, si bien que l'éditeur complète les noms de permissions et signale une faute de frappe. Ajouter le fichier sous `tauri dev` a recompilé l'application (`File src-tauri\capabilities\export.json changed. Rebuilding application...`) : les capabilities sont embarquées dans le binaire, pas lues à l'exécution.

La boîte de dialogue s'ouvre désormais, et l'annuler donne `export cancelled`. Choisir un fichier l'écrit :

```text
1 favorites written to C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\favorites.txt
```

`dialog:allow-save` et `fs:allow-write-text-file` étaient les deux permissions les plus étroites. L'ensemble `fs:default` que `tauri add fs` aurait mis dans la capability n'inclut pas du tout l'écriture, et accorder `fs:write-all` autoriserait toutes les commandes d'écriture. Quand vous ajoutez un plugin avec `tauri add`, ouvrez ensuite la capability et lisez ce qu'il a accordé.

## Les scopes

`fs:allow-write-text-file` autorise la *commande*, pas n'importe quel *chemin*. Appelée directement avec un chemin que l'utilisateur n'a pas choisi :

```text
rejected (string) "forbidden path: C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\favorites.txt, maybe it is not allowed on the scope for `allow-write-text-file` permission in your capability file"
```

Alors comment l'export a-t-il réussi ? Le plugin dialog ajoute le chemin choisi par l'utilisateur au scope de fs avant de le renvoyer (extrait de [`plugins/dialog/src/commands.rs` à `dialog-v2.7.3`, lignes 248-256](https://github.com/tauri-apps/plugins-workspace/blob/dialog-v2.7.3/plugins/dialog/src/commands.rs#L248-L256)) :

```rust
    let path = dialog_builder.blocking_save_file();
    if let Some(p) = &path {
        if let Ok(path) = p.clone().into_path() {
            if let Some(s) = window.try_fs_scope() {
                s.allow_file(&path)?;
            }
            tauri_scope.allow_file(&path)?;
        }
    }
```

Après cet export, depuis la même page, le fichier choisi et son voisin :

```text
favorites.txt: written
other.txt: forbidden path: C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\other.txt, maybe it is not allowed on the scope for `allow-write-text-file` permission in your capability file
```

Le choix de l'utilisateur vaut autorisation, pour ce seul fichier. Le scope vit en mémoire ; le [plugin persisted-scope](https://v2.tauri.app/plugin/persisted-scope/) le conserve d'un redémarrage à l'autre (*à vérifier*, pas utilisé ici). Un scope statique s'écrit plutôt dans la capability, avec un objet à la place de la chaîne :

```json
{
  "identifier": "fs:allow-write-text-file",
  "allow": [{ "path": "$DOCUMENT/chords/*" }]
}
```

`$DOCUMENT`, `$APPDATA`, `$HOME` et les autres variables sont résolues selon le système d'exploitation, et les entrées `deny` l'emportent sur les `allow` (*à vérifier* : cette capability n'est pas celle du cours).

## Rust n'est pas restreint

Les favoris survivent maintenant à un redémarrage, et aucune capability n'accorde le store. Le côté Rust l'ouvre au démarrage et enregistre chaque changement annoncé par l'événement de la leçon 18 (extrait de [`src-tauri/src/lib.rs`, lignes 62-74](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L62-L74)) :

```rust
fn restore_favorites<R: Runtime>(app: &AppHandle<R>) -> Result<(), Box<dyn std::error::Error>> {
    let store = app.store(STORE_FILE)?;
    if let Some(saved) = store.get(FAVORITES_KEY) {
        let symbols: Vec<String> = serde_json::from_value(saved).unwrap_or_default();
        app.state::<state::Favorites>().replace(symbols);
    }
    app.listen("favorites-changed", move |event| {
        if let Ok(symbols) = serde_json::from_str::<serde_json::Value>(event.payload()) {
            store.set(FAVORITES_KEY, symbols);
        }
    });
    Ok(())
}
```

Après l'ajout de `Am7` aux favoris, `%APPDATA%\dev.learn.chord-explorer\favorites.json` contenait :

```json
{
  "favorites": [
    "Am7"
  ]
}
```

tandis que `store.load` depuis la page était toujours refusé. Les permissions filtrent les appels IPC venant de la webview ; le code Rust appelle directement l'API Rust du plugin. C'est la conception à viser : gardez les permissions de la page réduites et placez le travail privilégié derrière vos propres commandes, qui valident leurs arguments.

Vos propres commandes, en revanche, ne sont pas refusées par défaut : chaque commande de `generate_handler!` peut être appelée par chaque fenêtre. Pour qu'elles demandent elles aussi une permission, listez-les dans [`AppManifest::commands`](https://docs.rs/tauri-build/2.6.3/tauri_build/struct.AppManifest.html#method.commands) dans `build.rs`, puis accordez `allow-<command>` dans une capability (*à vérifier* : l'application du cours ne le fait pas).

## shell et opener

Deux plugins se ressemblent et diffèrent d'un ordre de grandeur en risque :

- [opener](https://v2.tauri.app/plugin/opener/) (2.5.5) ouvre une URL dans le navigateur par défaut, ou un fichier avec son application par défaut. C'est ce que faisait `shell.open` dans Tauri 1.
- [shell](https://v2.tauri.app/plugin/shell/) (2.3.6) lance des programmes. Sa permission prend un scope par programme, avec un validateur pour chaque argument :

```json
{
  "identifier": "shell:allow-execute",
  "allow": [
    {
      "name": "exec-sh",
      "cmd": "sh",
      "args": ["-c", { "validator": "\\S+" }],
      "sidecar": false
    }
  ]
}
```

Cet exemple de la documentation de Tauri montre le danger plutôt qu'une recommandation : `sh -c` avec n'importe quel argument non vide permet à la page de lancer n'importe quoi. Si la page doit lancer un programme, accordez ce programme avec des arguments fixes ou étroitement validés, ou mieux, écrivez une commande Rust qui le lance.

## La Content Security Policy

Le modèle de la leçon 16 livrait `"csp": null`. Le `tauri.conf.json` du cours en définit une (extrait de [`src-tauri/tauri.conf.json`, lignes 18-20](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.conf.json#L18-L20)) :

```json
    "security": {
      "csp": "default-src 'self'; connect-src ipc: http://ipc.localhost"
    }
```

- `default-src 'self'` : scripts, styles, images et polices ne viennent que des ressources de l'application elle-même ;
- `connect-src ipc: http://ipc.localhost` : `fetch` peut atteindre l'IPC de Tauri et rien d'autre. Sans cette ligne, `invoke` lui-même serait bloqué, puisque l'IPC passe par ces deux URL.

Tauri ajoute cette politique aux ressources qu'il sert et, au build, y ajoute les empreintes et les nonces des scripts et des styles empaquetés. Dans le build de release de l'explorateur, un `fetch` vers une API distante a affiché, dans la console des DevTools :

```text
[security error] Connecting to 'https://api.github.com/zen' violates the following Content Security Policy directive: "connect-src ipc: http://ipc.localhost". The action has been blocked.
[javascript error] Fetch API cannot load https://api.github.com/zen. Refused to connect because it violates the document's Content Security Policy.
```

Sous `tauri dev` avec Vite, le même `fetch` depuis la page à `http://localhost:5173` a renvoyé `200`. La page y est servie par Vite, pas par Tauri, donc la politique n'a pas été appliquée. Testez la CSP sur un build, pas seulement en développement.

Ce qu'une CSP apporte dans une application de bureau : si un attaquant parvient à injecter un script, celui-ci ne peut pas charger d'autre code depuis ailleurs ni envoyer de données à l'extérieur avec `fetch`. Charger des scripts distants depuis un CDN la neutralise. Empaquetez-les plutôt.

## À retenir

- La webview est traitée comme non fiable : chaque commande de plugin est refusée tant qu'une capability n'accorde pas une permission pour cette fenêtre.
- Une capability liste des permissions ; une permission autorise des commandes et peut porter un scope. Préférez `allow-<command>` aux ensembles `default` et `*-all`, et lisez ce que `tauri add` a écrit.
- Les scopes restreignent les ressources : `fs:allow-write-text-file` n'écrit nulle part à lui seul, et la boîte de dialogue accorde exactement le fichier choisi par l'utilisateur.
- Les capabilities filtrent ce que la page appelle, pas ce que fait Rust : le store utilisé depuis Rust n'a rien demandé, et vos propres commandes sont appelables par défaut.
- La CSP de `tauri.conf.json` s'applique à l'application construite, pas à la page d'un serveur de dev ; gardez-y `connect-src ipc: http://ipc.localhost`.

## Exercices

1. L'explorateur doit aussi *importer* des favoris depuis un fichier texte choisi par l'utilisateur. De quelles deux permissions la capability a-t-elle besoin, et que ne doit-elle pas contenir ?

<details>
<summary>Solution</summary>

`dialog:allow-open` pour afficher la boîte de dialogue d'ouverture, et `fs:allow-read-text-file` pour lire le fichier. `open` ajoute le chemin choisi au scope de fs de la même façon que `save` (lignes 195-212 du même `commands.rs`), donc aucun scope statique n'est nécessaire.

Elle ne doit contenir ni `fs:default`, qui accorde la lecture des dossiers propres à l'application, inutile ici, ni `fs:read-all`. Une conception plus stricte n'a aucune permission fs : la page obtient le chemin depuis la boîte de dialogue et appelle une commande Rust `import_favorites(path)`, qui lit le fichier, valide chaque symbole avec `theory` et met à jour l'état.

</details>

2. Une dépendance npm du frontend est compromise et exécute son propre script dans la page de l'explorateur. Avec les capabilities du cours, listez ce qu'elle peut faire et ce qu'elle ne peut pas faire.

<details>
<summary>Solution</summary>

Elle peut :

- appeler toutes les commandes de l'application (`generate_handler!` les expose à chaque fenêtre), par exemple remplir les favoris de n'importe quoi, que Rust enregistre ensuite dans le store ;
- ouvrir la boîte de dialogue d'enregistrement et, si l'utilisateur choisit un fichier, écrire n'importe quel contenu dans ce fichier ;
- utiliser `core:default` (événements, informations sur la fenêtre, …).

Elle ne peut pas :

- lire ou écrire un autre fichier : aucune permission de lecture, et le scope d'écriture ne contient que les chemins choisis par l'utilisateur ;
- lancer un programme ou ouvrir une URL : shell et opener ne sont même pas enregistrés ;
- envoyer ce qu'elle trouve à un serveur avec `fetch`, ou charger d'autre code depuis une URL, dans l'application construite : la CSP les bloque. Faire naviguer la fenêtre vers un autre site est une autre affaire, la CSP ne régit pas la navigation (*à vérifier*).

</details>

3. Un designer veut une police de Google Fonts dans l'application construite. Quelles directives de la CSP doivent changer, et que proposeriez-vous à la place ?

<details>
<summary>Solution</summary>

La feuille de style vient de `https://fonts.googleapis.com` et les fichiers de police de `https://fonts.gstatic.com`, donc `style-src 'self' https://fonts.googleapis.com` et `font-src 'self' https://fonts.gstatic.com`, en gardant `default-src 'self'` et le `connect-src` pour l'IPC. L'exemple de Tauri dans sa page sur la CSP utilise exactement ces deux hôtes.

Mieux : téléchargez les fichiers de police, placez-les dans `frontend/`, et laissez Vite les empaqueter. La CSP reste à `'self'`, l'application fonctionne hors ligne, et rien sur l'utilisateur n'est envoyé à un tiers au démarrage de l'application.

</details>

## Sources

- [Tauri 2 — Sécurité](https://v2.tauri.app/security/), [Capabilities](https://v2.tauri.app/security/capabilities/), [Permissions](https://v2.tauri.app/security/permissions/), [Scopes des commandes](https://v2.tauri.app/security/scope/), [Content Security Policy](https://v2.tauri.app/security/csp/)
- [Tauri 2 — Dialog](https://v2.tauri.app/plugin/dialog/), [File System](https://v2.tauri.app/plugin/file-system/), [Store](https://v2.tauri.app/plugin/store/), [Opener](https://v2.tauri.app/plugin/opener/), [Shell](https://v2.tauri.app/plugin/shell/)
- [tauri-apps/plugins-workspace](https://github.com/tauri-apps/plugins-workspace) : le code source des plugins et leurs dossiers `permissions/`
- [Electron — Context Isolation](https://www.electronjs.org/docs/latest/tutorial/context-isolation) et [Checklist de sécurité](https://www.electronjs.org/docs/latest/tutorial/security)
- [MDN — Content Security Policy](https://developer.mozilla.org/docs/Web/HTTP/Guides/CSP)
