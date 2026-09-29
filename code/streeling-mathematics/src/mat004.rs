//! MAT-004, vectors, matrices and norms: IX's distances checked for the triangle inequality on a grid, `minkowski`
//! at p = 1/2, infinity, 1000 and NaN, `cosine_distance` against the triangle inequality, and the product rule
//! of `determinant`. Pre-registered in preregistration-mat004.md.

use crate::max_or_nan;
use ix_math::distance::{chebyshev, cosine_distance, euclidean, manhattan, minkowski};
use ix_math::error::MathError;
use ix_math::linalg::{determinant, matmul};
use ndarray::{Array1, Array2, array};

/// A distance of IX, by name.
pub type Distance = fn(&Array1<f64>, &Array1<f64>) -> Result<f64, MathError>;

fn minkowski_3(a: &Array1<f64>, b: &Array1<f64>) -> Result<f64, MathError> {
    minkowski(a, b, 3.0)
}

/// The four distances of step 1.
pub fn distances() -> [(&'static str, Distance); 4] {
    [
        ("manhattan", manhattan),
        ("euclidean", euclidean),
        ("chebyshev", chebyshev),
        ("minkowski p = 3", minkowski_3),
    ]
}

/// The 25 points of R^2 with integer coordinates from -2 to 2, row by row.
pub fn grid() -> Vec<Array1<f64>> {
    (-2..=2)
        .flat_map(|i| (-2..=2).map(move |j| array![i as f64, j as f64]))
        .collect()
}

/// Step 1 for one distance: the largest d(x, z) - (d(x, y) + d(y, z)) over the 15,625 triples, the number of
/// triples where it is strictly positive, and the number of triples checked.
pub fn triangle(d: Distance, points: &[Array1<f64>]) -> (f64, usize, usize) {
    let n = points.len();
    let table: Vec<Vec<f64>> = points
        .iter()
        .map(|x| {
            points
                .iter()
                .map(|y| d(x, y).expect("same length"))
                .collect()
        })
        .collect();
    let (mut worst, mut positive, mut count) = (f64::NEG_INFINITY, 0, 0);
    for x in 0..n {
        for y in 0..n {
            for z in 0..n {
                let excess = table[x][z] - (table[x][y] + table[y][z]);
                worst = max_or_nan(worst, excess);
                if excess > 0.0 {
                    positive += 1;
                }
                count += 1;
            }
        }
    }
    (worst, positive, count)
}

/// The p = 1/2 formula of the section 5 exercise, by hand, without IX.
pub fn half_distance(a: &Array1<f64>, b: &Array1<f64>) -> Result<f64, MathError> {
    let s: f64 = a.iter().zip(b).map(|(x, y)| (x - y).abs().sqrt()).sum();
    Ok(s * s)
}

/// The points of the section 5 exercise: x = (0, 0), y = (1, 0), z = (1, 1).
pub fn exercise_points() -> [Array1<f64>; 3] {
    [array![0.0, 0.0], array![1.0, 0.0], array![1.0, 1.0]]
}

/// Step 2: `minkowski` with p = 1/2 on (x, y), (y, z) and (x, z).
pub fn half_p_results() -> Vec<Result<f64, MathError>> {
    let [x, y, z] = exercise_points();
    [(&x, &y), (&y, &z), (&x, &z)]
        .into_iter()
        .map(|(a, b)| minkowski(a, b, 0.5))
        .collect()
}

/// Whether a result is `InvalidParameter("p must be >= 1")`.
pub fn is_p_refusal(r: &Result<f64, MathError>) -> bool {
    matches!(r, Err(MathError::InvalidParameter(m)) if m == "p must be >= 1")
}

pub fn origin() -> Array1<f64> {
    array![0.0, 0.0]
}

pub fn three_four() -> Array1<f64> {
    array![3.0, 4.0]
}

/// The cosine distances d(x, z), d(x, y) + d(y, z) for x = (1, 0), y = (1, 1), z = (0, 1).
pub fn cosine_triangle() -> (f64, f64) {
    let (x, y, z) = (array![1.0, 0.0], array![1.0, 1.0], array![0.0, 1.0]);
    let d = |a, b| cosine_distance(a, b).expect("same length");
    (d(&x, &z), d(&x, &y) + d(&y, &z))
}

/// F_n[i][j] = ((i + 2j) mod 5) - 2, the fixed matrices of step 5.
pub fn fixed_matrix(n: usize) -> Array2<f64> {
    Array2::from_shape_fn((n, n), |(i, j)| ((i + 2 * j) % 5) as f64 - 2.0)
}

/// The 64-bit generator of step 5, started at 0.
pub struct Lcg(u64);

impl Lcg {
    pub fn new() -> Self {
        Lcg(0)
    }

    /// The next entry in -3 ... 3.
    pub fn entry(&mut self) -> f64 {
        self.0 = self
            .0
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        ((self.0 >> 33) % 7) as f64 - 3.0
    }

    pub fn matrix(&mut self) -> Array2<f64> {
        let mut m = Array2::zeros((3, 3));
        for v in m.iter_mut() {
            *v = self.entry();
        }
        m
    }
}

impl Default for Lcg {
    fn default() -> Self {
        Self::new()
    }
}

/// One pair of step 5: det A, det B and det(AB), all from IX.
pub struct ProductRule {
    pub det_a: f64,
    pub det_b: f64,
    pub det_ab: f64,
}

/// The 1,000 pairs of step 5.
pub fn product_rule_pairs() -> Vec<ProductRule> {
    let mut g = Lcg::new();
    (0..1000)
        .map(|_| {
            let a = g.matrix();
            let b = g.matrix();
            let ab = matmul(&a, &b).expect("3 x 3 times 3 x 3");
            ProductRule {
                det_a: determinant(&a).expect("square"),
                det_b: determinant(&b).expect("square"),
                det_ab: determinant(&ab).expect("square"),
            }
        })
        .collect()
}

/// n!/2, the number of 2 x 2 determinants the expansion evaluates for n >= 2.
pub fn half_factorial(n: u64) -> u64 {
    (1..=n).product::<u64>() / 2
}

/// The calls per timed run of step 5: max(1, ceil(10^6 / (n!/2))).
pub fn calls_per_run(n: u64) -> u64 {
    1_000_000u64.div_ceil(half_factorial(n)).max(1)
}
