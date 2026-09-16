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
- [ ] Lección 19 — El frontend: Vite, TypeScript y tipos generados
- [ ] Lección 20 — Seguridad: capabilities, CSP y plugins
- [ ] Lección 21 — Tests y empaquetado

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

## Preguntas abiertas

- ¿Se abre y funciona la ventana del explorador en WSLg, en Ubuntu con WebKitGTK 4.1 y en macOS? La CI demuestra que compila y que sus pruebas pasan allí, no que la ventana funcione (*por verificar*).
- ¿Cambia `tauri-runtime-cef` de Tauri 3 las cifras de tamaño y memoria lo bastante como para importar? Es una alfa a fecha de 2026-09-13.
- ¿Cómo se compara `rust-analyzer` en RustRover con VS Code para estos ejercicios?
