---
title: 12. Threads, Send/Sync, Mutex et rayon
description: La concurrence sans crainte — threads, threads à portée, état partagé, canaux, atomiques et parallélisme de données, avec les data races rejetées à la compilation.
sidebar:
  order: 12
---

Exemple complet : [`examples/l12_threads.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l12_threads.rs) — `cargo run --example l12_threads`.

## Ce que le compilateur vérifie pour vous

En C# et en Java, le compilateur vous laisse volontiers deux threads écrire dans la même `List<T>`. Le bug apparaît plus tard, peut-être une exécution sur mille, sous forme de données corrompues ou d'une exception loin de sa cause.

Les règles de possession et d'emprunt de Rust — *un seul rédacteur ou plusieurs lecteurs* — sont exactement les règles qui empêchent les **data races** (courses de données). Appliquées aux threads, elles font d'une data race une erreur de compilation. La communauté Rust appelle cela la *fearless concurrency* (concurrence sans crainte).

Ce que Rust n'empêche **pas** : les interblocages (deadlocks), les situations de concurrence à plus haut niveau (vérifier-puis-agir) et la famine. Ceux-là restent votre affaire.

## `thread::spawn`

Extrait de [`examples/l12_threads.rs`, lignes 6](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L6), [17-19](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L17-L19) :

```rust
use std::thread;

let names = [String::from("ada"), String::from("grace")];
let handle = thread::spawn(move || names.iter().map(|n| n.len()).sum::<usize>());
println!("total name length: {}", handle.join().unwrap());   // 8
```

| Rust | C# | Java |
|---|---|---|
| [`thread::spawn(closure)`](https://doc.rust-lang.org/std/thread/fn.spawn.html) | `new Thread(...).Start()` / [`Task.Run`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.run) | `new Thread(...).start()` |
| `handle.join()` renvoie le résultat de la closure | `thread.Join()` (pas de résultat) / `await task` | `thread.join()` (pas de résultat) / `future.get()` |
| `join()` renvoie `Err` si le thread a paniqué | exception relancée par `Task` | [`ExecutionException`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ExecutionException.html) |

Le nouveau thread peut survivre à la fonction qui l'a démarré, il ne peut donc pas emprunter les variables locales de cette fonction ([leçon 9](../09-lifetimes/), `'static`). Oublier `move` donne une erreur très directe ([`src/lib.rs`, lignes 890-894](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L890-L894)) :

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

## Threads à portée : l'emprunt est autorisé

[`thread::scope`](https://doc.rust-lang.org/std/thread/fn.scope.html) garantit que chaque thread lancé à l'intérieur est joint avant que `scope` ne rende la main, si bien que ces threads à portée (scoped threads) **peuvent** emprunter des données locales ([lignes 22-29](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L22-L29)) :

```rust
let data: Vec<u64> = (1..=1_000).collect();
let chunk_sums: Vec<u64> = thread::scope(|s| {
    let handles: Vec<_> = data
        .chunks(250)
        .map(|chunk| s.spawn(move || chunk.iter().sum::<u64>()))   // déplace la slice &[u64], pas les données
        .collect();
    handles.into_iter().map(|h| h.join().unwrap()).collect()
});
// chunk sums: [31375, 93875, 156375, 218875], total 500500
```

L'emprunt suit toujours les règles habituelles. Deux threads qui modifient le même compteur, c'est une data race, et cela ne compile pas ([`src/lib.rs`, lignes 900-904](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L900-L904)) :

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

L'équivalent C# — `count++` depuis deux tâches — compile et perd des incréments en silence.

## `Send` et `Sync`

Deux traits marqueurs, implémentés automatiquement par le compilateur, décident de ce qui peut franchir la frontière d'un thread :

- **[`Send`](https://doc.rust-lang.org/std/marker/trait.Send.html)** : une valeur de ce type peut être **déplacée** vers un autre thread.
- **[`Sync`](https://doc.rust-lang.org/std/marker/trait.Sync.html)** : une valeur peut être **partagée** par référence entre threads (`T` est `Sync` quand `&T` est `Send`).

Presque tous les types sont les deux. Les exceptions sont les outils mono-thread de la [leçon 11](../11-smart-pointers/) :

| Type | `Send` | `Sync` | Pourquoi |
|---|---|---|---|
| `i32`, `String`, `Vec<T>`… | oui | oui | données possédées ordinaires |
| `Rc<T>` | non | non | compteur de références non atomique |
| `Arc<T>` (avec `T: Send + Sync`) | oui | oui | compteur atomique |
| `Cell<T>`, `RefCell<T>` | oui | **non** | mutabilité intérieure non synchronisée |
| [`Mutex<T>`](https://doc.rust-lang.org/std/sync/struct.Mutex.html) (avec `T: Send`) | oui | oui | l'accès est synchronisé |

`thread::spawn` exige que sa closure soit `Send`, donc tout ce qu'elle capture doit l'être aussi. Partager un `RefCell` à travers un `Arc` échoue — et le compilateur suggère l'alternative thread-safe ([`src/lib.rs`, lignes 913-915](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L913-L915)) :

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

C# et Java ne font pas cette distinction : la sûreté vis-à-vis des threads est un commentaire dans la documentation. En Rust, elle fait partie du type.

## État partagé : `Arc<Mutex<T>>`

Un [`lock (obj) { … }`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/lock) C# protège du code ; rien n'empêche une autre méthode de toucher la liste sans verrouiller. Un `Mutex<T>` Rust **possède** les données, et le seul moyen de les atteindre est `lock()` ([`src/lib.rs`, ligne 921](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L921)) :

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

Combiné à `Arc` pour la possession partagée :

```rust
use std::sync::{Arc, Mutex};

let results = Arc::new(Mutex::new(Vec::new()));
let workers: Vec<_> = (1..=4)
    .map(|id| {
        let results = Arc::clone(&results);
        thread::spawn(move || {
            let square = id * id;
            results.lock().unwrap().push((id, square));   // déverrouillé à la fin de l'instruction
        })
    })
    .collect();
for worker in workers {
    worker.join().unwrap();
}
// squares: [(1, 1), (2, 4), (3, 9), (4, 16)]   (après tri)
```

- `lock()` renvoie une **garde** (guard, [`MutexGuard`](https://doc.rust-lang.org/std/sync/struct.MutexGuard.html)) qui se déréférence vers les données. Le verrou est relâché quand la garde est détruite — pas de `finally`, pas d'`unlock()` oublié comme avec le [`ReentrantLock`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/locks/ReentrantLock.html) de Java.
- `lock()` renvoie un `Result` : si un thread a **paniqué** en détenant le verrou, le mutex est [*empoisonné*](https://doc.rust-lang.org/std/sync/struct.Mutex.html#poisoning) (poisoned) et les appels ultérieurs à `lock()` renvoient `Err`. `.unwrap()` propage cette panique, ce qui est généralement ce que l'on veut.
- Gardez la portée de la garde courte. La conserver pendant un appel lent bloque tous les autres — et deux threads qui prennent deux verrous dans l'ordre inverse aboutissent toujours à un interblocage.

[`RwLock<T>`](https://doc.rust-lang.org/std/sync/struct.RwLock.html) autorise plusieurs lecteurs ou un seul rédacteur, comme [`ReaderWriterLockSlim`](https://learn.microsoft.com/dotnet/api/system.threading.readerwriterlockslim) ou [`ReentrantReadWriteLock`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/locks/ReentrantReadWriteLock.html) ([lignes 80-86](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L80-L86)) :

```rust
let settings = RwLock::new(HashMap::from([("mode", "fast")]));
{
    let a = settings.read().unwrap();
    let b = settings.read().unwrap();      // deux lecteurs à la fois, aucun problème
}
settings.write().unwrap().insert("mode", "safe");
```

## Atomiques

Pour un compteur ou un indicateur, un verrou est disproportionné ([lignes 3](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L3), [54-63](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L54-L63)) :

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

`fetch_add` correspond à [`Interlocked.Increment`](https://learn.microsoft.com/dotnet/api/system.threading.interlocked.increment) / [`AtomicInteger.getAndAdd`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/AtomicInteger.html#getAndAdd(int)). L'argument [`Ordering`](https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html) décrit la garantie d'ordonnancement mémoire dont vous avez besoin ; pour un compteur indépendant, `Relaxed` suffit (le livre *Rust Atomics and Locks*, en lien plus bas, explique les autres). Notez que les threads à portée empruntent `hits` sans `Arc` : un atomique est `Sync`.

## Canaux : partager en communiquant

Au lieu de partager des données, les threads peuvent s'envoyer des valeurs. Envoyer **déplace** la valeur, donc l'émetteur ne peut plus y toucher ensuite ([lignes 4](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L4), [67-76](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L67-L76)) :

```rust
use std::sync::mpsc;

let (sender, receiver) = mpsc::channel();
for id in 0..3 {
    let sender = sender.clone();            // un émetteur par thread
    thread::spawn(move || {
        sender.send(format!("worker {id} done")).unwrap();
    });
}
drop(sender);                               // sinon la boucle ci-dessous ne se termine jamais
let messages: Vec<String> = receiver.iter().collect();
// ["worker 0 done", "worker 1 done", "worker 2 done"]   (après tri)
```

[`mpsc`](https://doc.rust-lang.org/std/sync/mpsc/index.html) signifie *multiple producer, single consumer* (plusieurs producteurs, un seul consommateur). L'équivalent C# est [`System.Threading.Channels.Channel<T>`](https://learn.microsoft.com/dotnet/api/system.threading.channels.channel-1) ou [`BlockingCollection<T>`](https://learn.microsoft.com/dotnet/api/system.collections.concurrent.blockingcollection-1) ; en Java, une [`BlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/BlockingQueue.html). L'itérateur du récepteur se termine quand tous les `Sender` ont été détruits — oublier `drop(sender)` est le blocage classique.

## Parallélisme de données avec rayon

Pour « faire ceci sur chaque élément, sur tous les cœurs », ne gérez pas les threads vous-même. La crate [rayon](https://docs.rs/rayon) transforme une chaîne d'itérateurs en chaîne parallèle — l'équivalent de [PLINQ](https://learn.microsoft.com/dotnet/standard/parallel-programming/introduction-to-plinq) et de son [`AsParallel()`](https://learn.microsoft.com/dotnet/api/system.linq.parallelenumerable.asparallel), ou du [`parallelStream()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Collection.html#parallelStream()) de Java :

```toml
[dependencies]
rayon = "1"
```

Extrait de [`examples/l12_threads.rs`, lignes 1-13](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L1-L13), [90-99](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l12_threads.rs#L90-L99) :

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
let lengths: Vec<usize> = words.par_iter().map(|w| w.len()).collect();   // l'ordre est préservé
// ["apple", "fig", "kiwi", "pear"] [5, 3, 4, 4]
```

| Séquentiel | rayon |
|---|---|
| `.iter()` | `.par_iter()` |
| `.into_iter()` | `.into_par_iter()` |
| `.iter_mut()` | `.par_iter_mut()` |
| `.sort()` | `.par_sort()` |

rayon exécute le travail sur un pool comptant un thread par cœur et le répartit par vol de tâches (*work stealing*), comme le [pool de threads .NET](https://learn.microsoft.com/dotnet/standard/threading/the-managed-thread-pool) et le [`ForkJoinPool`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ForkJoinPool.html) de Java. Ses closures doivent être [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html) (pas de modification des variables capturées) et `Send + Sync`, si bien que la data race de tout à l'heure ne peut pas revenir en douce ([`src/lib.rs`, lignes 929-930](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L929-L930)) :

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

Utilisez plutôt `.count()`, ou un [`AtomicUsize`](https://doc.rust-lang.org/std/sync/atomic/type.AtomicUsize.html).

Sur ma machine (Intel Core Ultra 9 285K, 24 cœurs, build release), compter les nombres premiers inférieurs à 5 000 000 a pris **environ 775 ms** en séquentiel et **environ 41 ms** avec `into_par_iter()` — voir l'exercice 3.

:::note[Threads ou async ?]
Les threads (et rayon) servent au travail **limité par le CPU** (CPU-bound) : chaque cœur calcule. Pour le travail **limité par les E/S** (I/O-bound) — des milliers de requêtes réseau qui passent l'essentiel de leur temps à attendre — il vous faut `async`, le sujet de la leçon 13.
:::

## À retenir

- Les règles d'emprunt interdisent les data races, donc une data race est une erreur de compilation ; les interblocages restent possibles.
- `thread::spawn` a besoin de `move` et de données `'static` ; `thread::scope` permet aux threads d'emprunter des variables locales.
- `Send` (peut être déplacé vers un thread) et `Sync` (peut être partagé entre threads) sont vérifiés par le compilateur ; `Rc` et `RefCell` ne sont pas thread-safe.
- `Mutex<T>` possède ses données : impossible d'oublier de verrouiller, et la garde déverrouille à sa destruction. Partagez-le avec `Arc`.
- Les atomiques pour les compteurs, les canaux pour transférer la possession entre threads, rayon pour le parallélisme de données.

## Exercices

1. Écrivez `fn parallel_sum(data: &[u64], threads: usize) -> u64` qui découpe `data` en au plus `threads` morceaux et les somme sur des threads à portée. La fonction doit fonctionner pour une slice vide et pour plus de threads que d'éléments.

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 936-946](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L936-L946) :

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

`chunks` panique avec une taille de 0, d'où les deux `max(1)`. Les handles sont collectés dans un `Vec` **avant** d'être joints : joindre dans le même `map` attendrait chaque thread avant de lancer le suivant, et le code s'exécuterait séquentiellement.

</details>

2. Écrivez `fn count_words(texts: &[&str]) -> HashMap<String, usize>` (insensible à la casse) qui traite chaque texte sur son propre thread. Utilisez un canal plutôt qu'un `Arc<Mutex<HashMap>>`. Pourquoi est-ce une meilleure conception ici ?

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 952-980](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L952-L980) :

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

Chaque thread travaille sur sa propre map sans aucun verrou, et l'envoie une seule fois quand il a terminé. Avec un `Mutex<HashMap>` partagé, chaque mot prendrait le verrou, et les threads passeraient l'essentiel de leur temps à s'attendre les uns les autres. Le canal non borné met les maps en tampon, si bien que les threads peuvent se terminer avant que `main` ne les lise.

</details>

3. Comptez les nombres premiers inférieurs à 5 000 000 avec `is_prime` de cette leçon, en séquentiel et avec rayon, et chronométrez les deux avec [`std::time::Instant`](https://doc.rust-lang.org/std/time/struct.Instant.html) dans un build **release** (`cargo run --release`). Vérifiez que les deux comptes sont égaux. À quel point l'accélération approche-t-elle « nombre de cœurs × » ?

<details>
<summary>Solution</summary>

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

Sur ma machine :

```text
348513 primes in 770.75ms sequential, 348513 in 41.76ms parallel on 24 threads
```

Environ 18× sur 24 cœurs. L'accélération reste sous 24× parce que ce processeur mélange cœurs de performance et cœurs d'efficacité, et parce que découper et rassembler le travail a un coût. De plus, tester les grands nombres prend plus de temps que les petits, donc les morceaux sont inégaux. Pour le reste, la tâche est idéale : chaque nombre est indépendant. Mesurez toujours en mode release ; les temps d'un build debug ne sont pas représentatifs.

</details>

## Sources

- [The Book, ch. 16 — Fearless Concurrency](https://doc.rust-lang.org/book/ch16-00-concurrency.html)
- [`std::thread::scope`](https://doc.rust-lang.org/std/thread/fn.scope.html)
- [`std::marker::Send`](https://doc.rust-lang.org/std/marker/trait.Send.html) et [`Sync`](https://doc.rust-lang.org/std/marker/trait.Sync.html)
- [`std::sync::Mutex`](https://doc.rust-lang.org/std/sync/struct.Mutex.html) — y compris l'empoisonnement
- [Documentation de rayon](https://docs.rs/rayon)
- [Mara Bos, *Rust Atomics and Locks*](https://mara.nl/atomics/) — gratuit en ligne
