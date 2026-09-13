pub fn cm_to_inches(cm: f64) -> f64 {
    cm / 2.54
}

// Visible anywhere in this crate, invisible to `app`
pub(crate) fn non_negative(value: f64) -> f64 {
    value.max(0.0)
}
