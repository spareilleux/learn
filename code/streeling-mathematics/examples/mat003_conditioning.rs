//! MAT-003: conditioning, residuals and the refusal boundary of IX's inverse, on Hilbert matrices.
//! The printed values are rounded for reading; tests/mat003.rs checks each claim against a bound.

use ndarray::{Array2, array};
use std::time::Instant;
use streeling_mathematics::*;

fn sizes() -> std::ops::RangeInclusive<usize> {
    2..=16
}

fn opt(x: Option<f64>) -> String {
    x.map_or("-".to_string(), |v| format!("{v:.2e}"))
}

fn first_refusal(rows: &[Measurement]) -> String {
    rows.iter()
        .find(|m| m.inverse.is_none())
        .map_or("none up to 16".to_string(), |m| m.n.to_string())
}

fn worst_accepted(rows: &[Measurement]) -> String {
    let worst = rows
        .iter()
        .filter_map(|m| m.forward_error.map(|e| (e, m.n)))
        .fold(None, |w: Option<(f64, usize)>, x| match w {
            Some(w) if w.0 >= x.0 => Some(w),
            _ => Some(x),
        });
    worst.map_or("-".to_string(), |(e, n)| format!("{e:.2e} at n = {n}"))
}

fn main() {
    let start = Instant::now();
    println!(
        "MAT-003: Hilbert matrices against ix-math at e35138b9, IEEE 754 binary64 (u = 2^-53 = {U:.3e})"
    );
    println!(
        "inverse refuses below a pivot of {IX_PIVOT_THRESHOLD:e} (linalg.rs:110); MCP rank tol = sigma_1 * {MCP_RANK_FACTOR:e} (handlers.rs:639)"
    );
    println!();
    println!(
        " n  kappa_inf  kappa_2    band  inverse   fwd_err   residual  rank  pinv_res  pinv0_fwd"
    );
    let e = |x: f64| format!("{x:.2e}");
    let scales = [
        ("1", 1.0),
        ("2^-20", 2f64.powi(-20)),
        ("2^20", 2f64.powi(20)),
    ];
    let tables: Vec<Vec<Measurement>> = scales
        .iter()
        .map(|&(_, s)| sizes().map(|n| measure(n, s)).collect())
        .collect();
    for m in &tables[0] {
        println!(
            "{:>2}  {:<9}  {:<9}  {:<4}  {:<8}  {:<8}  {:<8}  {:>4}  {:<8}  {}",
            m.n,
            e(m.kappa_inf),
            e(m.kappa2),
            if m.band_holds() { "ok" } else { "out" },
            if m.inverse.is_some() {
                "ok"
            } else {
                "Singular"
            },
            opt(m.forward_error),
            opt(m.residual),
            m.rank_mcp,
            e(m.pinv_mcp_residual),
            e(m.pinv0_forward_error)
        );
    }

    println!();
    println!("Refusal boundary, by scale (the true kappa does not change with scale)");
    for ((label, _), rows) in scales.iter().zip(&tables) {
        println!(
            "  scale {label:<6} first Singular: {:<14} worst accepted fwd_err: {}",
            first_refusal(rows),
            worst_accepted(rows)
        );
    }
    let verdicts: Vec<String> = tables[0]
        .iter()
        .map(|m| format!("{}:{}", m.n, if m.inverse.is_some() { "ok" } else { "S" }))
        .collect();
    println!("  scale 1 verdicts: {}", verdicts.join(" "));

    let (mut same, mut both) = (0, 0);
    for k in [1, 2] {
        for (m1, ms) in tables[0].iter().zip(&tables[k]) {
            if let (Some(x1), Some(xs)) = (&m1.inverse, &ms.inverse) {
                both += 1;
                if x1
                    .iter()
                    .zip(xs.iter())
                    .all(|(a, b)| (a / ms.scale).to_bits() == b.to_bits())
                {
                    same += 1;
                }
            }
        }
    }
    let kappa_same = tables[0]
        .iter()
        .zip(&tables[1])
        .zip(&tables[2])
        .filter(|((a, b), c)| {
            a.kappa2.to_bits() == b.kappa2.to_bits() && a.kappa2.to_bits() == c.kappa2.to_bits()
        })
        .count();
    println!();
    println!("Scaling by 2^k is exact in binary floating point; is the answer?");
    println!("  inverse(2^k H) == inverse(H) / 2^k bit for bit: {same} of {both} accepted pairs");
    println!(
        "  IX kappa_2 bit-identical at the three scales: {kappa_same} of {}",
        tables[0].len()
    );

    println!();
    println!("Controls");
    for (label, e) in [("I * 2^-40", -40), ("I * 2^-39", -39)] {
        let a = Array2::<f64>::eye(3) * 2f64.powi(e);
        let verdict = match ix_inverse(&a) {
            None => "Singular".to_string(),
            Some(x) => format!(
                "ok, inverse == I * 2^{}: {}",
                -e,
                x == Array2::<f64>::eye(3) * 2f64.powi(-e)
            ),
        };
        println!("  {label}: kappa = 1, inverse {verdict}");
    }
    let singular = array![[1.0, 2.0], [2.0, 4.0]];
    let s = ix_math::svd::svd(&singular).expect("svd");
    println!(
        "  [[1,2],[2,4]]: inverse {}, rank(sigma_1 * 1e-10) = {}",
        if ix_inverse(&singular).is_some() {
            "ok"
        } else {
            "Singular"
        },
        s.rank(s.singular_values[0] * MCP_RANK_FACTOR)
    );
    let exact3 = exact_hilbert_inverse(3);
    println!(
        "  exact H_3^-1 = {exact3:?}, H_3 * H_3^-1 == I exactly: {:?}",
        exact_identity_holds(&exact3)
    );
    println!(
        "  checker on a wrong inverse (I for H_3^-1): residual {:.2e}",
        residual(&hilbert(3), &Array2::eye(3))
    );

    let digest = bits_digest(
        tables
            .iter()
            .flatten()
            .flat_map(raw_values)
            .collect::<Vec<_>>()
            .iter(),
    );
    println!();
    println!("raw-bits digest of every computed value: {digest:016x}");
    if std::env::var_os("MAT003_TIMING").is_some() {
        eprintln!("elapsed: {:.3} s", start.elapsed().as_secs_f64());
    }
}
