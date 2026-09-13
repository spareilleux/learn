use std::collections::HashMap;

// A declarative macro: pattern => expansion
macro_rules! square {
    ($x:expr) => {
        $x * $x
    };
}

// Repetition: $( ... ),* matches a comma-separated list
macro_rules! hashmap {
    ($($key:expr => $value:expr),* $(,)?) => {{
        let mut map = HashMap::new();
        $( map.insert($key, $value); )*
        map
    }};
}

// Several rules, tried in order, like match arms
macro_rules! max_of {
    ($x:expr) => { $x };
    ($x:expr, $($rest:expr),+) => {{
        let rest = max_of!($($rest),+);
        if $x > rest { $x } else { rest }
    }};
}

// Generating items: one newtype per invocation
macro_rules! newtype {
    ($name:ident, $inner:ty) => {
        #[derive(Debug, Clone, Copy, PartialEq)]
        struct $name($inner);
    };
}

newtype!(UserId, u32);
newtype!(OrderId, u32);

// A safe function built on unsafe code: it upholds the invariants itself
fn split_first_rest(values: &mut [i32]) -> Option<(&mut i32, &mut [i32])> {
    if values.is_empty() {
        return None;
    }
    let len = values.len();
    let ptr = values.as_mut_ptr();
    // SAFETY: the slice is not empty, so `ptr` is valid for `len` elements;
    // element 0 and elements 1..len do not overlap, so the two mutable borrows are disjoint.
    unsafe {
        Some((
            &mut *ptr,
            std::slice::from_raw_parts_mut(ptr.add(1), len - 1),
        ))
    }
}

// Declaring a function from the C runtime: Rust cannot check what it does
unsafe extern "C" {
    fn abs(input: i32) -> i32;
}

fn main() {
    println!("square!(1 + 2) = {}", square!(1 + 2)); // 9, not 5 as with a C #define

    let ages = hashmap! {
        "Ada" => 36,
        "Grace" => 85,
    };
    let mut names: Vec<_> = ages.keys().collect();
    names.sort();
    println!("{names:?}");

    println!("max_of!(3, 9, 4) = {}", max_of!(3, 9, 4));

    let user = UserId(7);
    let order = OrderId(7);
    println!("{user:?} {order:?} {}", user.0 == order.0);

    let mut scores = [10, 20, 30];
    if let Some((first, rest)) = split_first_rest(&mut scores) {
        *first += 1;
        for score in rest.iter_mut() {
            *score *= 2;
        }
    }
    println!("{scores:?}");

    // Raw pointers can be created in safe code; only dereferencing is unsafe
    let x = 42;
    let ptr = &x as *const i32;
    // SAFETY: `ptr` comes from a live reference to `x`.
    println!("through a raw pointer: {}", unsafe { *ptr });

    // SAFETY: `abs` has no preconditions for this input.
    println!("abs(-3) from C = {}", unsafe { abs(-3) });
}
