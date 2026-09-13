//! A tiny C ABI over pricing rules, called from C# in `dotnet/Program.cs`.

use std::ffi::{CStr, CString, c_char};

/// Adds `percent` VAT to an amount in cents.
#[unsafe(no_mangle)]
pub extern "C" fn pricing_add_vat(cents: u64, percent: u32) -> u64 {
    cents * (100 + u64::from(percent)) / 100
}

/// Sums `len` prices.
///
/// # Safety
///
/// `prices` must point to `len` initialised `f64` values, or be null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pricing_sum(prices: *const f64, len: usize) -> f64 {
    if prices.is_null() {
        return 0.0;
    }
    // SAFETY: the caller guarantees `prices` points to `len` values.
    let prices = unsafe { std::slice::from_raw_parts(prices, len) };
    prices.iter().sum()
}

/// Formats `name: 42.50` into a string allocated by Rust.
/// The caller must release it with [`pricing_free_string`].
///
/// # Safety
///
/// `name` must be a valid, NUL-terminated string, or null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pricing_label(name: *const c_char, cents: u64) -> *mut c_char {
    if name.is_null() {
        return std::ptr::null_mut();
    }
    // SAFETY: the caller guarantees a valid NUL-terminated string.
    let name = unsafe { CStr::from_ptr(name) }.to_string_lossy();
    let label = format!("{name}: {}.{:02}", cents / 100, cents % 100);
    CString::new(label).map_or(std::ptr::null_mut(), CString::into_raw)
}

/// Frees a string returned by [`pricing_label`].
///
/// # Safety
///
/// `label` must come from `pricing_label` and must not be used or freed again.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pricing_free_string(label: *mut c_char) {
    if !label.is_null() {
        // SAFETY: the pointer was created by CString::into_raw in pricing_label.
        drop(unsafe { CString::from_raw(label) });
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn vat_is_added() {
        assert_eq!(pricing_add_vat(1_000, 20), 1_200);
    }

    #[test]
    fn label_round_trip() {
        let name = CString::new("book").expect("no interior NUL");
        let label = unsafe { pricing_label(name.as_ptr(), 4_250) };
        let text = unsafe { CStr::from_ptr(label) }.to_str().map(str::to_owned);
        unsafe { pricing_free_string(label) };
        assert_eq!(text.as_deref(), Ok("book: 42.50"));
    }

    #[test]
    fn sum_of_slice_and_null() {
        let prices = [19.99, 5.0, 12.5];
        let sum = unsafe { pricing_sum(prices.as_ptr(), prices.len()) };
        assert!((sum - 37.49).abs() < 1e-9, "got {sum}");
        assert_eq!(unsafe { pricing_sum(std::ptr::null(), 3) }, 0.0);
    }
}
