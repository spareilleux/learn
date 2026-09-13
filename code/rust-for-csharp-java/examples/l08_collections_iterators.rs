use std::collections::{BTreeMap, HashMap, HashSet};

#[derive(Debug, Clone)]
struct Order {
    customer: &'static str,
    product: &'static str,
    quantity: u32,
    unit_price: f64,
}

// A custom iterator: the equivalent of an IEnumerable with `yield return`
struct Fibonacci {
    current: u64,
    next: u64,
}

impl Iterator for Fibonacci {
    type Item = u64;

    fn next(&mut self) -> Option<Self::Item> {
        let value = self.current;
        self.current = self.next;
        self.next += value;
        Some(value)
    }
}

fn main() {
    let orders = vec![
        Order { customer: "ada", product: "keyboard", quantity: 1, unit_price: 89.0 },
        Order { customer: "grace", product: "mouse", quantity: 2, unit_price: 25.0 },
        Order { customer: "ada", product: "monitor", quantity: 2, unit_price: 199.0 },
        Order { customer: "linus", product: "mouse", quantity: 1, unit_price: 25.0 },
    ];

    // Where + Select + ToList
    let big_orders: Vec<&str> = orders
        .iter()
        .filter(|o| o.quantity >= 2)
        .map(|o| o.product)
        .collect();
    println!("big orders: {big_orders:?}");

    // Sum, Any, All, First
    let revenue: f64 = orders.iter().map(|o| o.quantity as f64 * o.unit_price).sum();
    let any_monitor = orders.iter().any(|o| o.product == "monitor");
    let all_positive = orders.iter().all(|o| o.quantity > 0);
    let first_mouse = orders.iter().find(|o| o.product == "mouse").map(|o| o.customer);
    println!("revenue {revenue}, any monitor {any_monitor}, all positive {all_positive}, first mouse buyer {first_mouse:?}");

    // GroupBy + Sum, with the entry API
    let mut spend: HashMap<&str, f64> = HashMap::new();
    for o in &orders {
        *spend.entry(o.customer).or_insert(0.0) += o.quantity as f64 * o.unit_price;
    }
    // HashMap iteration order is unspecified: copy into a BTreeMap for sorted output
    let sorted: BTreeMap<_, _> = spend.iter().collect();
    println!("spend per customer: {sorted:?}");

    // Distinct
    let products: HashSet<&str> = orders.iter().map(|o| o.product).collect();
    println!("{} distinct products", products.len());

    // OrderByDescending + Take
    let mut by_value = orders.clone();
    by_value.sort_by(|a, b| (b.quantity as f64 * b.unit_price).total_cmp(&(a.quantity as f64 * a.unit_price)));
    let top: Vec<_> = by_value.iter().take(2).map(|o| o.product).collect();
    println!("top 2 by value: {top:?}");

    // Zip, enumerate, SelectMany (flat_map), fold (Aggregate)
    let names = ["ada", "grace"];
    let ages = [36, 85];
    for (i, (name, age)) in names.iter().zip(ages.iter()).enumerate() {
        println!("{i}: {name} is {age}");
    }
    let letters: String = names.iter().flat_map(|n| n.chars().take(1)).collect();
    let (low, high) = [7, 3, 9, 4].iter().fold((i32::MAX, i32::MIN), |(lo, hi), &x| (lo.min(x), hi.max(x)));
    println!("initials {letters}, range {low}..={high}");

    // iter() borrows, iter_mut() borrows mutably, into_iter() consumes
    let mut prices = vec![10.0, 20.0, 30.0];
    for p in prices.iter_mut() {
        *p *= 1.2;
    }
    let total: f64 = prices.into_iter().sum();
    println!("total with tax {total:.2}");

    // Closures capture their environment; `move` takes ownership
    let threshold = 50.0;
    let is_expensive = |o: &Order| o.unit_price * o.quantity as f64 > threshold;
    println!("expensive orders: {}", orders.iter().filter(|o| is_expensive(o)).count());

    let label = String::from("report");
    let make_title = move |n: usize| format!("{label} #{n}");
    println!("{}", make_title(1));

    // Lazy, infinite, and only evaluated as far as needed
    let fibs: Vec<u64> = Fibonacci { current: 0, next: 1 }.take_while(|&n| n < 100).collect();
    println!("fibonacci < 100: {fibs:?}");

    // windows and chunks on slices
    let readings = [3, 5, 4, 8, 9];
    let rising = readings.windows(2).filter(|w| w[1] > w[0]).count();
    let batches: Vec<i32> = readings.chunks(2).map(|c| c.iter().sum()).collect();
    println!("rising steps {rising}, batch sums {batches:?}");
}
