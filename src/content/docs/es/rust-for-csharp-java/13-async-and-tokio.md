---
title: 13. async y tokio
description: async/await sin runtime integrado — futures perezosos, tareas de tokio, join!, select!, cancelación y la regla Send a través de .await.
sidebar:
  order: 13
---

Ejemplo completo: [`examples/l13_async.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l13_async.rs) — `cargo run --example l13_async`.

## Las mismas palabras clave, otra maquinaria

La sintaxis te resultará familiar ([líneas 8-11](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l13_async.rs#L8-L11)):

```rust
async fn fetch_price(item: &str, delay_ms: u64) -> u32 {
    sleep(Duration::from_millis(delay_ms)).await;   // E/S simulada
    item.len() as u32 * 10
}
```

Fíjate en que `.await` es una palabra clave **postfija**: `fetch(url).await?.json().await?` se encadena de izquierda a derecha, donde C# necesita `await (await fetch(url)).Json()`.

Hay tres cosas que difieren radicalmente de C#:

| | [`Task`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task) en C# / [`CompletableFuture`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/CompletableFuture.html) en Java | [`Future`](https://doc.rust-lang.org/std/future/trait.Future.html) en Rust |
|---|---|---|
| Empieza a ejecutarse | de inmediato, al crearse («caliente») | solo cuando se espera con await o se lanza con spawn («perezoso») |
| Runtime | integrado (thread pool, [`SynchronizationContext`](https://learn.microsoft.com/dotnet/api/system.threading.synchronizationcontext)) | ninguno en la biblioteca estándar — eliges un crate, normalmente **tokio** |
| Coste | normalmente un objeto asignado en el heap por tarea | una máquina de estados que genera el compilador; sin asignación salvo si se lanza con spawn o se mete en un box |

## Los futures son perezosos

Una `async fn` devuelve un **future**: un valor que describe un trabajo que todavía no ha empezado.

De [`examples/l13_async.rs`, líneas 28-34](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l13_async.rs#L28-L34):

```rust
let future = async {
    println!("  future body runs");
    1
};
println!("future created");
let one = future.await;
println!("awaited: {one}");
```

```text
future created
  future body runs
awaited: 1
```

En C#, olvidar `await` sigue ejecutando la tarea (fire-and-forget). En Rust, un future que nunca se espera **nunca se ejecuta**. El compilador te avisa:

```rust
async fn log_call(name: &str) {
    println!("called {name}");
}

#[tokio::main]
async fn main() {
    log_call("save");         // falta .await
    println!("done");
}
```

```text
warning: unused implementer of `Future` that must be used
 --> examples\w13_not_awaited.rs:7:5
  |
7 |     log_call("save");
  |     ^^^^^^^^^^^^^^^^
  |
  = note: futures do nothing unless you `.await` or poll them
  = note: `#[warn(unused_must_use)]` (part of `#[warn(unused)]`) on by default
```

El programa imprime `done` y nada más. Cuando sí usas el resultado, un `.await` olvidado es un error de tipos: el future no es el valor.

```text
error[E0308]: mismatched types
 --> examples\e13_missing_await.rs:6:22
  |
6 |     let price: u32 = fetch_price();
  |                ---   ^^^^^^^^^^^^^ expected `u32`, found future
  |                |
  |                expected due to this
  |
note: calling an async function returns a future
 --> examples\e13_missing_await.rs:6:22
  |
6 |     let price: u32 = fetch_price();
  |                      ^^^^^^^^^^^^^
help: consider `await`ing on the `Future`
  |
6 |     let price: u32 = fetch_price().await;
  |                                   ++++++
```

## Un runtime: tokio

Algo tiene que sondear (poll) los futures, despertarlos cuando la E/S está lista y planificarlos en hilos. La biblioteca estándar no incluye esa pieza, así que `main` no puede ser `async` sin más:

```text
error[E0752]: `main` function is not allowed to be `async`
 --> examples\e13_async_main.rs:1:1
  |
1 | async fn main() {
  | ^^^^^^^^^^^^^^^ `main` function is not allowed to be `async`
```

[tokio](https://tokio.rs) es el runtime estándar de facto ([axum](https://docs.rs/axum), [reqwest](https://docs.rs/reqwest), [tonic](https://docs.rs/tonic) y la mayor parte del ecosistema async se apoyan en él):

```toml
[dependencies]
tokio = { version = "1", features = ["rt-multi-thread", "macros", "time", "sync"] }
```

De [`examples/l13_async.rs`, líneas 25-31](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l13_async.rs#L25-L31):

```rust
#[tokio::main]              // construye un runtime multihilo y ejecuta main en él
async fn main() {
    // …
}
```

`.await` además solo se permite dentro de código `async` ([`E0728`](https://doc.rust-lang.org/error_codes/E0728.html)). El puente desde el código síncrono es el [`block_on`](https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html#method.block_on) del runtime, al que [`#[tokio::main]`](https://docs.rs/tokio/latest/tokio/attr.main.html) llama por ti.

## Concurrencia: `join!`, `spawn`, `JoinSet`

Esperar un future tras otro es **secuencial** ([líneas 38-48](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l13_async.rs#L38-L48)):

```rust
let a = fetch_price("book", 100).await;
let b = fetch_price("pen", 100).await;
let c = fetch_price("lamp", 100).await;

let (a, b, c) = tokio::join!(fetch_price("book", 100), fetch_price("pen", 100), fetch_price("lamp", 100));
```

```text
sequential: 110 in ~300 ms
join!:      110 in ~100 ms
```

Aquí se nota la pereza: en C#, `var t1 = FetchAsync(); var t2 = FetchAsync(); await t1; await t2;` ya es concurrente porque ambas tareas empezaron al crearse. En Rust, el código equivalente se ejecuta uno detrás de otro; la concurrencia se pide explícitamente.

| C# | Java | tokio |
|---|---|---|
| [`await Task.WhenAll(a, b)`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall) | `CompletableFuture.allOf(a, b)` | [`tokio::join!(a, b)`](https://docs.rs/tokio/latest/tokio/macro.join.html) |
| [`Task.Run(…)`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.run) | `CompletableFuture.supplyAsync(…)` | [`tokio::spawn(async { … })`](https://docs.rs/tokio/latest/tokio/task/fn.spawn.html) |
| [`Task.WhenAny`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenany) en un bucle | [`ExecutorCompletionService`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ExecutorCompletionService.html) | [`JoinSet::join_next()`](https://docs.rs/tokio/latest/tokio/task/struct.JoinSet.html#method.join_next) |
| `await Task.WhenAny(a, b)` | `CompletableFuture.anyOf(a, b)` | [`tokio::select!`](https://docs.rs/tokio/latest/tokio/macro.select.html) |
| [`Task.Delay`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.delay) | `CompletableFuture.delayedExecutor` | [`tokio::time::sleep`](https://docs.rs/tokio/latest/tokio/time/fn.sleep.html) |
| [`Channel<T>`](https://learn.microsoft.com/dotnet/api/system.threading.channels.channel-1) | [`BlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/BlockingQueue.html) | [`tokio::sync::mpsc`](https://docs.rs/tokio/latest/tokio/sync/mpsc/index.html) |
| [`SemaphoreSlim.WaitAsync`](https://learn.microsoft.com/dotnet/api/system.threading.semaphoreslim.waitasync) | [`Semaphore`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Semaphore.html) | [`tokio::sync::Semaphore`](https://docs.rs/tokio/latest/tokio/sync/struct.Semaphore.html) |

`join!` ejecuta sus futures de forma concurrente **dentro de la tarea actual**. `tokio::spawn` entrega un future al runtime como **tarea** independiente, que puede ejecutarse en otro hilo, y devuelve un [`JoinHandle`](https://docs.rs/tokio/latest/tokio/task/struct.JoinHandle.html) ([líneas 52-53](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l13_async.rs#L52-L53)):

```rust
let handle = tokio::spawn(async { fetch_price("keyboard", 50).await });
println!("spawned task returned {}", handle.await.unwrap());   // 80
```

`JoinSet` recoge los resultados en orden de finalización ([líneas 56-63](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l13_async.rs#L56-L63)):

```rust
let mut set = JoinSet::new();
for (item, delay) in [("slow", 150), ("fast", 50), ("medium", 100)] {
    set.spawn(async move { (item, fetch_price(item, delay).await) });
}
while let Some(result) = set.join_next().await {
    let (item, price) = result.unwrap();
    println!("  finished {item}: {price}");
}
```

```text
  finished fast: 40
  finished medium: 60
  finished slow: 40
```

## Cancelar es liberar

C# pasa un [`CancellationToken`](https://learn.microsoft.com/dotnet/api/system.threading.cancellationtoken) a través de cada llamada. En Rust, un future que se **libera** (drop) simplemente se detiene en su `.await` actual y nunca se reanuda. [`timeout`](https://docs.rs/tokio/latest/tokio/time/fn.timeout.html) y `select!` se basan en eso ([líneas 66-73](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l13_async.rs#L66-L73)):

```rust
match timeout(Duration::from_millis(50), fetch_price("late", 200)).await {
    Ok(price) => println!("got {price}"),
    Err(_) => println!("timed out after 50 ms"),
}

tokio::select! {
    price = fetch_price("tortoise", 200) => println!("tortoise won: {price}"),
    price = fetch_price("hare", 20) => println!("hare won: {price}"),
}
```

```text
timed out after 50 ms
hare won: 40
```

El future de la tortuga se libera en cuanto gana la liebre. Los destructores se ejecutan, así que los recursos se liberan. La trampa es la *cancellation safety* (seguridad frente a la cancelación): si un future se libera a mitad de, por ejemplo, la lectura de un mensaje, ese trabajo parcial se pierde. La documentación de tokio tiene una sección *cancel safety* para los métodos en los que esto importa.

Una tarea lanzada con spawn sigue ejecutándose después de que se libere su `JoinHandle`; detenla con [`handle.abort()`](https://docs.rs/tokio/latest/tokio/task/struct.JoinHandle.html#method.abort).

## `Send` a través de `.await`

El runtime multihilo puede mover una tarea a otro hilo en cualquier `.await`. Por eso `tokio::spawn` exige que el future sea `Send` — y un future contiene cada variable local que vive a través de un `.await`. Vuelve el problema de `Rc` de la lección 12 ([`src/lib.rs`, líneas 1036-1040](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L1036-L1040)):

```rust
let handle = tokio::spawn(async {
    let counter = Rc::new(0);
    sleep(Duration::from_millis(10)).await;
    println!("{counter}");
});
```

```text
error: future cannot be sent between threads safely
   --> examples\e13_not_send.rs:6:18
    |
  6 |       let handle = tokio::spawn(async {
    |  __________________^
  7 | |         let counter = Rc::new(0);
  8 | |         sleep(Duration::from_millis(10)).await;
  9 | |         println!("{counter}");
 10 | |     });
    | |______^ future created by async block is not `Send`
    |
    = help: within `{async block@examples\e13_not_send.rs:6:31: 6:36}`, the trait `Send` is not implemented for `Rc<i32>`
note: future is not `Send` as this value is used across an await
   --> examples\e13_not_send.rs:8:42
    |
  7 |         let counter = Rc::new(0);
    |             ------- has type `Rc<i32>` which is not `Send`
  8 |         sleep(Duration::from_millis(10)).await;
    |                                          ^^^^^ await occurs here, with `counter` maybe used later
```

Este error no tiene código `E`: viene de la restricción `F: Future + Send + 'static` de `tokio::spawn`. La solución es usar `Arc`, o asegurarse de que el valor se libere antes del `.await`.

Lo mismo se aplica a un [`std::sync::MutexGuard`](https://doc.rust-lang.org/std/sync/struct.MutexGuard.html) (ejercicio 3). Cuando hay que mantener un bloqueo **a través** de un `.await`, usa [`tokio::sync::Mutex`](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html), cuyo `lock()` es a su vez asíncrono:

```rust
let cache = Arc::new(tokio::sync::Mutex::new(Vec::new()));
// en cada tarea:
let mut guard = cache.lock().await;
let price = fetch_price(item, 10).await;     // la guarda se mantiene durante este await
guard.push(price);
```

Para secciones críticas cortas sin ningún `.await` dentro, el `Mutex` estándar es más rápido y sirve perfectamente.

## No bloquees el runtime

Un hilo de trabajo async ejecuta muchas tareas y cambia de una a otra en cada `.await`. El código que bloquea sin esperar — [`std::thread::sleep`](https://doc.rust-lang.org/std/thread/fn.sleep.html), la E/S síncrona de archivos o de red, un cálculo largo — congela todas las tareas de ese hilo. El equivalente en C# es llamar a [`.Result`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task-1.result) o hacer trabajo de CPU en un hilo de interfaz o de ASP.NET.

De [`examples/l13_async.rs`, líneas 109-111](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l13_async.rs#L109-L111):

```rust
let primes = tokio::task::spawn_blocking(|| (1..100_000u64).filter(|&n| is_prime(n)).count())
    .await
    .unwrap();
// primes below 100000: 9592
```

[`spawn_blocking`](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html) ejecuta una closure en un pool aparte reservado al trabajo bloqueante. Para el cálculo paralelo sobre datos, rayon (lección 12) sigue siendo la mejor herramienta.

:::note[Java tomó el otro camino]
Los [*hilos virtuales*](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) de Java 21 permiten escribir código bloqueante normal mientras la JVM multiplexa por debajo hilos ligeros — sin ninguna palabra clave `async`. Rust y C# eligieron en su lugar un `async`/`await` explícito: más sintaxis, pero sin runtime oculto y, en el caso de Rust, con futures que no cuestan ninguna asignación.
:::

## Puntos clave

- Los futures de Rust son perezosos: nada se ejecuta hasta que haces `.await` o los lanzas con spawn; un `.await` olvidado es una advertencia o un error de tipos.
- El runtime es una biblioteca: `#[tokio::main]`, `tokio::spawn`, `tokio::time`, `tokio::sync`.
- La concurrencia es explícita: `join!` y `JoinSet` para «todos», `select!` y `timeout` para «el primero».
- Cancelar significa liberar el future; piensa en lo que deja atrás un future a medio terminar.
- Los futures lanzados con spawn deben ser `Send`: nada de `Rc` ni de `std::sync::MutexGuard` a través de un `.await`.
- No bloquees nunca un hilo async; usa `spawn_blocking` o rayon para el trabajo de CPU.

## Ejercicios

1. Escribe `async fn fetch_all(items: &[(&str, u64)]) -> Vec<u32>`, que obtiene todos los precios de forma concurrente (cada artículo con su propio retardo) y devuelve los precios **en el orden de entrada**. Con retardos de 150, 10 y 80 ms, ¿cuánto debería tardar?

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 1050-1068](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L1050-L1068):

```rust
async fn fetch_price(item: String, delay_ms: u64) -> u32 {
    sleep(Duration::from_millis(delay_ms)).await;
    item.len() as u32 * 10
}

async fn fetch_all(items: &[(&str, u64)]) -> Vec<u32> {
    let handles: Vec<_> = items
        .iter()
        .map(|&(item, delay)| tokio::spawn(fetch_price(item.to_string(), delay)))
        .collect();
    let mut prices = Vec::with_capacity(handles.len());
    for handle in handles {
        prices.push(handle.await.unwrap());
    }
    prices
}

let prices = fetch_all(&[("slow", 150), ("fast", 10), ("medium", 80)]).await;
assert_eq!(prices, [40, 40, 60]);   // ~150 ms, no 240 ms
```

Todas las tareas empiezan al lanzarse, así que el total es el retardo más largo, unos 150 ms. Esperar los handles en orden conserva el orden de entrada; un `JoinSet` daría en cambio el orden de finalización. `fetch_price` recibe un `String` porque una tarea lanzada con spawn debe ser `'static` y no puede tomar prestado `items`.

</details>

2. Escribe `async fn fetch_with_retry(delays: &[u64], per_try: Duration) -> Result<u32, String>`: el intento `i` llama a una obtención que tarda `delays[i]` ms, abandona ese intento tras `per_try` y pasa al siguiente. Devuelve el primer éxito, o un error tras el último intento.

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 1077-1094](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L1077-L1094):

```rust
async fn fetch_price(delay_ms: u64) -> u32 {
    sleep(Duration::from_millis(delay_ms)).await;
    42
}

async fn fetch_with_retry(delays: &[u64], per_try: Duration) -> Result<u32, String> {
    for (attempt, &delay) in delays.iter().enumerate() {
        match timeout(per_try, fetch_price(delay)).await {
            Ok(price) => return Ok(price),
            Err(_) => println!("attempt {} timed out", attempt + 1),
        }
    }
    Err(format!("gave up after {} attempts", delays.len()))
}

let per_try = Duration::from_millis(50);
assert_eq!(fetch_with_retry(&[5_000, 5_000, 10], per_try).await, Ok(42));
assert_eq!(fetch_with_retry(&[5_000, 5_000], per_try).await, Err("gave up after 2 attempts".to_string()));
```

Cada intento que agota su tiempo se libera, así que las esperas de 5 segundos nunca terminan y no cuestan nada después. No hay ningún token que pasar a través de `fetch_price`.

</details>

3. Esto no compila. Lee el error y corrígelo de dos maneras distintas.

```rust
let hits = Arc::new(std::sync::Mutex::new(0));
let h = Arc::clone(&hits);
tokio::spawn(async move {
    let mut guard = h.lock().unwrap();
    sleep(Duration::from_millis(10)).await;
    *guard += 1;
})
.await
.unwrap();
```

```text
error: future cannot be sent between threads safely
   --> examples\e13_guard_await.rs:8:5
    |
  8 | /     tokio::spawn(async move {
  9 | |         let mut guard = h.lock().unwrap();
 10 | |         sleep(Duration::from_millis(10)).await;
 11 | |         *guard += 1;
 12 | |     })
    | |______^ future created by async block is not `Send`
    |
    = help: within `{async block@examples\e13_guard_await.rs:8:18: 8:28}`, the trait `Send` is not implemented for `std::sync::MutexGuard<'_, i32>`
note: future is not `Send` as this value is used across an await
   --> examples\e13_guard_await.rs:10:42
    |
  9 |         let mut guard = h.lock().unwrap();
    |             --------- has type `std::sync::MutexGuard<'_, i32>` which is not `Send`
 10 |         sleep(Duration::from_millis(10)).await;
    |                                          ^^^^^ await occurs here, with `mut guard` maybe used later
```

<details>
<summary>Solución</summary>

**Solución 1** — no mantengas la guarda a través del `.await`. Bloquea solo para la actualización ([`src/lib.rs`, líneas 1126-1129](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L1126-L1129)):

```rust
tokio::spawn(async move {
    sleep(Duration::from_millis(10)).await;
    *h.lock().unwrap() += 1;          // la guarda se libera al final de la sentencia
})
```

**Solución 2** — usa un mutex asíncrono, cuya guarda es `Send` y puede mantenerse mientras se espera:

```rust
let hits = Arc::new(tokio::sync::Mutex::new(0));
let h = Arc::clone(&hits);
tokio::spawn(async move {
    let mut guard = h.lock().await;
    sleep(Duration::from_millis(10)).await;
    *guard += 1;
})
```

Prefiere la solución 1 cuando la sección crítica no necesita ningún `.await`: es más barata, y mantener un bloqueo mientras se espera la E/S ralentiza todas las demás tareas. Usa la solución 2 cuando la propia operación protegida es asíncrona.

</details>

## Fuentes

- [The Book, ch. 17 — Fundamentals of Asynchronous Programming](https://doc.rust-lang.org/book/ch17-00-async-await.html)
- [Asynchronous Programming in Rust](https://rust-lang.github.io/async-book/)
- [Tutorial de Tokio](https://tokio.rs/tokio/tutorial) — lanzamiento de tareas, estado compartido, canales, `select!`
- [`tokio::task::JoinSet`](https://docs.rs/tokio/latest/tokio/task/struct.JoinSet.html) y [`tokio::select!`](https://docs.rs/tokio/latest/tokio/macro.select.html) (seguridad frente a la cancelación)
- [`tokio::task::spawn_blocking`](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html)
