---
title: 11. Box, Rc, Arc et RefCell
description: Allocation sur le tas, possession partagée et mutabilité intérieure — comment Rust exprime les graphes d'objets que C# et Java offrent gratuitement.
sidebar:
  order: 11
---

Exemple complet : [`examples/l11_smart_pointers.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l11_smart_pointers.rs) — `cargo run --example l11_smart_pointers`.

## Pourquoi des « pointeurs intelligents » ?

En C# et en Java, chaque objet d'une classe vit sur le tas, un nombre quelconque de variables peuvent y faire référence, n'importe laquelle peut le modifier, et le ramasse-miettes le libère quand plus personne n'y fait référence.

Rust sépare ce lot en éléments distincts, à demander explicitement :

| Vous avez besoin de | Rust | Coût |
|---|---|---|
| une valeur sur le tas avec **un seul** propriétaire | [`Box<T>`](https://doc.rust-lang.org/std/boxed/struct.Box.html) | une allocation |
| **plusieurs propriétaires** d'une valeur, un seul thread | [`Rc<T>`](https://doc.rust-lang.org/std/rc/struct.Rc.html) | un compteur de références |
| plusieurs propriétaires sur plusieurs **threads** | [`Arc<T>`](https://doc.rust-lang.org/std/sync/struct.Arc.html) | un compteur de références atomique |
| **modifier** quelque chose de partagé | [`RefCell<T>`](https://doc.rust-lang.org/std/cell/struct.RefCell.html) (un thread), [`Mutex<T>`](https://doc.rust-lang.org/std/sync/struct.Mutex.html) (threads) | une vérification d'emprunt à l'exécution |

Une référence de classe C# correspond à peu près à `Rc<RefCell<T>>` (ou à `Arc<Mutex<T>>` quand des threads sont en jeu). Rust vous fait demander chaque capacité, et la plupart du code n'en a besoin d'aucune.

On les appelle *pointeurs intelligents* (smart pointers) parce qu'ils possèdent leurs données et implémentent [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) — `.` appelle les méthodes de la valeur contenue — et [`Drop`](https://doc.rust-lang.org/std/ops/trait.Drop.html) — le nettoyage se fait automatiquement.

## `Box<T>` : un seul propriétaire, sur le tas

`Box::new(value)` déplace la valeur sur le tas ; la `Box` elle-même est un propriétaire de la taille d'un pointeur. Quand la box sort de la portée, la mémoire sur le tas est libérée.

Vous avez déjà rencontré `Box<dyn Trait>` dans la [leçon 7](../07-traits-and-generics/). L'autre usage classique est un **type récursif**. En C#, `class Expr { Expr Left; }` ne pose pas de problème, car `Left` est une référence. En Rust, un enum stocke ses champs en ligne, donc un type qui se contient lui-même serait infiniment grand :

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

Une `Box` a une taille fixe, quoi qu'elle pointe :

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
        Expr::Add(a, b) => eval(a) + eval(b),   // &Box<Expr> est utilisé comme &Expr
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

## `Rc<T>` : la possession partagée

Parfois, une valeur n'a pas de propriétaire unique naturel : plusieurs services partagent une configuration, plusieurs nœuds d'un graphe pointent vers le même nœud. `Rc` (*reference counted*, à comptage de références) le permet :

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

`Rc::clone` ne copie **pas** la `Config` : il incrémente un compteur et renvoie un autre pointeur vers la même valeur. Quand le dernier `Rc` est détruit, le compteur atteint zéro et la valeur est libérée — de manière déterministe, contrairement à un ramasse-miettes. La convention d'écrire `Rc::clone(&x)` plutôt que `x.clone()` rend visible en revue de code cette copie de pointeur bon marché.

Partagé signifie **en lecture seule**. Deux propriétaires qui modifient la même valeur, c'est précisément ce qu'interdisent les règles d'emprunt :

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

## `RefCell<T>` : les règles d'emprunt vérifiées à l'exécution

La **mutabilité intérieure** permet de modifier à travers une référence partagée. `RefCell` conserve la règle de la [leçon 4](../04-borrowing-and-strings/) — plusieurs lecteurs *ou* un seul rédacteur — mais la vérifie pendant l'exécution du programme plutôt qu'à sa compilation :

```rust
use std::cell::RefCell;

#[derive(Debug)]
struct Account { balance: i64 }

let account = Rc::new(RefCell::new(Account { balance: 100 }));
let alice = Rc::clone(&account);
let bob = Rc::clone(&account);

alice.borrow_mut().balance -= 30;    // borrow_mut() -> RefMut<Account>, comme &mut
bob.borrow_mut().balance += 5;
println!("{:?}", account.borrow());  // borrow() -> Ref<Account>, comme &
// Account { balance: 75 }
```

Enfreignez la règle et le programme **panique** :

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

[`try_borrow`](https://doc.rust-lang.org/std/cell/struct.RefCell.html#method.try_borrow) et [`try_borrow_mut`](https://doc.rust-lang.org/std/cell/struct.RefCell.html#method.try_borrow_mut) renvoient un `Result` au lieu de paniquer :

```rust
let reading = account.borrow();
account.try_borrow_mut().is_err()    // true : refusé tant que `reading` est vivant
```

:::caution[Vous échangez une erreur de compilation contre un plantage possible]
`RefCell` est le bon outil quand le compilateur ne peut pas voir que votre schéma d'accès est sûr — un cache partagé, une liste d'observateurs, un graphe. Gardez chaque `borrow_mut()` aussi court que possible (ne le conservez pas pendant un appel qui pourrait emprunter à nouveau), et préférez la possession simple et `&mut` quand ils suffisent. C'est la version à l'exécution de l'[`InvalidOperationException: Collection was modified`](https://learn.microsoft.com/dotnet/api/system.invalidoperationexception) de C#.
:::

Pour les valeurs `Copy` comme les compteurs et les indicateurs, [`Cell<T>`](https://doc.rust-lang.org/std/cell/struct.Cell.html) est plus simple : elle ne prête jamais de référence, elle se contente de lire et d'écrire la valeur.

```rust
use std::cell::Cell;
let hits = Cell::new(0);
hits.set(hits.get() + 1);
```

## Les cycles fuient — utilisez `Weak`

Le comptage de références ne peut pas libérer un cycle : si `a` pointe vers `b` et `b` vers `a`, les deux compteurs restent au-dessus de zéro pour toujours. Un ramasse-miettes gère ce cas ; `Rc`, non.

```rust
struct Node {
    name: &'static str,
    next: RefCell<Option<Rc<Node>>>,
}
// avec une impl de Drop qui affiche "drop {name}"

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

Les messages `drop` n'apparaissent jamais : la mémoire a fui. C'est *sûr pour la mémoire* — pas de pointeur pendant — mais c'est tout de même un bug.

La solution est un pointeur **[`Weak<T>`](https://doc.rust-lang.org/std/rc/struct.Weak.html)** pour l'un des deux sens du lien. Un `Weak` ne maintient pas la valeur en vie ; [`upgrade()`](https://doc.rust-lang.org/std/rc/struct.Weak.html#method.upgrade) renvoie `Some(Rc<T>)` si la valeur existe encore et `None` sinon — comme [`WeakReference<T>.TryGetTarget`](https://learn.microsoft.com/dotnet/api/system.weakreference-1.trygettarget) en C# ou [`WeakReference.get()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ref/WeakReference.html) en Java. La conception habituelle : les parents possèdent leurs enfants (`Rc`), les enfants pointent vers leur parent (`Weak`).

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

## `Arc<T>` : `Rc` pour les threads

`Rc` met à jour son compteur sans synchronisation, donc le compilateur refuse de l'envoyer vers un autre thread :

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

`Arc` (*atomically reference counted*, à comptage de références atomique) offre la même API avec un compteur thread-safe :

```rust
use std::sync::Arc;

let shared = Arc::new(vec![1, 2, 3]);
let for_thread = Arc::clone(&shared);
let sum = std::thread::spawn(move || for_thread.iter().sum::<i32>()).join().unwrap();
// sum computed on another thread: 6, strong count back to 1
```

Pourquoi ne pas toujours utiliser `Arc` ? Les opérations atomiques coûtent plus cher, et `Rc` documente qu'une valeur reste sur un seul thread. Le partenaire thread-safe de `RefCell` est `Mutex` ou [`RwLock`](https://doc.rust-lang.org/std/sync/struct.RwLock.html) — [leçon 12](../12-threads-and-concurrency/).

## Choisir

| Question | Réponse |
|---|---|
| Un seul propriétaire, mais la valeur doit être sur le tas (type récursif, `dyn Trait`, grosse valeur à déplacer à moindre coût) ? | `Box<T>` |
| Plusieurs propriétaires, en lecture seule, un seul thread ? | `Rc<T>` |
| Plusieurs propriétaires, en lecture seule, plusieurs threads ? | `Arc<T>` |
| Plusieurs propriétaires qui modifient, un seul thread ? | `Rc<RefCell<T>>` |
| Plusieurs propriétaires qui modifient, plusieurs threads ? | `Arc<Mutex<T>>` ou `Arc<RwLock<T>>` |
| Une référence arrière ou un cache qui ne doit pas maintenir les valeurs en vie ? | `Weak<T>` |

## À retenir

- C# et Java donnent d'un coup à chaque objet l'allocation sur le tas, le partage et la mutation ; Rust rend chacun explicite.
- `Box<T>` place une valeur possédée sur le tas : types récursifs et objets trait.
- `Rc<T>` et `Arc<T>` comptent les propriétaires et libèrent la valeur quand le dernier disparaît ; `Rc::clone` copie un pointeur, pas les données.
- `RefCell<T>` déplace la vérification des emprunts à l'exécution : les violations paniquent au lieu d'empêcher la compilation.
- Le comptage de références fait fuir les cycles ; cassez-les avec `Weak<T>`.
- `Rc` n'est pas [`Send`](https://doc.rust-lang.org/std/marker/trait.Send.html) ; utilisez `Arc` entre threads.

## Exercices

1. Ajoutez une variante `Neg(Box<Expr>)` à `Expr`, mettez `eval` à jour, et écrivez `fn show(e: &Expr) -> String` de sorte que `(2 + 3) * -4` s'affiche `((2 + 3) * -4)`.

<details>
<summary>Solution</summary>

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

`use Expr::*;` amène les variantes dans la portée. Le `to_string()` de `f64` affiche `2.0` sous la forme `2`.

</details>

2. Un `Cart` et un `Payment` doivent tous deux ajouter des lignes au même journal. Modélisez-le avec `type Log = Rc<RefCell<Vec<String>>>`. Puis prédisez ce que fait ce code :

```rust
let lines = Rc::new(RefCell::new(vec![String::from("start")]));
for line in lines.borrow().iter() {
    lines.borrow_mut().push(format!("seen {line}"));
}
```

<details>
<summary>Solution</summary>

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

Notez que `add` et `pay` prennent `&self`, pas `&mut self` : la mutation est cachée à l'intérieur du `RefCell`.

La boucle compile mais **panique** avec `RefCell already borrowed` : l'itérateur détient un `borrow()` pendant toute la boucle, et le `borrow_mut()` à l'intérieur est refusé. C'est l'erreur « push pendant l'itération » de la leçon 4, déplacée de la compilation à l'exécution. Collectez d'abord les nouvelles lignes, puis ajoutez-les.

</details>

3. Dans l'exemple de `Node` qui fuit, `a` pointe vers `b` et `b` pointe vers `a`. Modifiez la conception pour que les deux nœuds soient libérés à la fin de la portée, et vérifiez les compteurs forts.

<details>
<summary>Solution</summary>

Gardez `next` comme lien fort et rendez le lien arrière `Weak` :

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

`b` est détruit en premier (son compteur passe de 2 à 1), puis `a` (de 1 à 0, donc la valeur est libérée), et la libération de `a` détruit son `next`, ce qui libère `b`.

</details>

## Sources

- [The Book, ch. 15 — Smart Pointers](https://doc.rust-lang.org/book/ch15-00-smart-pointers.html)
- [`std::rc`](https://doc.rust-lang.org/std/rc/index.html) et [`std::sync::Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html)
- [`std::cell`](https://doc.rust-lang.org/std/cell/index.html) — `Cell`, `RefCell` et la mutabilité intérieure
- [The Book, ch. 15.6 — Reference Cycles Can Leak Memory](https://doc.rust-lang.org/book/ch15-06-reference-cycles.html)
