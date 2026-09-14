---
title: 11. Box, Rc, Arc y RefCell
description: Asignación en el heap, ownership compartido y mutabilidad interior — cómo expresa Rust los grafos de objetos que C# y Java dan gratis.
sidebar:
  order: 11
---

Ejemplo completo: [`examples/l11_smart_pointers.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l11_smart_pointers.rs) — `cargo run --example l11_smart_pointers`.

## ¿Por qué «punteros inteligentes»?

En C# y Java, todo objeto de una clase vive en el heap, cualquier número de variables puede referirse a él, cualquiera de ellas puede modificarlo, y el recolector de basura lo libera cuando ya nadie se refiere a él.

Rust separa ese paquete en piezas independientes que se piden explícitamente:

| Necesitas | Rust | Coste |
|---|---|---|
| un valor en el heap con **un solo** propietario | [`Box<T>`](https://doc.rust-lang.org/std/boxed/struct.Box.html) | una asignación |
| **varios propietarios** de un valor, un solo hilo | [`Rc<T>`](https://doc.rust-lang.org/std/rc/struct.Rc.html) | un contador de referencias |
| varios propietarios entre **hilos** | [`Arc<T>`](https://doc.rust-lang.org/std/sync/struct.Arc.html) | un contador de referencias atómico |
| **modificar** algo compartido | [`RefCell<T>`](https://doc.rust-lang.org/std/cell/struct.RefCell.html) (un hilo), [`Mutex<T>`](https://doc.rust-lang.org/std/sync/struct.Mutex.html) (hilos) | una comprobación de préstamos en tiempo de ejecución |

Una referencia a una clase de C# es, a grandes rasgos, `Rc<RefCell<T>>` (o `Arc<Mutex<T>>` cuando hay hilos de por medio). Rust te obliga a pedir cada capacidad, y la mayor parte del código no necesita ninguna.

Se llaman *punteros inteligentes* (smart pointers) porque son dueños de sus datos e implementan [`Deref`](https://doc.rust-lang.org/std/ops/trait.Deref.html) — `.` llama a los métodos del valor contenido — y [`Drop`](https://doc.rust-lang.org/std/ops/trait.Drop.html) — la limpieza ocurre automáticamente.

## `Box<T>`: un propietario, en el heap

`Box::new(value)` mueve el valor al heap; el propio `Box` es un propietario del tamaño de un puntero. Cuando el box sale de ámbito, se libera la memoria del heap.

Ya conociste `Box<dyn Trait>` en la [lección 7](../07-traits-and-generics/). El otro uso clásico es un **tipo recursivo**. En C#, `class Expr { Expr Left; }` no plantea problema porque `Left` es una referencia. En Rust, un enum almacena sus campos en línea, así que un tipo que se contiene a sí mismo sería infinitamente grande ([`src/lib.rs`, líneas 742-745](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L742-L745)):

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

Un `Box` tiene un tamaño fijo, apunte a lo que apunte ([líneas 6-19](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L6-L19), [52-58](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L52-L58)):

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
        Expr::Add(a, b) => eval(a) + eval(b),   // &Box<Expr> se usa como &Expr
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

## `Rc<T>`: ownership compartido

A veces un valor no tiene un único propietario natural: varios servicios comparten una configuración, varios nodos de un grafo apuntan al mismo nodo. `Rc` (*reference counted*, con contador de referencias) lo permite:

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

`Rc::clone` **no** copia el `Config`: incrementa un contador y devuelve otro puntero al mismo valor. Cuando se libera el último `Rc`, el contador llega a cero y el valor se libera — de forma determinista, a diferencia de un recolector de basura. La convención de escribir `Rc::clone(&x)` en lugar de `x.clone()` hace visible en la revisión de código que se trata de una copia barata de puntero.

Compartido significa **solo lectura**. Dos propietarios que modifican el mismo valor es precisamente lo que prohíben las reglas de préstamo ([`src/lib.rs`, líneas 752-754](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L752-L754)):

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

## `RefCell<T>`: reglas de préstamo comprobadas en tiempo de ejecución

La **mutabilidad interior** te permite modificar a través de una referencia compartida. `RefCell` mantiene la regla de la [lección 4](../04-borrowing-and-strings/) — muchos lectores *o* un solo escritor — pero la comprueba cuando el programa se ejecuta en lugar de cuando se compila:

```rust
use std::cell::RefCell;

#[derive(Debug)]
struct Account { balance: i64 }

let account = Rc::new(RefCell::new(Account { balance: 100 }));
let alice = Rc::clone(&account);
let bob = Rc::clone(&account);

alice.borrow_mut().balance -= 30;    // borrow_mut() -> RefMut<Account>, como &mut
bob.borrow_mut().balance += 5;
println!("{:?}", account.borrow());  // borrow() -> Ref<Account>, como &
// Account { balance: 75 }
```

Si incumples la regla, el programa **entra en pánico** ([`src/lib.rs`, líneas 761-764](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L761-L764)):

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

[`try_borrow`](https://doc.rust-lang.org/std/cell/struct.RefCell.html#method.try_borrow) y [`try_borrow_mut`](https://doc.rust-lang.org/std/cell/struct.RefCell.html#method.try_borrow_mut) devuelven un `Result` en lugar de entrar en pánico ([líneas 92-95](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L92-L95)):

```rust
let reading = account.borrow();
account.try_borrow_mut().is_err()    // true: rechazado mientras `reading` siga vivo
```

:::caution[Cambias un error de compilación por un posible fallo en ejecución]
`RefCell` es la herramienta adecuada cuando el compilador no puede ver que tu patrón de acceso es seguro — una caché compartida, una lista de observadores, un grafo. Mantén cada `borrow_mut()` lo más breve posible (no lo conserves durante una llamada que podría volver a tomar prestado), y prefiere el ownership simple y `&mut` cuando funcionen. Es la versión en tiempo de ejecución de [`InvalidOperationException: Collection was modified`](https://learn.microsoft.com/dotnet/api/system.invalidoperationexception) de C#.
:::

Para valores `Copy` como contadores e indicadores, [`Cell<T>`](https://doc.rust-lang.org/std/cell/struct.Cell.html) es más sencillo: nunca presta una referencia, solo lee y escribe el valor.

```rust
use std::cell::Cell;
let hits = Cell::new(0);
hits.set(hits.get() + 1);
```

## Los ciclos provocan fugas — usa `Weak`

El conteo de referencias no puede liberar un ciclo: si `a` apunta a `b` y `b` apunta a `a`, ambos contadores se quedan por encima de cero para siempre. Un recolector de basura resuelve esto; `Rc`, no.

```rust
struct Node {
    name: &'static str,
    next: RefCell<Option<Rc<Node>>>,
}
// con una impl de Drop que imprime "drop {name}"

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

Los mensajes de `drop` nunca aparecen: la memoria se ha fugado. Esto es *seguro en memoria* — ningún puntero colgante — pero sigue siendo un bug.

La solución es un puntero **[`Weak<T>`](https://doc.rust-lang.org/std/rc/struct.Weak.html)** para una de las dos direcciones del enlace. Un `Weak` no mantiene vivo el valor; [`upgrade()`](https://doc.rust-lang.org/std/rc/struct.Weak.html#method.upgrade) devuelve `Some(Rc<T>)` si el valor aún existe y `None` en caso contrario — como [`WeakReference<T>.TryGetTarget`](https://learn.microsoft.com/dotnet/api/system.weakreference-1.trygettarget) de C# o [`WeakReference.get()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ref/WeakReference.html) de Java. El diseño habitual: los padres son dueños de sus hijos (`Rc`), y los hijos apuntan de vuelta a su padre (`Weak`).

De [`examples/l11_smart_pointers.rs`, líneas 38-42](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L38-L42), [130-132](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L130-L132):

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

## `Arc<T>`: `Rc` para hilos

`Rc` actualiza su contador sin sincronización, así que el compilador se niega a enviarlo a otro hilo ([`src/lib.rs`, líneas 880-882](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L880-L882)):

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

`Arc` (*atomically reference counted*, con contador de referencias atómico) tiene la misma API con un contador seguro entre hilos ([líneas 3](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L3), [146-150](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l11_smart_pointers.rs#L146-L150)):

```rust
use std::sync::Arc;

let shared = Arc::new(vec![1, 2, 3]);
let for_thread = Arc::clone(&shared);
let sum = std::thread::spawn(move || for_thread.iter().sum::<i32>()).join().unwrap();
// sum computed on another thread: 6, strong count back to 1
```

¿Por qué no usar siempre `Arc`? Las operaciones atómicas cuestan más, y `Rc` documenta que un valor se queda en un solo hilo. El compañero seguro entre hilos de `RefCell` es `Mutex` o [`RwLock`](https://doc.rust-lang.org/std/sync/struct.RwLock.html) — [lección 12](../12-threads-and-concurrency/).

## Elegir

| Pregunta | Respuesta |
|---|---|
| ¿Un propietario, pero el valor debe estar en el heap (tipo recursivo, `dyn Trait`, valor grande que mover de forma barata)? | `Box<T>` |
| ¿Varios propietarios, solo lectura, un hilo? | `Rc<T>` |
| ¿Varios propietarios, solo lectura, varios hilos? | `Arc<T>` |
| ¿Varios propietarios que modifican, un hilo? | `Rc<RefCell<T>>` |
| ¿Varios propietarios que modifican, varios hilos? | `Arc<Mutex<T>>` o `Arc<RwLock<T>>` |
| ¿Una referencia inversa o una caché que no debe mantener cosas vivas? | `Weak<T>` |

## Puntos clave

- C# y Java dan a cada objeto asignación en el heap, compartición y mutación a la vez; Rust hace explícita cada una.
- `Box<T>` pone un valor con propietario en el heap: tipos recursivos y trait objects.
- `Rc<T>` y `Arc<T>` cuentan los propietarios y liberan el valor cuando se va el último; `Rc::clone` copia un puntero, no los datos.
- `RefCell<T>` traslada la comprobación de préstamos a tiempo de ejecución: las infracciones provocan un pánico en lugar de impedir la compilación.
- El conteo de referencias fuga los ciclos; rómpelos con `Weak<T>`.
- `Rc` no es [`Send`](https://doc.rust-lang.org/std/marker/trait.Send.html); usa `Arc` entre hilos.

## Ejercicios

1. Añade una variante `Neg(Box<Expr>)` a `Expr`, actualiza `eval` y escribe `fn show(e: &Expr) -> String` para que `(2 + 3) * -4` se imprima como `((2 + 3) * -4)`.

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 787-812](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L787-L812):

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

`use Expr::*;` trae las variantes al ámbito. El `to_string()` de `f64` imprime `2.0` como `2`.

</details>

2. Un `Cart` y un `Payment` deben añadir líneas al mismo registro. Modélalo con `type Log = Rc<RefCell<Vec<String>>>`. Después, predice qué hace esto ([`src/lib.rs`, líneas 850-853](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L850-L853)):

```rust
let lines = Rc::new(RefCell::new(vec![String::from("start")]));
for line in lines.borrow().iter() {
    lines.borrow_mut().push(format!("seen {line}"));
}
```

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 818-842](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L818-L842):

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

Fíjate en que `add` y `pay` reciben `&self`, no `&mut self`: la mutación queda oculta dentro del `RefCell`.

El bucle compila, pero **entra en pánico** con `RefCell already borrowed`: el iterador mantiene un `borrow()` durante todo el bucle, y el `borrow_mut()` de dentro se rechaza. Es el error «push mientras se itera» de la lección 4, trasladado de tiempo de compilación a tiempo de ejecución. Recoge primero las líneas nuevas y añádelas después.

</details>

3. En el ejemplo de `Node` con fuga, `a` apunta a `b` y `b` apunta a `a`. Cambia el diseño para que ambos nodos se liberen al final del ámbito, y comprueba los contadores fuertes.

<details>
<summary>Solución</summary>

Mantén `next` como enlace fuerte y haz que el enlace hacia atrás sea `Weak` ([`src/lib.rs`, líneas 859-873](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L859-L873)):

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

`b` se libera primero (su contador pasa de 2 a 1), después `a` (de 1 a 0, así que se libera de verdad), y liberar `a` libera su `next`, lo que libera `b`.

</details>

## Fuentes

- [The Book, ch. 15 — Smart Pointers](https://doc.rust-lang.org/book/ch15-00-smart-pointers.html)
- [`std::rc`](https://doc.rust-lang.org/std/rc/index.html) y [`std::sync::Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html)
- [`std::cell`](https://doc.rust-lang.org/std/cell/index.html) — `Cell`, `RefCell` y la mutabilidad interior
- [The Book, ch. 15.6 — Reference Cycles Can Leak Memory](https://doc.rust-lang.org/book/ch15-06-reference-cycles.html)
