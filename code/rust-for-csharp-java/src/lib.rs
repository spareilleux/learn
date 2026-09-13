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
