fn word_count(text: &str) -> usize {
    text.split_whitespace().count()
}

fn shout(text: &mut String) {
    text.make_ascii_uppercase();
    text.push('!');
}

fn first_word(text: &str) -> &str {
    text.split_whitespace().next().unwrap_or("")
}

fn main() {
    // Shared borrows: any number, read-only
    let title = String::from("the rust programming language");
    let r1 = &title;
    let r2 = &title;
    println!("{r1} / {r2} / {} words", word_count(&title));

    // A mutable borrow: exactly one at a time
    let mut message = String::from("hello");
    shout(&mut message);
    println!("{message}");

    // &str accepts string literals, String (via &) and slices
    println!("{}", word_count("a literal works too"));
    println!("first word: {}", first_word(&title));

    // Slices borrow part of a collection
    let mut scores = vec![90, 72, 85];
    scores.push(60);
    let top_two = &scores[..2];
    println!("top two: {top_two:?}");

    // Strings are UTF-8: iterate chars or bytes, slice on byte boundaries
    let word = "café";
    println!(
        "{} bytes, {} chars, first 3 bytes: {}",
        word.len(),
        word.chars().count(),
        &word[..3]
    );

    // Modify while iterating: collect first, then mutate
    let mut numbers = vec![1, 2, 3];
    let doubled: Vec<i32> = numbers.iter().map(|n| n * 2).collect();
    numbers.extend(doubled);
    println!("{numbers:?}");

    // Building strings
    let mut log = String::new();
    for (i, s) in ["alpha", "beta"].iter().enumerate() {
        log.push_str(&format!("{i}:{s} "));
    }
    println!("{}", log.trim_end());
}
