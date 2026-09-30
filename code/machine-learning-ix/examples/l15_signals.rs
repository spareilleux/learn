//! Lesson 15: the FFT, Welch's density, filters, Haar wavelets and the Kalman filter, with IX's `ix-signal`.

use machine_learning_ix::fmt_vec;
use machine_learning_ix::signal::{
    FALLING, Q, R, RAMP, against_direct_dft, blocks, butterworth, default_kalman, empty_fft,
    fir_checks, haar_denoise, haar_round_trip, haar_shapes, ix_fft_error, k_infinity,
    kalman_consistency, kalman_random_walk, length_one_windows, pearson, ramp_autocorrelation,
    ramps_cross_correlation, welch_peak, welch_scale,
};

/// The decade a positive number falls in: "1e-13 to 1e-12". The platform's `cos` and `sin` move IX's
/// FFT error in its last digits, not across a decade.
fn decade(x: f64) -> String {
    let e = x.log10().floor() as i32;
    format!("1e{} to 1e{}", e, e + 1)
}

fn main() {
    println!("== Welch's density, 16,384 samples of unit-variance noise, fs 1000, segments 512");
    let scale = welch_scale(15);
    println!(
        "  integral / variance, as IX returns it:     {:.3}",
        scale.integral
    );
    println!(
        "  bins 1 to 255 doubled (one-sided):         {:.3}",
        scale.one_sided
    );

    println!();
    println!("== welch_psd on sines, fs 1000, 8,192 samples");
    for (freq, window) in [(200.0, 300), (400.0, 300), (200.0, 256), (400.0, 256)] {
        let peak = welch_peak(freq, window);
        println!(
            "  {freq:.0} Hz, segments of {window}: {} bins, peak at index {}, labelled {:.1} Hz",
            peak.bins, peak.index, peak.label
        );
    }
    let ratio = welch_peak(400.0, 300).value / welch_peak(200.0, 300).value;
    println!(
        "  segments of 300: largest value of the 400 Hz sine / the 200 Hz peak: {}",
        decade(ratio)
    );

    println!();
    println!("== IX's FFT against a reference whose twiddles are computed one by one");
    for log2 in [8, 12, 16] {
        println!(
            "  N = 2^{log2:<2}  relative RMS error {}",
            decade(ix_fft_error(log2))
        );
    }
    println!(
        "  error at 2^16 / error at 2^8: at least 16: {}",
        ix_fft_error(16) >= 16.0 * ix_fft_error(8)
    );
    let (reference, _) = against_direct_dft(10);
    println!(
        "  N = 2^10, the reference against the DFT by its definition: {}",
        decade(reference)
    );

    println!();
    println!("== Second-order Butterworth, fc 0.1");
    let bw = butterworth();
    println!("  b {}", fmt_vec(bw.b.iter().copied(), 9));
    println!("  a {}", fmt_vec(bw.a.iter().copied(), 9));
    println!(
        "  gain at DC {:.12}, at fc {:.12}, at Nyquist {}",
        bw.dc, bw.cutoff, bw.nyquist
    );
    println!(
        "  a sine at fc through IirFilter::apply: amplitude {:.4}",
        bw.amplitude
    );

    println!();
    println!("== Kalman filter of a random walk, q {Q}, r {R}");
    let k = k_infinity(Q, R);
    let run = kalman_random_walk(15);
    println!("  steady-state gain from the Riccati equation:   {k:.9}");
    println!(
        "  IX's variance after 200 steps:                 {:.9}",
        run.variance_200
    );
    println!(
        "  largest |state - ewma(K)|, steps 300 to 1000:  {}",
        decade(run.ewma_gap)
    );
    println!(
        "  mean squared error / (K r), 200 runs:          {:.3}",
        kalman_consistency(200)
    );
    let (largest, first_variance) = default_kalman();
    println!(
        "  KalmanFilter::new(2, 1) as built, 100 measurements of 5: largest |state| {largest}, first variance {first_variance:.6}"
    );

    println!();
    println!("== Haar wavelets");
    let shapes = haar_shapes(12, 3);
    println!(
        "  12 samples, 3 levels: approximation {}, details {:?}, haar_idwt returns {}, wavelet_denoise returns {}",
        shapes.approx, shapes.details, shapes.inverse, shapes.denoised
    );
    println!(
        "  16 samples, 4 levels: round trip within 1e-12: {}",
        haar_round_trip(4, 4) < 1e-12
    );
    let aligned = haar_denoise(0, 20);
    let shifted = haar_denoise(16, 20);
    println!(
        "  blocks of 64, sigma 0.5, 5 levels, universal threshold, 20 draws ({} jumps)",
        blocks(0).windows(2).filter(|w| w[0] != w[1]).count()
    );
    println!("    jumps on multiples of 64: MSE / sigma^2 {aligned:.4}");
    println!(
        "    shifted by 16:            MSE / sigma^2 {shifted:.4} ({:.1} times)",
        shifted / aligned
    );

    println!();
    println!("== FIR filters");
    let fir = fir_checks();
    println!(
        "  highpass(0.25, 31) at f 0.05: gain {:.4}",
        fir.odd_highpass
    );
    println!(
        "  highpass(0.25, 32) at f 0.05: gain {:.5}",
        fir.even_highpass
    );
    println!(
        "  lowpass(0.1, 64): gain on [0, 0.05] {:.4} to {:.4}, largest on [0.15, 0.5] {:.5}",
        fir.passband.0, fir.passband.1, fir.stopband
    );
    println!(
        "  lowpass(0.1, 64): centre tap {:.9}, sum of the taps {:.9}",
        fir.centre_tap, fir.tap_sum
    );
    println!(
        "  lowpass(0.1, 64) on a sine at 0.02: largest |y[n] - x[n - 32]| after 64 samples {:.4}",
        fir.delay_gap
    );

    println!();
    println!("== Edge cases");
    for (name, value) in length_one_windows() {
        println!("  {name:<14} of length 1: {value:.4}");
    }
    match empty_fft() {
        Ok(spectrum) => println!(
            "  fft(&[]): {} value(s), {:?}",
            spectrum.len(),
            spectrum.iter().map(|c| (c.re, c.im)).collect::<Vec<_>>()
        ),
        Err(message) => println!("  fft(&[]): panic {message:?}"),
    }
    println!(
        "  normalized_cross_correlation({RAMP:?}, {FALLING:?}): {}",
        fmt_vec(ramps_cross_correlation(), 4)
    );
    println!("  Pearson at lag 0: {:.4}", pearson(&RAMP, &FALLING));
    println!(
        "  autocorrelation({RAMP:?}): {}",
        fmt_vec(ramp_autocorrelation(), 4)
    );
}
