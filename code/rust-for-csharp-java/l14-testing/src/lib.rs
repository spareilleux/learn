//! Prices and discounts for a small shop.
//!
//! The main entry point is [`Cart`]; discounts are described by [`Discount`].

use std::fmt;

/// A discount applied to a cart total.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Discount {
    /// No discount.
    None,
    /// A percentage between 0 and 100.
    Percent(u8),
    /// A fixed amount in cents, never taking the total below zero.
    Fixed(u64),
}

/// Errors returned by [`Cart::add`].
#[derive(Debug, PartialEq)]
pub enum PricingError {
    /// The quantity was zero.
    ZeroQuantity,
    /// The unit price was zero.
    FreeItem(String),
}

impl fmt::Display for PricingError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            PricingError::ZeroQuantity => write!(f, "quantity must be at least 1"),
            PricingError::FreeItem(name) => write!(f, "`{name}` has no price"),
        }
    }
}

impl std::error::Error for PricingError {}

/// A shopping cart holding line totals in cents.
#[derive(Debug, Default)]
pub struct Cart {
    lines: Vec<(String, u64)>,
}

impl Cart {
    /// Creates an empty cart.
    pub fn new() -> Self {
        Self::default()
    }

    /// Adds `quantity` items at `unit_cents` each.
    ///
    /// # Errors
    ///
    /// Returns [`PricingError::ZeroQuantity`] if `quantity` is 0 and
    /// [`PricingError::FreeItem`] if `unit_cents` is 0.
    ///
    /// # Examples
    ///
    /// ```
    /// use pricing::Cart;
    ///
    /// let mut cart = Cart::new();
    /// cart.add("pen", 2, 150)?;
    /// assert_eq!(cart.total_cents(), 300);
    /// # Ok::<(), pricing::PricingError>(())
    /// ```
    pub fn add(&mut self, name: &str, quantity: u32, unit_cents: u64) -> Result<(), PricingError> {
        if quantity == 0 {
            return Err(PricingError::ZeroQuantity);
        }
        if unit_cents == 0 {
            return Err(PricingError::FreeItem(name.to_string()));
        }
        self.lines
            .push((name.to_string(), u64::from(quantity) * unit_cents));
        Ok(())
    }

    /// Sum of all lines, in cents.
    pub fn total_cents(&self) -> u64 {
        self.lines.iter().map(|(_, cents)| cents).sum()
    }

    /// Total after applying `discount`.
    ///
    /// # Panics
    ///
    /// Panics if a [`Discount::Percent`] is above 100.
    ///
    /// ```should_panic
    /// use pricing::{Cart, Discount};
    /// Cart::new().total_with(Discount::Percent(150));
    /// ```
    pub fn total_with(&self, discount: Discount) -> u64 {
        let total = self.total_cents();
        match discount {
            Discount::None => total,
            Discount::Percent(p) => {
                assert!(p <= 100, "discount above 100%: {p}");
                total * u64::from(100 - p) / 100
            }
            Discount::Fixed(cents) => total.saturating_sub(cents),
        }
    }
}

// Unit tests: a child module, so it can reach private items
#[cfg(test)]
mod tests {
    use super::*;

    fn cart_with(lines: &[(&str, u32, u64)]) -> Cart {
        let mut cart = Cart::new();
        for &(name, quantity, cents) in lines {
            cart.add(name, quantity, cents).expect("valid line");
        }
        cart
    }

    #[test]
    fn empty_cart_totals_zero() {
        assert_eq!(Cart::new().total_cents(), 0);
    }

    #[test]
    fn percent_discount_rounds_down() {
        let cart = cart_with(&[("book", 1, 999)]);
        assert_eq!(cart.total_with(Discount::Percent(10)), 899);
    }

    #[test]
    fn fixed_discount_never_goes_negative() {
        let cart = cart_with(&[("pen", 1, 150)]);
        assert_eq!(cart.total_with(Discount::Fixed(500)), 0);
    }

    #[test]
    fn zero_quantity_is_rejected() {
        let mut cart = Cart::new();
        assert_eq!(cart.add("pen", 0, 150), Err(PricingError::ZeroQuantity));
        assert!(cart.lines.is_empty(), "a rejected line must not be stored");
    }

    #[test]
    #[should_panic(expected = "discount above 100%")]
    fn percent_above_100_panics() {
        Cart::new().total_with(Discount::Percent(101));
    }

    // A test can return Result and use `?`
    #[test]
    fn free_item_error_message() -> Result<(), String> {
        let err = Cart::new()
            .add("gift", 1, 0)
            .err()
            .ok_or("expected an error")?;
        assert_eq!(err.to_string(), "`gift` has no price");
        Ok(())
    }

    #[test]
    #[ignore = "slow: run with cargo test -- --ignored"]
    fn many_lines() {
        let mut cart = Cart::new();
        for i in 1..=1_000_000 {
            cart.add("item", 1, i).expect("valid line");
        }
        assert_eq!(cart.total_cents(), 500_000_500_000);
    }
}
