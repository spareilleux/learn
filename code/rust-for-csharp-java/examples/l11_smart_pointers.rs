use std::cell::{Cell, RefCell};
use std::rc::{Rc, Weak};
use std::sync::Arc;

// Box: a recursive type needs indirection to have a known size
#[derive(Debug)]
enum Expr {
    Num(f64),
    Add(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
}

fn eval(expr: &Expr) -> f64 {
    match expr {
        Expr::Num(n) => *n,
        Expr::Add(a, b) => eval(a) + eval(b),
        Expr::Mul(a, b) => eval(a) * eval(b),
    }
}

// Rc: several owners of the same immutable value
struct Config {
    env: String,
}

struct Service {
    name: &'static str,
    config: Rc<Config>,
}

// Rc<RefCell<T>>: several owners that can also mutate
#[derive(Debug)]
struct Account {
    balance: i64,
}

// Weak: a back-reference that does not keep the parent alive
struct TreeNode {
    name: String,
    parent: RefCell<Weak<TreeNode>>,
    children: RefCell<Vec<Rc<TreeNode>>>,
}

impl Drop for TreeNode {
    fn drop(&mut self) {
        println!("drop {}", self.name);
    }
}

fn main() {
    // (2 + 3) * 4
    let expr = Expr::Mul(
        Box::new(Expr::Add(
            Box::new(Expr::Num(2.0)),
            Box::new(Expr::Num(3.0)),
        )),
        Box::new(Expr::Num(4.0)),
    );
    println!("{expr:?} = {}", eval(&expr));

    let config = Rc::new(Config { env: "prod".into() });
    let api = Service {
        name: "api",
        config: Rc::clone(&config),
    };
    let worker = Service {
        name: "worker",
        config: Rc::clone(&config),
    };
    println!(
        "{} and {} share env {:?}, strong count = {}",
        api.name,
        worker.name,
        config.env,
        Rc::strong_count(&config)
    );
    println!("{}", api.config.env == worker.config.env);
    drop(api);
    println!(
        "after dropping api: strong count = {}",
        Rc::strong_count(&config)
    );

    let account = Rc::new(RefCell::new(Account { balance: 100 }));
    let alice = Rc::clone(&account);
    let bob = Rc::clone(&account);
    alice.borrow_mut().balance -= 30;
    bob.borrow_mut().balance += 5;
    println!("shared account: {:?}", account.borrow());

    // The borrow rules still apply, checked at runtime
    let reading = account.borrow();
    println!(
        "try_borrow_mut while reading: {}",
        if account.try_borrow_mut().is_err() {
            "refused"
        } else {
            "allowed"
        }
    );
    drop(reading);
    println!(
        "try_borrow_mut after: {}",
        if account.try_borrow_mut().is_err() {
            "refused"
        } else {
            "allowed"
        }
    );

    // Cell: interior mutability for Copy values, no borrowing at all
    let hits = Cell::new(0);
    for _ in 0..3 {
        hits.set(hits.get() + 1);
    }
    println!("hits: {}", hits.get());

    {
        let root = Rc::new(TreeNode {
            name: "root".into(),
            parent: RefCell::new(Weak::new()),
            children: RefCell::new(vec![]),
        });
        let leaf = Rc::new(TreeNode {
            name: "leaf".into(),
            parent: RefCell::new(Weak::new()),
            children: RefCell::new(vec![]),
        });
        *leaf.parent.borrow_mut() = Rc::downgrade(&root);
        root.children.borrow_mut().push(Rc::clone(&leaf));

        let parent_name = leaf.parent.borrow().upgrade().map(|p| p.name.clone());
        println!(
            "leaf's parent: {parent_name:?}, children of root: {}",
            root.children.borrow().len()
        );
        println!(
            "root strong = {}, weak = {}",
            Rc::strong_count(&root),
            Rc::weak_count(&root)
        );
    }
    println!("tree scope ended");

    // Arc: the thread-safe Rc (lesson 12)
    let shared = Arc::new(vec![1, 2, 3]);
    let for_thread = Arc::clone(&shared);
    let sum = std::thread::spawn(move || for_thread.iter().sum::<i32>())
        .join()
        .unwrap();
    println!(
        "sum computed on another thread: {sum}, strong count back to {}",
        Arc::strong_count(&shared)
    );
}
