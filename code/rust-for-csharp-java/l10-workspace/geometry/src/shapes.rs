use crate::units::non_negative;

pub trait Shape {
    fn area(&self) -> f64;
}

pub struct Circle {
    pub radius: f64,
}

// Private fields: the only way to build a Rect is Rect::new
pub struct Rect {
    width: f64,
    height: f64,
}

impl Rect {
    pub fn new(width: f64, height: f64) -> Self {
        Rect {
            width: non_negative(width),
            height: non_negative(height),
        }
    }
}

impl Shape for Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * self.radius * self.radius
    }
}

impl Shape for Rect {
    fn area(&self) -> f64 {
        self.width * self.height
    }
}

// Only compiled when a dependent crate enables the `display` feature
#[cfg(feature = "display")]
impl std::fmt::Display for Rect {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}x{} rectangle", self.width, self.height)
    }
}
