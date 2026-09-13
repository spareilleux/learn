//! Compile-fail checks for the "Rust for C#/Java developers" course.
//!
//! Every snippet a lesson shows as "this does not compile" lives here as a
//! `compile_fail` doctest, so `cargo test --doc` proves the compiler still rejects it.
//! Runnable examples live in `examples/` (`cargo run --example l03_ownership`).

/// Lesson 2 — variables are immutable by default (E0384).
///
/// ```compile_fail,E0384
/// let count = 0;
/// count += 1;
/// println!("{count}");
/// ```
///
/// Lesson 2 — no implicit numeric conversion (E0308).
///
/// ```compile_fail,E0308
/// let small: i32 = 10;
/// let big: i64 = 20;
/// let total = small + big;
/// ```
///
/// Exercise 1 — `if` as an expression.
///
/// ```
/// fn clamp_percent(value: i32) -> u8 {
///     if value < 0 {
///         0
///     } else if value > 100 {
///         100
///     } else {
///         value as u8
///     }
/// }
/// assert_eq!(clamp_percent(-5), 0);
/// assert_eq!(clamp_percent(42), 42);
/// assert_eq!(clamp_percent(250), 100);
/// assert_eq!(250i32.clamp(0, 100) as u8, 100);
/// ```
///
/// Exercise 2 — a trailing semicolon makes the body `()` (E0308).
///
/// ```compile_fail,E0308
/// fn double(x: i32) -> i32 {
///     x * 2;
/// }
/// ```
///
/// Exercise 3 — explicit overflow handling.
///
/// ```
/// let b: u8 = 255;
/// assert_eq!(b.wrapping_add(1), 0);
/// assert_eq!(b.checked_add(1), None);
/// ```
pub mod lesson02 {}

/// Lesson 3 — use after move (E0382).
///
/// ```compile_fail,E0382
/// let a = String::from("hello");
/// let b = a;
/// println!("{a} {b}");
/// ```
///
/// Lesson 3 — passing by value moves (E0382).
///
/// ```compile_fail,E0382
/// fn take(s: String) -> usize {
///     s.len()
/// }
///
/// let name = String::from("Ferris");
/// let len = take(name);
/// println!("{name} has {len} letters");
/// ```
///
/// Exercise 1 — Copy vs move vs clone: (1) and (3) compile.
///
/// ```
/// let a = 10;
/// let _b = a;
/// println!("{a}");
///
/// let u = String::from("y");
/// let v = u.clone();
/// println!("{u} {v}");
/// ```
///
/// ```compile_fail,E0382
/// let s = String::from("x");
/// let _t = s;
/// println!("{s}");
/// ```
///
/// Exercise 2 — borrow instead of taking ownership.
///
/// ```
/// fn count_vowels(text: &str) -> usize {
///     text.chars().filter(|c| "aeiouAEIOU".contains(*c)).count()
/// }
/// let name = String::from("Ferris");
/// assert_eq!(count_vowels(&name), 2);
/// println!("{name}");
/// ```
///
/// Exercise 3 — drop order: explicit drop first, then reverse declaration order.
///
/// ```
/// use std::cell::RefCell;
/// thread_local!(static LOG: RefCell<Vec<String>> = RefCell::new(Vec::new()));
///
/// struct TempFile { name: String }
/// impl Drop for TempFile {
///     fn drop(&mut self) {
///         LOG.with(|l| l.borrow_mut().push(self.name.clone()));
///     }
/// }
///
/// {
///     let _a = TempFile { name: "a".into() };
///     let b = TempFile { name: "b".into() };
///     let _c = TempFile { name: "c".into() };
///     drop(b);
///     LOG.with(|l| l.borrow_mut().push("done".into()));
/// }
/// LOG.with(|l| assert_eq!(*l.borrow(), ["b", "done", "c", "a"]));
/// ```
pub mod lesson03 {}

/// Lesson 4 — a shared borrow blocks mutation (E0502).
///
/// ```compile_fail,E0502
/// let mut names = vec![String::from("Ada")];
/// let first = &names[0];
/// names.push(String::from("Grace"));
/// println!("{first}");
/// ```
///
/// Lesson 4 — no mutation while iterating (E0502).
///
/// ```compile_fail,E0502
/// let mut numbers = vec![1, 2, 3];
/// for n in &numbers {
///     numbers.push(n * 2);
/// }
/// ```
///
/// Lesson 4 — returning a reference to a local (E0106).
///
/// ```compile_fail,E0106
/// fn longest_line() -> &str {
///     let text = String::from("line one\nline two");
///     text.lines().next().unwrap()
/// }
/// ```
///
/// Lesson 4 — strings cannot be indexed by integer (E0277).
///
/// ```compile_fail,E0277
/// let word = String::from("cafe");
/// let c = word[0];
/// ```
///
/// Exercise 1 — `&str` parameter keeps ownership with the caller.
///
/// ```
/// fn is_shouting(text: &str) -> bool {
///     text.chars().any(|c| c.is_alphabetic()) && text == text.to_uppercase()
/// }
/// let msg = String::from("HELLO");
/// assert!(is_shouting(&msg));
/// assert!(!is_shouting("hi"));
/// println!("{msg}");
/// ```
///
/// Exercise 2 — fix by cloning the element before pushing.
///
/// ```
/// let mut names = vec![String::from("Ada")];
/// let first = names[0].clone();
/// names.push(String::from("Grace"));
/// assert_eq!(first, "Ada");
/// ```
///
/// Exercise 3 — initials, Unicode-aware.
///
/// ```
/// fn initials(full_name: &str) -> String {
///     full_name
///         .split_whitespace()
///         .filter_map(|word| word.chars().next())
///         .map(|c| format!("{c}."))
///         .collect()
/// }
/// assert_eq!(initials("Ada Lovelace"), "A.L.");
/// assert_eq!(initials("Émile Zola"), "É.Z.");
/// ```
pub mod lesson04 {}

/// Lesson 5 — every field must be initialised (E0063).
///
/// ```compile_fail,E0063
/// struct Account { owner: String, balance_cents: i64 }
/// let account = Account { owner: String::from("Ada") };
/// ```
///
/// Lesson 5 — `match` must be exhaustive (E0004).
///
/// ```compile_fail,E0004
/// enum Shape { Circle { radius: f64 }, Rectangle { width: f64, height: f64 }, Triangle(f64, f64, f64) }
/// fn area(shape: &Shape) -> f64 {
///     match shape {
///         Shape::Circle { radius } => 3.14 * radius * radius,
///         Shape::Rectangle { width, height } => width * height,
///     }
/// }
/// ```
///
/// Exercises 1 and 2 — a closed hierarchy as an enum; adding a variant breaks the match.
///
/// ```
/// enum Payment { Card { last4: String }, Transfer { iban: String }, Cash }
/// fn describe(payment: &Payment) -> String {
///     match payment {
///         Payment::Card { last4 } => format!("card ending {last4}"),
///         Payment::Transfer { iban } => format!("transfer from {iban}"),
///         Payment::Cash => String::from("cash"),
///     }
/// }
/// assert_eq!(describe(&Payment::Card { last4: "4242".into() }), "card ending 4242");
/// assert_eq!(describe(&Payment::Cash), "cash");
/// ```
///
/// ```compile_fail,E0004
/// enum Payment { Card { last4: String }, Transfer { iban: String }, Cash, Crypto { wallet: String } }
/// fn describe(payment: &Payment) -> String {
///     match payment {
///         Payment::Card { last4 } => format!("card ending {last4}"),
///         Payment::Transfer { iban } => format!("transfer from {iban}"),
///         Payment::Cash => String::from("cash"),
///     }
/// }
/// ```
///
/// Exercise 3 — methods and struct update syntax.
///
/// ```
/// #[derive(Debug, Clone, Copy, PartialEq)]
/// struct Rectangle { width: f64, height: f64 }
/// impl Rectangle {
///     fn square(size: f64) -> Self { Self { width: size, height: size } }
///     fn area(&self) -> f64 { self.width * self.height }
///     fn scale(&mut self, factor: f64) { self.width *= factor; self.height *= factor; }
/// }
/// let mut r = Rectangle::square(2.0);
/// r.scale(1.5);
/// let wide = Rectangle { width: r.width * 2.0, ..r };
/// assert_eq!(wide.area(), 18.0);
/// ```
pub mod lesson05 {}

/// Lesson 6 — an `Option<i32>` is not an `i32` (E0369).
///
/// ```compile_fail,E0369
/// let maybe: Option<i32> = Some(1);
/// let total = maybe + 1;
/// ```
///
/// Lesson 6 — `?` needs a function returning `Result` or `Option` (E0277).
///
/// ```compile_fail,E0277
/// fn run() {
///     let port: u16 = "3000".parse()?;
/// }
/// ```
///
/// Exercise 1 — `Option` and `unwrap_or`.
///
/// ```
/// use std::collections::HashMap;
/// fn find_age(ages: &HashMap<&str, u32>, name: &str) -> Option<u32> {
///     ages.get(name).copied()
/// }
/// let ages = HashMap::from([("Ada", 36)]);
/// assert_eq!(find_age(&ages, "Ada").map(i64::from).unwrap_or(-1), 36);
/// assert_eq!(find_age(&ages, "Bob"), None);
/// ```
///
/// Exercise 2 — `?` with `ok_or` and `map_err`.
///
/// ```
/// fn parse_point(text: &str) -> Result<(i32, i32), String> {
///     let (x, y) = text.split_once(',').ok_or("expected x,y")?;
///     let x = x.trim().parse::<i32>().map_err(|e| format!("bad x: {e}"))?;
///     let y = y.trim().parse::<i32>().map_err(|e| format!("bad y: {e}"))?;
///     Ok((x, y))
/// }
/// assert_eq!(parse_point("3,4"), Ok((3, 4)));
/// assert_eq!(parse_point("3"), Err(String::from("expected x,y")));
/// assert_eq!(parse_point("3,z"), Err(String::from("bad y: invalid digit found in string")));
/// ```
///
/// Exercise 3 — `main` returning a `Result`.
///
/// ```
/// fn main() -> Result<(), Box<dyn std::error::Error>> {
///     let port: u16 = "3000".parse()?;
///     assert_eq!(port, 3000);
///     Ok(())
/// }
/// ```
pub mod lesson06 {}

/// Lesson 7 — a missing trait method (E0046).
///
/// ```compile_fail,E0046
/// trait Shape { fn area(&self) -> f64; }
/// struct Square { side: f64 }
/// impl Shape for Square {}
/// ```
///
/// Lesson 7 — generic code needs a bound (E0599).
///
/// ```compile_fail,E0599
/// trait Shape { fn area(&self) -> f64; }
/// fn total_area<T>(shapes: &[T]) -> f64 {
///     shapes.iter().map(|s| s.area()).sum()
/// }
/// ```
///
/// Lesson 7 — the orphan rule (E0117).
///
/// ```compile_fail,E0117
/// use std::fmt;
/// impl fmt::Display for Vec<i32> {
///     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
///         write!(f, "{} items", self.len())
///     }
/// }
/// ```
///
/// Exercises 1 and 2 — default methods, generic bound, trait objects.
///
/// ```
/// trait Priced {
///     fn price(&self) -> f64;
///     fn price_with_tax(&self, rate: f64) -> f64 { self.price() * (1.0 + rate) }
/// }
/// struct Book { title: String, price: f64 }
/// struct Coffee { size_ml: u32 }
/// impl Priced for Book { fn price(&self) -> f64 { self.price } }
/// impl Priced for Coffee { fn price(&self) -> f64 { self.size_ml as f64 * 0.01 } }
///
/// fn cheapest<T: Priced>(items: &[T]) -> Option<&T> {
///     items.iter().min_by(|a, b| a.price().total_cmp(&b.price()))
/// }
/// fn total(items: &[Box<dyn Priced>]) -> f64 {
///     items.iter().map(|i| i.price()).sum()
/// }
///
/// let books = [Book { title: "Rust".into(), price: 40.0 }, Book { title: "C#".into(), price: 35.0 }];
/// assert_eq!(cheapest(&books).map(|b| b.title.as_str()), Some("C#"));
/// assert_eq!(books[0].price_with_tax(0.25), 50.0);
///
/// let basket: Vec<Box<dyn Priced>> = vec![
///     Box::new(Book { title: "Rust".into(), price: 40.0 }),
///     Box::new(Coffee { size_ml: 250 }),
/// ];
/// assert_eq!(total(&basket), 42.5);
///
/// impl Priced for Box<dyn Priced> {
///     fn price(&self) -> f64 { (**self).price() }
/// }
/// assert_eq!(cheapest(&basket).map(|i| i.price()), Some(2.5));
/// ```
///
/// Exercise 3 — the newtype workaround.
///
/// ```
/// use std::fmt;
/// struct Scores(Vec<i32>);
/// impl fmt::Display for Scores {
///     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
///         let list: Vec<String> = self.0.iter().map(|s| s.to_string()).collect();
///         write!(f, "{} scores: {}", self.0.len(), list.join(", "))
///     }
/// }
/// assert_eq!(Scores(vec![12, 7, 30]).to_string(), "3 scores: 12, 7, 30");
/// ```
pub mod lesson07 {}

/// Lesson 8 — `collect` needs a target type (E0283).
///
/// ```compile_fail,E0283
/// let evens = (1..10).filter(|n| n % 2 == 0).collect();
/// ```
///
/// Lesson 8 — a `for` loop over a `Vec` consumes it (E0382).
///
/// ```compile_fail,E0382
/// let prices = vec![10.0, 20.0];
/// for p in prices {
///     println!("{p}");
/// }
/// println!("{prices:?}");
/// ```
///
/// Lesson 8 — floats are not `Ord` (E0277).
///
/// ```compile_fail,E0277
/// let mut prices = vec![19.99, 5.0, 12.5];
/// prices.sort();
/// ```
///
/// Lesson 8 — sorting floats with an explicit total order.
///
/// ```
/// let mut prices: Vec<f64> = vec![19.99, 5.0, 12.5];
/// prices.sort_by(|a, b| a.total_cmp(b));
/// assert_eq!(prices, [5.0, 12.5, 19.99]);
/// ```
///
/// Lesson 8 — without the annotation the float type is still undecided (E0599).
///
/// ```compile_fail,E0599
/// let mut prices = vec![19.99, 5.0, 12.5];
/// prices.sort_by(|a, b| a.total_cmp(b));
/// ```
///
/// Exercise 1 — LINQ query as an iterator chain.
///
/// ```
/// let words = ["tree", "sky", "apple", "rust", "go"];
/// let mut result: Vec<String> = words.iter().filter(|w| w.len() > 3).map(|w| w.to_uppercase()).collect();
/// result.sort();
/// assert_eq!(result, ["APPLE", "RUST", "TREE"]);
/// ```
///
/// Exercise 2 — word counts with the entry API.
///
/// ```
/// use std::collections::BTreeMap;
/// fn word_counts(text: &str) -> BTreeMap<String, usize> {
///     let mut counts = BTreeMap::new();
///     for word in text.split_whitespace() {
///         *counts.entry(word.to_lowercase()).or_insert(0) += 1;
///     }
///     counts
/// }
/// let counts = word_counts("the cat and THE hat");
/// assert_eq!(counts["the"], 2);
/// assert_eq!(counts.keys().collect::<Vec<_>>(), ["and", "cat", "hat", "the"]);
/// ```
///
/// Exercise 3 — a finite custom iterator.
///
/// ```
/// struct Countdown(u32);
/// impl Iterator for Countdown {
///     type Item = u32;
///     fn next(&mut self) -> Option<u32> {
///         if self.0 == 0 { None } else { self.0 -= 1; Some(self.0 + 1) }
///     }
/// }
/// let text: Vec<String> = Countdown(3).map(|n| format!("{n}...")).collect();
/// assert_eq!(text.join(" "), "3... 2... 1...");
/// ```
pub mod lesson08 {}
