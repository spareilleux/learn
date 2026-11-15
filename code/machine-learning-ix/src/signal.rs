//! Lesson 15: signals, measured against IX's `ix-signal`: the FFT, Welch's density, FIR and IIR filters,
//! Haar wavelets and the Kalman filter.
//!
//! Noise comes from the course's `Rng` as sums of twelve uniforms minus six, arithmetic only. Sines,
//! cosines and IX's FFT go through the platform's maths library, so the example prints what they feed
//! rounded, or as decades.

use std::f64::consts::PI;
use std::panic::{AssertUnwindSafe, catch_unwind};

use ix_signal::fft::{self, Complex};
use ix_signal::filter::{FirFilter, butterworth_lowpass_2nd};
use ix_signal::kalman::KalmanFilter;
use ix_signal::{correlation, spectral, timeseries, wavelet, window};
use ndarray::array;

use crate::autodiff::Rng;
use crate::rl::normal;
use crate::transformer::panic_message;

/// `n` draws of unit-variance noise from `Rng(seed)`
pub fn white_noise(n: usize, seed: u64) -> Vec<f64> {
    let mut rng = Rng(seed);
    (0..n).map(|_| normal(&mut rng)).collect()
}

/// Mean of the squared deviations from the mean
pub fn variance(x: &[f64]) -> f64 {
    let mean = x.iter().sum::<f64>() / x.len() as f64;
    x.iter().map(|v| (v - mean) * (v - mean)).sum::<f64>() / x.len() as f64
}

/// `n` samples of sin(2π·freq·i/fs)
pub fn sine(freq: f64, fs: f64, n: usize) -> Vec<f64> {
    (0..n)
        .map(|i| (2.0 * PI * freq * i as f64 / fs).sin())
        .collect()
}

/// Index of the first largest value
fn argmax(v: &[f64]) -> usize {
    v.iter()
        .enumerate()
        .fold(0, |best, (i, &x)| if x > v[best] { i } else { best })
}

/// Welch's density integrated over its bins and divided by the sample variance, as IX returns it and with
/// bins 1 to N/2 − 1 doubled, the one-sided convention
pub struct WelchScale {
    pub integral: f64,
    pub one_sided: f64,
}

/// 16,384 samples of unit-variance noise at fs = 1,000, segments of 512 overlapping by 256
pub fn welch_scale(seed: u64) -> WelchScale {
    let x = white_noise(16_384, seed);
    let var = variance(&x);
    let (_, psd) = spectral::welch_psd(&x, 512, 256, 1000.0);
    let df = 1000.0 / 512.0;
    let last = psd.len() - 1;
    let doubled = psd
        .iter()
        .enumerate()
        .map(|(i, p)| if i == 0 || i == last { *p } else { 2.0 * p });
    WelchScale {
        integral: psd.iter().sum::<f64>() * df / var,
        one_sided: doubled.sum::<f64>() * df / var,
    }
}

/// Where `welch_psd` puts the peak of a sine: how many bins it returns, the index of the largest, the
/// frequency it labels that index with, and the value there
pub struct WelchPeak {
    pub bins: usize,
    pub index: usize,
    pub label: f64,
    pub value: f64,
}

/// A sine of `freq` Hz, 8,192 samples at fs = 1,000, segments of `window` overlapping by half
pub fn welch_peak(freq: f64, window: usize) -> WelchPeak {
    let x = sine(freq, 1000.0, 8192);
    let (freqs, psd) = spectral::welch_psd(&x, window, window / 2, 1000.0);
    let index = argmax(&psd);
    WelchPeak {
        bins: psd.len(),
        index,
        label: freqs[index],
        value: psd[index],
    }
}

/// Radix-2 FFT whose twiddle factors are each computed directly, e^(−2πik/N) for k < N/2
pub fn reference_fft(x: &[f64]) -> Vec<Complex> {
    let n = x.len();
    assert!(n.is_power_of_two() && n >= 2);
    let bits = n.trailing_zeros();
    let mut data: Vec<Complex> = (0..n)
        .map(|i| Complex::from_real(x[i.reverse_bits() >> (usize::BITS - bits)]))
        .collect();
    let table: Vec<Complex> = (0..n / 2)
        .map(|k| {
            let angle = -2.0 * PI * k as f64 / n as f64;
            Complex::new(angle.cos(), angle.sin())
        })
        .collect();
    let mut len = 2;
    while len <= n {
        let half = len / 2;
        let step = n / len;
        for start in (0..n).step_by(len) {
            for k in 0..half {
                let even = data[start + k];
                let odd = data[start + k + half] * table[k * step];
                data[start + k] = even + odd;
                data[start + k + half] = even - odd;
            }
        }
        len <<= 1;
    }
    data
}

/// Neumaier's compensated sum
fn compensated_sum(values: impl Iterator<Item = f64>) -> f64 {
    let (mut sum, mut compensation) = (0.0_f64, 0.0_f64);
    for v in values {
        let t = sum + v;
        compensation += if sum.abs() >= v.abs() {
            (sum - t) + v
        } else {
            (v - t) + sum
        };
        sum = t;
    }
    sum + compensation
}

/// The DFT by its definition, X_k = Σ x_j e^(−2πi·(kj mod N)/N), each sum compensated
pub fn direct_dft(x: &[f64]) -> Vec<Complex> {
    let n = x.len();
    let table: Vec<Complex> = (0..n)
        .map(|m| {
            let angle = -2.0 * PI * m as f64 / n as f64;
            Complex::new(angle.cos(), angle.sin())
        })
        .collect();
    let table = &table;
    (0..n)
        .map(|k| {
            let terms = || {
                x.iter()
                    .enumerate()
                    .map(move |(j, &v)| table[(k * j) % n] * v)
            };
            Complex::new(
                compensated_sum(terms().map(|c| c.re)),
                compensated_sum(terms().map(|c| c.im)),
            )
        })
        .collect()
}

/// ‖a − b‖ / ‖b‖ over complex vectors
pub fn relative_rms(a: &[Complex], b: &[Complex]) -> f64 {
    let num: f64 = a
        .iter()
        .zip(b)
        .map(|(x, y)| (x.re - y.re).powi(2) + (x.im - y.im).powi(2))
        .sum();
    let den: f64 = b.iter().map(|y| y.re * y.re + y.im * y.im).sum();
    (num / den).sqrt()
}

/// 2^log2 uniform numbers in [−1, 1) from `Rng(15_200 + log2)`
pub fn uniform_signal(log2: u32) -> Vec<f64> {
    let mut rng = Rng(15_200 + log2 as u64);
    (0..1usize << log2)
        .map(|_| 2.0 * rng.next_f64() - 1.0)
        .collect()
}

/// Relative RMS error of IX's `fft` against `reference_fft` on `uniform_signal(log2)`
pub fn ix_fft_error(log2: u32) -> f64 {
    let x = uniform_signal(log2);
    relative_rms(&fft::rfft(&x), &reference_fft(&x))
}

/// Relative RMS error of `reference_fft` against `direct_dft`, and of IX's `fft` against it, at 2^log2
pub fn against_direct_dft(log2: u32) -> (f64, f64) {
    let x = uniform_signal(log2);
    let dft = direct_dft(&x);
    (
        relative_rms(&reference_fft(&x), &dft),
        relative_rms(&fft::rfft(&x), &dft),
    )
}

/// |H(e^(2πif))| of a filter with numerator `b` and denominator `a`
pub fn response(b: &[f64], a: &[f64], f: f64) -> f64 {
    let at = |c: &[f64]| {
        c.iter().enumerate().fold(Complex::zero(), |acc, (k, &v)| {
            let angle = -2.0 * PI * f * k as f64;
            acc + Complex::new(angle.cos(), angle.sin()) * v
        })
    };
    at(b).magnitude() / at(a).magnitude()
}

/// IX's second-order Butterworth at fc = 0.1: its coefficients, its gain at DC and at fc, its gain at
/// Nyquist computed at z = −1 in real arithmetic, and the amplitude (RMS × √2 over the last 1,000 of
/// 4,000 samples) of a sine at fc through `IirFilter::apply`
pub struct Butterworth {
    pub b: Vec<f64>,
    pub a: Vec<f64>,
    pub dc: f64,
    pub cutoff: f64,
    pub nyquist: f64,
    pub amplitude: f64,
}

pub fn butterworth() -> Butterworth {
    let filter = butterworth_lowpass_2nd(0.1);
    let alternating = |c: &[f64]| {
        c.iter()
            .enumerate()
            .map(|(k, v)| if k % 2 == 0 { *v } else { -v })
            .sum::<f64>()
    };
    let y = filter.apply(&sine(0.1, 1.0, 4000));
    let tail = &y[3000..];
    let rms = (tail.iter().map(|v| v * v).sum::<f64>() / tail.len() as f64).sqrt();
    Butterworth {
        dc: filter.b.iter().sum::<f64>() / filter.a.iter().sum::<f64>(),
        cutoff: response(&filter.b, &filter.a, 0.1),
        nyquist: alternating(&filter.b) / alternating(&filter.a),
        amplitude: rms * std::f64::consts::SQRT_2,
        b: filter.b,
        a: filter.a,
    }
}

/// The steady-state gain of a random walk with step variance `q` observed with noise variance `r`:
/// P⁻ = (q + √(q² + 4qr))/2 solves the Riccati equation, and K = P⁻/(P⁻ + r)
pub fn k_infinity(q: f64, r: f64) -> f64 {
    let prior = (q + (q * q + 4.0 * q * r).sqrt()) / 2.0;
    prior / (prior + r)
}

pub const Q: f64 = 0.01;
pub const R: f64 = 1.0;

/// 1,000 steps of a random walk from 0 with step variance `Q`, and its measurements with noise variance `R`
pub fn random_walk(seed: u64) -> (Vec<f64>, Vec<f64>) {
    let mut rng = Rng(seed);
    let mut x = 0.0;
    let mut truth = Vec::with_capacity(1000);
    let mut measured = Vec::with_capacity(1000);
    for _ in 0..1000 {
        x += Q.sqrt() * normal(&mut rng);
        truth.push(x);
        measured.push(x + R.sqrt() * normal(&mut rng));
    }
    (truth, measured)
}

fn random_walk_filter() -> KalmanFilter {
    let mut kf = KalmanFilter::new(1, 1);
    kf.transition = array![[1.0]];
    kf.observation = array![[1.0]];
    kf.process_noise = array![[Q]];
    kf.measurement_noise = array![[R]];
    kf
}

/// IX's Kalman filter on one random walk: the filtered states, its variance after 200 steps, and the
/// largest gap between the filtered state and `timeseries::ewma` at α = K∞ over steps 300 to 1,000
pub struct KalmanRun {
    pub states: Vec<f64>,
    pub variance_200: f64,
    pub ewma_gap: f64,
}

pub fn kalman_random_walk(seed: u64) -> KalmanRun {
    let (_, measured) = random_walk(seed);
    let mut kf = random_walk_filter();
    let mut states = Vec::with_capacity(measured.len());
    let mut variance_200 = f64::NAN;
    for (k, z) in measured.iter().enumerate() {
        states.push(kf.step(&array![*z], None)[0]);
        if k == 199 {
            variance_200 = kf.covariance[[0, 0]];
        }
    }
    let smoothed = timeseries::ewma(&measured, k_infinity(Q, R));
    let ewma_gap = (300..1000)
        .map(|k| (states[k] - smoothed[k]).abs())
        .fold(0.0, f64::max);
    KalmanRun {
        states,
        variance_200,
        ewma_gap,
    }
}

/// Mean of (x − x̂)² over steps 200 to 1,000 of `runs` random walks, divided by the steady-state
/// variance K∞·R
pub fn kalman_consistency(runs: u64) -> f64 {
    let mut total = 0.0;
    let mut count = 0;
    for run in 0..runs {
        let (truth, _) = random_walk(15_000 + run);
        let states = kalman_random_walk(15_000 + run).states;
        for k in 200..1000 {
            total += (truth[k] - states[k]).powi(2);
            count += 1;
        }
    }
    total / count as f64 / (k_infinity(Q, R) * R)
}

/// `KalmanFilter::new(2, 1)` left as built, fed 100 measurements of 5: the largest |state| and the
/// first variance
pub fn default_kalman() -> (f64, f64) {
    let mut kf = KalmanFilter::new(2, 1);
    let states = kf.filter(&vec![array![5.0]; 100]);
    let largest = states
        .iter()
        .flat_map(|s| s.iter().map(|v| v.abs()))
        .fold(0.0, f64::max);
    (largest, kf.covariance[[0, 0]])
}

/// Lengths through IX's Haar functions for the input 1, 2, …, `len`: the approximation, each level's
/// details, what `haar_idwt` returns and what `wavelet_denoise` returns
pub struct HaarShapes {
    pub approx: usize,
    pub details: Vec<usize>,
    pub inverse: usize,
    pub denoised: usize,
}

pub fn haar_shapes(len: usize, levels: usize) -> HaarShapes {
    let x: Vec<f64> = (1..=len).map(|i| i as f64).collect();
    let (approx, details) = wavelet::haar_dwt(&x, levels);
    HaarShapes {
        approx: approx.len(),
        details: details.iter().map(Vec::len).collect(),
        inverse: wavelet::haar_idwt(&approx, &details).len(),
        denoised: wavelet::wavelet_denoise(&x, levels, 0.5).len(),
    }
}

/// Largest |x − haar_idwt(haar_dwt(x))| on `uniform_signal`-like input of length 2^log2
pub fn haar_round_trip(log2: u32, levels: usize) -> f64 {
    let x = uniform_signal(log2);
    let (approx, details) = wavelet::haar_dwt(&x, levels);
    let back = wavelet::haar_idwt(&approx, &details);
    x.iter()
        .zip(&back)
        .map(|(a, b)| (a - b).abs())
        .fold(0.0, f64::max)
}

/// The 16 levels of the block signal, each held for 64 samples; consecutive levels differ by at least 1
pub const BLOCKS: [f64; 16] = [
    0.0, 2.0, -1.0, 3.0, 1.0, -2.0, 0.0, 4.0, -3.0, 1.0, 2.0, -1.0, 0.0, 3.0, -2.0, 1.0,
];
pub const SIGMA: f64 = 0.5;

/// The block signal of 1,024 samples moved `shift` samples to the right, wrapping around
pub fn blocks(shift: usize) -> Vec<f64> {
    (0..1024)
        .map(|n| BLOCKS[((n + 1024 - shift) % 1024) / 64])
        .collect()
}

/// Mean over `draws` noise draws (σ = 0.5, `Rng(15_100 + draw)`) of the mean squared error of
/// `wavelet_denoise` at 5 levels and the universal threshold σ√(2 ln N), divided by σ²
pub fn haar_denoise(shift: usize, draws: u64) -> f64 {
    let clean = blocks(shift);
    let threshold = SIGMA * (2.0 * (clean.len() as f64).ln()).sqrt();
    let mut total = 0.0;
    for draw in 0..draws {
        let mut rng = Rng(15_100 + draw);
        let noisy: Vec<f64> = clean.iter().map(|c| c + SIGMA * normal(&mut rng)).collect();
        let denoised = wavelet::wavelet_denoise(&noisy, 5, threshold);
        total += clean
            .iter()
            .zip(&denoised)
            .map(|(c, d)| (c - d).powi(2))
            .sum::<f64>()
            / clean.len() as f64;
    }
    total / draws as f64 / (SIGMA * SIGMA)
}

/// |H(e^(2πif))| of an FIR filter
pub fn fir_gain(h: &[f64], f: f64) -> f64 {
    response(h, &[1.0], f)
}

/// Smallest and largest FIR gain on [lo, hi], every 0.001
pub fn gain_range(h: &[f64], lo: f64, hi: f64) -> (f64, f64) {
    let steps = ((hi - lo) / 0.001).round() as usize;
    (0..=steps)
        .map(|i| fir_gain(h, lo + i as f64 * 0.001))
        .fold((f64::INFINITY, 0.0), |(min, max), g| {
            (min.min(g), max.max(g))
        })
}

/// The FIR checks: the odd and even high-passes at f = 0.05, the low-pass's gain on its bands, and the
/// largest gap between the low-pass's output and its input 32 samples earlier, for a sine at 0.02 cycles
/// per sample after the first 64 samples, and the low-pass's centre tap and the sum of its taps (its gain
/// at DC)
pub struct FirChecks {
    pub odd_highpass: f64,
    pub even_highpass: f64,
    pub passband: (f64, f64),
    pub stopband: f64,
    pub delay_gap: f64,
    pub centre_tap: f64,
    pub tap_sum: f64,
}

pub fn fir_checks() -> FirChecks {
    let odd = FirFilter::highpass(0.25, 31);
    let even = FirFilter::highpass(0.25, 32);
    let low = FirFilter::lowpass(0.1, 64);
    let x = sine(0.02, 1.0, 1000);
    let y = low.apply(&x);
    FirChecks {
        odd_highpass: fir_gain(&odd.coefficients, 0.05),
        even_highpass: fir_gain(&even.coefficients, 0.05),
        passband: gain_range(&low.coefficients, 0.0, 0.05),
        stopband: gain_range(&low.coefficients, 0.15, 0.5).1,
        delay_gap: (64..1000)
            .map(|n| (y[n] - x[n - 32]).abs())
            .fold(0.0, f64::max),
        centre_tap: low.coefficients[32],
        tap_sum: low.coefficients.iter().sum(),
    }
}

/// The value of each IX window of length 1
pub fn length_one_windows() -> Vec<(&'static str, f64)> {
    vec![
        ("hanning", window::hanning(1)[0]),
        ("hamming", window::hamming(1)[0]),
        ("blackman", window::blackman(1)[0]),
        ("bartlett", window::bartlett(1)[0]),
        ("gaussian(0.4)", window::gaussian(1, 0.4)[0]),
        ("kaiser(5)", window::kaiser(1, 5.0)[0]),
    ]
}

/// `fft(&[])`, run under `catch_unwind`
pub fn empty_fft() -> Result<Vec<Complex>, String> {
    catch_unwind(AssertUnwindSafe(|| fft::fft(&[]))).map_err(panic_message)
}

/// Pearson's correlation of two equal-length series
pub fn pearson(a: &[f64], b: &[f64]) -> f64 {
    let mean = |v: &[f64]| v.iter().sum::<f64>() / v.len() as f64;
    let (ma, mb) = (mean(a), mean(b));
    let cov: f64 = a.iter().zip(b).map(|(x, y)| (x - ma) * (y - mb)).sum();
    let va: f64 = a.iter().map(|x| (x - ma).powi(2)).sum();
    let vb: f64 = b.iter().map(|y| (y - mb).powi(2)).sum();
    cov / (va * vb).sqrt()
}

pub const RAMP: [f64; 4] = [1.0, 2.0, 3.0, 4.0];
pub const FALLING: [f64; 4] = [4.0, 3.0, 2.0, 1.0];

/// IX's `normalized_cross_correlation` of the rising and falling ramps, every lag
pub fn ramps_cross_correlation() -> Vec<f64> {
    correlation::normalized_cross_correlation(&RAMP, &FALLING)
}

/// IX's `autocorrelation` of the rising ramp, every lag
pub fn ramp_autocorrelation() -> Vec<f64> {
    correlation::autocorrelation(&RAMP)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn p1_welch_density_integrates_to_half_the_variance() {
        let scale = welch_scale(15);
        assert!(
            (0.45..=0.55).contains(&scale.integral),
            "{}",
            scale.integral
        );
        // control: doubling bins 1 to 255 gives the one-sided density, which integrates to the variance
        assert!((scale.one_sided - 1.0).abs() < 0.05, "{}", scale.one_sided);
    }

    #[test]
    fn p2_a_300_sample_segment_mislabels_and_drops_frequencies() {
        let at200 = welch_peak(200.0, 300);
        assert_eq!((at200.bins, at200.index), (151, 102));
        assert!((at200.label - 340.0).abs() < 1e-9, "{}", at200.label);
        let at400 = welch_peak(400.0, 300);
        assert!(at400.value < 1e-6 * at200.value, "{}", at400.value);
        // control: with segments of 256 both sines peak within one bin (3.9 Hz) of their frequency
        for freq in [200.0, 400.0] {
            let peak = welch_peak(freq, 256);
            assert!((peak.label - freq).abs() < 1000.0 / 256.0, "{}", peak.label);
        }
    }

    #[test]
    fn p3_the_fft_twiddles_drift_with_n() {
        let small = ix_fft_error(8);
        let large = ix_fft_error(16);
        assert!((1e-14..=1e-11).contains(&large), "{large:e}");
        assert!(large >= 16.0 * small, "{large:e} vs {small:e}");
        // control: the reference agrees with the DFT by its definition
        let (reference, _) = against_direct_dft(10);
        assert!(reference < 1e-14, "{reference:e}");
    }

    #[test]
    fn p4_butterworth_is_exact_at_dc_cutoff_and_nyquist() {
        let bw = butterworth();
        assert!((bw.dc - 1.0).abs() < 1e-12, "{}", bw.dc);
        assert!(
            (bw.cutoff - std::f64::consts::FRAC_1_SQRT_2).abs() < 1e-12,
            "{}",
            bw.cutoff
        );
        assert_eq!(bw.nyquist, 0.0);
        assert!(
            (bw.amplitude - std::f64::consts::FRAC_1_SQRT_2).abs() < 1e-3,
            "{}",
            bw.amplitude
        );
    }

    #[test]
    fn p5_the_steady_state_kalman_filter_is_an_ewma() {
        let k = k_infinity(Q, R);
        assert!((k - 0.0951249).abs() < 1e-7, "{k}");
        let run = kalman_random_walk(15);
        assert!(
            (run.variance_200 - k * R).abs() < 1e-12,
            "{}",
            run.variance_200
        );
        assert!(run.ewma_gap < 1e-9, "{:e}", run.ewma_gap);
        let ratio = kalman_consistency(200);
        assert!((0.95..=1.05).contains(&ratio), "{ratio}");
        // control: with its zero observation matrix the default filter never moves
        let (largest, first_variance) = default_kalman();
        assert_eq!(largest, 0.0);
        assert!((first_variance - 2.0).abs() < 1e-12, "{first_variance}");
    }

    #[test]
    fn p6_haar_truncates_a_length_that_is_not_a_power_of_two() {
        let shapes = haar_shapes(12, 3);
        assert_eq!(shapes.approx, 1);
        assert_eq!(shapes.details, vec![6, 3, 1]);
        assert_eq!((shapes.inverse, shapes.denoised), (8, 8));
        // control: a power of two comes back
        assert!(haar_round_trip(4, 4) < 1e-12);
    }

    #[test]
    fn p7_haar_denoising_depends_on_where_the_jumps_fall() {
        let aligned = haar_denoise(0, 20);
        let shifted = haar_denoise(16, 20);
        assert!((0.02..=0.05).contains(&aligned), "{aligned}");
        assert!(shifted >= 3.0 * aligned, "{shifted} vs {aligned}");
    }

    #[test]
    fn p8_an_odd_order_breaks_the_highpass() {
        let fir = fir_checks();
        assert!(
            (0.12..=0.2).contains(&fir.odd_highpass),
            "{}",
            fir.odd_highpass
        );
        assert!(fir.even_highpass < 0.0032, "{}", fir.even_highpass);
        // control: the even low-pass keeps its bands and delays by order/2 samples
        let (low, high) = fir.passband;
        assert!(low > 0.99 && high < 1.01, "{low} {high}");
        assert!(fir.stopband < 0.0032, "{}", fir.stopband);
        assert!(fir.delay_gap < 1e-2, "{}", fir.delay_gap);
    }

    #[test]
    fn p9_edge_cases_against_the_contract() {
        let windows = length_one_windows();
        for (name, value) in &windows[..5] {
            assert!(value.is_nan(), "{name}: {value}");
        }
        assert!((windows[5].1 - 0.0367).abs() < 1e-4, "{}", windows[5].1);
        assert_eq!(empty_fft(), Ok(vec![Complex::zero()]));
        let ncc = ramps_cross_correlation();
        assert_eq!(ncc.len(), 7);
        assert!((ncc[3] - 20.0 / 30.0).abs() < 1e-12, "{}", ncc[3]);
        assert!(ncc.iter().all(|v| *v >= 0.0));
        assert!((pearson(&RAMP, &FALLING) + 1.0).abs() < 1e-12);
        assert_eq!(ramp_autocorrelation()[3], 1.0);
    }

    #[test]
    fn the_reference_fft_matches_the_dft_on_a_small_case() {
        let x = [1.0, 2.0, 0.0, -1.0];
        let (reference, direct) = (reference_fft(&x), direct_dft(&x));
        // X = [2, 1 − 3i, 0, 1 + 3i]
        assert!(relative_rms(&reference, &direct) < 1e-15);
        assert!((direct[1].re - 1.0).abs() < 1e-15 && (direct[1].im + 3.0).abs() < 1e-15);
    }

    #[test]
    fn the_noise_has_mean_0_and_variance_1() {
        let x = white_noise(100_000, 15);
        let mean = x.iter().sum::<f64>() / x.len() as f64;
        assert!(mean.abs() < 0.01, "{mean}");
        assert!((variance(&x) - 1.0).abs() < 0.02);
    }
}
