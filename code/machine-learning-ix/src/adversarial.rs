//! Lesson 18: evasion attacks, the defences against them, and data poisoning, measured against IX's
//! `ix-adversarial`.
//!
//! The model under attack is fixed rather than trained, so that every number the tests check follows from
//! a formula: two classes y = ±1 in 100 dimensions, x = y·μ + n with μ = 0.2 in every coordinate and the
//! course's approximate normal noise, and the Bayes-optimal linear classifier w = μ, b = 0.

use ix_adversarial::defense::{
    adversarial_training_augment, detect_adversarial, feature_squeezing,
};
use ix_adversarial::evasion::{cw_attack, fgsm, jsma, pgd, universal_perturbation};
use ix_adversarial::poisoning::{
    detect_label_flips, influence_function, spectral_signature_defense,
};
use ix_adversarial::robustness::{certified_radius, lipschitz_estimate};
use ndarray::{Array1, Array2, array};

use crate::autodiff::Rng;
use crate::rl::normal;

/// Dimension of the attacked model's inputs
pub const DIM: usize = 100;
/// Test points of each class
pub const PER_CLASS: usize = 1000;
/// Every coordinate of the class mean μ, and of the weights w = μ
pub const MU: f64 = 0.2;
/// The attacks' L∞ budgets, and Φ(2 − 10ε), the accuracy each leaves on the linear model
pub const EPSILONS: [f64; 4] = [0.0, 0.1, 0.2, 0.3];
pub const FORMULA: [f64; 4] = [0.9772, 0.8413, 0.5000, 0.1587];

/// A test point and its class, +1 or −1
pub struct Point {
    pub x: Array1<f64>,
    pub y: f64,
}

/// 2,000 test points, alternating classes +1 and −1, each x = y·μ + n drawn from `Rng(18_100)`
pub fn test_set() -> Vec<Point> {
    let mut rng = Rng(18_100);
    (0..2 * PER_CLASS)
        .map(|i| {
            let y = if i % 2 == 0 { 1.0 } else { -1.0 };
            let x = Array1::from_shape_fn(DIM, |_| y * MU + normal(&mut rng));
            Point { x, y }
        })
        .collect()
}

/// The weights w = μ: 0.2 in every coordinate, so ‖w‖₂ = 2 and ‖w‖₁ = 20
pub fn weights() -> Array1<f64> {
    Array1::from_elem(DIM, MU)
}

/// The margin y·w·x, positive when x is on its class's side
pub fn margin(w: &Array1<f64>, y: f64, x: &Array1<f64>) -> f64 {
    y * w.dot(x)
}

fn sigmoid(z: f64) -> f64 {
    1.0 / (1.0 + (-z).exp())
}

fn norm(v: &Array1<f64>) -> f64 {
    v.dot(v).sqrt()
}

fn largest_gap(a: &Array1<f64>, b: &Array1<f64>) -> f64 {
    (a - b).iter().fold(0.0f64, |m, d| m.max(d.abs()))
}

/// The gradient of the logistic loss log(1 + e^(−m)) with respect to the input, −y·σ(−m)·w: the scalar
/// first, then each weight times it, so a zero weight gives a zero with the scalar's sign
pub fn loss_gradient(w: &Array1<f64>, y: f64, x: &Array1<f64>) -> Array1<f64> {
    let c = -y * sigmoid(-margin(w, y, x));
    w.mapv(|wj| wj * c)
}

/// FGSM at one ε against the full model
pub struct FgsmRun {
    pub epsilon: f64,
    pub accuracy: f64,
    /// Largest |new margin − (m − ε‖w‖₁)|
    pub margin_error: f64,
    /// Points whose class changed
    pub changed: usize,
    /// Whether they are exactly the correctly classified points with m < ε‖w‖₁
    pub changed_as_predicted: bool,
}

pub fn fgsm_run(points: &[Point], epsilon: f64) -> FgsmRun {
    let w = weights();
    let l1 = w.sum();
    let (mut correct, mut changed, mut as_predicted, mut margin_error) = (0, 0, true, 0.0f64);
    for p in points {
        let m = margin(&w, p.y, &p.x);
        let adversarial = fgsm(&p.x, &loss_gradient(&w, p.y, &p.x), epsilon);
        let m_adversarial = margin(&w, p.y, &adversarial);
        margin_error = margin_error.max((m_adversarial - (m - epsilon * l1)).abs());
        correct += usize::from(m_adversarial > 0.0);
        let did_change = (m > 0.0) != (m_adversarial > 0.0);
        changed += usize::from(did_change);
        as_predicted &= did_change == (m > 0.0 && m < epsilon * l1);
    }
    FgsmRun {
        epsilon,
        accuracy: correct as f64 / points.len() as f64,
        margin_error,
        changed,
        changed_as_predicted: as_predicted,
    }
}

/// What `pgd`, `adversarial_training_augment` and `fgsm` do with a gradient that is a zero of one sign
/// everywhere, at ε = 0.2, α = 0.05 and 10 steps: the largest distance from x + `shift` for the first two,
/// and from x for `fgsm`
pub struct ZeroGradient {
    pub pgd: f64,
    pub augment: f64,
    pub fgsm: f64,
}

pub fn zero_gradient(x: &Array1<f64>, zero: f64, shift: f64) -> ZeroGradient {
    let g = Array1::from_elem(x.len(), zero);
    let shifted = x + shift;
    let augmented =
        adversarial_training_augment(std::slice::from_ref(x), std::slice::from_ref(&g), 0.2);
    ZeroGradient {
        pgd: largest_gap(&pgd(x, |_| g.clone(), 0.2, 0.05, 10), &shifted),
        augment: largest_gap(&augmented[0], &shifted),
        fgsm: largest_gap(&fgsm(x, &g, 0.2), x),
    }
}

/// PGD and FGSM at ε = 0.2 against the model that gives the last 50 features a weight of 0
pub struct Sparse {
    /// Fewest and most features moved, over the points
    pub pgd_moved: (usize, usize),
    pub fgsm_moved: (usize, usize),
    /// Smallest and largest perturbation norm, over the points
    pub pgd_norm: (f64, f64),
    pub fgsm_norm: (f64, f64),
    pub pgd_accuracy: f64,
    pub fgsm_accuracy: f64,
}

pub fn sparse_model() -> Array1<f64> {
    Array1::from_shape_fn(DIM, |j| if j < DIM / 2 { MU } else { 0.0 })
}

pub fn sparse(points: &[Point]) -> Sparse {
    let w = sparse_model();
    let mut moved = [(usize::MAX, 0), (usize::MAX, 0)];
    let mut norms = [(f64::MAX, 0.0f64), (f64::MAX, 0.0f64)];
    let mut correct = [0, 0];
    for p in points {
        let by_pgd = pgd(&p.x, |a| loss_gradient(&w, p.y, a), 0.2, 0.05, 10);
        let by_fgsm = fgsm(&p.x, &loss_gradient(&w, p.y, &p.x), 0.2);
        for (k, adversarial) in [by_pgd, by_fgsm].iter().enumerate() {
            let delta = adversarial - &p.x;
            let count = delta.iter().filter(|d| **d != 0.0).count();
            moved[k] = (moved[k].0.min(count), moved[k].1.max(count));
            norms[k] = (norms[k].0.min(norm(&delta)), norms[k].1.max(norm(&delta)));
            correct[k] += usize::from(margin(&w, p.y, adversarial) > 0.0);
        }
    }
    let n = points.len() as f64;
    Sparse {
        pgd_moved: moved[0],
        fgsm_moved: moved[1],
        pgd_norm: norms[0],
        fgsm_norm: norms[1],
        pgd_accuracy: correct[0] as f64 / n,
        fgsm_accuracy: correct[1] as f64 / n,
    }
}

/// Against the full model, the largest distance between PGD's point (ε = 0.2, α = 0.05, 10 steps) and FGSM's
pub fn pgd_against_fgsm(points: &[Point]) -> f64 {
    let w = weights();
    points
        .iter()
        .map(|p| {
            let by_pgd = pgd(&p.x, |a| loss_gradient(&w, p.y, a), 0.2, 0.05, 10);
            largest_gap(&by_pgd, &fgsm(&p.x, &loss_gradient(&w, p.y, &p.x), 0.2))
        })
        .fold(0.0, f64::max)
}

pub const CW_STEPS: usize = 2000;
pub const CW_RATE: f64 = 0.01;

/// `cw_attack` at one c on the correctly classified points, with the hinge loss max(m, 0) and its gradient
pub struct CwRun {
    pub c: f64,
    pub points: usize,
    /// Results equal to their input
    pub unchanged: usize,
    /// Results on the wrong side of the boundary
    pub misclassified: usize,
    /// Largest | ‖δ‖₂ − m/‖w‖ |, the distance from the minimal perturbation's length
    pub distance_gap: f64,
}

pub fn cw_run(points: &[Point], c: f64) -> CwRun {
    let w = weights();
    let w_norm = norm(&w);
    let (mut n, mut unchanged, mut misclassified, mut distance_gap) = (0, 0, 0, 0.0f64);
    for p in points {
        let m = margin(&w, p.y, &p.x);
        if m <= 0.0 {
            continue;
        }
        n += 1;
        let hinge = |a: &Array1<f64>, _target: usize| margin(&w, p.y, a).max(0.0);
        let hinge_gradient = |a: &Array1<f64>| {
            if margin(&w, p.y, a) > 0.0 {
                &w * p.y
            } else {
                Array1::zeros(DIM)
            }
        };
        let target = usize::from(p.y > 0.0);
        let adversarial = cw_attack(&p.x, target, hinge, hinge_gradient, c, CW_STEPS, CW_RATE);
        unchanged += usize::from(adversarial == p.x);
        misclassified += usize::from(margin(&w, p.y, &adversarial) < 0.0);
        distance_gap = distance_gap.max((norm(&(&adversarial - &p.x)) - m / w_norm).abs());
    }
    CwRun {
        c,
        points: n,
        unchanged,
        misclassified,
        distance_gap,
    }
}

/// `universal_perturbation` on one correctly classified input at a time, one iteration, ε = 10⁹, loss = m:
/// the largest relative errors of the new margin against m(1 − ‖w‖) with the fooling direction −y·w, against
/// m(1 + ‖w‖) with the loss's gradient +y·w, and against (m/4)(1 − ‖w‖/4) for w/4; and of the w/4
/// perturbation's length against a quarter of the full one
pub struct UniversalRun {
    pub points: usize,
    pub fooling: f64,
    pub loss_gradient: f64,
    pub scaled: f64,
    pub scaled_length: f64,
}

fn one_universal(w: &Array1<f64>, p: &Point, direction: f64) -> Array1<f64> {
    let g = w * (direction * p.y);
    universal_perturbation(
        std::slice::from_ref(&p.x),
        |a| margin(w, p.y, a),
        |_| g.clone(),
        1e9,
        1,
    )
}

pub fn universal_run(points: &[Point]) -> UniversalRun {
    let w = weights();
    let w4 = &w / 4.0;
    let (w_norm, w4_norm) = (norm(&w), norm(&w4));
    let relative = |got: f64, want: f64| ((got - want) / want).abs();
    let mut run = UniversalRun {
        points: 0,
        fooling: 0.0,
        loss_gradient: 0.0,
        scaled: 0.0,
        scaled_length: 0.0,
    };
    for p in points {
        let m = margin(&w, p.y, &p.x);
        if m <= 0.0 {
            continue;
        }
        run.points += 1;
        let fooling = one_universal(&w, p, -1.0);
        let along = one_universal(&w, p, 1.0);
        let scaled = one_universal(&w4, p, -1.0);
        let m4 = margin(&w4, p.y, &p.x);
        run.fooling = run.fooling.max(relative(
            margin(&w, p.y, &(&p.x + &fooling)),
            m * (1.0 - w_norm),
        ));
        run.loss_gradient = run.loss_gradient.max(relative(
            margin(&w, p.y, &(&p.x + &along)),
            m * (1.0 + w_norm),
        ));
        run.scaled = run.scaled.max(relative(
            margin(&w4, p.y, &(&p.x + &scaled)),
            m4 * (1.0 - w4_norm),
        ));
        run.scaled_length = run
            .scaled_length
            .max(relative(norm(&scaled), norm(&fooling) / 4.0));
    }
    run
}

/// Whether `jsma` returns the same point for targets 0 and 1, with the same saliency
pub fn jsma_ignores_its_target(x: &Array1<f64>) -> bool {
    let w = weights();
    jsma(x, 0, |_| w.clone(), 5, 0.1) == jsma(x, 1, |_| w.clone(), 5, 0.1)
}

pub const NOISE: f64 = 0.1;
pub const SAMPLES: usize = 50;
pub const DETECT_SEED: u64 = 18_500;

/// The score `detect_adversarial` compares with its threshold, found by bisection: the largest threshold
/// at which it still flags the input
fn detection_score(x: &Array1<f64>, model: impl Fn(&Array1<f64>) -> Array1<f64> + Copy) -> f64 {
    let flags = |t: f64| detect_adversarial(x, model, NOISE, SAMPLES, t, DETECT_SEED);
    let (mut low, mut high) = (0.0, 1.0);
    while flags(high) {
        high *= 2.0;
    }
    for _ in 0..2000 {
        let middle = 0.5 * (low + high);
        if middle <= low || middle >= high {
            break;
        }
        if flags(middle) {
            low = middle;
        } else {
            high = middle;
        }
    }
    low
}

/// `detect_adversarial` on the 2,000 clean test points and their FGSM versions at ε = 0.2
pub struct Detection {
    pub inputs: usize,
    /// The score of the first clean input, with the logit outputs (z, −z)
    pub score: f64,
    /// Inputs whose score is within 10⁻¹² relative of it
    pub same_score: usize,
    /// Inputs flagged at thresholds 0.015 and 0.09
    pub flagged_low: usize,
    pub flagged_high: usize,
    /// With the probability outputs (p, 1 − p): the score of the input nearest the boundary, and of the one
    /// farthest from it
    pub near: f64,
    pub far: f64,
}

pub fn detection(points: &[Point]) -> Detection {
    let w = weights();
    let logits = |x: &Array1<f64>| {
        let z = w.dot(x);
        array![z, -z]
    };
    let probabilities = |x: &Array1<f64>| {
        let p = sigmoid(w.dot(x));
        array![p, 1.0 - p]
    };
    let mut inputs: Vec<Array1<f64>> = points.iter().map(|p| p.x.clone()).collect();
    inputs.extend(
        points
            .iter()
            .map(|p| fgsm(&p.x, &loss_gradient(&w, p.y, &p.x), 0.2)),
    );
    let flags =
        |x: &Array1<f64>, t: f64| detect_adversarial(x, logits, NOISE, SAMPLES, t, DETECT_SEED);
    let score = detection_score(&inputs[0], logits);
    let same_score = inputs
        .iter()
        .filter(|x| flags(x, score * (1.0 - 1e-12)) && !flags(x, score * (1.0 + 1e-12)))
        .count();
    let by_distance =
        |a: &&Array1<f64>, b: &&Array1<f64>| w.dot(*a).abs().total_cmp(&w.dot(*b).abs());
    let nearest = inputs.iter().min_by(by_distance).expect("inputs");
    let farthest = inputs.iter().max_by(by_distance).expect("inputs");
    Detection {
        inputs: inputs.len(),
        score,
        same_score,
        flagged_low: inputs.iter().filter(|x| flags(x, 0.015)).count(),
        flagged_high: inputs.iter().filter(|x| flags(x, 0.09)).count(),
        near: detection_score(nearest, probabilities),
        far: detection_score(farthest, probabilities),
    }
}

pub const VALUES: usize = 100_000;

/// `feature_squeezing` on 100,000 values uniform on [0, 1] and on the same values moved by ±ε
pub struct Squeeze {
    pub bits: u32,
    pub epsilon: f64,
    /// Fraction of the rounded values that differ
    pub changed: f64,
    /// Mean absolute and root mean square difference between the rounded values
    pub mean_abs: f64,
    pub rms: f64,
}

pub fn squeeze(bits: u32, epsilon: f64) -> Squeeze {
    let mut values = Rng(18_600);
    let mut signs = Rng(18_601);
    let clean = Array1::from_shape_fn(VALUES, |_| values.next_f64());
    let moved = Array1::from_shape_fn(VALUES, |i| {
        clean[i]
            + if signs.next_f64() < 0.5 {
                -epsilon
            } else {
                epsilon
            }
    });
    let d = &feature_squeezing(&moved, bits) - &feature_squeezing(&clean, bits);
    Squeeze {
        bits,
        epsilon,
        changed: d.iter().filter(|v| **v != 0.0).count() as f64 / VALUES as f64,
        mean_abs: d.mapv(f64::abs).mean().expect("values"),
        rms: d.mapv(|v| v * v).mean().expect("values").sqrt(),
    }
}

/// `feature_squeezing` at 0 bits
pub fn squeeze_zero_bits() -> Array1<f64> {
    feature_squeezing(&array![0.0, 0.3, 0.7, 1.0], 0)
}

/// Φ⁻¹(p) by algorithm AS 241 of Wichura (1988), PPND16, about 16 significant digits
// the coefficients as published, with more digits than an f64 keeps
#[allow(clippy::excessive_precision)]
pub fn inverse_normal(p: f64) -> f64 {
    fn poly(c: &[f64], x: f64) -> f64 {
        c.iter().rev().fold(0.0, |acc, &k| acc * x + k)
    }
    const A: [f64; 8] = [
        3.387_132_872_796_366_608,
        133.141_667_891_784_377_45,
        1_971.590_950_306_551_442_7,
        13_731.693_765_509_461_125,
        45_921.953_931_549_871_457,
        67_265.770_927_008_700_853,
        33_430.575_583_588_128_105,
        2_509.080_928_730_122_672_7,
    ];
    const B: [f64; 8] = [
        1.0,
        42.313_330_701_600_911_252,
        687.187_007_492_057_908_3,
        5_394.196_021_424_751_107_7,
        21_213.794_301_586_595_867,
        39_307.895_800_092_710_61,
        28_729.085_735_721_942_674,
        5_226.495_278_852_854_561,
    ];
    const C: [f64; 8] = [
        1.423_437_110_749_683_577_34,
        4.630_337_846_156_545_295_9,
        5.769_497_221_460_691_405_5,
        3.647_848_324_763_204_605_04,
        1.270_458_252_452_368_382_58,
        0.241_780_725_177_450_611_77,
        0.022_723_844_989_269_184_583_3,
        7.745_450_142_783_414_076_4e-4,
    ];
    const D: [f64; 8] = [
        1.0,
        2.053_191_626_637_758_821_87,
        1.676_384_830_183_803_849_4,
        0.689_767_334_985_100_004_55,
        0.148_103_976_427_480_074_59,
        0.015_198_666_563_616_457_196_6,
        5.475_938_084_995_344_946e-4,
        1.050_750_071_644_416_843_24e-9,
    ];
    const E: [f64; 8] = [
        6.657_904_643_501_103_777_2,
        5.463_784_911_164_114_369_9,
        1.784_826_539_917_291_335_8,
        0.296_560_571_828_504_891_23,
        0.026_532_189_526_576_123_093,
        0.001_242_660_947_388_078_438_6,
        2.711_555_568_743_487_578_15e-5,
        2.010_334_399_292_288_132_65e-7,
    ];
    const F: [f64; 8] = [
        1.0,
        0.599_832_206_555_887_937_69,
        0.136_929_880_922_735_805_31,
        0.014_875_361_290_850_614_852_5,
        7.868_691_311_456_132_591e-4,
        1.846_318_317_510_054_681_8e-5,
        1.421_511_758_316_445_888_7e-7,
        2.044_263_103_389_939_785_64e-15,
    ];
    let q = p - 0.5;
    if q.abs() <= 0.425 {
        let r = 0.180_625 - q * q;
        return q * poly(&A, r) / poly(&B, r);
    }
    let r = (-(if q < 0.0 { p } else { 1.0 - p }).ln()).sqrt();
    let value = if r <= 5.0 {
        poly(&C, r - 1.6) / poly(&D, r - 1.6)
    } else {
        poly(&E, r - 5.0) / poly(&F, r - 5.0)
    };
    if q < 0.0 { -value } else { value }
}

/// `certified_radius` at σ = 1 against the exact radius, (Φ⁻¹(p_A) − Φ⁻¹(p_B))/2 with AS 241
pub struct Radius {
    /// Largest |IX − exact| over p_A = 0.501, 0.502, ..., 0.999 with p_B = 1 − p_A, and where
    pub max_error: f64,
    pub at: f64,
    /// At p_A = 0.9: IX's radius and the exact one
    pub ix_09: f64,
    pub exact_09: f64,
    /// Logits (2, −1) and (3, 1)
    pub logits_2_1: f64,
    pub logits_3_1: f64,
}

pub fn radius() -> Radius {
    let exact = |pa: f64| (inverse_normal(pa) - inverse_normal(1.0 - pa)) / 2.0;
    let ix = |pa: f64| certified_radius(&array![pa, 1.0 - pa], 1.0);
    let (mut max_error, mut at) = (0.0, 0.0);
    for k in 501..=999 {
        let pa = k as f64 / 1000.0;
        let error = (ix(pa) - exact(pa)).abs();
        if error > max_error {
            (max_error, at) = (error, pa);
        }
    }
    Radius {
        max_error,
        at,
        ix_09: ix(0.9),
        exact_09: exact(0.9),
        logits_2_1: certified_radius(&array![2.0, -1.0], 1.0),
        logits_3_1: certified_radius(&array![3.0, 1.0], 1.0),
    }
}

/// Two classes of 500 points around (−2, −2) and (2, 2), labels 0 and 1, with 100 of them flipped
pub struct Flips {
    pub flipped: usize,
    /// Whether `influence_function` returns the same bits before and after the flips
    pub influence_identical: bool,
    /// Flipped labels `detect_label_flips` finds with k = 5, and other points it flags
    pub found: usize,
    pub others: usize,
}

pub fn label_flips() -> Flips {
    const N: usize = 1000;
    const FLIPPED: usize = 100;
    let mut rng = Rng(18_800);
    let mut features = Array2::zeros((N, 2));
    let mut labels = Array1::zeros(N);
    for i in 0..N {
        let centre = if i % 2 == 1 { 2.0 } else { -2.0 };
        for j in 0..2 {
            features[[i, j]] = centre + normal(&mut rng);
        }
        labels[i] = (i % 2) as f64;
    }
    // the first 100 places of a Fisher–Yates shuffle
    let mut order: Vec<usize> = (0..N).collect();
    let mut pick = Rng(18_801);
    for i in 0..FLIPPED {
        let j = i + (pick.next_f64() * (N - i) as f64) as usize;
        order.swap(i, j);
    }
    let flipped = &order[..FLIPPED];
    let mut noisy = labels.clone();
    for &i in flipped {
        noisy[i] = 1.0 - noisy[i];
    }
    let test = array![0.5, -0.3];
    let before = influence_function(&features, &labels, &test, 1.0, 0.1);
    let after = influence_function(&features, &noisy, &test, 1.0, 0.1);
    let flagged = detect_label_flips(&features, &noisy, 5);
    let found = flagged.iter().filter(|&&i| flipped.contains(&i)).count();
    Flips {
        flipped: FLIPPED,
        influence_identical: before
            .iter()
            .zip(after.iter())
            .all(|(a, b)| a.to_bits() == b.to_bits()),
        found,
        others: flagged.len() - found,
    }
}

/// `spectral_signature_defense` at the 90th percentile on two classes of 100 points in 10 dimensions, then
/// with 5 more points in class 0 shifted by 6 on the last feature
pub struct Spectral {
    /// Points flagged in classes 0 and 1, without and with the shifted points
    pub clean: [usize; 2],
    pub poisoned: [usize; 2],
    /// Shifted points among the flagged
    pub poison_found: usize,
}

pub fn spectral() -> Spectral {
    const D: usize = 10;
    let mut rng = Rng(18_802);
    let mut rows: Vec<Vec<f64>> = Vec::new();
    let mut labels: Vec<f64> = Vec::new();
    for class in 0..2 {
        for _ in 0..100 {
            let mut row: Vec<f64> = (0..D).map(|_| normal(&mut rng)).collect();
            // class 1 sits 3 away on the first feature
            row[0] += 3.0 * class as f64;
            rows.push(row);
            labels.push(class as f64);
        }
    }
    let flag = |rows: &[Vec<f64>], labels: &[f64]| {
        let features = Array2::from_shape_fn((rows.len(), D), |(i, j)| rows[i][j]);
        spectral_signature_defense(&features, &Array1::from(labels.to_vec()), 2, 90.0)
    };
    let per_class = |flagged: &[usize], labels: &[f64]| {
        let ones = flagged.iter().filter(|&&i| labels[i] == 1.0).count();
        [flagged.len() - ones, ones]
    };
    let clean_flags = flag(&rows, &labels);
    for _ in 0..5 {
        let mut row: Vec<f64> = (0..D).map(|_| normal(&mut rng)).collect();
        row[D - 1] += 6.0;
        rows.push(row);
        labels.push(0.0);
    }
    let poisoned_flags = flag(&rows, &labels);
    Spectral {
        clean: per_class(&clean_flags, &labels),
        poisoned: per_class(&poisoned_flags, &labels),
        poison_found: poisoned_flags.iter().filter(|&&i| i >= 200).count(),
    }
}

/// `lipschitz_estimate` of x ↦ (10·x₀, x₁, ..., x₉₉), whose Lipschitz constant is 10, at 0 with 200
/// samples in the unit ball, for 20 seeds
pub fn lipschitz_runs() -> Vec<f64> {
    let stretch = |x: &Array1<f64>| {
        let mut y = x.clone();
        y[0] *= 10.0;
        y
    };
    (0..20)
        .map(|s| lipschitz_estimate(stretch, &Array1::zeros(DIM), 200, 1.0, 18_900 + s))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn inverse_normal_matches_known_quantiles() {
        // Φ⁻¹ at 0.5, Φ(1), 0.9, 0.975, 0.999 and 10⁻¹⁰, and its symmetry
        for (p, z) in [
            (0.5, 0.0),
            (0.841_344_746_068_542_9, 1.0),
            (0.9, 1.281_551_565_544_600_4),
            (0.975, 1.959_963_984_540_054),
            (0.999, 3.090_232_306_167_813_5),
            (1e-10, -6.361_340_902_404_056),
        ] {
            assert!(
                (inverse_normal(p) - z).abs() < 1e-12,
                "{p}: {}",
                inverse_normal(p)
            );
        }
        assert!((inverse_normal(0.3) + inverse_normal(0.7)).abs() < 1e-15);
    }

    #[test]
    fn p1_fgsm_moves_every_margin_by_eps_times_the_l1_norm() {
        let points = test_set();
        let intervals = [
            (0.967, 0.988),
            (0.815, 0.867),
            (0.464, 0.536),
            (0.133, 0.185),
        ];
        for (eps, (low, high)) in EPSILONS.iter().zip(intervals) {
            let run = fgsm_run(&points, *eps);
            assert!(run.margin_error < 1e-12, "{eps}: {}", run.margin_error);
            assert!(run.changed_as_predicted, "{eps}");
            assert!(
                run.accuracy >= low && run.accuracy <= high,
                "{eps}: {}",
                run.accuracy
            );
        }
    }

    #[test]
    fn p2_pgd_moves_the_features_the_gradient_ignores() {
        let points = test_set();
        let x = &points[0].x;
        for (zero, shift) in [(0.0, 0.2), (-0.0, -0.2)] {
            let z = zero_gradient(x, zero, shift);
            assert!(
                z.pgd < 1e-12 && z.augment < 1e-12,
                "{zero}: {} {}",
                z.pgd,
                z.augment
            );
            assert_eq!(z.fgsm, 0.0);
        }
        let s = sparse(&points);
        assert_eq!(s.pgd_moved, (100, 100));
        assert_eq!(s.fgsm_moved, (50, 50));
        assert!((s.pgd_norm.0 - 2.0).abs() < 1e-9 && (s.pgd_norm.1 - 2.0).abs() < 1e-9);
        let root50 = 0.2 * 50f64.sqrt();
        assert!((s.fgsm_norm.0 - root50).abs() < 1e-9 && (s.fgsm_norm.1 - root50).abs() < 1e-9);
        assert_eq!(s.pgd_accuracy, s.fgsm_accuracy);
        // control: with a gradient of one sign, PGD lands on FGSM's point
        assert!(pgd_against_fgsm(&points) < 1e-12);
    }

    #[test]
    fn p3_carlini_wagner_without_its_search_over_c() {
        let points = test_set();
        let small = cw_run(&points, 0.25);
        assert_eq!(small.unchanged, small.points);
        let two = cw_run(&points, 1.0);
        assert!(two.distance_gap <= 0.02, "{}", two.distance_gap);
        let half = two.misclassified as f64 / two.points as f64;
        assert!((0.464..=0.536).contains(&half), "{half}");
        let three_halves = cw_run(&points, 0.75);
        let third = three_halves.misclassified as f64 / three_halves.points as f64;
        assert!((0.299..=0.367).contains(&third), "{third}");
    }

    #[test]
    fn p4_the_universal_step_is_as_long_as_the_loss() {
        let run = universal_run(&test_set());
        assert!(run.points > 1900);
        for error in [
            run.fooling,
            run.loss_gradient,
            run.scaled,
            run.scaled_length,
        ] {
            assert!(error < 1e-12, "{error}");
        }
    }

    #[test]
    fn p5_detection_gives_every_input_of_a_linear_model_the_same_score() {
        let d = detection(&test_set());
        assert_eq!(d.same_score, d.inputs);
        assert_eq!(d.flagged_low, d.inputs);
        assert_eq!(d.flagged_high, 0);
        // control: with probability outputs, the score depends on the input
        assert!(d.near > 10.0 * d.far, "{} {}", d.near, d.far);
    }

    #[test]
    fn p6_squeezing_keeps_the_mean_perturbation() {
        for (bits, eps, fraction, rms) in [(3, 0.05, 0.350, 0.0845), (5, 0.01, 0.310, 0.0180)] {
            let s = squeeze(bits, eps);
            assert!(
                (s.changed - fraction).abs() <= 0.005,
                "{bits}: {}",
                s.changed
            );
            assert!(
                (s.mean_abs - eps).abs() <= 0.02 * eps,
                "{bits}: {}",
                s.mean_abs
            );
            assert!((s.rms - rms).abs() <= 0.02 * rms, "{bits}: {}", s.rms);
        }
        assert!(squeeze_zero_bits().iter().all(|v| v.is_nan()));
    }

    #[test]
    fn p7_the_certified_radius_uses_a_four_digit_probit() {
        let r = radius();
        assert!((1e-4..=4.5e-4).contains(&r.max_error), "{}", r.max_error);
        assert!((r.logits_2_1 - 6.36).abs() < 0.01, "{}", r.logits_2_1);
        assert_eq!(r.logits_3_1, 0.0);
    }

    #[test]
    fn p8_poisoning_defences() {
        let f = label_flips();
        assert!(f.influence_identical);
        assert!(f.found >= 95, "{}", f.found);
        assert!(f.others <= 17, "{}", f.others);
        let s = spectral();
        assert_eq!(s.clean, [9, 9]);
        assert_eq!(s.poisoned, [10, 9]);
        assert_eq!(s.poison_found, 5);
    }
}
