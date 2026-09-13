use std::fmt;

// A struct with named fields and derived behaviour (like a C# record's equality and ToString)
#[derive(Debug, Clone, PartialEq)]
struct Account {
    owner: String,
    balance_cents: i64,
}

impl Account {
    // Associated function: the conventional "constructor"
    fn new(owner: &str) -> Self {
        Self { owner: owner.to_string(), balance_cents: 0 }
    }

    // &self: read-only method
    fn balance(&self) -> f64 {
        self.balance_cents as f64 / 100.0
    }

    // &mut self: mutating method
    fn deposit(&mut self, cents: i64) {
        self.balance_cents += cents;
    }

    // self: consumes the value
    fn close(self) -> i64 {
        self.balance_cents
    }
}

// Tuple struct used as a "newtype": a distinct type around an f64
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Meters(f64);

// An enum whose variants carry different data
#[derive(Debug)]
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle(f64, f64, f64),
}

impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle(a, b, c) => {
                // Heron's formula
                let s = (a + b + c) / 2.0;
                (s * (s - a) * (s - b) * (s - c)).sqrt()
            }
        }
    }
}

impl fmt::Display for Shape {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Shape::Circle { radius } => write!(f, "circle r={radius}"),
            Shape::Rectangle { width, height } => write!(f, "rectangle {width}x{height}"),
            Shape::Triangle(..) => write!(f, "triangle"),
        }
    }
}

enum Command {
    Move { dx: i32, dy: i32 },
    Say(String),
    Quit,
}

fn describe(temperature: i32) -> &'static str {
    // Ranges and guards in patterns
    match temperature {
        i32::MIN..=0 => "freezing",
        1..=15 => "cold",
        t if t > 30 => "hot",
        _ => "mild",
    }
}

fn parse_port(text: &str) -> u16 {
    // let-else: bind or leave the function early
    let Ok(port) = text.parse::<u16>() else {
        return 8080;
    };
    port
}

fn main() {
    let mut account = Account::new("Ada");
    account.deposit(1_250);
    let copy = account.clone();
    println!("{account:?}");
    println!("balance = {:.2}, equal to copy: {}", account.balance(), account == copy);

    // Struct update syntax: like a C# `with` expression
    let other = Account { owner: "Grace".into(), ..copy };
    println!("{} has {} cents", other.owner, other.balance_cents);

    let final_cents = account.close();
    println!("closed with {final_cents} cents");

    let short = Meters(3.5);
    let long = Meters(10.0);
    println!("{short:?} < {long:?}: {}", short < long);

    let shapes = [
        Shape::Circle { radius: 1.0 },
        Shape::Rectangle { width: 3.0, height: 4.0 },
        Shape::Triangle(3.0, 4.0, 5.0),
    ];
    for shape in &shapes {
        println!("{shape}: area {:.2}", shape.area());
    }

    let commands = vec![
        Command::Move { dx: 3, dy: 0 },
        Command::Move { dx: 1, dy: -2 },
        Command::Say("hi".into()),
        Command::Quit,
    ];
    for command in commands {
        match command {
            Command::Move { dx, dy: 0 } => println!("horizontal move by {dx}"),
            Command::Move { dx, dy } => println!("move by ({dx}, {dy})"),
            Command::Say(text) => println!("say {text:?}"),
            Command::Quit => println!("quit"),
        }
    }

    for t in [-5, 10, 22, 35] {
        println!("{t}°C is {}", describe(t));
    }

    // if let: match a single pattern
    let first = shapes.first();
    if let Some(Shape::Circle { radius }) = first {
        println!("first shape is a circle of radius {radius}");
    }

    println!("port {} / {}", parse_port("3000"), parse_port("oops"));
}
