---
title: 20. Seguridad en Tauri, capabilities, CSP y plugins
description: Por qué una página Tauri no puede llamar a nada que no se le haya concedido — plugins, permisos, capabilities y scopes, los rechazos reales y la exportación que funciona una vez permitida, lo que la Content Security Policy bloquea en un build de release y no con tauri dev, y por qué el código Rust no está restringido — comparado con el aislamiento de contexto de Electron, las capabilities de Android y MSIX, y la CSP de un navegador.
sidebar:
  order: 20
---

Ejemplo completo: [`l16-tauri/src-tauri/capabilities/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri/src-tauri/capabilities), [`src-tauri/src/lib.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs) y [`frontend/src/main.ts`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts).

El explorador debería exportar los acordes favoritos a un archivo de texto que elija el usuario. Una página web no puede hacerlo: no tiene un diálogo de archivos que devuelva una ruta ni acceso al disco. Los plugins de Tauri añaden ambas cosas, y el modelo de seguridad de Tauri decide si esta página, en esta ventana, puede usarlos.

## Lo que ya conoces

| Idea | Tauri | Electron | Windows / Android | Navegador |
|---|---|---|---|---|
| La página no es de confianza | el webview solo llama a lo que concede una capability | [aislamiento de contexto](https://www.electronjs.org/docs/latest/tutorial/context-isolation) + un preload que expone funciones elegidas | | política del mismo origen |
| Privilegios declarados | [capabilities](https://v2.tauri.app/security/capabilities/) que enumeran [permisos](https://v2.tauri.app/security/permissions/) | la API `contextBridge` del preload | [capabilities MSIX](https://learn.microsoft.com/windows/uwp/packaging/app-capability-declarations), [permisos de Android](https://developer.android.com/guide/topics/permissions/overview) | |
| Qué recursos | [scopes](https://v2.tauri.app/security/scope/) (rutas, URL, programas) | tus propias comprobaciones en el proceso principal | el consentimiento del usuario, por tipo de recurso | |
| Qué puede cargar la página | la [CSP](https://v2.tauri.app/security/csp/) de `tauri.conf.json` | una CSP que defines tú | | [Content-Security-Policy](https://developer.mozilla.org/docs/Web/HTTP/Guides/CSP) |

La analogía más cercana es Electron con el aislamiento de contexto bien hecho: la página nunca obtiene Node.js, solo una lista de funciones. En Tauri esa lista no es código que escribes en un preload, es configuración que comprueba el build.

## Por qué denegar por defecto

La [documentación de seguridad](https://v2.tauri.app/security/) de Tauri traza la frontera entre dos partes de la aplicación. El núcleo Rust es de confianza: es tu código, compilado en el binario. El webview no: ejecuta HTML y JavaScript, y un fallo de cross-site scripting, una dependencia npm comprometida o una página remota cargada por error se ejecutarían con todo lo que la página puede llamar. Así que lo que la página puede llamar empieza vacío, y cada comando de plugin se rechaza hasta que una capability lo concede.

Las capabilities *reducen el impacto* de un frontend comprometido. No protegen contra código Rust inseguro: un comando que escribes tú puede seguir borrando cualquier archivo que le dejes borrar.

## Plugins

Un plugin es un crate más, normalmente, un paquete npm con su API TypeScript. El curso añade tres oficiales: [dialog](https://v2.tauri.app/plugin/dialog/), [fs](https://v2.tauri.app/plugin/file-system/) y [store](https://v2.tauri.app/plugin/store/) (de [`src-tauri/src/lib.rs`, líneas 43-47](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L43-L47)):

```rust
    let builder = setup(tauri::Builder::default())
        // Lección 20: plugins. Sus comandos siguen necesitando permisos en una capability
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_store::Builder::new().build());
```

La exportación usa los dos primeros desde TypeScript (de [`frontend/src/main.ts`, líneas 87-104](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/frontend/src/main.ts#L87-L104)):

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

[`save`](https://v2.tauri.app/reference/javascript/dialog/#save) y [`writeTextFile`](https://v2.tauri.app/reference/javascript/fs/#writetextfile) son llamadas `invoke` a los comandos `plugin:dialog|save` y `plugin:fs|write_text_file`, exactamente como los comandos de la lección 17, así que los comprueba la misma capa IPC.

## Rechazado

Con los plugins registrados y la capability de la lección 16 sin cambios (solo `core:default`), hacer clic en *Export…* con `tauri dev` muestra:

```text
dialog.save not allowed. Permissions associated with this command: dialog:allow-save, dialog:default
```

El mensaje es una cadena, no el `CommandError` del curso: la llamada nunca llegó al plugin. También enumera los permisos que permitirían el comando. Llamar a los otros dos plugins desde la página, mediante el protocolo de las DevTools, da el mismo tipo de rechazo:

```text
fs write: rejected (string) "fs.write_text_file not allowed. Permissions associated with this command: fs:allow-app-write, fs:allow-app-write-recursive, fs:allow-appcache-write, fs:allow-appcache-write-recursive, fs:allow-appconfig-write, fs:allow-appconfig-write-recursive, fs:allow-appdata-write, fs:allow-appdata-write-recursive, fs:allow-applocaldata-write, fs:allow-applocaldata-write-recursive, fs:allow-applog-write, fs:allow-applog-write-recursive, fs:allow-audio-write, fs:allow-audio-write-recursive, fs:allow-cache-write, fs:allow-cache-write-recursive, fs:allow-config-write, fs:allow-config-write-recursive, fs:allow-data-write, fs:allow-data-write-recursive, fs:allow-desktop-write, fs:allow-desktop-write-recursive, fs:allow-document-write, fs:allow-document-write-recursive, fs:allow-download-write, fs:allow-download-write-recursive, fs:allow-exe-write, fs:allow-exe-write-recursive, fs:allow-font-write, fs:allow-font-write-recursive, fs:allow-home-write, fs:allow-home-write-recursive, fs:allow-localdata-write, fs:allow-localdata-write-recursive, fs:allow-log-write, fs:allow-log-write-recursive, fs:allow-picture-write, fs:allow-picture-write-recursive, fs:allow-public-write, fs:allow-public-write-recursive, fs:allow-resource-write, fs:allow-resource-write-recursive, fs:allow-runtime-write, fs:allow-runtime-write-recursive, fs:allow-temp-write, fs:allow-temp-write-recursive, fs:allow-template-write, fs:allow-template-write-recursive, fs:allow-video-write, fs:allow-video-write-recursive, fs:allow-write-text-file, fs:write-all, fs:write-files"
store load: rejected (string) "store.load not allowed. Permissions associated with this command: store:allow-load, store:default"
```

La lista de fs muestra cómo se construyen los permisos: un `allow-<command>` por comando, y conjuntos que combinan un comando con un scope, como `fs:allow-appdata-write` (escribe, pero solo en la carpeta de datos de la aplicación).

Un build de release rechaza con un mensaje más corto, sin la lista:

```text
plugin:store|load: rejected "Command plugin:store|load not allowed by ACL"
plugin:fs|read_text_file: rejected "Command plugin:fs|read_text_file not allowed by ACL"
```

## Una capability para la exportación

Una capability es un archivo JSON (o TOML) en `src-tauri/capabilities/`: qué ventanas, qué permisos (de [`src-tauri/capabilities/export.json`, líneas 1-7](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/capabilities/export.json#L1-L7)):

```json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "export",
  "description": "Lesson 20: export the favourites to a file the user picks",
  "windows": ["main"],
  "permissions": ["dialog:allow-save", "fs:allow-write-text-file"]
}
```

Todos los archivos de esa carpeta están activos salvo que `tauri.conf.json` enumere las capabilities por identificador, y una ventana presente en varias capabilities obtiene todos sus permisos: la ventana `main` tiene ahora `core:default` de `default.json` más estos dos. El `$schema` se genera al compilar a partir de los plugins realmente registrados, así que el editor completa los nombres de los permisos y señala una errata. Añadir el archivo con `tauri dev` recompiló la aplicación (`File src-tauri\capabilities\export.json changed. Rebuilding application...`): las capabilities se incrustan en el binario, no se leen en ejecución.

Ahora el diálogo se abre, y cancelarlo da `export cancelled`. Elegir un archivo lo escribe:

```text
1 favorites written to C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\favorites.txt
```

`dialog:allow-save` y `fs:allow-write-text-file` eran los dos permisos más estrechos. El conjunto `fs:default` que `tauri add fs` habría puesto en la capability no incluye escritura alguna, y conceder `fs:write-all` permitiría todos los comandos de escritura. Cuando añadas un plugin con `tauri add`, abre después la capability y lee lo que ha concedido.

## Scopes

`fs:allow-write-text-file` permite el *comando*, no cualquier *ruta*. Llamado directamente con una ruta que el usuario no eligió:

```text
rejected (string) "forbidden path: C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\favorites.txt, maybe it is not allowed on the scope for `allow-write-text-file` permission in your capability file"
```

¿Cómo tuvo éxito entonces la exportación? El plugin dialog añade la ruta que eligió el usuario al scope de fs antes de devolverla (de [`plugins/dialog/src/commands.rs` en `dialog-v2.7.3`, líneas 248-256](https://github.com/tauri-apps/plugins-workspace/blob/dialog-v2.7.3/plugins/dialog/src/commands.rs#L248-L256)):

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

Después de esa exportación, desde la misma página, el archivo elegido y su vecino:

```text
favorites.txt: written
other.txt: forbidden path: C:\Users\spare\AppData\Local\Temp\claude\C--Users-spare-source-repos-learn\515605f1-4f43-4be8-b806-602d45816b1f\scratchpad\exportdir\other.txt, maybe it is not allowed on the scope for `allow-write-text-file` permission in your capability file
```

La elección del usuario es la concesión, para ese único archivo. El scope vive en memoria; el [plugin persisted-scope](https://v2.tauri.app/plugin/persisted-scope/) lo conserva entre reinicios (*por verificar*, no se usa aquí). Un scope estático se escribe en cambio en la capability, con un objeto en lugar de la cadena:

```json
{
  "identifier": "fs:allow-write-text-file",
  "allow": [{ "path": "$DOCUMENT/chords/*" }]
}
```

`$DOCUMENT`, `$APPDATA`, `$HOME` y las demás variables se resuelven según el sistema operativo, y las entradas `deny` prevalecen sobre las `allow` (*por verificar*: esta capability no es la del curso).

## Rust no está restringido

Los favoritos sobreviven ahora a un reinicio, y ninguna capability concede el store. El lado Rust lo abre al arrancar y guarda cada cambio anunciado por el evento de la lección 18 (de [`src-tauri/src/lib.rs`, líneas 62-74](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/src/lib.rs#L62-L74)):

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

Después de añadir `Am7` a los favoritos, `%APPDATA%\dev.learn.chord-explorer\favorites.json` contenía:

```json
{
  "favorites": [
    "Am7"
  ]
}
```

mientras que `store.load` desde la página seguía rechazándose. Los permisos filtran las llamadas IPC que vienen del webview; el código Rust llama directamente a la API Rust del plugin. Ese es el diseño al que apuntar: mantén pequeños los permisos de la página y pon el trabajo privilegiado detrás de tus propios comandos, que validan sus argumentos.

Tus propios comandos, en cambio, no se deniegan por defecto: cualquier ventana puede llamar a cualquier comando de `generate_handler!`. Para que también necesiten un permiso, enuméralos en [`AppManifest::commands`](https://docs.rs/tauri-build/2.6.3/tauri_build/struct.AppManifest.html#method.commands) en `build.rs` y luego concede `allow-<command>` en una capability (*por verificar*: la aplicación del curso no lo hace).

## shell y opener

Dos plugins se parecen y difieren en un orden de magnitud en riesgo:

- [opener](https://v2.tauri.app/plugin/opener/) (2.5.5) abre una URL en el navegador por defecto, o un archivo con su aplicación por defecto. Es lo que hacía `shell.open` en Tauri 1.
- [shell](https://v2.tauri.app/plugin/shell/) (2.3.6) ejecuta programas. Su permiso recibe un scope por programa, con un validador para cada argumento:

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

Ese ejemplo de la documentación de Tauri muestra el peligro más que una recomendación: `sh -c` con cualquier argumento no vacío permite a la página ejecutar cualquier cosa. Si la página necesita ejecutar un programa, concede ese programa con argumentos fijos o validados de forma estricta, o mejor aún, escribe un comando Rust que lo ejecute.

## La Content Security Policy

La plantilla de la lección 16 venía con `"csp": null`. El `tauri.conf.json` del curso define una (de [`src-tauri/tauri.conf.json`, líneas 18-20](https://github.com/spareilleux/learn/blob/2ce5e72/code/rust-for-csharp-java/l16-tauri/src-tauri/tauri.conf.json#L18-L20)):

```json
    "security": {
      "csp": "default-src 'self'; connect-src ipc: http://ipc.localhost"
    }
```

- `default-src 'self'`: scripts, estilos, imágenes y fuentes vienen solo de los recursos propios de la aplicación;
- `connect-src ipc: http://ipc.localhost`: `fetch` puede llegar al IPC de Tauri y a nada más. Sin esta línea, el propio `invoke` quedaría bloqueado, ya que el IPC viaja por esas dos URL.

Tauri añade esta política a los recursos que sirve, y al compilar le añade los hashes y nonces de los scripts y estilos empaquetados. En el build de release del explorador, un `fetch` a una API remota registró, en la consola de las DevTools:

```text
[security error] Connecting to 'https://api.github.com/zen' violates the following Content Security Policy directive: "connect-src ipc: http://ipc.localhost". The action has been blocked.
[javascript error] Fetch API cannot load https://api.github.com/zen. Refused to connect because it violates the document's Content Security Policy.
```

Con `tauri dev` y Vite, el mismo `fetch` desde la página en `http://localhost:5173` devolvió `200`. Allí la página la sirve Vite, no Tauri, así que la política no se aplicó. Prueba la CSP en un build, no solo en desarrollo.

Lo que aporta una CSP en una aplicación de escritorio: si un atacante consigue inyectar un script, este no puede cargar más código de otro sitio ni enviar datos fuera con `fetch`. Cargar scripts remotos desde un CDN la anula. Empaquétalos en su lugar.

## Puntos clave

- El webview se trata como no fiable: cada comando de plugin se rechaza hasta que una capability concede un permiso para esa ventana.
- Una capability enumera permisos; un permiso permite comandos y puede llevar un scope. Prefiere `allow-<command>` a los conjuntos `default` y `*-all`, y lee lo que escribió `tauri add`.
- Los scopes restringen los recursos: `fs:allow-write-text-file` por sí solo no escribe en ninguna parte, y el diálogo concede exactamente el archivo que eligió el usuario.
- Las capabilities filtran lo que llama la página, no lo que hace Rust: el store usado desde Rust no necesitó nada, y tus propios comandos se pueden llamar por defecto.
- La CSP de `tauri.conf.json` se aplica a la aplicación compilada, no a la página de un servidor de desarrollo; mantén en ella `connect-src ipc: http://ipc.localhost`.

## Ejercicios

1. El explorador también debería *importar* favoritos desde un archivo de texto que elija el usuario. ¿Qué dos permisos necesita la capability, y qué no debería contener?

<details>
<summary>Solución</summary>

`dialog:allow-open` para mostrar el diálogo de apertura, y `fs:allow-read-text-file` para leer el archivo. `open` añade la ruta elegida al scope de fs igual que `save` (líneas 195-212 del mismo `commands.rs`), así que no hace falta un scope estático.

No debería contener `fs:default`, que concede la lectura de las carpetas propias de la aplicación, inútil aquí, ni `fs:read-all`. Un diseño más estricto no tiene ningún permiso fs: la página obtiene la ruta del diálogo y llama a un comando Rust `import_favorites(path)`, que lee el archivo, valida cada símbolo con `theory` y actualiza el estado.

</details>

2. Una dependencia npm del frontend está comprometida y ejecuta su propio script en la página del explorador. Con las capabilities del curso, enumera lo que puede hacer y lo que no.

<details>
<summary>Solución</summary>

Puede:

- llamar a todos los comandos de la aplicación (`generate_handler!` los expone a todas las ventanas), por ejemplo llenar los favoritos de basura, que Rust guarda luego en el store;
- abrir el diálogo de guardado y, si el usuario elige un archivo, escribir cualquier contenido en ese archivo;
- usar `core:default` (eventos, información de la ventana, …).

No puede:

- leer ni escribir ningún otro archivo: no hay permiso de lectura, y el scope de escritura solo contiene rutas que eligió el usuario;
- ejecutar un programa ni abrir una URL: shell y opener ni siquiera están registrados;
- enviar lo que encuentre a un servidor con `fetch`, ni cargar más código desde una URL, en la aplicación compilada: la CSP lo bloquea. Hacer navegar la ventana a otro sitio es otra cuestión, la CSP no rige la navegación (*por verificar*).

</details>

3. Un diseñador quiere una fuente de Google Fonts en la aplicación compilada. ¿Qué directivas de la CSP deben cambiar, y qué propondrías en su lugar?

<details>
<summary>Solución</summary>

La hoja de estilos viene de `https://fonts.googleapis.com` y los archivos de fuente de `https://fonts.gstatic.com`, así que `style-src 'self' https://fonts.googleapis.com` y `font-src 'self' https://fonts.gstatic.com`, conservando `default-src 'self'` y el `connect-src` para el IPC. El propio ejemplo de Tauri en su página sobre la CSP usa exactamente esos dos hosts.

Mejor: descarga los archivos de fuente, ponlos en `frontend/` y deja que Vite los empaquete. La CSP se queda en `'self'`, la aplicación funciona sin conexión y no se envía nada sobre el usuario a un tercero cuando arranca la aplicación.

</details>

## Fuentes

- [Tauri 2 — Security](https://v2.tauri.app/security/), [Capabilities](https://v2.tauri.app/security/capabilities/), [Permissions](https://v2.tauri.app/security/permissions/), [Command scopes](https://v2.tauri.app/security/scope/), [Content Security Policy](https://v2.tauri.app/security/csp/)
- [Tauri 2 — Dialog](https://v2.tauri.app/plugin/dialog/), [File System](https://v2.tauri.app/plugin/file-system/), [Store](https://v2.tauri.app/plugin/store/), [Opener](https://v2.tauri.app/plugin/opener/), [Shell](https://v2.tauri.app/plugin/shell/)
- [tauri-apps/plugins-workspace](https://github.com/tauri-apps/plugins-workspace): el código fuente de los plugins y sus carpetas `permissions/`
- [Electron — Context Isolation](https://www.electronjs.org/docs/latest/tutorial/context-isolation) y [Security checklist](https://www.electronjs.org/docs/latest/tutorial/security)
- [MDN — Content Security Policy](https://developer.mozilla.org/docs/Web/HTTP/Guides/CSP)
