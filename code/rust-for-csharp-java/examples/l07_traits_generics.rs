use std::fmt;

// A trait is like an interface, and can have default methods
trait Shape {
    fn area(&self) -> f64;

    fn name(&self) -> String {
        String::from("shape")
    }
}

struct Circle {
    radius: f64,
}

struct Square {
    side: f64,
}

impl Shape for Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * self.radius * self.radius
    }

    fn name(&self) -> String {
        format!("circle r={}", self.radius)
    }
}

impl Shape for Square {
    fn area(&self) -> f64 {
        self.side * self.side
    }
    // uses the default name()
}

// Static dispatch: one copy of the function per concrete T (monomorphization)
fn total_area<T: Shape>(shapes: &[T]) -> f64 {
    shapes.iter().map(|s| s.area()).sum()
}

// Same thing, shorter syntax for a single argument
fn describe(shape: &impl Shape) -> String {
    format!("{} has area {:.2}", shape.name(), shape.area())
}

// Dynamic dispatch: a vtable call, like calling through a C# or Java interface
fn largest(shapes: &[Box<dyn Shape>]) -> Option<&dyn Shape> {
    shapes
        .iter()
        .map(|s| s.as_ref())
        .max_by(|a, b| a.area().total_cmp(&b.area()))
}

// Several bounds with a where clause
fn print_all<T>(items: &[T])
where
    T: fmt::Display + PartialOrd,
{
    let mut max = &items[0];
    for item in items {
        if item > max {
            max = item;
        }
        print!("{item} ");
    }
    println!("(max {max})");
}

// Implementing standard traits: Display ~ ToString(), Default ~ parameterless constructor, From ~ conversion
#[derive(Debug, Default, PartialEq)]
struct Celsius(f64);

struct Fahrenheit(f64);

impl fmt::Display for Celsius {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:.1}°C", self.0)
    }
}

impl From<Fahrenheit> for Celsius {
    fn from(f: Fahrenheit) -> Self {
        Celsius((f.0 - 32.0) * 5.0 / 9.0)
    }
}

// A trait implemented for a type you don't own: like a C# extension method
trait Shout {
    fn shout(&self) -> String;
}

impl Shout for str {
    fn shout(&self) -> String {
        format!("{}!", self.to_uppercase())
    }
}

fn main() {
    let circles = [Circle { radius: 1.0 }, Circle { radius: 2.0 }];
    println!("total circle area = {:.2}", total_area(&circles));
    println!("{}", describe(&Square { side: 3.0 }));

    let mixed: Vec<Box<dyn Shape>> = vec![
        Box::new(Circle { radius: 1.5 }),
        Box::new(Square { side: 2.0 }),
    ];
    if let Some(big) = largest(&mixed) {
        println!("largest: {} ({:.2})", big.name(), big.area());
    }

    print_all(&[3, 9, 4]);
    print_all(&["pear", "apple", "fig"]);

    let body = Celsius::from(Fahrenheit(98.6));
    let also: Celsius = Fahrenheit(212.0).into();
    println!("{body} / {also} / default {}", Celsius::default());

    println!("{}", "hello".shout());
}
