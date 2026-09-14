---
title: 12. Hilos, Send/Sync, Mutex y rayon
description: Concurrencia sin miedo — hilos, hilos con ámbito, estado compartido, canales, atómicos y paralelismo de datos, con las carreras de datos rechazadas en tiempo de compilación.
sidebar:
  order: 12
---

Ejemplo completo: [`examples/l12_threads.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l12_threads.rs) — `cargo run --example l12_threads`.

## Lo que el compilador comprueba por ti

En C# y Java, el compilador te deja sin problema que dos hilos escriban en la misma `List<T>`. El bug aparece más tarde, quizá una vez de cada mil ejecuciones, en forma de datos corruptos o de una excepción lejos de su causa.

Las reglas de ownership y de préstamo de Rust — *un escritor o muchos lectores* — son exactamente las reglas que impiden las **carreras de datos** (data races). Aplicadas a los hilos, convierten una carrera de datos en un error de compilación. La comunidad de Rust lo llama *fearless concurrency* (concurrencia sin miedo).

Lo que Rust **no** impide: los interbloqueos (deadlocks), las condiciones de carrera de más alto nivel (comprobar y luego actuar) y la inanición. Eso sigue siendo cosa tuya.

## `thread::spawn`

De [`examples/l12_threads.rs`, líneas 6](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L6), [17-19](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L17-L19):

```rust
use std::thread;

let names = [String::from("ada"), String::from("grace")];
let handle = thread::spawn(move || names.iter().map(|n| n.len()).sum::<usize>());
println!("total name length: {}", handle.join().unwrap());   // 8
```

| Rust | C# | Java |
|---|---|---|
| [`thread::spawn(closure)`](https://doc.rust-lang.org/std/thread/fn.spawn.html) | `new Thread(...).Start()` / [`Task.Run`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.run) | `new Thread(...).start()` |
| `handle.join()` devuelve el resultado de la closure | `thread.Join()` (sin resultado) / `await task` | `thread.join()` (sin resultado) / `future.get()` |
| `join()` devuelve `Err` si el hilo entró en pánico | excepción relanzada por `Task` | [`ExecutionException`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ExecutionException.html) |

El hilo nuevo puede sobrevivir a la función que lo inició, así que no puede tomar prestadas las variables locales de esa función ([lección 9](../09-lifetimes/), `'static`). Olvidar `move` da un error muy directo ([`src/lib.rs`, líneas 890-894](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L890-L894)):

```rust
let names = vec!["ada", "grace"];
let handle = thread::spawn(|| {
    println!("{names:?}");
});
```

```text
error[E0373]: closure may outlive the current function, but it borrows `names`, which is owned by the current function
 --> e12_no_move.rs:5:32
  |
5 |     let handle = thread::spawn(|| {
  |                                ^^ may outlive borrowed value `names`
6 |         println!("{names:?}");
  |                    ----- `names` is borrowed here
  |
note: function requires argument type to outlive `'static`
…
help: to force the closure to take ownership of `names` (and any other referenced variables), use the `move` keyword
  |
5 |     let handle = thread::spawn(move || {
  |                                ++++
```

## Hilos con ámbito: se permite tomar prestado

[`thread::scope`](https://doc.rust-lang.org/std/thread/fn.scope.html) garantiza que cada hilo lanzado dentro de él se une (join) antes de que `scope` retorne, así que esos hilos con ámbito (scoped threads) **sí pueden** tomar prestados datos locales ([líneas 22-29](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L22-L29)):

```rust
let data: Vec<u64> = (1..=1_000).collect();
let chunk_sums: Vec<u64> = thread::scope(|s| {
    let handles: Vec<_> = data
        .chunks(250)
        .map(|chunk| s.spawn(move || chunk.iter().sum::<u64>()))   // mueve el slice &[u64], no los datos
        .collect();
    handles.into_iter().map(|h| h.join().unwrap()).collect()
});
// chunk sums: [31375, 93875, 156375, 218875], total 500500
```

Tomar prestado sigue las reglas habituales. Dos hilos que modifican el mismo contador son una carrera de datos, y no compila ([`src/lib.rs`, líneas 900-904](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L900-L904)):

```rust
let mut count = 0;
thread::scope(|s| {
    s.spawn(|| count += 1);
    s.spawn(|| count += 1);
});
```

```text
error[E0499]: cannot borrow `count` as mutable more than once at a time
   --> e12_race.rs:7:17
    |
  5 |     thread::scope(|s| {
    |                    - has type `&'1 Scope<'1, '_>`
  6 |         s.spawn(|| count += 1);
    |         ----------------------
    |         |       |  |
    |         |       |  first borrow occurs due to use of `count` in closure
    |         |       first mutable borrow occurs here
    |         argument requires that `count` is borrowed for `'1`
  7 |         s.spawn(|| count += 1);
    |                 ^^ ----- second borrow occurs due to use of `count` in closure
    |                 |
    |                 second mutable borrow occurs here
```

El equivalente en C# — `count++` desde dos tareas — compila y pierde incrementos en silencio.

## `Send` y `Sync`

Dos marker traits, implementados automáticamente por el compilador, deciden qué puede cruzar la frontera de un hilo:

- **[`Send`](https://doc.rust-lang.org/std/marker/trait.Send.html)**: un valor de este tipo puede **moverse** a otro hilo.
- **[`Sync`](https://doc.rust-lang.org/std/marker/trait.Sync.html)**: un valor puede **compartirse** por referencia entre hilos (`T` es `Sync` cuando `&T` es `Send`).

Casi todos los tipos son ambas cosas. Las excepciones son las herramientas de un solo hilo de la [lección 11](../11-smart-pointers/):

| Tipo | `Send` | `Sync` | Por qué |
|---|---|---|---|
| `i32`, `String`, `Vec<T>`… | sí | sí | datos simples con propietario |
| `Rc<T>` | no | no | contador de referencias no atómico |
| `Arc<T>` (con `T: Send + Sync`) | sí | sí | contador atómico |
| `Cell<T>`, `RefCell<T>` | sí | **no** | mutabilidad interior sin sincronizar |
| [`Mutex<T>`](https://doc.rust-lang.org/std/sync/struct.Mutex.html) (con `T: Send`) | sí | sí | el acceso está sincronizado |

`thread::spawn` exige que su closure sea `Send`, así que todo lo que captura también debe serlo. Compartir un `RefCell` mediante un `Arc` falla — y el compilador sugiere la alternativa segura entre hilos ([`src/lib.rs`, líneas 913-915](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L913-L915)):

```rust
let total = Arc::new(RefCell::new(0));
let t = Arc::clone(&total);
thread::spawn(move || *t.borrow_mut() += 1).join().unwrap();
```

```text
error[E0277]: `RefCell<i32>` cannot be shared between threads safely
   --> e12_refcell_sync.rs:8:19
    |
  8 |     thread::spawn(move || *t.borrow_mut() += 1).join().unwrap();
    |     ------------- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `RefCell<i32>` cannot be shared between threads safely
    |     |
    |     required by a bound introduced by this call
    |
    = help: the trait `Sync` is not implemented for `RefCell<i32>`
    = note: if you want to do aliasing and mutation between multiple threads, use `std::sync::RwLock` instead
    = note: required for `Arc<RefCell<i32>>` to implement `Send`
```

C# y Java no tienen esta distinción: la seguridad entre hilos es un comentario en la documentación. En Rust forma parte del tipo.

## Estado compartido: `Arc<Mutex<T>>`

Un [`lock (obj) { … }`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/lock) de C# protege código; nada impide que otro método toque la lista sin bloquear. Un `Mutex<T>` de Rust **es dueño** de los datos, y la única forma de llegar a ellos es `lock()` ([`src/lib.rs`, línea 921](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L921)):

```rust
let count = std::sync::Mutex::new(0);
*count += 1;
```

```text
error[E0614]: type `std::sync::Mutex<{integer}>` cannot be dereferenced
 --> e12_mutex_no_lock.rs:5:5
  |
5 |     *count += 1;
  |     ^^^^^^ can't be dereferenced
```

Combinado con `Arc` para el ownership compartido:

```rust
use std::sync::{Arc, Mutex};

let results = Arc::new(Mutex::new(Vec::new()));
let workers: Vec<_> = (1..=4)
    .map(|id| {
        let results = Arc::clone(&results);
        thread::spawn(move || {
            let square = id * id;
            results.lock().unwrap().push((id, square));   // se desbloquea al final de la sentencia
        })
    })
    .collect();
for worker in workers {
    worker.join().unwrap();
}
// squares: [(1, 1), (2, 4), (3, 9), (4, 16)]   (tras ordenar)
```

- `lock()` devuelve una **guarda** (guard, [`MutexGuard`](https://doc.rust-lang.org/std/sync/struct.MutexGuard.html)) que se desreferencia a los datos. El bloqueo se libera cuando se destruye la guarda — sin `finally`, sin `unlock()` olvidado como con el [`ReentrantLock`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/locks/ReentrantLock.html) de Java.
- `lock()` devuelve un `Result`: si un hilo **entró en pánico** mientras tenía el bloqueo, el mutex queda [*envenenado*](https://doc.rust-lang.org/std/sync/struct.Mutex.html#poisoning) (poisoned) y las llamadas posteriores a `lock()` devuelven `Err`. `.unwrap()` propaga ese pánico, que suele ser lo que quieres.
- Mantén corto el ámbito de la guarda. Conservarla durante una llamada lenta bloquea a todos los demás — y dos hilos que toman dos bloqueos en orden inverso siguen provocando un interbloqueo.

[`RwLock<T>`](https://doc.rust-lang.org/std/sync/struct.RwLock.html) permite muchos lectores o un solo escritor, como [`ReaderWriterLockSlim`](https://learn.microsoft.com/dotnet/api/system.threading.readerwriterlockslim) o [`ReentrantReadWriteLock`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/locks/ReentrantReadWriteLock.html) ([líneas 80-86](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L80-L86)):

```rust
let settings = RwLock::new(HashMap::from([("mode", "fast")]));
{
    let a = settings.read().unwrap();
    let b = settings.read().unwrap();      // dos lectores a la vez, sin problema
}
settings.write().unwrap().insert("mode", "safe");
```

## Atómicos

Para un contador o un indicador, un bloqueo es excesivo ([líneas 3](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L3), [54-63](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L54-L63)):

```rust
use std::sync::atomic::{AtomicUsize, Ordering};

let hits = AtomicUsize::new(0);
thread::scope(|s| {
    for _ in 0..8 {
        s.spawn(|| {
            for _ in 0..1_000 {
                hits.fetch_add(1, Ordering::Relaxed);
            }
        });
    }
});
// hits: 8000
```

`fetch_add` es [`Interlocked.Increment`](https://learn.microsoft.com/dotnet/api/system.threading.interlocked.increment) / [`AtomicInteger.getAndAdd`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/AtomicInteger.html#getAndAdd(int)). El argumento [`Ordering`](https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html) describe la garantía de ordenación de memoria que necesitas; para un contador independiente basta con `Relaxed` (el libro *Rust Atomics and Locks*, enlazado más abajo, explica los demás). Fíjate en que los hilos con ámbito toman prestado `hits` sin `Arc`: un atómico es `Sync`.

## Canales: compartir comunicando

En lugar de compartir datos, los hilos pueden enviarse valores. Enviar **mueve** el valor, así que el emisor ya no puede tocarlo después ([líneas 4](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L4), [67-76](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L67-L76)):

```rust
use std::sync::mpsc;

let (sender, receiver) = mpsc::channel();
for id in 0..3 {
    let sender = sender.clone();            // un emisor por hilo
    thread::spawn(move || {
        sender.send(format!("worker {id} done")).unwrap();
    });
}
drop(sender);                               // si no, el bucle de abajo nunca termina
let messages: Vec<String> = receiver.iter().collect();
// ["worker 0 done", "worker 1 done", "worker 2 done"]   (tras ordenar)
```

[`mpsc`](https://doc.rust-lang.org/std/sync/mpsc/index.html) significa *multiple producer, single consumer* (varios productores, un consumidor). El equivalente en C# es [`System.Threading.Channels.Channel<T>`](https://learn.microsoft.com/dotnet/api/system.threading.channels.channel-1) o [`BlockingCollection<T>`](https://learn.microsoft.com/dotnet/api/system.collections.concurrent.blockingcollection-1); en Java, una [`BlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/BlockingQueue.html). El iterador del receptor termina cuando se han liberado todos los `Sender` — olvidar `drop(sender)` es el bloqueo clásico.

## Paralelismo de datos con rayon

Para «haz esto con cada elemento, en todos los núcleos», no gestiones los hilos tú mismo. El crate [rayon](https://docs.rs/rayon) convierte una cadena de iteradores en una paralela — el equivalente de [PLINQ](https://learn.microsoft.com/dotnet/standard/parallel-programming/introduction-to-plinq) y su [`AsParallel()`](https://learn.microsoft.com/dotnet/api/system.linq.parallelenumerable.asparallel), o de [`parallelStream()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collection.html#parallelStream()) de Java:

```toml
[dependencies]
rayon = "1"
```

De [`examples/l12_threads.rs`, líneas 1-13](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L1-L13), [90-99](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L90-L99):

```rust
use rayon::prelude::*;

fn is_prime(n: u64) -> bool {
    n >= 2 && (2..).take_while(|d| d * d <= n).all(|d| !n.is_multiple_of(d))
}

let sequential = (1..200_000u64).filter(|&n| is_prime(n)).count();
let parallel = (1..200_000u64).into_par_iter().filter(|&n| is_prime(n)).count();
// primes below 200000: 17984 sequential, 17984 parallel

let mut words = vec!["pear", "fig", "apple", "kiwi"];
words.par_sort_unstable();
let lengths: Vec<usize> = words.par_iter().map(|w| w.len()).collect();   // se conserva el orden
// ["apple", "fig", "kiwi", "pear"] [5, 3, 4, 4]
```

| Secuencial | rayon |
|---|---|
| `.iter()` | `.par_iter()` |
| `.into_iter()` | `.into_par_iter()` |
| `.iter_mut()` | `.par_iter_mut()` |
| `.sort()` | `.par_sort()` |

rayon ejecuta el trabajo en un pool con un hilo por núcleo y lo reparte con *work stealing* (robo de trabajo), como el [thread pool de .NET](https://learn.microsoft.com/dotnet/standard/threading/the-managed-thread-pool) y el [`ForkJoinPool`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ForkJoinPool.html) de Java. Sus closures deben ser [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html) (sin mutación de variables capturadas) y `Send + Sync`, así que la carrera de datos de antes no puede colarse de nuevo ([`src/lib.rs`, líneas 929-930](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L929-L930)):

```rust
let mut seen = 0;
let doubled: Vec<i32> = (1..100).into_par_iter().map(|n| { seen += 1; n * 2 }).collect();
```

```text
error[E0594]: cannot assign to `seen`, as it is a captured variable in a `Fn` closure
 --> src\main.rs:5:64
  |
4 |     let mut seen = 0;
  |         -------- `seen` declared here, outside the closure
5 |     let doubled: Vec<i32> = (1..100).into_par_iter().map(|n| { seen += 1; n * 2 }).collect();
  |                                                          ---   ^^^^^^^^^ cannot assign
  |                                                          |
  |                                                          in this closure
```

Usa `.count()`, o un [`AtomicUsize`](https://doc.rust-lang.org/std/sync/atomic/type.AtomicUsize.html), en su lugar.

En mi máquina (Intel Core Ultra 9 285K, 24 núcleos, compilación release), contar los primos por debajo de 5.000.000 tardó **unos 775 ms** en secuencial y **unos 41 ms** con `into_par_iter()` — consulta el ejercicio 3.

:::note[¿Hilos o async?]
Los hilos (y rayon) sirven para el trabajo **limitado por la CPU** (CPU-bound): todos los núcleos calculan. Para el trabajo **limitado por la E/S** (I/O-bound) — miles de peticiones de red que pasan casi todo el tiempo esperando — lo que quieres es `async`, el tema de la lección 13.
:::

## Puntos clave

- Las reglas de préstamo prohíben las carreras de datos, así que una carrera de datos es un error de compilación; los interbloqueos siguen siendo posibles.
- `thread::spawn` necesita `move` y datos `'static`; `thread::scope` permite que los hilos tomen prestadas variables locales.
- `Send` (puede moverse a un hilo) y `Sync` (puede compartirse entre hilos) los comprueba el compilador; `Rc` y `RefCell` no son seguros entre hilos.
- `Mutex<T>` es dueño de sus datos: no puedes olvidarte de bloquear, y la guarda desbloquea al destruirse. Compártelo con `Arc`.
- Atómicos para los contadores, canales para pasar el ownership entre hilos, rayon para el paralelismo de datos.

## Ejercicios

1. Escribe `fn parallel_sum(data: &[u64], threads: usize) -> u64`, que divide `data` en como máximo `threads` trozos y los suma en hilos con ámbito. Debe funcionar con un slice vacío y con más hilos que elementos.

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 936-946](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L936-L946):

```rust
fn parallel_sum(data: &[u64], threads: usize) -> u64 {
    let chunk_size = data.len().div_ceil(threads.max(1)).max(1);
    std::thread::scope(|s| {
        let handles: Vec<_> = data
            .chunks(chunk_size)
            .map(|chunk| s.spawn(move || chunk.iter().sum::<u64>()))
            .collect();
        handles.into_iter().map(|h| h.join().unwrap()).sum()
    })
}

let data: Vec<u64> = (1..=10_001).collect();
assert_eq!(parallel_sum(&data, 4), 50_015_001);
assert_eq!(parallel_sum(&data, 64), 50_015_001);
assert_eq!(parallel_sum(&[], 4), 0);
```

`chunks` entra en pánico con un tamaño de 0, de ahí los dos `max(1)`. Los handles se recogen en un `Vec` **antes** de unirlos: unirlos dentro del mismo `map` esperaría a cada hilo antes de lanzar el siguiente, y el código se ejecutaría en secuencial.

</details>

2. Escribe `fn count_words(texts: &[&str]) -> HashMap<String, usize>` (sin distinguir mayúsculas de minúsculas), que procesa cada texto en su propio hilo. Usa un canal en lugar de un `Arc<Mutex<HashMap>>`. ¿Por qué es un mejor diseño aquí?

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 952-980](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L952-L980):

```rust
use std::collections::HashMap;
use std::sync::mpsc;

fn count_words(texts: &[&str]) -> HashMap<String, usize> {
    let (sender, receiver) = mpsc::channel();
    std::thread::scope(|s| {
        for &text in texts {
            let sender = sender.clone();
            s.spawn(move || {
                let mut local = HashMap::new();
                for word in text.split_whitespace() {
                    *local.entry(word.to_lowercase()).or_insert(0) += 1;
                }
                sender.send(local).unwrap();
            });
        }
    });
    drop(sender);

    let mut total = HashMap::new();
    for local in receiver {
        for (word, n) in local {
            *total.entry(word).or_insert(0) += n;
        }
    }
    total
}

let counts = count_words(&["the cat", "The dog", "a cat and THE end"]);
assert_eq!(counts["the"], 3);
assert_eq!(counts["cat"], 2);
assert_eq!(counts.len(), 6);
```

Cada hilo trabaja sobre su propio mapa sin bloqueos y lo envía una sola vez al terminar. Con un `Mutex<HashMap>` compartido, cada palabra tomaría el bloqueo, así que los hilos pasarían la mayor parte del tiempo esperándose unos a otros. El canal sin límite almacena los mapas en búfer, así que los hilos pueden terminar antes de que `main` los lea.

</details>

3. Cuenta los primos por debajo de 5.000.000 con el `is_prime` de esta lección, en secuencial y con rayon, y cronometra ambos con [`std::time::Instant`](https://doc.rust-lang.org/std/time/struct.Instant.html) en una compilación **release** (`cargo run --release`). Comprueba que ambos recuentos son iguales. ¿Cuánto se acerca la aceleración a «número de núcleos ×»?

<details>
<summary>Solución</summary>

```rust
use rayon::prelude::*;
use std::time::Instant;

let limit = 5_000_000u64;

let start = Instant::now();
let sequential = (1..limit).filter(|&n| is_prime(n)).count();
let seq_time = start.elapsed();

let start = Instant::now();
let parallel = (1..limit).into_par_iter().filter(|&n| is_prime(n)).count();
let par_time = start.elapsed();

assert_eq!(parallel, sequential);
println!("{sequential} primes in {seq_time:.2?} sequential, {parallel} in {par_time:.2?} parallel on {} threads", rayon::current_num_threads());
```

En mi máquina:

```text
348513 primes in 770.75ms sequential, 348513 in 41.76ms parallel on 24 threads
```

Unas 18× con 24 núcleos. La aceleración queda por debajo de 24× porque esta CPU mezcla núcleos de rendimiento y de eficiencia, y porque dividir y unir tiene un coste. Además, comprobar números grandes lleva más tiempo que comprobar pequeños, así que los trozos son desiguales. Por lo demás, la tarea es ideal: cada número es independiente. Mide siempre en modo release; los tiempos de una compilación de depuración no son representativos.

</details>

## Fuentes

- [The Book, ch. 16 — Fearless Concurrency](https://doc.rust-lang.org/book/ch16-00-concurrency.html)
- [`std::thread::scope`](https://doc.rust-lang.org/std/thread/fn.scope.html)
- [`std::marker::Send`](https://doc.rust-lang.org/std/marker/trait.Send.html) y [`Sync`](https://doc.rust-lang.org/std/marker/trait.Sync.html)
- [`std::sync::Mutex`](https://doc.rust-lang.org/std/sync/struct.Mutex.html) — incluido el envenenamiento
- [Documentación de rayon](https://docs.rs/rayon)
- [Mara Bos, *Rust Atomics and Locks*](https://mara.nl/atomics/) — gratis en línea
