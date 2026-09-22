---
title: Diario
description: Notas de progreso fechadas del curso de Rust — intentos, sorpresas y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Lección 1 — Cadena de herramientas y Cargo
- [x] Lección 2 — Tipos, mutabilidad y expresiones
- [x] Lección 3 — Ownership y movimientos
- [x] Lección 4 — Préstamos y cadenas
- [x] Lección 5 — Structs, enums y pattern matching
- [x] Lección 6 — `Option`, `Result` y `?`
- [x] Lección 7 — Traits y genéricos
- [x] Lección 8 — Colecciones e iteradores
- [x] Lección 9 — Tiempos de vida (lifetimes)
- [x] Lección 10 — Módulos, crates y workspaces
- [x] Lección 11 — `Box`, `Rc`, `Arc`, `RefCell`
- [x] Lección 12 — Hilos, `Send`/`Sync`, `Mutex`, rayon
- [x] Lección 13 — `async` y tokio
- [x] Lección 14 — Tests, docs, clippy, fmt
- [x] Lección 15 — Macros, `unsafe` y FFI
- [x] Lección 16 — Interfaces de escritorio en Rust, y luego Tauri
- [x] Lección 17 — Comandos de Tauri
- [x] Lección 18 — Estado, eventos y canales
- [x] Lección 19 — El frontend: Vite, TypeScript y tipos generados
- [x] Lección 20 — Seguridad: capabilities, CSP y plugins
- [x] Lección 21 — Tests, empaquetado y distribución

## QA

rustc, cargo, Tauri y las crates de su entorno. Una fila es el único hallazgo de este repositorio que ya estaba abierto aguas arriba cuando el curso se topó con él, y la columna Estado nombra la incidencia en lugar de dar a entender que la abrió el curso. Nada más de aquí se ha reportado.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| `cargo test` ejecuta los tests de una aplicación Tauri | Cada ejecutable de test moría antes de correr un test: `tauri-build` solo incrusta el manifiesto de Common Controls v6 en los binarios | `tauri-build`, Tauri 2.11.5, Windows | `STATUS_ENTRYPOINT_NOT_FOUND` | Abierto aguas arriba desde mayo de 2025 como [tauri#13419](https://github.com/tauri-apps/tauri/issues/13419), no abierto por este curso. Sorteado en `build.rs` con `cargo:rustc-link-arg-tests` [2026-09-15](#2026-09-15--lecciones-16-a-18-aplicaciones-de-escritorio-con-tauri) |
| `compile_fail,E0382` comprueba que el código de error sea el que se nombra | En stable solo comprueba que la compilación falle | `cargo test --doc`, rustc 1.94.0 | Un doctest marcado `compile_fail,E0999` alrededor de un uso tras mover pasaba igualmente. `cargo +nightly test --doc` sí compara los códigos | Reproducido; limitación documentada. La CI ahora corre también nightly [2026-09-13](#2026-09-13--lecciones-1-a-4) |
| La documentación de Tauri compila y apunta a Tauri 2 | El ejemplo de error de la página *Calling Rust* no compila, su ejemplo de `AppHandle` usa API de Tauri 1, y la página *State management* describe un pánico que la 2.11.5 no produce | tauri-docs en el commit `a6b59b7` | `Ok(format!(value))`; `GlobalShortcutManager` y `app_dir`; olvidar `.manage()` compila y la llamada se rechaza en ejecución con `state not managed for field …`, solo `Manager::state` entra en pánico | Reproducido contra la 2.11.5, no reportado [2026-09-15](#2026-09-15--lecciones-16-a-18-aplicaciones-de-escritorio-con-tauri) |
| `create-tauri-app` genera un proyecto de escritorio actual | Imprime un comando de móvil como primer paso de un proyecto de escritorio, y su plantilla está desfasada | `create-tauri-app` 4.7.4 | `npm run tauri android init`; la plantilla usa la edición 2021 y `"csp": null` | Reproducido, no reportado [2026-09-15](#2026-09-15--lecciones-16-a-18-aplicaciones-de-escritorio-con-tauri) |
| La ruta que recomienda la página de WebDriver de Tauri es la rápida | Es unas noventa veces más lenta | `@wdio/tauri-service` | Dos tests tardaban 1 min 30 s, porque espera 5 s antes de cada comando a un segundo plugin que el curso no usa. WebdriverIO a secas contra el servidor incrustado los pasa en un segundo aproximadamente | Reproducido, no reportado [2026-09-16](#2026-09-16--lecciones-19-a-21-frontend-seguridad-tests-y-empaquetado) |
| `tauri dev` aplica la CSP | No la aplica | Tauri 2.11.5 con Vite | Un `fetch` a una API remota devolvió `200` en desarrollo y quedó bloqueado por una violación de `connect-src` en la build de publicación | Reproducido; una falsa sensación de seguridad propia del desarrollo [2026-09-16](#2026-09-16--lecciones-19-a-21-frontend-seguridad-tests-y-empaquetado) |
| El origen de la página del runtime de prueba es el mismo en todas partes | `http://tauri.localhost` solo es el origen en Windows y Android; macOS y Linux usan `tauri://localhost` | runtime de prueba de Tauri 2.11.5 | En la primera pasada de CI las capacidades rechazaban cada llamada con `not allowed. Plugin not found` | Reproducido en CI, corregido en el código del curso [2026-09-15](#2026-09-15--lecciones-16-a-18-aplicaciones-de-escritorio-con-tauri) |
| Una llamada rechazada lo es con el tipo de error del comando | Los rechazos propios de Tauri devuelven una cadena, y las dos builds la redactan distinto | ACL de Tauri 2.11.5 | La página mostraba `undefined: undefined`. Desarrollo: `dialog.save not allowed. Permissions associated with this command: …`; publicación: `Command plugin:store|load not allowed by ACL` | Reproducido [2026-09-15](#2026-09-15--lecciones-16-a-18-aplicaciones-de-escritorio-con-tauri) · [2026-09-16](#2026-09-16--lecciones-19-a-21-frontend-seguridad-tests-y-empaquetado) |
| `cargo fmt --check --manifest-path …` se comporta igual en cualquier cargo reciente | Funciona en local y falla en los ejecutores | Cargo 1.94.0 en local, 1.98.1 en los ejecutores | `Failed to find targets`. La CI ahora ejecuta `cargo fmt --check` desde la carpeta de cada crate | Reproducido, cambio entre versiones, no reportado [2026-09-13](#2026-09-13--lecciones-13-a-15-y-tres-sistemas-operativos) |
| ts-rs y serde_json coinciden en un `u128` | ts-rs lo tipa como `bigint` mientras serde_json envía un número corriente | ts-rs con serde_json | `tsc` rechazó `elapsedMs / 1000` para el `elapsed_ms: u128` de la lección 18. Sorteado con `#[ts(type = "number")]` | Reproducido [2026-09-16](#2026-09-16--lecciones-19-a-21-frontend-seguridad-tests-y-empaquetado) |
| Vitest comprueba los tipos de los tests que ejecuta | No los comprueba | Vitest | Un test construido con `elapsedMs: 3` pasaba mientras `tsc` rechazaba el mismo archivo | Por diseño, documentado [2026-09-16](#2026-09-16--lecciones-19-a-21-frontend-seguridad-tests-y-empaquetado) |
| Un comando síncrono no congela la aplicación | Congela la ventana nativa, aunque la vista web siga funcionando | Tauri 2.11.5, Windows | Durante una búsqueda de un segundo los temporizadores de la página seguían, pero la ventana nativa no respondió a `WM_NULL` durante 945 ms y todos los demás comandos esperaron | Reproducido; por diseño [2026-09-15](#2026-09-15--lecciones-16-a-18-aplicaciones-de-escritorio-con-tauri) |
| El mensaje de pánico de `RefCell` coincide con lo publicado | Ha cambiado | biblioteca estándar de Rust 1.94 | La 1.94 dice `RefCell already borrowed`; los textos más antiguos citan `already borrowed: BorrowMutError` | Reproducido; envejecimiento de la documentación de todo el ecosistema [2026-09-13](#2026-09-13--lecciones-5-a-8) |
| Una enumeración recursiva da un error claro | Da dos, uno de ellos sobre un ciclo en la consulta interna del compilador | rustc 1.94.0 | `E0391` además de `E0072` | Reproducido; ruido de diagnóstico [2026-09-13](#2026-09-13--lecciones-5-a-8) |
| `[lints] missing_docs = "warn"` cubre la biblioteca | También cubre los tests de integración, porque cada archivo de `tests/` es su propia crate | lints de Cargo | Cada uno necesita su propia línea `//!` | Por diseño, sorprendente [2026-09-13](#2026-09-13--lecciones-9-a-12) |
| Un `.await` olvidado deja que el trabajo se ejecute igual | El código no se ejecuta en absoluto, al revés que en C#, donde la tarea arranca de todos modos | Rust asíncrono | Ninguna salida, ningún error | Por diseño; la mayor trampa para un lector que viene de C# [2026-09-13](#2026-09-13--lecciones-9-a-12) |
| `tauri build` usa las herramientas de empaquetado ya instaladas | Se las descarga él mismo la primera vez, con comprobación de huella | CLI de Tauri 2.11.4 | WiX 3.14 y NSIS 3.11 | Reproducido; un hecho de cadena de suministro que conviene saber [2026-09-16](#2026-09-16--lecciones-19-a-21-frontend-seguridad-tests-y-empaquetado) |
| Veinte segundos bastan al servidor WebDriver incrustado en CI | No en Linux, y demasiado en Windows | ejecutores de CI | `ubuntu-latest` no respondió en 20 s; con 60 s, el valor por defecto de WebdriverIO en CI, responde tras unos 25 s. `windows-latest` respondió en 394 ms, antes de que la página hubiera enganchado sus manejadores: el primer test pulsaba un formulario HTML a secas | Reproducido en CI, corregido por ambos lados [2026-09-16](#2026-09-16--lecciones-19-a-21-frontend-seguridad-tests-y-empaquetado) |

## Experimentos

Cinco de estas siete estaban equivocadas, y ahí está la gracia: en este curso una predicción suele escribirse en un doctest o en una afirmación de la lección, así que la compilación falla cuando se equivoca en lugar de reescribirse sin ruido. La única hipótesis que solo se recordó después lo dice.

| Pregunta | Hipótesis | Resultado | Veredicto | Dónde |
|---|---|---|---|---|
| ¿Comprueba `compile_fail,E0382` el código de error? | Escrita como la pregunta propia del diario, antes de la respuesta | Un doctest marcado `compile_fail,E0999` alrededor de un uso tras mover pasaba igualmente en stable 1.94.0 | Refutada; la CI ahora corre también nightly, que sí compara los códigos | [2026-09-13](#2026-09-13--lecciones-1-a-4) |
| ¿Vale `pricing_sum([19.99, 5.0, 12.5])` exactamente 37,49? | Escrita en el test de FFI de la lección 15 como aserción, antes de ejecutarlo | La suma real en `f64` vale 37,489999999999995. C# imprimía 37,49 solo por su formato `F2` | Refutada, por un test que falló | [2026-09-13](#2026-09-13--lecciones-13-a-15-y-tres-sistemas-operativos) |
| ¿Puede `cheapest` tomar un `Vec<Box<dyn Priced>>` con una restricción `T: Priced + ?Sized`? | Afirmada en la lección 7 antes de compilar | Falso: `&[T]` exige `T: Sized`. La versión que funciona implementa `Priced` para `Box<dyn Priced>` | Refutada | [2026-09-13](#2026-09-13--lecciones-5-a-8) |
| ¿Marshala `[LibraryImport]` un `bool` como `BOOL` de cuatro bytes por defecto? | Escrita en el material antes de compilar | No tiene ningún valor por defecto: la compilación falla con `SYSLIB1051` hasta que se añade un `[MarshalAs]`. Ese era el comportamiento de `[DllImport]` | Refutada | [2026-09-13](#2026-09-13--lecciones-13-a-15-y-tres-sistemas-operativos) |
| ¿Cómo falla un `map` de rayon que modifica un contador capturado? | Se supuso que fallaría por `Send`/`Sync`; la suposición queda registrada después | Falla antes: las closures de rayon son `Fn`, de ahí `E0594: cannot assign to a captured variable in a Fn closure` | Refutada | [2026-09-13](#2026-09-13--lecciones-5-a-8) |
| ¿Terminan tres esperas concurrentes de tokio en menos de 290 ms? | Afirmada en un doctest de la lección 13 antes de que la CI lo ejecutara | Cierto en la máquina del autor, pero una aserción temporal es un test inestable en ejecutores compartidos. El test ya solo comprueba los resultados | Confirmada en local, retirada como aserción | [2026-09-13](#2026-09-13--lecciones-9-a-12) |
| ¿Se comporta el desbordamiento de enteros distinto en los dos perfiles? | Una afirmación documentada, comprobada a propósito en vez de repetida | `255u8 + 1` entra en pánico en debug y da la vuelta en release. C# da la vuelta en ambos, salvo `checked` | Confirmada | [2026-09-13](#2026-09-13--lecciones-1-a-4) |

## 2026-09-13 — Lecciones 1 a 4

- Cadena de herramientas en mi máquina: `rustc 1.94.0`, `cargo 1.94.0`, edición 2024 por defecto para `cargo new`.
- Cada fragmento se compiló antes de escribirse en una lección; los errores del compilador están copiados de la salida real de `rustc` (solo se recortaron las largas notas «other types implement this trait»).
- El código del curso vive en [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java): `examples/` ejecutables y doctests `compile_fail` en `src/lib.rs`, verificados por el workflow de GitHub *Rust course examples*.

**Sorpresas viniendo de C#:**

- El desbordamiento de enteros **provoca un pánico** en las compilaciones de depuración, pero **da la vuelta** en las compilaciones release — verificado con `255u8 + 1` compilado de las dos maneras. C# da la vuelta en ambos casos salvo con `checked`.
- Clippy marcó `let scores = vec![90, 72, 85, 60];` como `useless_vec` porque el vector solo se leía como slice — bastaba con un array.
- El error del borrow checker para «push mientras se itera» es la versión en tiempo de compilación de `InvalidOperationException: Collection was modified`.

**Resuelto: ¿comprueba `compile_fail,E0382` el código de error?** No en stable. Un doctest marcado `compile_fail,E0999` alrededor de un uso tras un movimiento (en realidad `E0382`) seguía pasando con `cargo test --doc` en 1.94.0 — stable solo comprueba que la compilación falla. El workflow de CI ahora también ejecuta `cargo +nightly test --doc`, que sí compara los códigos.

## 2026-09-13 — Lecciones 5 a 8

Cada solución de ejercicio es ahora también un doctest: 41 doctests en total (fragmentos compile-fail más soluciones), todos en verde en 1.94.0.

**Errores que los tests detectaron antes de publicar:**

- Primero escribí `prices.sort_by(|a, b| a.total_cmp(b))` sobre `vec![19.99, 5.0, 12.5]`. No compila: los literales siguen siendo un `{float}` sin decidir cuando se comprueban los tipos de la closure (`E0599: no method named total_cmp found for reference &{float}`). Anotar `Vec<f64>` lo arregla — la lección 8 lo explica ahora.
- En la lección 7 afirmé que `cheapest` podía recibir un `Vec<Box<dyn Priced>>` con una restricción `T: Priced + ?Sized`. Falso: `&[T]` exige `T: Sized`. La versión que funciona implementa `Priced` para `Box<dyn Priced>`, y eso es lo que el ejercicio muestra (y prueba) ahora.
- Clippy rechazó `(1..=5).fold(1, |acc, n| acc * n)` en favor de `.product()` (`unnecessary_fold`), así que el ejemplo de `fold` calcula un par mín/máx — algo que ningún adaptador hace por sí solo.

**Sorpresas viniendo de C#:**

- Cuando `main` devuelve `Err`, Rust imprime el error con su formato `Debug` (`Error: Missing("port")`), no `Display`, y termina con el código 1.
- `Vec<f64>::sort()` no compila en absoluto (`f64` no es `Ord`), mientras que C# y Java ordenan doubles sin rechistar.
- El mensaje `E0004` para una nueva variante de enum nombra el patrón exacto que falta (`&Payment::Crypto { .. } not covered`) — mejor que cualquier advertencia de analizador de C# que conozca.

## 2026-09-13 — Lecciones 9 a 12

76 doctests ahora (stable y nightly), más un workspace real de dos crates para la lección 10 (`code/rust-for-csharp-java/l10-workspace`) que la CI prueba, analiza y ejecuta. El crate del curso ganó su primera dependencia: `rayon`, como dev-dependency.

**Cosas que primero hice mal:**

- En el ejemplo de la lección 9 usé `drop(parser)` para mostrar que los tokens sobreviven al parser. Clippy lo rechazó (`drop_non_drop`): hacer drop de un tipo sin impl de `Drop` no sirve de nada. Una función `tokenize` cuyo parser local muere al final demuestra lo mismo mejor.
- Clippy también me enseñó `u64::is_multiple_of` (`manual_is_multiple_of`) en lugar de `n % d != 0`.
- Supuse que un `map` de rayon que muta un contador capturado fallaría con un error de `Send`/`Sync`. Falla antes: las closures de rayon son `Fn`, así que es `E0594: cannot assign to a captured variable in a Fn closure`.

**Sorpresas:**

- El mensaje de pánico de `RefCell` en 1.94 es simplemente `RefCell already borrowed`; el material más antiguo cita `already borrowed: BorrowMutError`.
- Escribir `&str` en lugar de `&'a str` como tipo de retorno de un método compila sin problema — el error solo aparece en el punto de llamada, cuando intentas conservar dos tokens (`E0499`). La elisión eligió el lifetime de `&mut self`.
- Un enum recursivo sin `Box` da `E0391` (un ciclo en la consulta «needs drop» del compilador) además de `E0072`.
- rayon en esta máquina (Core Ultra 9 285K, 24 núcleos): contar los primos por debajo de 5.000.000 pasó de ~775 ms a ~41 ms, unas 18×.

## 2026-09-13 — Lecciones 13 a 15, y tres sistemas operativos

El curso principal está completo. El código tiene ahora tokio como dev-dependency, dos crates pequeños más (`l14-testing`, y `l15-ffi` con un cliente .NET 10), y la CI lo ejecuta todo en **Windows, Ubuntu y macOS**. El programa C# llama con éxito a la biblioteca Rust en los tres.

**Cosas que primero hice mal:**

- El test FFI de la lección 15 afirmaba `pricing_sum([19.99, 5.0, 12.5]) == 37.49`. La suma `f64` real es `37.489999999999995`; C# había impreso `37.49` solo por su formato `F2`.
- Un comentario XML del `.csproj` contenía `--release`: MSBuild se niega a cargar un proyecto cuyo comentario contiene `--`.
- Escribí que `[LibraryImport]` serializa `bool` como un `BOOL` de 4 bytes por defecto. No tiene ningún valor por defecto: la compilación falla con `SYSLIB1051` hasta que añades `[MarshalAs]`. Ese era el comportamiento de `[DllImport]`.
- `cargo fmt --check --manifest-path …` funcionaba en mi máquina (Cargo 1.94) pero fallaba en los runners de CI (Cargo 1.98.1) con `Failed to find targets`. La CI ahora ejecuta `cargo fmt --check` desde la carpeta de cada crate.
- `missing_docs = "warn"` en `[lints]` también se aplica a los tests de integración: cada archivo de `tests/` es su propio crate y necesita una línea `//!`.
- Un doctest de la lección 13 afirmaba que tres esperas concurrentes terminan en menos de 290 ms. Es cierto en mi máquina, pero una aserción de tiempo es un test inestable en runners de CI compartidos, así que el test ahora solo comprueba los resultados.
- Incluso sin aserción de tiempo, un retardo sigue siendo una carrera: en un runner macOS sobrecargado, un intento de 200 ms «tuvo éxito» a pesar de un `timeout` de 50 ms (cuando el runtime se despierta después de ambos plazos, `timeout` sondea primero el future, y este ya está listo). Los intentos lentos del ejercicio 2 duran ahora 5 segundos; el test sigue siendo rápido porque se abandonan tras 50 ms.

**Sorpresas:**

- En Rust asíncrono, un `.await` olvidado significa que el código **nunca se ejecuta** — lo contrario de C#, donde la tarea arranca de todos modos.
- El error «future cannot be sent between threads safely» no tiene código `E`: viene de la restricción `Send` de `tokio::spawn`, no del lenguaje.
- La edición 2024 exige `unsafe extern "C"` y `#[unsafe(no_mangle)]`; mucho material FFI antiguo ya no compila tal cual.
- `cargo fmt` nunca se había ejecutado en este curso: 30 diferencias de formato en doce lecciones de ejemplos.
- Hello world en modo release: unos 130 KB en Windows, 430–460 KB en Linux y macOS (runners de CI, Cargo 1.98.1).

## 2026-09-15 — Lecciones 16 a 18: aplicaciones de escritorio con Tauri

Empieza la parte 2. El curso construye ahora un explorador de acordes con Tauri 2.11.5 en `l16-tauri`, un workspace aparte con su propio `Cargo.lock` y su `package-lock.json`. La CI lo compila, lo analiza y lo prueba en Windows, Ubuntu y macOS, con un build release en cada uno; la ventana en sí solo se ha ejecutado en Windows.

**Cosas que primero hice mal:**

- El primer `cargo test` de la aplicación Tauri compiló, y luego cada ejecutable de test murió con `STATUS_ENTRYPOINT_NOT_FOUND` antes de ejecutar un test. `tauri-build` integra el manifiesto de Common Controls v6 solo en los binarios ([tauri#13419](https://github.com/tauri-apps/tauri/issues/13419), abierta desde mayo de 2025). La corrección en `build.rs` pasa el mismo manifiesto al enlazador para los targets de test con `cargo:rustc-link-arg-tests`.
- La página mostraba `undefined: undefined` para algunos errores: cuando es Tauri quien rechaza una llamada (comando desconocido, argumentos inválidos), la promesa se rechaza con una **cadena**, no con el objeto de error del comando.
- Mi primer script para controlar la ventana mediante el protocolo DevTools se conectó a `127.0.0.1:9222`, donde ya escuchaba otro programa de esta máquina; la instancia de WebView2 estaba en `[::1]:9222`. No se envió nada al destino equivocado; el script ahora indica `[::1]`, y las ejecuciones posteriores usaron otro puerto.
- Mi envoltorio de `tauri dev` esperaba la línea ``Running ` ``, que nunca coincidía porque Cargo colorea su salida: la espera tiene que quitar los códigos de escape.
- Las pruebas con el runtime mock enviaban `http://tauri.localhost` como URL de la página. Ese es el origen solo en Windows y Android; macOS y Linux usan `tauri://localhost`, así que en la primera ejecución de la CI las capabilities rechazaron allí cada llamada con `not allowed. Plugin not found`. Las pruebas eligen ahora el origen según la plataforma (commit `2253508`).

**Sorpresas:**

- Un comando síncrono se ejecuta en el hilo principal. Durante una búsqueda de un segundo, los temporizadores JavaScript de la página siguieron funcionando (el webview es otro proceso), pero la ventana nativa no respondió a `WM_NULL` durante 945 ms, y todos los demás comandos esperaron.
- Olvidar `.manage()` compila; la llamada se rechaza en ejecución con `state not managed for field …`. La guía de Tauri dice que un tipo `State` que no coincide provoca un panic: en 2.11.5 un comando se rechaza, y solo `Manager::state` hace panic.
- `#[tauri::command]` convierte errores en errores de compilación inusuales: `blocking_kind … IpcResponse` para un tipo de retorno sin `Serialize`, `E0255 __cmd__…` para un comando `pub` en la raíz del crate, `AsyncCommandMustReturnResult` para un comando `async` que toma prestado.
- El ejecutable release pesa 4,2 MB, frente a 385 MB de un Electron 44.3.0 descomprimido; con la ventana abierta, el proceso Rust usa 5,6 MB de memoria privada y los seis procesos de WebView2 unos 170 MB.
- `create-tauri-app` 4.7.4 muestra `npm run tauri android init` como primer paso de un proyecto de escritorio, y su plantilla usa la edición 2021 y `"csp": null`.

**Encontrado en la documentación de Tauri** (tauri-docs en `a6b59b7`): el ejemplo de error de la página *Calling Rust*, `Ok(format!(value))`, no compila; su ejemplo de `AppHandle` usa API de Tauri 1 (`GlobalShortcutManager`, `app_dir`); y el panic en ejecución de la página *State management* para un tipo que no coincide, citado arriba.

**Dogfooding de IX** (`crates/ix-demo` en `a7e5fbc`, leído, sin cambios): todo el cálculo se ejecuta dentro del `ui` de egui, en el hilo de dibujo (58 manejadores `clicked()`, ni hilos ni canales); la pestaña *Neural Network (ix-nn)* entrena su propia red `ndarray` en lugar de llamar a `ix-nn`; la lista de capas que teclea el usuario descarta en silencio las entradas inválidas; `eframe = "0.31"` cuando la versión actual es la 0.36.2, sin `Cargo.lock` commiteado.

## 2026-09-16 — Lecciones 19 a 21: frontend, seguridad, tests y empaquetado

Termina la parte 2. El explorador recibe un segundo frontend en TypeScript con Vite (seleccionado con `--config`, `ui/` se queda), tipos generados por ts-rs, los plugins dialog, fs y store con una capability `export`, tests Vitest con `mockIPC`, tests WebdriverIO contra el binario de release, e instaladores. La CI comprueba ahora también los bindings generados, ejecuta Vitest y los tests end-to-end, y compila los instaladores en los tres sistemas.

**Cosas que primero hice mal:**

- ts-rs tipó el `elapsed_ms: u128` de la lección 18 como `bigint`, mientras que serde_json envía un número normal: `tsc` rechazó `elapsedMs / 1000`. Corregido con `#[ts(type = "number")]` en el campo.
- Un test Vitest construido con `elapsedMs: 3` pasaba mientras `tsc` rechazaba el mismo archivo: Vitest no comprueba los tipos.
- `@wdio/tauri-service`, la vía que recomienda la página de Tauri sobre WebDriver, hizo que dos tests tardaran 1 min 30 s: antes de cada comando esperaba 5 s a `tauri-plugin-wdio`, un segundo plugin que el curso no usa. WebdriverIO a secas contra el servidor incrustado los ejecuta en más o menos un segundo.
- `browser.keys("Enter")` en el campo del acorde no enviaba el formulario; hacer clic en el botón de envío sí.
- En `ubuntu-latest`, el servidor WebDriver incrustado no respondió dentro de los 20 s que esperaba mi configuración; el propio servicio de WebdriverIO espera 60 s en CI. Con 60 s, el servidor respondió a los 25 s más o menos.
- En `windows-latest`, lo contrario: el servidor respondió a los 394 ms, antes de que la página hubiera enganchado sus handlers, y el primer test hizo clic en un formulario HTML normal. Los tests esperan ahora a que la página haya rellenado desde Rust su lista de calidades.
- Mis primeros intentos de automatizar el diálogo *Guardar como* de Windows mediante UI Automation pulsaban botones que no hacían nada y dejaban dos diálogos abiertos; funcionó fijar el nombre del archivo con `WM_SETTEXT` y enviar `IDOK` con `WM_COMMAND`.

**Sorpresas:**

- Con `tauri dev` y Vite, la CSP no se aplica: un `fetch` a una API remota devolvió `200`, y la misma llamada en el build de release se bloqueó con una violación de `connect-src`.
- Los mensajes de rechazo difieren entre builds: `dialog.save not allowed. Permissions associated with this command: …` en desarrollo, `Command plugin:store|load not allowed by ACL` en release.
- El plugin dialog añade al scope de fs el archivo que elige el usuario, y solo ese archivo: la misma página pudo entonces escribir `favorites.txt` y no `other.txt` en la misma carpeta.
- Un cambio de CSS actualizó la página en caliente y conservó su estado; un cambio en `main.ts` recargó la página, y los favoritos sobrevivieron porque viven en Rust.
- El ejecutable de release pasó de 4,2 MB (lección 16) a 4,9 MB con los tres plugins; el instalador NSIS pesa 1,5 MB y el MSI 2,2 MB, ya que WebView2 no va incrustado. La feature `webdriver` añade 1,2 MB.
- `tauri build` descargó por su cuenta WiX 3.14 y NSIS 3.11 la primera vez, con comprobación de hashes.

**No probado, marcado *por verificar* en las lecciones:** instalar los instaladores, la firma de código y la notarización, el updater (solo se ejecutó `tauri signer generate`), tauri-specta, los scopes estáticos de fs, `AppManifest::commands`, los targets móviles.

## Preguntas abiertas

- ¿Se abre y funciona la ventana del explorador en WSLg, en Ubuntu con WebKitGTK 4.1 y en macOS? La CI demuestra que compila y que sus pruebas pasan allí, no que la ventana funcione (*por verificar*).
- ¿Cambia `tauri-runtime-cef` de Tauri 3 las cifras de tamaño y memoria lo bastante como para importar? Es una alfa a fecha de 2026-09-13.
- ¿Cómo se compara `rust-analyzer` en RustRover con VS Code para estos ejercicios?
