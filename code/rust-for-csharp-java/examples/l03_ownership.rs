struct TempFile {
    name: String,
}

impl Drop for TempFile {
    fn drop(&mut self) {
        println!("dropping {}", self.name);
    }
}

fn take(s: String) -> usize {
    s.len()
} // s is dropped here

fn make_greeting(name: &str) -> String {
    format!("Hello, {name}!") // ownership moves to the caller
}

fn main() {
    // Move: ownership of the heap buffer goes to `b`
    let a = String::from("hello");
    let b = a;
    println!("b = {b}");

    // Explicit deep copy
    let c = b.clone();
    println!("b = {b}, c = {c}");

    // Copy types are duplicated, not moved
    let x = 5;
    let y = x;
    println!("x = {x}, y = {y}");

    // Passing by value moves too
    let len = take(c);
    println!("len = {len}");

    let greeting = make_greeting("Ferris");
    println!("{greeting}");

    // Deterministic destruction, in reverse declaration order
    let _first = TempFile {
        name: "first.tmp".into(),
    };
    {
        let _inner = TempFile {
            name: "inner.tmp".into(),
        };
        println!("leaving inner scope");
    }
    let _second = TempFile {
        name: "second.tmp".into(),
    };
    println!("end of main");
}
