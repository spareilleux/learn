// Inline modules: the same rules apply when each module is its own file
mod billing {
    // Items are private to their module unless marked `pub`
    pub fn invoice_total(amounts: &[f64]) -> f64 {
        let subtotal: f64 = amounts.iter().sum();
        subtotal + tax(subtotal)
    }

    fn tax(amount: f64) -> f64 {
        amount * rates::SALES_TAX
    }

    pub mod rates {
        pub const SALES_TAX: f64 = 0.15;
    }

    pub mod discounts {
        // `super` is the parent module, like `..` in a path
        pub fn with_discount(amounts: &[f64], percent: f64) -> f64 {
            super::invoice_total(amounts) * (1.0 - percent / 100.0)
        }
    }
}

mod shapes {
    pub struct Rect {
        width: f64,
        height: f64,
    }

    impl Rect {
        pub fn new(width: f64, height: f64) -> Self {
            Rect { width: width.max(0.0), height: height.max(0.0) }
        }

        pub fn area(&self) -> f64 {
            self.width * self.height
        }
    }

    // Visible in the whole crate, like C# `internal`
    pub(crate) fn unit_square() -> Rect {
        Rect::new(1.0, 1.0)
    }
}

// `use` brings names into scope; `as` renames them
use billing::discounts::with_discount;
use billing::rates::SALES_TAX as TAX;
use shapes::Rect;

fn main() {
    let amounts = [100.0, 50.0];
    println!("total: {:.2}", billing::invoice_total(&amounts));
    println!("with 10% off: {:.2}", with_discount(&amounts, 10.0));
    println!("tax rate: {TAX}");

    let rect = Rect::new(2.0, -3.0);
    println!("clamped area: {}", rect.area());
    println!("unit square: {}", shapes::unit_square().area());

    // Absolute path from the crate root
    println!("{}", crate::billing::rates::SALES_TAX * 100.0);
}
