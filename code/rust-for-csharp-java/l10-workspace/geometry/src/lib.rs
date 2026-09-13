//! Shapes shared by the workspace members.

mod shapes; // private module, loaded from src/shapes.rs
pub mod units; // public module, loaded from src/units.rs

// Re-export: callers write `geometry::Circle`, not `geometry::shapes::Circle`
pub use shapes::{Circle, Rect, Shape};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rect_area() {
        assert_eq!(Rect::new(2.0, 3.0).area(), 6.0);
    }

    #[test]
    fn negative_sizes_are_clamped() {
        assert_eq!(Rect::new(-2.0, 3.0).area(), 0.0);
    }
}
