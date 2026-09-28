//! MAT-005: IX's `symmetric_eigen` through its invariants, on a repeated eigenvalue, on an asymmetric input and
//! across scales, and IX's `PCA` on six points. The printed values are for reading; tests/mat005.rs checks each
//! pre-registered claim.

use ndarray::Array2;
use std::f64::consts::FRAC_1_SQRT_2;
use streeling_mathematics::mat005::*;

fn list(values: &[f64]) -> String {
    values
        .iter()
        .map(|v| format!("{v:.12}"))
        .collect::<Vec<_>>()
        .join(", ")
}

fn main() {
    let mut raw = Vec::new();
    println!(
        "MAT-005: ix-math symmetric_eigen and ix-unsupervised PCA at e35138b9, IEEE 754 binary64"
    );

    println!();
    println!(
        "Step 1: invariants, largest |entry| of A v - lambda v, V^T V - I and V Lambda V^T - A"
    );
    for row in invariants() {
        raw.extend(row.values.iter().copied());
        raw.extend([row.residual, row.orthonormality, row.reconstruction]);
        println!(
            "  {:<6} | eigenvalues {} | predicted {} | {:.3e} | {:.3e} | {:.3e}",
            row.name,
            list(&row.values),
            row.predicted
                .as_ref()
                .map_or("none".to_string(), |p| list(p)),
            row.residual,
            row.orthonormality,
            row.reconstruction
        );
    }

    println!();
    let (columns, err) = eigenspace();
    raw.push(err);
    println!(
        "Step 2: I+J(3), columns with eigenvalue 1: {columns:?}; largest |entry| of u u^T + w w^T - (I - J/3): {err:.3e}"
    );

    println!();
    let n = matrix_n();
    let e = eigen(&n);
    raw.extend(e.values.iter().copied());
    raw.extend(e.vectors.iter().copied());
    let first: Vec<f64> = e.vectors.column(0).to_vec();
    let expected = [1.0 / 5f64.sqrt(), 2.0 / 5f64.sqrt()];
    println!(
        "Step 3: symmetric_eigen([[1, 2], [3, 4]]) = Ok, eigenvalues {:?} (bits {:016x}, {:016x})",
        e.values,
        e.values[0].to_bits(),
        e.values[1].to_bits()
    );
    println!(
        "  vector for {}: {} | distance to (1, 2)/sqrt 5, up to sign: {:.3e} | ||A v - lambda v|| = {:.12} (1/sqrt 5 = {:.12})",
        e.values[0],
        list(&first),
        distance_up_to_sign(&first, &expected),
        residual_norm(&n, &e, 0),
        1.0 / 5f64.sqrt()
    );
    println!("  ix_eigen over MCP: not run");

    println!();
    let p = pca();
    raw.extend(p.components.iter().copied());
    raw.extend(p.variances.iter().copied());
    raw.extend(p.ratios.iter().copied());
    println!("Step 4: PCA::new(2) on the six points");
    for i in 0..2 {
        let c = p.components.row(i).to_vec();
        println!(
            "  component {} = ({}) | distance to (1, 1)/sqrt 2, up to sign: {:.3e} | variance {:.12} | ratio {}",
            i + 1,
            list(&c),
            distance_up_to_sign(&c, &[FRAC_1_SQRT_2, FRAC_1_SQRT_2]),
            p.variances[i],
            p.ratios[i]
        );
    }
    let dot: f64 = p
        .components
        .row(0)
        .iter()
        .zip(p.components.row(1).iter())
        .map(|(a, b)| a * b)
        .sum();
    let c = eigen(&covariance());
    raw.extend(c.values.iter().copied());
    raw.push(dot);
    println!("  dot product of the two components: {dot:.12}");
    println!(
        "  symmetric_eigen of the same covariance: {} | share of the variance the components miss: {:.12}",
        list(&c.values),
        unaccounted_share(&p.variances)
    );

    println!();
    let identity = eigen(&Array2::eye(4));
    println!(
        "Section 7 reading: eigenvectors of I_4 equal I_4 bit for bit: {}; of I+J(4): {}",
        same_bits(&identity.vectors, &Array2::eye(4)),
        same_bits(&eigen(&identity_plus_ones(4)).vectors, &Array2::eye(4))
    );

    println!();
    println!(
        "M5-L1, the lab's own: symmetric_eigen(10^e B); eigenvalues / 10^e against (6, 1), and whether they are"
    );
    println!("  the diagonal of 10^e B with V = I, bit for bit");
    for exponent in exponents() {
        let row = scale_row(exponent);
        raw.extend(row.values_over_s.iter().copied());
        raw.push(row.max_residual);
        println!(
            "  e = {:>3} | eigenvalues / 10^e {} | relative errors {:.3e}, {:.3e} | diagonal returned: {:<5} | largest |A v - lambda v| {:.3e}",
            row.exponent,
            list(&row.values_over_s),
            row.relative_errors[0],
            row.relative_errors[1],
            row.returned_diagonal,
            row.max_residual
        );
    }

    println!();
    println!("Negative controls:");
    let b = matrix_b();
    let good = eigen(&b);
    let swapped = Eigen {
        values: good.values.iter().rev().copied().collect(),
        vectors: good.vectors.clone(),
    };
    println!(
        "  B with its two eigenvalues swapped: largest |A v - lambda v| {:.3e}",
        max_eigen_residual(&b, &swapped)
    );
    let ipj = eigen(&identity_plus_ones(3));
    let wrong = projector_from(&ipj.vectors, &[0, 1]);
    let wrong_err = wrong
        .iter()
        .zip(eigenspace_projector().iter())
        .map(|(x, y)| (x - y).abs())
        .fold(0.0, f64::max);
    println!("  eigenspace built from the vector for 4 and one for 1: {wrong_err:.3e}");
    println!(
        "  distance from (1, 1)/sqrt 2 to (1, -1)/sqrt 2, up to sign: {:.3e}",
        distance_up_to_sign(
            &[FRAC_1_SQRT_2, FRAC_1_SQRT_2],
            &[FRAC_1_SQRT_2, -FRAC_1_SQRT_2]
        )
    );

    println!();
    println!(
        "raw-bits digest of every computed value: {:016x}",
        streeling_mathematics::bits_digest(raw.iter())
    );
}
