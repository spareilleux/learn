// The returned reference lives as long as the shorter of the two inputs
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

// Elision: one reference in, one reference out — no annotation needed
fn first_word(text: &str) -> &str {
    text.split_whitespace().next().unwrap_or("")
}

// Only `a` flows into the result, so only `a` needs the lifetime
fn prefix_of<'a>(a: &'a str, len_from: &str) -> &'a str {
    &a[..len_from.len().min(a.len())]
}

// A struct that borrows: it cannot outlive the text it points into
struct Excerpt<'a> {
    text: &'a str,
}

impl Excerpt<'_> {
    fn word_count(&self) -> usize {
        self.text.split_whitespace().count()
    }
}

// A tokenizer that hands out slices of its input, not of itself
struct Parser<'a> {
    input: &'a str,
    pos: usize,
}

impl<'a> Parser<'a> {
    fn new(input: &'a str) -> Self {
        Parser { input, pos: 0 }
    }

    fn next_token(&mut self) -> Option<&'a str> {
        let rest = &self.input[self.pos..];
        let trimmed = rest.trim_start();
        if trimmed.is_empty() {
            return None;
        }
        let start = self.pos + (rest.len() - trimmed.len());
        let len = trimmed.find(' ').unwrap_or(trimmed.len());
        self.pos = start + len;
        Some(&self.input[start..start + len])
    }
}

// The parser is dropped at the end; the tokens borrow `line`, so they survive
fn tokenize(line: &str) -> Vec<&str> {
    let mut parser = Parser::new(line);
    let mut tokens = Vec::new();
    while let Some(token) = parser.next_token() {
        tokens.push(token);
    }
    tokens
}

// 'static: string literals are baked into the binary
fn default_greeting() -> &'static str {
    "hello"
}

// The owned alternative: no lifetime, the caller gets its own String
fn shout(word: &str) -> String {
    word.to_uppercase()
}

fn main() {
    let title = String::from("Rust for C# developers");
    {
        let subtitle = String::from("ownership");
        let winner = longest(&title, &subtitle);
        println!("longest: {winner}");
    }

    println!("first word: {}", first_word(&title));
    println!("prefix: {}", prefix_of(&title, "Rust"));

    let novel = String::from("Call me Ishmael. Some years ago, never mind how long precisely...");
    let excerpt = Excerpt {
        text: novel.split('.').next().unwrap_or(""),
    };
    println!(
        "excerpt: {:?} ({} words)",
        excerpt.text,
        excerpt.word_count()
    );

    let line = String::from("let x = 42");
    println!("tokens: {:?}", tokenize(&line));

    println!("{} / {}", default_greeting(), shout("rust"));
}
