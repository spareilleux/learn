fn main() {
    // Immutable by default
    let answer = 42; // inferred as i32
    let mut counter: u32 = 0;
    counter += 1;
    println!("answer = {answer}, counter = {counter}");

    // Shadowing: a new variable with the same name, possibly another type
    let input = "  7 ";
    let input: i32 = input.trim().parse().expect("not a number");
    println!("input + 1 = {}", input + 1);

    // No implicit numeric conversions
    let small: i32 = 10;
    let big: i64 = 20;
    let total = small as i64 + big;
    println!("total = {total}");

    // Checked and wrapping arithmetic are explicit
    let max = u8::MAX;
    println!(
        "checked: {:?}, wrapping: {}",
        max.checked_add(1),
        max.wrapping_add(1)
    );

    // char is a Unicode scalar value (4 bytes), not a UTF-16 code unit
    let note = '♪';
    println!(
        "{note} is {} bytes in UTF-8, size_of::<char>() = {}",
        note.len_utf8(),
        std::mem::size_of::<char>()
    );

    // Tuples and arrays
    let point: (f64, f64) = (1.5, -2.0);
    let (x, y) = point;
    let primes = [2, 3, 5, 7, 11];
    println!(
        "x = {x}, y = {y}, first prime = {}, count = {}",
        primes[0],
        primes.len()
    );

    // if is an expression: no ternary operator needed
    let parity = if answer % 2 == 0 { "even" } else { "odd" };
    println!("{answer} is {parity}");

    // Blocks evaluate to their last expression (no semicolon)
    let area = {
        let width = 3;
        let height = 4;
        width * height
    };
    println!("area = {area}");

    // loop can return a value with break
    let mut n = 1;
    let first_power_over_100 = loop {
        n *= 2;
        if n > 100 {
            break n;
        }
    };
    println!("first power of two over 100 = {first_power_over_100}");

    // for over a range (end-exclusive) and an inclusive range
    let sum: i32 = (1..=10).sum();
    for i in 0..3 {
        print!("{i} ");
    }
    println!("| sum 1..=10 = {sum}");

    println!("square(9) = {}", square(9));
}

// The last expression is the return value; `return` is only for early exits
fn square(x: i32) -> i32 {
    x * x
}
