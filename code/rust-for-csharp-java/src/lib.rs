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

/// Lesson 9 — a reference cannot outlive its value (E0597).
///
/// ```compile_fail,E0597
/// let r;
/// {
///     let s = String::from("hello");
///     r = &s;
/// }
/// println!("{r}");
/// ```
///
/// Lesson 9 — two input references: the compiler cannot guess the output lifetime (E0106).
///
/// ```compile_fail,E0106
/// fn longest(a: &str, b: &str) -> &str {
///     if a.len() >= b.len() { a } else { b }
/// }
/// ```
///
/// Lesson 9 — the result of `longest` cannot outlive the shorter input (E0597).
///
/// ```compile_fail,E0597
/// fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
///     if a.len() >= b.len() { a } else { b }
/// }
/// let title = String::from("Rust for C# developers");
/// let winner;
/// {
///     let subtitle = String::from("ownership");
///     winner = longest(&title, &subtitle);
/// }
/// println!("{winner}");
/// ```
///
/// Lesson 9 — a struct field that is a reference needs a lifetime (E0106).
///
/// ```compile_fail,E0106
/// struct Excerpt {
///     text: &str,
/// }
/// ```
///
/// Lesson 9 — a struct cannot outlive the data it borrows (E0597).
///
/// ```compile_fail,E0597
/// struct Excerpt<'a> {
///     text: &'a str,
/// }
/// let excerpt;
/// {
///     let novel = String::from("Call me Ishmael. Some years ago...");
///     excerpt = Excerpt { text: novel.split('.').next().unwrap() };
/// }
/// println!("{}", excerpt.text);
/// ```
///
/// Lesson 9 — no reference to a local variable can escape (E0515).
///
/// ```compile_fail,E0515
/// fn shout(word: &str) -> &str {
///     let upper = word.to_uppercase();
///     &upper
/// }
/// ```
///
/// Lesson 9 — `thread::spawn` needs `'static` data (E0597).
///
/// ```compile_fail,E0597
/// let name = String::from("worker");
/// let label: &str = &name;
/// let handle = std::thread::spawn(move || println!("{label}"));
/// handle.join().unwrap();
/// ```
///
/// Exercise 1 — elision and an explicit lifetime.
///
/// ```
/// fn longest_line(text: &str) -> &str {
///     text.lines().max_by_key(|line| line.len()).unwrap_or("")
/// }
/// fn pick<'a>(first: &'a str, second: &'a str, use_first: bool) -> &'a str {
///     if use_first { first } else { second }
/// }
/// let poem = String::from("short\na much longer line\nmid");
/// assert_eq!(longest_line(&poem), "a much longer line");
/// assert_eq!(pick("left", "right", false), "right");
/// ```
///
/// Exercise 2 — results borrow the text, not the query.
///
/// ```
/// #[derive(Debug, PartialEq)]
/// struct Highlight<'a> {
///     line: &'a str,
///     column: usize,
/// }
/// fn find_highlights<'a>(text: &'a str, word: &str) -> Vec<Highlight<'a>> {
///     text.lines()
///         .filter_map(|line| line.find(word).map(|column| Highlight { line, column }))
///         .collect()
/// }
/// let text = String::from("I like Rust\nC# too\nRust again");
/// let hits = {
///     let query = String::from("Rust");   // dropped at the end of this block
///     find_highlights(&text, &query)
/// };
/// assert_eq!(hits, [Highlight { line: "I like Rust", column: 7 }, Highlight { line: "Rust again", column: 0 }]);
/// ```
///
/// Exercise 2 — tying the query to `'a` as well makes the same call fail (E0597).
///
/// ```compile_fail,E0597
/// struct Highlight<'a> {
///     line: &'a str,
///     column: usize,
/// }
/// fn find_highlights<'a>(text: &'a str, word: &'a str) -> Vec<Highlight<'a>> {
///     text.lines()
///         .filter_map(|line| line.find(word).map(|column| Highlight { line, column }))
///         .collect()
/// }
/// let text = String::from("I like Rust\nC# too\nRust again");
/// let hits = {
///     let query = String::from("Rust");
///     find_highlights(&text, &query)
/// };
/// println!("{}", hits.len());
/// ```
///
/// Exercise 3 — elision ties the token to `&mut self` (E0499).
///
/// ```compile_fail,E0499
/// struct Parser<'a> {
///     input: &'a str,
///     pos: usize,
/// }
/// impl<'a> Parser<'a> {
///     fn next_token(&mut self) -> Option<&str> {
///         let start = self.pos;
///         self.pos = self.input.len();
///         Some(&self.input[start..])
///     }
/// }
/// let line = String::from("let x = 42");
/// let mut parser = Parser { input: &line, pos: 0 };
/// let first = parser.next_token();
/// let second = parser.next_token();
/// println!("{first:?} {second:?}");
/// ```
///
/// Exercise 3 — returning `&'a str` ties the token to the input instead.
///
/// ```
/// struct Parser<'a> {
///     input: &'a str,
///     pos: usize,
/// }
/// impl<'a> Parser<'a> {
///     fn next_token(&mut self) -> Option<&'a str> {
///         let start = self.pos;
///         self.pos = self.input.len();
///         Some(&self.input[start..])
///     }
/// }
/// let line = String::from("let x = 42");
/// let mut parser = Parser { input: &line, pos: 0 };
/// let first = parser.next_token();
/// let second = parser.next_token();
/// assert_eq!(first, Some("let x = 42"));
/// assert_eq!(second, Some(""));
/// ```
pub mod lesson09 {}

/// Lesson 10 — items are private to their module by default (E0603).
///
/// ```compile_fail,E0603
/// mod billing {
///     pub fn invoice_total(amounts: &[f64]) -> f64 {
///         amounts.iter().sum::<f64>() + tax(0.0)
///     }
///     fn tax(amount: f64) -> f64 {
///         amount * 0.15
///     }
/// }
/// println!("{}", billing::tax(100.0));
/// ```
///
/// Lesson 10 — a `pub` struct can still have private fields (E0451).
///
/// ```compile_fail,E0451
/// mod shapes {
///     pub struct Rect {
///         width: f64,
///         height: f64,
///     }
///     impl Rect {
///         pub fn area(&self) -> f64 {
///             self.width * self.height
///         }
///     }
/// }
/// let r = shapes::Rect { width: 2.0, height: 3.0 };
/// println!("{}", r.area());
/// ```
///
/// Lesson 10 — reading a private field (E0616).
///
/// ```compile_fail,E0616
/// mod shapes {
///     pub struct Rect {
///         width: f64,
///     }
///     impl Rect {
///         pub fn new(width: f64) -> Self {
///             Rect { width }
///         }
///     }
/// }
/// let r = shapes::Rect::new(1.0);
/// println!("{}", r.width);
/// ```
///
/// Lesson 10 — a name must be brought into scope with `use` (E0422).
///
/// ```compile_fail,E0422
/// mod shapes {
///     pub struct Rect {
///         pub width: f64,
///     }
/// }
/// let r = Rect { width: 2.0 };
/// ```
///
/// Exercise 1 — a tuple struct with a private field has a private constructor (E0603).
///
/// ```compile_fail,E0603
/// mod temperature {
///     #[derive(Debug)]
///     pub struct Celsius(f64);
/// }
/// let t = temperature::Celsius(-500.0);
/// ```
///
/// Exercise 1 — a validating constructor.
///
/// ```
/// mod temperature {
///     #[derive(Debug, PartialEq)]
///     pub struct Celsius(f64);
///
///     impl Celsius {
///         pub const ABSOLUTE_ZERO: f64 = -273.15;
///
///         pub fn new(value: f64) -> Option<Celsius> {
///             (value >= Self::ABSOLUTE_ZERO).then_some(Celsius(value))
///         }
///
///         pub fn value(&self) -> f64 {
///             self.0
///         }
///     }
/// }
/// use temperature::Celsius;
/// assert_eq!(Celsius::new(-500.0), None);
/// assert_eq!(Celsius::new(21.5).map(|c| c.value()), Some(21.5));
/// ```
pub mod lesson10 {}

/// Lesson 11 — a recursive type needs indirection (E0072).
///
/// ```compile_fail,E0072
/// enum Expr {
///     Num(f64),
///     Add(Expr, Expr),
/// }
/// ```
///
/// Lesson 11 — `Rc` gives shared, read-only access (E0596).
///
/// ```compile_fail,E0596
/// use std::rc::Rc;
/// let shared = Rc::new(vec![1, 2]);
/// let other = Rc::clone(&shared);
/// other.push(3);
/// ```
///
/// Lesson 11 — `RefCell` enforces the borrow rules at runtime.
///
/// ```should_panic
/// use std::cell::RefCell;
/// let log = RefCell::new(Vec::new());
/// let reader = log.borrow();
/// log.borrow_mut().push("boom");
/// println!("{}", reader.len());
/// ```
///
/// Lesson 11 — an `Rc` cycle is never freed.
///
/// ```
/// use std::cell::RefCell;
/// use std::rc::Rc;
/// struct Node {
///     next: RefCell<Option<Rc<Node>>>,
/// }
/// let a = Rc::new(Node { next: RefCell::new(None) });
/// let b = Rc::new(Node { next: RefCell::new(Some(Rc::clone(&a))) });
/// *a.next.borrow_mut() = Some(Rc::clone(&b));
/// let weak_a = Rc::downgrade(&a);
/// drop(a);
/// drop(b);
/// assert!(weak_a.upgrade().is_some(), "still alive: the cycle leaks");
/// ```
///
/// Exercise 1 — a boxed expression tree with negation and printing.
///
/// ```
/// enum Expr {
///     Num(f64),
///     Neg(Box<Expr>),
///     Add(Box<Expr>, Box<Expr>),
///     Mul(Box<Expr>, Box<Expr>),
/// }
/// use Expr::*;
/// fn eval(e: &Expr) -> f64 {
///     match e {
///         Num(n) => *n,
///         Neg(a) => -eval(a),
///         Add(a, b) => eval(a) + eval(b),
///         Mul(a, b) => eval(a) * eval(b),
///     }
/// }
/// fn show(e: &Expr) -> String {
///     match e {
///         Num(n) => n.to_string(),
///         Neg(a) => format!("-{}", show(a)),
///         Add(a, b) => format!("({} + {})", show(a), show(b)),
///         Mul(a, b) => format!("({} * {})", show(a), show(b)),
///     }
/// }
/// let e = Mul(Box::new(Add(Box::new(Num(2.0)), Box::new(Num(3.0)))), Box::new(Neg(Box::new(Num(4.0)))));
/// assert_eq!(show(&e), "((2 + 3) * -4)");
/// assert_eq!(eval(&e), -20.0);
/// ```
///
/// Exercise 2 — two components writing to one shared log.
///
/// ```
/// use std::cell::RefCell;
/// use std::rc::Rc;
/// type Log = Rc<RefCell<Vec<String>>>;
/// struct Cart {
///     log: Log,
/// }
/// struct Payment {
///     log: Log,
/// }
/// impl Cart {
///     fn add(&self, item: &str) {
///         self.log.borrow_mut().push(format!("cart: added {item}"));
///     }
/// }
/// impl Payment {
///     fn pay(&self, amount: u32) {
///         self.log.borrow_mut().push(format!("payment: {amount}"));
///     }
/// }
/// let log: Log = Rc::new(RefCell::new(Vec::new()));
/// let cart = Cart { log: Rc::clone(&log) };
/// let payment = Payment { log: Rc::clone(&log) };
/// cart.add("book");
/// payment.pay(40);
/// assert_eq!(*log.borrow(), ["cart: added book", "payment: 40"]);
/// ```
///
/// Exercise 2 — pushing while iterating over the same `RefCell` panics.
///
/// ```should_panic
/// use std::cell::RefCell;
/// use std::rc::Rc;
/// let lines = Rc::new(RefCell::new(vec![String::from("start")]));
/// for line in lines.borrow().iter() {
///     lines.borrow_mut().push(format!("seen {line}"));
/// }
/// ```
///
/// Exercise 3 — a `Weak` back-link breaks the cycle.
///
/// ```
/// use std::cell::RefCell;
/// use std::rc::{Rc, Weak};
/// struct Node {
///     next: RefCell<Option<Rc<Node>>>,
///     prev: RefCell<Weak<Node>>,
/// }
/// let a = Rc::new(Node { next: RefCell::new(None), prev: RefCell::new(Weak::new()) });
/// let b = Rc::new(Node { next: RefCell::new(None), prev: RefCell::new(Weak::new()) });
/// *a.next.borrow_mut() = Some(Rc::clone(&b));
/// *b.prev.borrow_mut() = Rc::downgrade(&a);
/// assert_eq!((Rc::strong_count(&a), Rc::strong_count(&b)), (1, 2));
/// let weak_b = Rc::downgrade(&b);
/// drop(b);
/// drop(a);
/// assert!(weak_b.upgrade().is_none(), "both nodes were freed");
/// ```
///
/// Lesson 11 — `Rc` is not `Send` (E0277).
///
/// ```compile_fail,E0277
/// use std::rc::Rc;
/// let config = Rc::new(String::from("prod"));
/// let copy = Rc::clone(&config);
/// let handle = std::thread::spawn(move || println!("{copy}"));
/// handle.join().unwrap();
/// ```
pub mod lesson11 {}

/// Lesson 12 — a spawned thread cannot borrow local variables (E0373).
///
/// ```compile_fail,E0373
/// let names = vec!["ada", "grace"];
/// let handle = std::thread::spawn(|| {
///     println!("{names:?}");
/// });
/// handle.join().unwrap();
/// ```
///
/// Lesson 12 — two threads mutating the same variable: a data race, rejected (E0499).
///
/// ```compile_fail,E0499
/// let mut count = 0;
/// std::thread::scope(|s| {
///     s.spawn(|| count += 1);
///     s.spawn(|| count += 1);
/// });
/// println!("{count}");
/// ```
///
/// Lesson 12 — `RefCell` is not `Sync` (E0277).
///
/// ```compile_fail,E0277
/// use std::cell::RefCell;
/// use std::sync::Arc;
/// let total = Arc::new(RefCell::new(0));
/// let t = Arc::clone(&total);
/// std::thread::spawn(move || *t.borrow_mut() += 1).join().unwrap();
/// ```
///
/// Lesson 12 — the data inside a `Mutex` is only reachable through `lock()` (E0614).
///
/// ```compile_fail,E0614
/// let count = std::sync::Mutex::new(0);
/// *count += 1;
/// ```
///
/// Lesson 12 — rayon closures are `Fn`: no mutation of captured variables (E0594).
///
/// ```compile_fail,E0594
/// use rayon::prelude::*;
/// let mut seen = 0;
/// let doubled: Vec<i32> = (1..100).into_par_iter().map(|n| { seen += 1; n * 2 }).collect();
/// ```
///
/// Exercise 1 — parallel sum with scoped threads.
///
/// ```
/// fn parallel_sum(data: &[u64], threads: usize) -> u64 {
///     let chunk_size = data.len().div_ceil(threads.max(1)).max(1);
///     std::thread::scope(|s| {
///         let handles: Vec<_> = data.chunks(chunk_size).map(|chunk| s.spawn(move || chunk.iter().sum::<u64>())).collect();
///         handles.into_iter().map(|h| h.join().unwrap()).sum()
///     })
/// }
/// let data: Vec<u64> = (1..=10_001).collect();
/// assert_eq!(parallel_sum(&data, 4), 50_015_001);
/// assert_eq!(parallel_sum(&data, 64), 50_015_001);
/// assert_eq!(parallel_sum(&[], 4), 0);
/// ```
///
/// Exercise 2 — workers count words locally and send their maps through a channel.
///
/// ```
/// use std::collections::HashMap;
/// use std::sync::mpsc;
/// fn count_words(texts: &[&str]) -> HashMap<String, usize> {
///     let (sender, receiver) = mpsc::channel();
///     std::thread::scope(|s| {
///         for &text in texts {
///             let sender = sender.clone();
///             s.spawn(move || {
///                 let mut local = HashMap::new();
///                 for word in text.split_whitespace() {
///                     *local.entry(word.to_lowercase()).or_insert(0) += 1;
///                 }
///                 sender.send(local).unwrap();
///             });
///         }
///     });
///     drop(sender);
///     let mut total = HashMap::new();
///     for local in receiver {
///         for (word, n) in local {
///             *total.entry(word).or_insert(0) += n;
///         }
///     }
///     total
/// }
/// let counts = count_words(&["the cat", "The dog", "a cat and THE end"]);
/// assert_eq!(counts["the"], 3);
/// assert_eq!(counts["cat"], 2);
/// assert_eq!(counts.len(), 6);
/// ```
///
/// Exercise 3 — the same count with rayon.
///
/// ```
/// use rayon::prelude::*;
/// fn is_prime(n: u64) -> bool {
///     n >= 2 && (2..).take_while(|d| d * d <= n).all(|d| !n.is_multiple_of(d))
/// }
/// let limit = 100_000u64;
/// let sequential = (1..limit).filter(|&n| is_prime(n)).count();
/// let parallel = (1..limit).into_par_iter().filter(|&n| is_prime(n)).count();
/// assert_eq!(sequential, 9_592);
/// assert_eq!(parallel, sequential);
/// ```
pub mod lesson12 {}
