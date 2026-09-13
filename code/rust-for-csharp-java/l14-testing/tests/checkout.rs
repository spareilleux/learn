//! Checkout scenarios, exercised through the public API only.

use pricing::{Cart, Discount, PricingError};

#[test]
fn checkout_with_discount() -> Result<(), PricingError> {
    let mut cart = Cart::new();
    cart.add("book", 2, 2_000)?;
    cart.add("pen", 3, 150)?;
    assert_eq!(cart.total_cents(), 4_450);
    assert_eq!(cart.total_with(Discount::Percent(20)), 3_560);
    Ok(())
}
