use geometry::units::cm_to_inches;
use geometry::{Circle, Rect, Shape};

fn main() {
    let shapes: Vec<Box<dyn Shape>> = vec![
        Box::new(Circle { radius: 1.0 }),
        Box::new(Rect::new(2.0, 3.0)),
    ];
    let total: f64 = shapes.iter().map(|s| s.area()).sum();
    println!("total area: {total:.2}");

    println!("{}", Rect::new(4.0, 2.5)); // Display exists because app enables the feature
    println!("10 cm = {:.2} in", cm_to_inches(10.0));
}
