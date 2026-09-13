use rayon::prelude::*;
use std::collections::HashMap;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc;
use std::sync::{Arc, Mutex, RwLock};
use std::thread;

fn is_prime(n: u64) -> bool {
    n >= 2 && (2..).take_while(|d| d * d <= n).all(|d| !n.is_multiple_of(d))
}

fn main() {
    // 1. spawn: the closure must own what it uses (`move`); join returns its result
    let names = [String::from("ada"), String::from("grace")];
    let handle = thread::spawn(move || names.iter().map(|n| n.len()).sum::<usize>());
    println!("total name length: {}", handle.join().unwrap());

    // 2. scoped threads may borrow local data: they are joined before `scope` returns
    let data: Vec<u64> = (1..=1_000).collect();
    let chunk_sums: Vec<u64> = thread::scope(|s| {
        let handles: Vec<_> = data.chunks(250).map(|chunk| s.spawn(move || chunk.iter().sum::<u64>())).collect();
        handles.into_iter().map(|h| h.join().unwrap()).collect()
    });
    println!("chunk sums: {chunk_sums:?}, total {}", chunk_sums.iter().sum::<u64>());

    // 3. Arc<Mutex<T>>: shared mutable state, one writer at a time
    let results = Arc::new(Mutex::new(Vec::new()));
    let workers: Vec<_> = (1..=4)
        .map(|id| {
            let results = Arc::clone(&results);
            thread::spawn(move || {
                let square = id * id;
                results.lock().unwrap().push((id, square)); // the guard unlocks at the end of the statement
            })
        })
        .collect();
    for worker in workers {
        worker.join().unwrap();
    }
    let mut squares = results.lock().unwrap().clone();
    squares.sort();
    println!("squares: {squares:?}");

    // 4. Atomics: lock-free counters, like Interlocked / AtomicInteger
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
    println!("hits: {}", hits.load(Ordering::Relaxed));

    // 5. Channels: send values instead of sharing them
    let (sender, receiver) = mpsc::channel();
    for id in 0..3 {
        let sender = sender.clone();
        thread::spawn(move || {
            sender.send(format!("worker {id} done")).unwrap();
        });
    }
    drop(sender); // the loop below ends when every sender is gone
    let mut messages: Vec<String> = receiver.iter().collect();
    messages.sort();
    println!("{messages:?}");

    // 6. RwLock: many readers or one writer
    let settings = RwLock::new(HashMap::from([("mode", "fast")]));
    {
        let a = settings.read().unwrap();
        let b = settings.read().unwrap(); // two readers at once are fine
        println!("mode read twice: {} {}", a["mode"], b["mode"]);
    }
    settings.write().unwrap().insert("mode", "safe");
    println!("mode after write: {}", settings.read().unwrap()["mode"]);

    // 7. rayon: data parallelism, like PLINQ's AsParallel() or Java's parallelStream()
    let sequential = (1..200_000u64).filter(|&n| is_prime(n)).count();
    let parallel = (1..200_000u64).into_par_iter().filter(|&n| is_prime(n)).count();
    println!("primes below 200000: {sequential} sequential, {parallel} parallel");

    let mut words = vec!["pear", "fig", "apple", "kiwi"];
    words.par_sort_unstable();
    let lengths: Vec<usize> = words.par_iter().map(|w| w.len()).collect(); // order is preserved
    println!("{words:?} {lengths:?}");
}
