use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::{Mutex, mpsc};
use tokio::task::JoinSet;
use tokio::time::{sleep, timeout};

// Simulated I/O: waiting, not computing
async fn fetch_price(item: &str, delay_ms: u64) -> u32 {
    sleep(Duration::from_millis(delay_ms)).await;
    item.len() as u32 * 10
}

// Round to the nearest 100 ms so the output is stable
fn rounded(start: Instant) -> u128 {
    (start.elapsed().as_millis() + 50) / 100 * 100
}

fn is_prime(n: u64) -> bool {
    n >= 2
        && (2..)
            .take_while(|d| d * d <= n)
            .all(|d| !n.is_multiple_of(d))
}

#[tokio::main]
async fn main() {
    // 1. Futures are lazy: nothing runs until .await
    let future = async {
        println!("  future body runs");
        1
    };
    println!("future created");
    let one = future.await;
    println!("awaited: {one}");

    // 2. Sequential awaits add up; join! runs them concurrently
    let start = Instant::now();
    let a = fetch_price("book", 100).await;
    let b = fetch_price("pen", 100).await;
    let c = fetch_price("lamp", 100).await;
    println!("sequential: {} in ~{} ms", a + b + c, rounded(start));

    let start = Instant::now();
    let (a, b, c) = tokio::join!(
        fetch_price("book", 100),
        fetch_price("pen", 100),
        fetch_price("lamp", 100)
    );
    println!("join!:      {} in ~{} ms", a + b + c, rounded(start));

    // 3. spawn: a task runs on the runtime's thread pool, like Task.Run
    let handle = tokio::spawn(async { fetch_price("keyboard", 50).await });
    println!("spawned task returned {}", handle.await.unwrap());

    // 4. JoinSet: results in completion order, like Task.WhenAny in a loop
    let mut set = JoinSet::new();
    for (item, delay) in [("slow", 150), ("fast", 50), ("medium", 100)] {
        set.spawn(async move { (item, fetch_price(item, delay).await) });
    }
    while let Some(result) = set.join_next().await {
        let (item, price) = result.unwrap();
        println!("  finished {item}: {price}");
    }

    // 5. Timeouts and select!: the losing future is dropped, i.e. cancelled
    match timeout(Duration::from_millis(50), fetch_price("late", 200)).await {
        Ok(price) => println!("got {price}"),
        Err(_) => println!("timed out after 50 ms"),
    }
    tokio::select! {
        price = fetch_price("tortoise", 200) => println!("tortoise won: {price}"),
        price = fetch_price("hare", 20) => println!("hare won: {price}"),
    }

    // 6. Channels between tasks
    let (sender, mut receiver) = mpsc::channel::<String>(8);
    for id in 0..3 {
        let sender = sender.clone();
        tokio::spawn(async move {
            sleep(Duration::from_millis(10 * (3 - id))).await;
            sender.send(format!("worker {id}")).await.unwrap();
        });
    }
    drop(sender);
    let mut messages = Vec::new();
    while let Some(message) = receiver.recv().await {
        messages.push(message);
    }
    messages.sort();
    println!("{messages:?}");

    // 7. tokio::sync::Mutex can be held across an .await
    let cache = Arc::new(Mutex::new(Vec::new()));
    let mut tasks = JoinSet::new();
    for item in ["a", "bb", "ccc"] {
        let cache = Arc::clone(&cache);
        tasks.spawn(async move {
            let mut guard = cache.lock().await;
            let price = fetch_price(item, 10).await;
            guard.push(price);
        });
    }
    tasks.join_all().await;
    let mut prices = cache.lock().await.clone();
    prices.sort();
    println!("cached prices: {prices:?}");

    // 8. CPU-bound work goes to spawn_blocking, not onto the async threads
    let primes = tokio::task::spawn_blocking(|| (1..100_000u64).filter(|&n| is_prime(n)).count())
        .await
        .unwrap();
    println!("primes below 100000: {primes}");
}
