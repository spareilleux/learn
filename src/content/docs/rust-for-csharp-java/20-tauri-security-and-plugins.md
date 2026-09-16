---
title: 20. Tauri security, capabilities, CSP and plugins
description: Why a Tauri page can call nothing it was not granted — plugins, permissions, capabilities and scopes, the real refusals and the export that works once allowed, what the Content Security Policy blocks in a release build and not under tauri dev, and why Rust code is not restricted — compared with Electron's context isolation, Android and MSIX capabilities, and a browser's CSP.
sidebar:
  order: 20
---

Full example: [`l16-tauri/src-tauri/capabilities/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/src-tauri/capabilities), [`src-tauri/src/lib.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs) and [`frontend/src/main.ts`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts).

The explorer should export the favourite chords to a text file that the user picks. A web page cannot do that: it has no file dialog that returns a path and no access to the disk. Tauri's plugins add both, and Tauri's security model decides whether this page, in this window, may use them.

## What you already know

| Idea | Tauri | Electron | Windows / Android | Browser |
|---|---|---|---|---|
| The page is not trusted | the webview calls only what a capability grants | [context isolation](https://www.electronjs.org/docs/latest/tutorial/context-isolation) + a preload that exposes chosen functions | | same-origin policy |
| Declared privileges | [capabilities](https://v2.tauri.app/security/capabilities/) listing [permissions](https://v2.tauri.app/security/permissions/) | the preload's `contextBridge` API | [MSIX capabilities](https://learn.microsoft.com/windows/uwp/packaging/app-capability-declarations), [Android permissions](https://developer.android.com/guide/topics/permissions/overview) | |
| Which resources | [scopes](https://v2.tauri.app/security/scope/) (paths, URLs, programs) | your own checks in the main process | the user's consent, per resource type | |
| What the page may load | the [CSP](https://v2.tauri.app/security/csp/) from `tauri.conf.json` | a CSP you set yourself | | [Content-Security-Policy](https://developer.mozilla.org/docs/Web/HTTP/Guides/CSP) |

The closest analogy is Electron with context isolation done right: the page never gets Node.js, only a list of functions. In Tauri that list is not code you write in a preload, it is configuration that the build checks.

## Why deny by default

Tauri's [security documentation](https://v2.tauri.app/security/) draws the line between two parts of the app. The Rust core is trusted: it is your code, compiled into the binary. The webview is not: it runs HTML and JavaScript, and a cross-site scripting bug, a compromised npm dependency or a remote page loaded by mistake would run with whatever the page may call. So what the page may call starts empty, and every plugin command is refused until a capability grants it.

Capabilities *reduce the impact* of a compromised frontend. They do not protect against insecure Rust code: a command you write can still delete any file you let it delete.

## Plugins

A plugin is a crate plus, usually, an npm package with its TypeScript API. The course adds three official ones: [dialog](https://v2.tauri.app/plugin/dialog/), [fs](https://v2.tauri.app/plugin/file-system/) and [store](https://v2.tauri.app/plugin/store/) (from [`src-tauri/src/lib.rs`, lines 43-47](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L43-L47)):

```rust
    let builder = setup(tauri::Builder::default())
        // Lesson 20: plugins. Their commands still need permissions in a capability
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_store::Builder::new().build());
```

The export uses the first two from TypeScript (from [`frontend/src/main.ts`, lines 87-104](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts#L87-L104)):

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

[`save`](https://v2.tauri.app/reference/javascript/dialog/#save) and [`writeTextFile`](https://v2.tauri.app/reference/javascript/fs/#writetextfile) are `invoke` calls to the commands `plugin:dialog|save` and `plugin:fs|write_text_file`, exactly like lesson 17's commands, so the same IPC layer checks them.

## Refused

With the plugins registered and the capability of lesson 16 unchanged (`core:default` only), clicking *Export…* under `tauri dev` shows:

```text
dialog.save not allowed. Permissions associated with this command: dialog:allow-save, dialog:default
```

The message is a string, not the course's `CommandError`: the call never reached the plugin. It also lists the permissions that would allow the command. Calling the other two plugins from the page, through the DevTools protocol, gives the same kind of refusal:

```text
fs write: rejected (string) "fs.write_text_file not allowed. Permissions associated with this command: fs:allow-app-write, fs:allow-app-write-recursive, fs:allow-appcache-write, fs:allow-appcache-write-recursive, fs:allow-appconfig-write, fs:allow-appconfig-write-recursive, fs:allow-appdata-write, fs:allow-appdata-write-recursive, fs:allow-applocaldata-write, fs:allow-applocaldata-write-recursive, fs:allow-applog-write, fs:allow-applog-write-recursive, fs:allow-audio-write, fs:allow-audio-write-recursive, fs:allow-cache-write, fs:allow-cache-write-recursive, fs:allow-config-write, fs:allow-config-write-recursive, fs:allow-data-write, fs:allow-data-write-recursive, fs:allow-desktop-write, fs:allow-desktop-write-recursive, fs:allow-document-write, fs:allow-document-write-recursive, fs:allow-download-write, fs:allow-download-write-recursive, fs:allow-exe-write, fs:allow-exe-write-recursive, fs:allow-font-write, fs:allow-font-write-recursive, fs:allow-home-write, fs:allow-home-write-recursive, fs:allow-localdata-write, fs:allow-localdata-write-recursive, fs:allow-log-write, fs:allow-log-write-recursive, fs:allow-picture-write, fs:allow-picture-write-recursive, fs:allow-public-write, fs:allow-public-write-recursive, fs:allow-resource-write, fs:allow-resource-write-recursive, fs:allow-runtime-write, fs:allow-runtime-write-recursive, fs:allow-temp-write, fs:allow-temp-write-recursive, fs:allow-template-write, fs:allow-template-write-recursive, fs:allow-video-write, fs:allow-video-write-recursive, fs:allow-write-text-file, fs:write-all, fs:write-files"
store load: rejected (string) "store.load not allowed. Permissions associated with this command: store:allow-load, store:default"
```

The fs list shows how permissions are built: one `allow-<command>` per command, and sets that combine a command with a scope, such as `fs:allow-appdata-write` (writes, but only under the app's data folder).

A release build refuses with a shorter message, without the list:

```text
plugin:store|load: rejected "Command plugin:store|load not allowed by ACL"
plugin:fs|read_text_file: rejected "Command plugin:fs|read_text_file not allowed by ACL"
```

## A capability for the export

A capability is a JSON (or TOML) file in `src-tauri/capabilities/`: which windows, which permissions (from [`src-tauri/capabilities/export.json`, lines 1-7](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/capabilities/export.json#L1-L7)):

```json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "export",
  "description": "Lesson 20: export the favourites to a file the user picks",
  "windows": ["main"],
  "permissions": ["dialog:allow-save", "fs:allow-write-text-file"]
}
```

Every file in that folder is enabled unless `tauri.conf.json` lists capabilities by identifier, and a window in several capabilities gets all their permissions: the `main` window now has `core:default` from `default.json` plus these two. The `$schema` is generated at build time from the plugins actually registered, so the editor completes permission names and flags a typo. Adding the file under `tauri dev` recompiled the app (`File src-tauri\capabilities\export.json changed. Rebuilding application...`): capabilities are embedded in the binary, not read at run time.

The dialog opens now, and cancelling it gives `export cancelled`. Choosing a file writes it:

```text
1 favorites written to C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\favorites.txt
```

`dialog:allow-save` and `fs:allow-write-text-file` were the two narrowest permissions. The `fs:default` set that `tauri add fs` would have put in the capability does not include writing at all, and granting `fs:write-all` would allow every write command. When you add a plugin with `tauri add`, open the capability afterwards and read what it granted.

## Scopes

`fs:allow-write-text-file` allows the *command*, not any *path*. Called directly with a path the user did not pick:

```text
rejected (string) "forbidden path: C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\favorites.txt, maybe it is not allowed on the scope for `allow-write-text-file` permission in your capability file"
```

So how did the export succeed? The dialog plugin adds the path the user chose to the fs scope before returning it (from [`plugins/dialog/src/commands.rs` at `dialog-v2.7.3`, lines 248-256](https://github.com/tauri-apps/plugins-workspace/blob/dialog-v2.7.3/plugins/dialog/src/commands.rs#L248-L256)):

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

After that export, from the same page, the chosen file and its neighbour:

```text
favorites.txt: written
other.txt: forbidden path: C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\other.txt, maybe it is not allowed on the scope for `allow-write-text-file` permission in your capability file
```

The user's choice is the grant, for that one file. The scope lives in memory; the [persisted-scope plugin](https://v2.tauri.app/plugin/persisted-scope/) keeps it across restarts (*to verify*, not used here). A static scope is written in the capability instead, with an object in place of the string:

```json
{
  "identifier": "fs:allow-write-text-file",
  "allow": [{ "path": "$DOCUMENT/chords/*" }]
}
```

`$DOCUMENT`, `$APPDATA`, `$HOME` and the other variables are resolved per operating system, and `deny` entries win over `allow` ones (*to verify*: this capability is not the course's).

## Rust is not restricted

The favourites now survive a restart, and no capability grants the store. The Rust side opens it at startup and saves each change announced by lesson 18's event (from [`src-tauri/src/lib.rs`, lines 62-74](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L62-L74)):

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

After adding `Am7` to the favourites, `%APPDATA%\dev.learn.chord-explorer\favorites.json` contained:

```json
{
  "favorites": [
    "Am7"
  ]
}
```

while `store.load` from the page was still refused. Permissions filter IPC calls from the webview; Rust code calls the plugin's Rust API directly. That is the design to aim for: keep the page's permissions small and put privileged work behind your own commands, which validate their arguments.

Your own commands, however, are not denied by default: every command in `generate_handler!` may be called by every window. To make them need a permission too, list them in [`AppManifest::commands`](https://docs.rs/tauri-build/2.6.3/tauri_build/struct.AppManifest.html#method.commands) in `build.rs`, then grant `allow-<command>` in a capability (*to verify*: the course's app does not do it).

## shell and opener

Two plugins look alike and differ by an order of magnitude in risk:

- [opener](https://v2.tauri.app/plugin/opener/) (2.5.5) opens a URL in the default browser, or a file with its default application. This is what `shell.open` did in Tauri 1.
- [shell](https://v2.tauri.app/plugin/shell/) (2.3.6) runs programs. Its permission takes a scope per program, with a validator for each argument:

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

That example from the Tauri documentation shows the danger rather than a recommendation: `sh -c` with any non-blank argument lets the page run anything. If the page needs to run a program, grant that program with fixed or tightly validated arguments, or better, write a Rust command that runs it.

## The Content Security Policy

Lesson 16's template shipped `"csp": null`. The course's `tauri.conf.json` sets one (from [`src-tauri/tauri.conf.json`, lines 18-20](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.conf.json#L18-L20)):

```json
    "security": {
      "csp": "default-src 'self'; connect-src ipc: http://ipc.localhost"
    }
```

- `default-src 'self'`: scripts, styles, images and fonts come from the app's own assets only;
- `connect-src ipc: http://ipc.localhost`: `fetch` may reach Tauri's IPC and nothing else. Without this line, `invoke` itself would be blocked, since the IPC travels over those two URLs.

Tauri adds this policy to the assets it serves, and at build time adds the hashes and nonces of the bundled scripts and styles to it. In the release build of the explorer, a `fetch` to a remote API logged, in the DevTools console:

```text
[security error] Connecting to 'https://api.github.com/zen' violates the following Content Security Policy directive: "connect-src ipc: http://ipc.localhost". The action has been blocked.
[javascript error] Fetch API cannot load https://api.github.com/zen. Refused to connect because it violates the document's Content Security Policy.
```

Under `tauri dev` with Vite, the same `fetch` from the page at `http://localhost:5173` returned `200`. The page is served by Vite there, not by Tauri, so the policy was not applied. Test the CSP on a build, not only in development.

What a CSP buys in a desktop app: if an attacker manages to inject a script, it cannot load more code from elsewhere and cannot send data out with `fetch`. Loading remote scripts from a CDN defeats it. Bundle them instead.

## Key takeaways

- The webview is treated as untrusted: every plugin command is refused until a capability grants a permission for that window.
- A capability lists permissions; a permission allows commands and may carry a scope. Prefer `allow-<command>` over `default` sets and `*-all`, and read what `tauri add` wrote.
- Scopes restrict the resources: `fs:allow-write-text-file` writes nowhere by itself, and the dialog grants exactly the file the user picked.
- Capabilities filter what the page calls, not what Rust does: the store used from Rust needed nothing, and your own commands are callable by default.
- The CSP from `tauri.conf.json` applies to the built app, not to a dev server's page; keep `connect-src ipc: http://ipc.localhost` in it.

## Exercises

1. The explorer should also *import* favourites from a text file the user picks. Which two permissions does the capability need, and what should it not contain?

<details>
<summary>Solution</summary>

`dialog:allow-open` to show the open dialog, and `fs:allow-read-text-file` to read the file. `open` adds the chosen path to the fs scope the same way `save` does (lines 195-212 of the same `commands.rs`), so no static scope is needed.

It should not contain `fs:default`, which grants reading the app's own folders, useless here, nor `fs:read-all`. A tighter design has no fs permission at all: the page gets the path from the dialog and calls a Rust command `import_favorites(path)`, which reads the file, validates each symbol with `theory`, and updates the state.

</details>

2. An npm dependency of the frontend is compromised and runs its own script in the explorer's page. With the course's capabilities, list what it can do and what it cannot.

<details>
<summary>Solution</summary>

It can:

- call every command of the app (`generate_handler!` exposes them to every window), for example fill the favourites with garbage, which Rust then saves in the store;
- open the save dialog and, if the user picks a file, write any content into that file;
- use `core:default` (events, window information, …).

It cannot:

- read or write any other file: no read permission, and the write scope contains only paths the user chose;
- run a program or open a URL: shell and opener are not even registered;
- send what it finds to a server with `fetch`, or load more code from a URL, in the built app: the CSP blocks them. Navigating the window to another site is a different matter, the CSP does not govern navigation (*to verify*).

</details>

3. A designer wants a font from Google Fonts in the built app. Which CSP directives must change, and what would you suggest instead?

<details>
<summary>Solution</summary>

The stylesheet comes from `https://fonts.googleapis.com` and the font files from `https://fonts.gstatic.com`, so `style-src 'self' https://fonts.googleapis.com` and `font-src 'self' https://fonts.gstatic.com`, keeping `default-src 'self'` and the `connect-src` for the IPC. Tauri's own example in its CSP page uses exactly those two hosts.

Better: download the font files, put them in `frontend/`, and let Vite bundle them. The CSP stays `'self'`, the app works offline, and nothing about the user is sent to a third party when the app starts.

</details>

## Sources

- [Tauri 2 — Security](https://v2.tauri.app/security/), [Capabilities](https://v2.tauri.app/security/capabilities/), [Permissions](https://v2.tauri.app/security/permissions/), [Command scopes](https://v2.tauri.app/security/scope/), [Content Security Policy](https://v2.tauri.app/security/csp/)
- [Tauri 2 — Dialog](https://v2.tauri.app/plugin/dialog/), [File System](https://v2.tauri.app/plugin/file-system/), [Store](https://v2.tauri.app/plugin/store/), [Opener](https://v2.tauri.app/plugin/opener/), [Shell](https://v2.tauri.app/plugin/shell/)
- [tauri-apps/plugins-workspace](https://github.com/tauri-apps/plugins-workspace): the plugins' source and their `permissions/` folders
- [Electron — Context Isolation](https://www.electronjs.org/docs/latest/tutorial/context-isolation) and [Security checklist](https://www.electronjs.org/docs/latest/tutorial/security)
- [MDN — Content Security Policy](https://developer.mozilla.org/docs/Web/HTTP/Guides/CSP)
