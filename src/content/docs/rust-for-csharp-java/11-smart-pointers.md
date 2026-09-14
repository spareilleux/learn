---
title: 11. Box, Rc, Arc and RefCell
description: Heap allocation, shared ownership and interior mutability — how Rust expresses the object graphs C# and Java get for free.
sidebar:
  order: 11
---

Full example: [`examples/l11_smart_pointers.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l11_smart_pointers.rs) — `cargo run --example l11_smart_pointers`.

## Why "smart pointers"?

In C# and Java, every object of a class lives on the heap, any number of variables can refer to it, any of them can modify it, and the garbage collector frees it when nobody refers to it anymore.

Rust splits that bundle into separate, opt-in pieces:

| You need | Rust | Cost |
|---|---|---|
| a value on the heap with **one** owner | [`Box<T>`](https://doc.rust-lang.org/std/boxed/struct.Box.html) | one allocation |
| **several owners** of a value, one thread | [`Rc<T>`](https://doc.rust-lang.org/std/rc/struct.Rc.html) | a reference count |
| several owners across **threads** | [`Arc<T>`](https://doc.rust-lang.org/std/sync/struct.Arc.html) | an atomic reference count |
| to **mutate** something that is shared | [`RefCell<T>`](https://doc.rust-lang.org/std/cell/struct.RefCell.html) (one thread), [`Mutex<T>`](https://doc.rust-lang.org/std/sync/struct.Mutex.html) (threads) | a borrow check at runtime |

A C# class reference is roughly `Rc<RefCell<T>>` (or `Arc<Mutex<T>>` when threads are involved). Rust makes you ask for each capability, and most code needs none of them.

They are called *smart pointers* because they own their data and implement [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) — `.` calls methods on the value inside — and [`Drop`](https://doc.rust-lang.org/std/ops/trait.Drop.html) — cleanup happens automatically.

## `Box<T>`: one owner, on the heap

`Box::new(value)` moves the value to the heap; the `Box` itself is a pointer-sized owner. When the box goes out of scope, the heap memory is freed.

You already met `Box<dyn Trait>` in [lesson 7](../07-traits-and-generics/). The other classic use is a **recursive type**. In C#, `class Expr { Expr Left; }` is fine because `Left` is a reference. In Rust, an enum stores its fields inline, so a type containing itself would be infinitely large ([`src/lib.rs`, lines 742-745](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L742-L745)):

```rust
enum Expr {
    Num(f64),
    Add(Expr, Expr),
}
```

```text
error[E0072]: recursive type `Expr` has infinite size
 --> e11_recursive.rs:1:1
  |
1 | enum Expr {
  | ^^^^^^^^^
2 |     Num(f64),
3 |     Add(Expr, Expr),
  |         ---- recursive without indirection
  |
help: insert some indirection (e.g., a `Box`, `Rc`, or `&`) to break the cycle
  |
3 |     Add(Box<Expr>, Expr),
  |         ++++    +
```

A `Box` has a fixed size, whatever it points to ([lines 6-19](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L6-L19), [52-58](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L52-L58)):

```rust
#[derive(Debug)]
enum Expr {
    Num(f64),
    Add(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
}

fn eval(expr: &Expr) -> f64 {
    match expr {
        Expr::Num(n) => *n,
        Expr::Add(a, b) => eval(a) + eval(b),   // &Box<Expr> is used as &Expr
        Expr::Mul(a, b) => eval(a) * eval(b),
    }
}

// (2 + 3) * 4
let expr = Expr::Mul(
    Box::new(Expr::Add(Box::new(Expr::Num(2.0)), Box::new(Expr::Num(3.0)))),
    Box::new(Expr::Num(4.0)),
);
// Mul(Add(Num(2.0), Num(3.0)), Num(4.0)) = 20
```

## `Rc<T>`: shared ownership

Sometimes a value has no single natural owner: several services share one configuration, several nodes of a graph point to the same node. `Rc` (*reference counted*) allows that:

```rust
use std::rc::Rc;

struct Config { env: String }
struct Service { name: &'static str, config: Rc<Config> }

let config = Rc::new(Config { env: "prod".into() });
let api = Service { name: "api", config: Rc::clone(&config) };
let worker = Service { name: "worker", config: Rc::clone(&config) };
println!("strong count = {}", Rc::strong_count(&config));   // 3

drop(api);
println!("strong count = {}", Rc::strong_count(&config));   // 2
```

`Rc::clone` does **not** copy the `Config`: it increments a counter and returns another pointer to the same value. When the last `Rc` is dropped, the counter reaches zero and the value is freed — deterministic, unlike a garbage collector. The convention of writing `Rc::clone(&x)` rather than `x.clone()` makes the cheap pointer copy visible in code review.

Shared means **read-only**. Two owners mutating the same value is precisely what the borrow rules forbid ([`src/lib.rs`, lines 752-754](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L752-L754)):

```rust
let shared = Rc::new(vec![1, 2]);
let other = Rc::clone(&shared);
other.push(3);
```

```text
error[E0596]: cannot borrow data in an `Rc` as mutable
 --> e11_rc_mut.rs:6:5
  |
6 |     other.push(3);
  |     ^^^^^ cannot borrow as mutable
  |
  = help: trait `DerefMut` is required to modify through a dereference, but it is not implemented for `Rc<Vec<i32>>`
```

## `RefCell<T>`: borrow rules checked at runtime

**Interior mutability** lets you mutate through a shared reference. `RefCell` keeps the rule from [lesson 4](../04-borrowing-and-strings/) — many readers *or* one writer — but checks it when the program runs instead of when it compiles:

```rust
use std::cell::RefCell;

#[derive(Debug)]
struct Account { balance: i64 }

let account = Rc::new(RefCell::new(Account { balance: 100 }));
let alice = Rc::clone(&account);
let bob = Rc::clone(&account);

alice.borrow_mut().balance -= 30;    // borrow_mut() -> RefMut<Account>, like &mut
bob.borrow_mut().balance += 5;
println!("{:?}", account.borrow());  // borrow() -> Ref<Account>, like &
// Account { balance: 75 }
```

Break the rule and the program **panics** ([`src/lib.rs`, lines 761-764](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L761-L764), [`core/src/cell.rs`](https://github.com/rust-lang/rust/blob/1.94.0/library/core/src/cell.rs#L885-L895)):

```rust
let log = RefCell::new(Vec::new());
let reader = log.borrow();
log.borrow_mut().push("boom");
println!("{}", reader.len());
```

```text
thread 'main' (…) panicked at p11_refcell.rs:6:9:
RefCell already borrowed
```

[`try_borrow`](https://doc.rust-lang.org/std/cell/struct.RefCell.html#method.try_borrow) and [`try_borrow_mut`](https://doc.rust-lang.org/std/cell/struct.RefCell.html#method.try_borrow_mut) return a `Result` instead of panicking ([lines 92-95](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L92-L95)):

```rust
let reading = account.borrow();
account.try_borrow_mut().is_err()    // true: refused while `reading` is alive
```

:::caution[You trade a compile error for a possible crash]
`RefCell` is the right tool when the compiler cannot see that your access pattern is safe — a shared cache, an observer list, a graph. Keep each `borrow_mut()` as short as possible (don't hold one across a call that might borrow again), and prefer plain ownership and `&mut` when they work. It is the runtime version of C#'s [`InvalidOperationException: Collection was modified`](https://learn.microsoft.com/dotnet/api/system.invalidoperationexception).
:::

For `Copy` values such as counters and flags, [`Cell<T>`](https://doc.rust-lang.org/std/cell/struct.Cell.html) is simpler: it never lends a reference, it just gets and sets.

```rust
use std::cell::Cell;
let hits = Cell::new(0);
hits.set(hits.get() + 1);
```

## Cycles leak — use `Weak`

Reference counting cannot free a cycle: if `a` points to `b` and `b` points to `a`, both counts stay above zero forever. A garbage collector handles this; `Rc` does not.

```rust
struct Node {
    name: &'static str,
    next: RefCell<Option<Rc<Node>>>,
}
// with a Drop impl that prints "drop {name}"

{
    let a = Rc::new(Node { name: "a", next: RefCell::new(None) });
    let b = Rc::new(Node { name: "b", next: RefCell::new(Some(Rc::clone(&a))) });
    *a.next.borrow_mut() = Some(Rc::clone(&b));
    println!("a strong = {}, b strong = {}", Rc::strong_count(&a), Rc::strong_count(&b));
}
println!("end of scope: nothing dropped");
```

```text
a strong = 2, b strong = 2
end of scope: nothing dropped
```

The `drop` messages never appear: the memory leaked. This is *memory-safe* — no dangling pointer — but still a bug.

The fix is a **[`Weak<T>`](https://doc.rust-lang.org/std/rc/struct.Weak.html)** pointer for one direction of the link. A `Weak` does not keep the value alive; [`upgrade()`](https://doc.rust-lang.org/std/rc/struct.Weak.html#method.upgrade) returns `Some(Rc<T>)` if the value still exists and `None` otherwise — like C#'s [`WeakReference<T>.TryGetTarget`](https://learn.microsoft.com/dotnet/api/system.weakreference-1.trygettarget) or Java's [`WeakReference.get()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ref/WeakReference.html). The usual design: parents own their children (`Rc`), children point back to their parent (`Weak`).

From [`examples/l11_smart_pointers.rs`, lines 38-42](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L38-L42), [130-132](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L130-L132):

```rust
struct TreeNode {
    name: String,
    parent: RefCell<Weak<TreeNode>>,
    children: RefCell<Vec<Rc<TreeNode>>>,
}

*leaf.parent.borrow_mut() = Rc::downgrade(&root);
root.children.borrow_mut().push(Rc::clone(&leaf));

let parent_name = leaf.parent.borrow().upgrade().map(|p| p.name.clone());
```

```text
leaf's parent: Some("root"), children of root: 1
root strong = 1, weak = 1
drop root
drop leaf
tree scope ended
```

## `Arc<T>`: `Rc` for threads

`Rc` updates its counter without synchronisation, so the compiler refuses to send it to another thread ([`src/lib.rs`, lines 880-882](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L880-L882)):

```rust
let config = Rc::new(String::from("prod"));
let copy = Rc::clone(&config);
let handle = std::thread::spawn(move || println!("{copy}"));
```

```text
error[E0277]: `Rc<String>` cannot be sent between threads safely
   --> e11_rc_thread.rs:7:32
    |
  7 |     let handle = thread::spawn(move || println!("{copy}"));
    |                  ------------- -------^^^^^^^^^^^^^^^^^^^
    |                  |             |
    |                  |             `Rc<String>` cannot be sent between threads safely
    |                  |             within this `{closure@e11_rc_thread.rs:7:32: 7:39}`
    |                  required by a bound introduced by this call
    |
    = help: within `{closure@e11_rc_thread.rs:7:32: 7:39}`, the trait `Send` is not implemented for `Rc<String>`
```

`Arc` (*atomically reference counted*) has the same API with a thread-safe counter ([lines 3](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L3), [146-150](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L146-L150)):

```rust
use std::sync::Arc;

let shared = Arc::new(vec![1, 2, 3]);
let for_thread = Arc::clone(&shared);
let sum = std::thread::spawn(move || for_thread.iter().sum::<i32>()).join().unwrap();
// sum computed on another thread: 6, strong count back to 1
```

Why not always use `Arc`? Atomic operations cost more, and `Rc` documents that a value stays on one thread. The thread-safe partner of `RefCell` is `Mutex` or [`RwLock`](https://doc.rust-lang.org/std/sync/struct.RwLock.html) — [lesson 12](../12-threads-and-concurrency/).

## Choosing

| Question | Answer |
|---|---|
| One owner, but the value must be on the heap (recursive type, `dyn Trait`, large value to move cheaply)? | `Box<T>` |
| Several owners, read-only, one thread? | `Rc<T>` |
| Several owners, read-only, several threads? | `Arc<T>` |
| Several owners that mutate, one thread? | `Rc<RefCell<T>>` |
| Several owners that mutate, several threads? | `Arc<Mutex<T>>` or `Arc<RwLock<T>>` |
| A back-reference or a cache that must not keep things alive? | `Weak<T>` |

## Key takeaways

- C# and Java give every object heap allocation, sharing and mutation at once; Rust makes each one explicit.
- `Box<T>` puts one owned value on the heap: recursive types and trait objects.
- `Rc<T>` and `Arc<T>` count owners and free the value when the last one goes; `Rc::clone` copies a pointer, not the data.
- `RefCell<T>` moves the borrow check to runtime: violations panic instead of failing to compile.
- Reference counting leaks cycles; break them with `Weak<T>`.
- `Rc` is not [`Send`](https://doc.rust-lang.org/std/marker/trait.Send.html); use `Arc` across threads.

## Exercises

1. Add a `Neg(Box<Expr>)` variant to `Expr`, update `eval`, and write `fn show(e: &Expr) -> String` so that `(2 + 3) * -4` prints as `((2 + 3) * -4)`.

<details>
<summary>Solution</summary>

From [`src/lib.rs`, lines 787-812](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L787-L812):

```rust
enum Expr {
    Num(f64),
    Neg(Box<Expr>),
    Add(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
}

use Expr::*;

fn eval(e: &Expr) -> f64 {
    match e {
        Num(n) => *n,
        Neg(a) => -eval(a),
        Add(a, b) => eval(a) + eval(b),
        Mul(a, b) => eval(a) * eval(b),
    }
}

fn show(e: &Expr) -> String {
    match e {
        Num(n) => n.to_string(),
        Neg(a) => format!("-{}", show(a)),
        Add(a, b) => format!("({} + {})", show(a), show(b)),
        Mul(a, b) => format!("({} * {})", show(a), show(b)),
    }
}

let e = Mul(Box::new(Add(Box::new(Num(2.0)), Box::new(Num(3.0)))), Box::new(Neg(Box::new(Num(4.0)))));
assert_eq!(show(&e), "((2 + 3) * -4)");
assert_eq!(eval(&e), -20.0);
```

`use Expr::*;` brings the variants into scope. `f64`'s `to_string()` prints `2.0` as `2`.

</details>

2. A `Cart` and a `Payment` must both append lines to the same log. Model it with `type Log = Rc<RefCell<Vec<String>>>`. Then predict what this does ([`src/lib.rs`, lines 850-853](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L850-L853)):

```rust
let lines = Rc::new(RefCell::new(vec![String::from("start")]));
for line in lines.borrow().iter() {
    lines.borrow_mut().push(format!("seen {line}"));
}
```

<details>
<summary>Solution</summary>

From [`src/lib.rs`, lines 818-842](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L818-L842):

```rust
use std::cell::RefCell;
use std::rc::Rc;

type Log = Rc<RefCell<Vec<String>>>;

struct Cart { log: Log }
struct Payment { log: Log }

impl Cart {
    fn add(&self, item: &str) {
        self.log.borrow_mut().push(format!("cart: added {item}"));
    }
}

impl Payment {
    fn pay(&self, amount: u32) {
        self.log.borrow_mut().push(format!("payment: {amount}"));
    }
}

let log: Log = Rc::new(RefCell::new(Vec::new()));
let cart = Cart { log: Rc::clone(&log) };
let payment = Payment { log: Rc::clone(&log) };
cart.add("book");
payment.pay(40);
assert_eq!(*log.borrow(), ["cart: added book", "payment: 40"]);
```

Note that `add` and `pay` take `&self`, not `&mut self`: the mutation is hidden inside the `RefCell`.

The loop compiles but **panics** with `RefCell already borrowed`: the iterator holds a `borrow()` for the whole loop, and `borrow_mut()` inside it is refused. It is lesson 4's "push while iterating" error, moved from compile time to runtime. Collect the new lines first, then push them.

</details>

3. In the leaking `Node` example, `a` points to `b` and `b` points to `a`. Change the design so both nodes are freed at the end of the scope, and check the strong counts.

<details>
<summary>Solution</summary>

Keep `next` as a strong link and make the backward link `Weak` ([`src/lib.rs`, lines 859-873](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L859-L873)):

```rust
use std::cell::RefCell;
use std::rc::{Rc, Weak};

struct Node {
    name: &'static str,
    next: RefCell<Option<Rc<Node>>>,
    prev: RefCell<Weak<Node>>,
}

{
    let a = Rc::new(Node { name: "a", next: RefCell::new(None), prev: RefCell::new(Weak::new()) });
    let b = Rc::new(Node { name: "b", next: RefCell::new(None), prev: RefCell::new(Weak::new()) });
    *a.next.borrow_mut() = Some(Rc::clone(&b));
    *b.prev.borrow_mut() = Rc::downgrade(&a);
    println!("a strong = {}, b strong = {}", Rc::strong_count(&a), Rc::strong_count(&b));
}
println!("end of scope");
```

```text
a strong = 1, b strong = 2
drop a
drop b
end of scope
```

`b` is dropped first (its count goes from 2 to 1), then `a` (1 to 0, so it is freed), and freeing `a` drops its `next`, which frees `b`.

</details>

## Sources

- [The Book, ch. 15 — Smart Pointers](https://doc.rust-lang.org/book/ch15-00-smart-pointers.html)
- [`std::rc`](https://doc.rust-lang.org/std/rc/index.html) and [`std::sync::Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html)
- [`std::cell`](https://doc.rust-lang.org/std/cell/index.html) — `Cell`, `RefCell` and interior mutability
- [The Book, ch. 15.6 — Reference Cycles Can Leak Memory](https://doc.rust-lang.org/book/ch15-06-reference-cycles.html)
