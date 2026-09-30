---
title: "15. Signals: the Fourier transform, wavelets, filters and Kalman"
description: "The FFT, Welch's density, FIR and IIR filters, Haar wavelets and the Kalman filter against IX's ix-signal, with nine predictions written before the first run, all held. The textbook designs come out exact; IX's Welch density covers half the variance, mislabels its frequencies when a segment is not a power of two, its FFT's error grows linearly with N, and its Haar transform truncates where its contract promises a panic."
sidebar:
  order: 15
---

A signal is a sequence of numbers sampled at regular intervals: a sound, a sensor, a price, a metric sampled every minute. IX's pinned [`ix-signal`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal) crate has the classic tools for it: the fast Fourier transform, window functions, Welch's power spectral density, FIR and IIR filters, Haar wavelets and the Kalman filter. [Lesson 12](../12-autodiff/) already differentiated through its FFT. This lesson measures what each tool returns against what the theory says, and checks what IX's [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md) promises.

The nine predictions this lesson tests were [written in the journal](../journal/#2026-09-30--lesson-15-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-15-measured) follow them. The experiments are in [`signal.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/signal.rs), one test per prediction. [`l15_signals.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l15_signals.rs) prints what they measure. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recomputes Welch's density, the Butterworth coefficients, the Kalman gain and the FIR taps with [numpy](https://numpy.org/doc/stable/) and [SciPy](https://docs.scipy.org/doc/scipy/). Noise comes from the course's `Rng` as sums of twelve uniforms minus six, as in [lesson 14](../14-reinforcement-learning/), so the three CI systems draw the same numbers.

## 1. The FFT and its twiddle factors

The discrete Fourier transform of N samples is

X_k = Σⱼ xⱼ e^(−2πi·jk/N), k = 0, …, N − 1.

Computed as written, it costs N² multiplications. [Cooley and Tukey](https://doi.org/10.1090/S0025-5718-1965-0178586-1)'s radix-2 algorithm splits the sum into even and odd samples, twice as short, and recombines them with the *twiddle factors* w^k = e^(−2πik/L), in log₂ N stages of N/2 operations each. IX's `fft` pads its input with zeros up to the next power of two ([`CONTRACTS.md` 8](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L8)), and `ifft` divides by N.

In each stage, IX computes one cosine and one sine, then reaches the other twiddles by multiplying by that one again ([`fft.rs` 169-178](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/fft.rs#L169-L178)). The k-th twiddle carries k roundings, and part of the error is systematic. For a small angle, cos θ is just below 1 and rounds to within half an ulp of it, about 5.5 × 10⁻¹⁷. The modulus of w then drifts by about k times that. `reference_fft` in `signal.rs` is the same algorithm with each twiddle computed directly. `direct_dft` is the sum above with compensated additions. P3 compares them on uniform input in [−1, 1]:

```text
== IX's FFT against a reference whose twiddles are computed one by one
  N = 2^8   relative RMS error 1e-15 to 1e-14
  N = 2^12  relative RMS error 1e-14 to 1e-13
  N = 2^16  relative RMS error 1e-13 to 1e-12
  error at 2^16 / error at 2^8: at least 16: true
  N = 2^10, the reference against the DFT by its definition: 1e-16 to 1e-15
```

The example prints decades, because each platform's `cos` and `sin` move the last digits. On Windows, the error is 1.8 × 10⁻¹⁵ at 2⁸, 2.9 × 10⁻¹⁴ at 2¹², 1.3 × 10⁻¹³ at 2¹⁴ and 5.4 × 10⁻¹³ at 2¹⁶. It is multiplied by about four each time N is. It grows linearly: 300 times from 2⁸ to 2¹⁶, where log N would give 2. The reference stays within 3.9 × 10⁻¹⁶ of the direct DFT. The numpy cross-check runs IX's recurrence against [`numpy.fft`](https://numpy.org/doc/stable/reference/routines.fft.html) and lands in the same decades.

[`CONTRACTS.md` 39](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L39) says that the twiddles are "computed via `f64::cos/sin`" and that platforms may differ "at ULP scale". At 2¹⁶ the error is about 2,400 ulps of 1. That still leaves twelve correct digits, plenty for a spectrum. But it keeps growing with N, and it is no longer what the contract describes. A table of directly computed twiddles, as in the reference, costs only N/2 values. [Schatzman (1996)](https://doi.org/10.1137/S1064827593247023) says it in his abstract: "Popular recursions for fast computation of the sine/cosine table (or twiddle factors) are inaccurate due to inherent instability."

## 2. Welch's density

A spectrum shows where a signal's power sits in frequency. The periodogram |X_k|² of the whole signal is noisy. [Welch (1967)](https://doi.org/10.1109/TAU.1967.1161901) cuts the signal into overlapping segments, multiplies each by a window, and averages their periodograms. The window tapers the segment's ends, so a frequency between two bins leaks less into the others. [Harris (1978)](https://doi.org/10.1109/PROC.1978.10837) compares the classic windows. IX's `welch_psd` uses a Hann window and divides each |X_k|² by Σw² and by the sample rate ([`spectral.rs` 79-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L79-L92)). For white noise of variance σ², each bin then averages σ²/fs.

A real signal's spectrum is symmetric: bin N − k carries the same power as bin k. A *one-sided* density keeps bins 0 to N/2 and doubles bins 1 to N/2 − 1, so that it integrates to the variance (Parseval). This is the density [`scipy.signal.welch`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html) returns by default. IX returns the same bins without doubling them (P1):

```text
== Welch's density, 16,384 samples of unit-variance noise, fs 1000, segments 512
  integral / variance, as IX returns it:     0.503
  bins 1 to 255 doubled (one-sided):         1.002
```

IX's density integrates to half the variance, 257/512 of it. In the cross-check, `scipy.signal.welch`, with the same symmetric Hann window and no detrending, returns exactly twice IX's convention on bins 1 to 255, within 10⁻⁹, and the same value on bins 0 and 256. Neither convention is wrong. A two-sided density is just as legitimate, but it would also cover the negative frequencies, and IX's doc comment names neither. Compared with SciPy or with a variance, IX's values come out half as large.

The second trap is in the frequency axis. `rfft` pads a segment to the next power of two. `welch_psd` keeps window_size/2 + 1 bins of that longer transform, and labels bin k with k·fs/window_size ([`spectral.rs` 94-96](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L94-L96)). With segments of 300, the transform has 512 bins, bin k lies at k·1000/512 Hz, and only bins 0 to 150 are kept, up to 293 Hz (P2):

```text
== welch_psd on sines, fs 1000, 8,192 samples
  200 Hz, segments of 300: 151 bins, peak at index 102, labelled 340.0 Hz
  400 Hz, segments of 300: 151 bins, peak at index 149, labelled 496.7 Hz
  200 Hz, segments of 256: 129 bins, peak at index 51, labelled 199.2 Hz
  400 Hz, segments of 256: 129 bins, peak at index 102, labelled 398.4 Hz
  segments of 300: largest value of the 400 Hz sine / the 200 Hz peak: 1e-11 to 1e-10
```

A 200 Hz sine lands in bin 102, at 199.2 Hz, and IX labels it 340 Hz. A 400 Hz sine lands in bin 204.8, beyond what is returned. What remains is the tail of the window's leakage, 10⁻¹¹ to 10⁻¹⁰ of a real peak, and its largest value sits at the top edge, labelled 496.7 Hz. With segments of 256, both sines are where they should be, within one bin. `spectrogram` keeps the same window_size/2 + 1 bins of the padded transform ([`spectral.rs` 33-54](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L33-L54)). That comes from reading the code; this lesson doesn't measure it.

## 3. FIR filters: the windowed sinc

A finite impulse response (FIR) filter replaces each sample with a weighted sum of the last M + 1 inputs: y[n] = Σₘ h[m]·x[n − m]. The ideal low-pass with cutoff fc has the impulse response 2fc·sinc(2fc·m), which is infinite. `FirFilter::lowpass(cutoff, order)` centres it on order/2, truncates it to order + 1 taps and multiplies it by a Hamming window ([`filter.rs` 17-37](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L17-L37)). The taps are symmetric, so the filter delays every frequency by the same order/2 samples. `highpass` subtracts the low-pass from a unit impulse at order/2, keeping what the low-pass removes ([`filter.rs` 40-50](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L40-L50)). P8:

```text
== FIR filters
  highpass(0.25, 31) at f 0.05: gain 0.1569
  highpass(0.25, 32) at f 0.05: gain 0.00046
  lowpass(0.1, 64): gain on [0, 0.05] 0.9995 to 1.0003, largest on [0.15, 0.5] 0.00184
  lowpass(0.1, 64): centre tap 0.200000000, sum of the taps 1.000041082
  lowpass(0.1, 64) on a sine at 0.02: largest |y[n] - x[n - 32]| after 64 samples 0.0002
```

Frequencies are in cycles per sample, so 0.5 is Nyquist. With an even order, the windowed sinc does what the textbook says. `lowpass(0.1, 64)` stays within 5 × 10⁻⁴ of 1 in its pass band and at most 0.00184 (−54.7 dB) from 0.15 on, and a sine comes out 32 samples late. [`scipy.signal.firwin`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.firwin.html)`(65, 0.2, window="hamming", scale=False)` gives the same centre tap and the same sum of taps. That sum, 1.000041, is the gain at DC. IX doesn't normalize it; `firwin` does by default.

The doc comment of `lowpass` says that the order "must be even". Nothing checks it, and `highpass` doesn't repeat it. With order 31 there are 32 taps, and the low-pass is centred at 15.5, between two of them. The impulse goes at index 31/2 = 15, half a sample early, and the subtraction no longer cancels the low band: the gain there is |1 − e^(−iπf)| = 2 sin(πf/2), 0.157 at f = 0.05. IX measures 0.1569, where the even order passes 0.00046. The deeper reason is that a symmetric filter with an even number of taps always has a zero at Nyquist, so it cannot be a high-pass at all. `firwin` refuses to design one: the cross-check prints its `ValueError`.

## 4. IIR filters: the Butterworth

An infinite impulse response (IIR) filter also feeds back its past outputs: y[n] = Σ b_k·x[n − k] − Σ a_k·y[n − k]. `butterworth_lowpass_2nd` designs a second-order Butterworth, whose gain is as flat as possible in the pass band, by the bilinear transform. The analogue cutoff is pre-warped with tan(π·fc), so that the digital filter's −3 dB point falls exactly at fc ([`filter.rs` 145-158](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L145-L158)). P4:

```text
== Second-order Butterworth, fc 0.1
  b [0.067455274, 0.134910548, 0.067455274]
  a [1.000000000, -1.142980503, 0.412801598]
  gain at DC 1.000000000000, at fc 0.707106781187, at Nyquist 0
  a sine at fc through IirFilter::apply: amplitude 0.7071
```

[`scipy.signal.butter`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.butter.html)`(2, 0.2)` returns the same coefficients to the nine decimals the cross-check prints, and within 1.7 × 10⁻¹⁶ when compared once at full precision on Windows (SciPy measures the cutoff against Nyquist, hence 0.2). The gain is 1 at DC and 1/√2 at fc to twelve decimals. At Nyquist, z = −1 and the gain is b₀ − b₁ + b₂, exactly 0: IX computes b₁ as 2·wc²/k and b₀ as wc²/k, and multiplying by 2 doesn't round. The `first_order_lowpass` of the same file is the exponential moving average y[n] = α·x[n] + (1 − α)·y[n − 1]. Section 6 meets it again.

## 5. Haar wavelets

The Fourier transform says which frequencies a signal contains, not when. A wavelet transform answers both, at several scales. Haar's is the simplest. Each pair (a, b) becomes an average (a + b)/√2 and a detail (a − b)/√2, and the averages are split again, level after level. The transform is orthonormal, so white noise of variance σ² stays white with variance σ² in every coefficient. A clean signal made of flat blocks has zero details wherever a pair doesn't straddle a jump. [Donoho and Johnstone (1994)](https://doi.org/10.1093/biomet/81.3.425) denoise by shrinking every detail toward 0 by a threshold t (soft thresholding), with the universal threshold t = σ√(2 ln N). `wavelet_denoise` does exactly that ([`wavelet.rs` 62-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L62-L82)). P6 and P7:

```text
== Haar wavelets
  12 samples, 3 levels: approximation 1, details [6, 3, 1], haar_idwt returns 8, wavelet_denoise returns 8
  16 samples, 4 levels: round trip within 1e-12: true
  blocks of 64, sigma 0.5, 5 levels, universal threshold, 20 draws (15 jumps)
    jumps on multiples of 64: MSE / sigma^2 0.0360
    shifted by 16:            MSE / sigma^2 0.1953 (5.4 times)
```

With the jumps on multiples of 64, the five levels see blocks of 2 to 32 samples that never straddle a jump. Every clean detail is 0, and thresholding removes almost all the noise in them. What is left is the noise in the 32 approximation coefficients, about 1/32 = 0.031 of σ², and IX measures 0.036. Shift the same signal by 16 samples and each jump falls in the middle of a 32-sample block. There are 16 of them now, counting the wrap-around. Each level-5 detail at a jump is 16h/√32 = 2.83h for a jump of height h, so it passes the threshold of 1.86, and it loses 1.86 on the way. The error grows 5.4 times. Haar is not shift-invariant: the same denoiser does much better on a signal whose jumps fall on its grid.

[`CONTRACTS.md` 14 and 33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L14-L33) say that `wavelet::dwt_haar` "requires input length to be a power of two" and panics otherwise. The crate has no `dwt_haar`. Its `haar_dwt` calls `haar_forward`, which takes len/2 pairs and silently drops an odd last sample ([`wavelet.rs` 6-18](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L6-L18)). Twelve samples at three levels go 12, 6, 3, then 1 pair out of 3, and come back as 8 samples, without a panic. The module's header also promises a Daubechies-4 transform ([`wavelet.rs` 3](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L3)) that the file doesn't contain.

## 6. The Kalman filter, and why it becomes a moving average

[Kalman (1960)](https://doi.org/10.1115/1.3662552)'s filter estimates a hidden state from noisy measurements. The state evolves as xₖ = F·xₖ₋₁ + wₖ, with noise of covariance Q, and is measured as zₖ = H·xₖ + vₖ, with noise of covariance R. Each step predicts (x̂ ← F·x̂, P ← F·P·Fᵀ + Q) and then corrects with the gain K = P·Hᵀ(H·P·Hᵀ + R)⁻¹: x̂ ← x̂ + K(z − H·x̂), P ← (I − K·H)·P. IX's `KalmanFilter` does exactly these steps ([`kalman.rs` 49-85](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/kalman.rs#L49-L85)).

Take the simplest case: a random walk (F = H = 1) with step variance q = 0.01, measured with noise of variance r = 1. The variance converges to the fixed point of the Riccati equation. The prediction's variance P⁻ satisfies P⁻² − q·P⁻ − q·r = 0, so P⁻ = (q + √(q² + 4qr))/2, the gain is K∞ = P⁻/(P⁻ + r) = 0.0951249, and the variance after an update is K∞·r. Once K is constant, the update x̂ₖ = x̂ₖ₋₁ + K(zₖ − x̂ₖ₋₁) = K·zₖ + (1 − K)·x̂ₖ₋₁ *is* an exponential moving average with α = K∞. IX has one, [`timeseries::ewma`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/timeseries.rs#L546-L558). P5:

```text
== Kalman filter of a random walk, q 0.01, r 1
  steady-state gain from the Riccati equation:   0.095124922
  IX's variance after 200 steps:                 0.095124922
  largest |state - ewma(K)|, steps 300 to 1000:  1e-13 to 1e-12
  mean squared error / (K r), 200 runs:          1.004
  KalmanFilter::new(2, 1) as built, 100 measurements of 5: largest |state| 0, first variance 2.000000
```

IX's variance reaches the Riccati value, and SciPy's [`solve_discrete_are`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.linalg.solve_discrete_are.html) gives the same 0.095124922 in the cross-check. From step 300 on, the filtered state and the moving average differ by less than 10⁻¹². The filter also says how wrong it is: over 200 random walks, its squared error averages 1.004 times the variance it reports. The noise here is not Gaussian, being a sum of 12 uniforms, and that doesn't matter: the filter is the best linear estimator for any noise with these variances. The last line is the control that [`CONTRACTS.md` 12](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L12) warns about: `KalmanFilter::new` leaves H at 0, so the gain is 0, the state never moves, and the variance grows by 0.01 per step.

## 7. Edge cases against the contract

P9 gathers four small checks:

```text
== Edge cases
  hanning        of length 1: NaN
  hamming        of length 1: NaN
  blackman       of length 1: NaN
  bartlett       of length 1: NaN
  gaussian(0.4)  of length 1: NaN
  kaiser(5)      of length 1: 0.0367
  fft(&[]): 1 value(s), [(0.0, 0.0)]
  normalized_cross_correlation([1.0, 2.0, 3.0, 4.0], [4.0, 3.0, 2.0, 1.0]): [0.0333, 0.1333, 0.3333, 0.6667, 0.8333, 0.8000, 0.5333]
  Pearson at lag 0: -1.0000
  autocorrelation([1.0, 2.0, 3.0, 4.0]): [0.1333, 0.3667, 0.6667, 1.0000, 0.6667, 0.3667, 0.1333]
```

- **Windows of length 1.** Every window divides by n − 1 ([`window.rs` 11-64](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/window.rs#L11-L64)), so at n = 1 it computes 0/0. `kaiser` passes the NaN through [`f64::max`](https://doc.rust-lang.org/std/primitive.f64.html#method.max), which "returns the maximum of the two numbers, ignoring NaN", and returns 1/I₀(5) = 0.0367. numpy's [`hanning`](https://numpy.org/doc/stable/reference/generated/numpy.hanning.html) and its siblings return 1 for a length of 1, as the cross-check prints.
- **An empty FFT.** [`CONTRACTS.md` 31](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L31) says that an empty input "panics inside `next_power_of_two()`", and then describes why it doesn't. `0usize.next_power_of_two()` is 1, and `fft(&[])` returns one zero.
- **"Pearson" correlation.** `normalized_cross_correlation` is documented as "Pearson correlation at each lag" ([`correlation.rs` 24-35](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs#L24-L35)). It divides the raw correlation by the product of the two norms, without removing the means. A rising ramp against a falling one has Pearson −1 at lag 0; IX gives 0.6667 there, and no lag goes below 0.
- **`auto_correlation`.** [`CONTRACTS.md` 17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L17) describes a `correlation::auto_correlation` that "returns unnormalized correlation". The crate has `autocorrelation`, which divides by its lag-0 value ([`correlation.rs` 6-17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs#L6-L17)), so the centre is exactly 1.

## 8. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | IX's Welch density integrates to 0.45–0.55 of the variance; SciPy's is twice it on bins 1–255, equal on 0 and 256 | 0.503; twice within 10⁻⁹, equal | Confirmed |
| P2 | Segments of 300: a 200 Hz sine peaks at index 102, labelled 340 Hz; a 400 Hz sine stays below 10⁻⁶ of that peak; 256 is right within a bin | 102, 340.0 Hz; 10⁻¹¹ to 10⁻¹⁰; 199.2 and 398.4 Hz | Confirmed |
| P3 | IX's FFT error at 2¹⁶ in [10⁻¹⁴, 10⁻¹¹] and at least 16 times its error at 2⁸; the reference within 10⁻¹⁴ of the DFT | 5.4 × 10⁻¹³ on Windows, 300 times; 3.9 × 10⁻¹⁶ | Confirmed |
| P4 | Butterworth at fc = 0.1: gain 1 at DC, 1/√2 at fc, exactly 0 at Nyquist; a sine at fc comes out at 1/√2 | As predicted; 0.7071 | Confirmed |
| P5 | Random walk: variance K∞·r = 0.0951249 after 200 steps; equal to the EWMA within 10⁻⁹ from step 300; error / variance in [0.95, 1.05] | 0.095124922; below 10⁻¹²; 1.004 | Confirmed |
| P6 | Haar on 12 samples, 3 levels: 1 + [6, 3, 1], back as 8, no panic; 16 samples come back | As predicted | Confirmed |
| P7 | Haar denoising: aligned error / σ² in [0.02, 0.05]; shifted by 16, at least 3 times more | 0.0360; 5.4 times | Confirmed |
| P8 | `highpass(0.25, 31)` passes 0.12–0.2 at f = 0.05, `highpass(0.25, 32)` below 0.0032; the order-64 low-pass keeps its bands and delays by 32 | 0.1569; 0.00046; as predicted | Confirmed |
| P9 | Windows of length 1 are NaN, `kaiser(1, 5)` 0.0367; `fft(&[])` returns one zero; the "Pearson" correlation gives 0.667 where Pearson is −1; `autocorrelation` is 1 at lag 0 | As predicted | Confirmed |

All nine held on the first run, and no interval was changed afterwards. The first build failed to compile, on a borrow in `direct_dft`, before any test ran. P1, P2, P6, P8 and P9 came from reading IX's code and contracts, to catch a gap between what they say and what the code does, and each found one. P3 did too, and it also came from arithmetic about rounding near 1. P4, P5 and P7 came from the theory, and IX matched it. Controls show that each check can fail. Doubling IX's interior bins does give the variance. Power-of-two segments do find the frequencies. The reference FFT does agree with the DFT. A power-of-two Haar round trip does come back. An even-order FIR does keep its bands. And the default Kalman filter does stay at 0.

## What to use for our repositories

- **IX's `fft`:** fine for spectra and features. Its relative error grows with N, 5 × 10⁻¹³ at 2¹⁶ on Windows. For long transforms, or when the last digits matter, compare with a table-based FFT such as [`rustfft`](https://docs.rs/rustfft) (not measured here).
- **IX's `welch_psd`:** use power-of-two segments only. Double bins 1 to N/2 − 1 before comparing with SciPy, or with a variance.
- **IX's `FirFilter`:** even orders only, and check the order yourself for `highpass`. Divide the taps by their sum if the DC gain must be exactly 1.
- **IX's `butterworth_lowpass_2nd` and `KalmanFilter`:** they match SciPy and the theory. Always set the Kalman filter's `observation`. For a random walk, the steady-state gain gives the equivalent `ewma` directly.
- **IX's Haar functions:** power-of-two lengths only, checked before calling. There is no Daubechies transform, whatever the header says.
- **IX's `normalized_cross_correlation`:** subtract the means first. Even then, each lag is divided by the full norms, not by the overlapping part.

## Exercises

1. Show that for a real signal |X_{N−k}| = |X_k|, and deduce which bins a one-sided density must double so that it integrates to the variance.
2. With an odd order M, IX's `highpass` is δ[n − (M − 1)/2] − h[n], where h is centred at M/2. Show that in the pass band of h, where h ≈ δ[n − M/2], the gain is 2 sin(πf/2).
3. Derive the steady-state gain of the random walk: write P⁺ as a function of P⁻ = P⁺ + q, solve for P⁻, and compute K∞ for q = 0.01 and r = 1.
4. Blocks of 64 samples, Haar at 5 levels. Why is every clean detail coefficient 0 when the jumps fall on multiples of 64? What is the level-5 detail of a jump of height h in the middle of a 32-sample block, and what does soft thresholding at t leave of it?

<details>
<summary>Solutions</summary>

1. X_{N−k} = Σⱼ xⱼ e^(−2πij(N−k)/N) = Σⱼ xⱼ e^(2πijk/N), since e^(−2πij) = 1. For real xⱼ, this is the complex conjugate of X_k, so their moduli are equal. Parseval says Σⱼ xⱼ² = (1/N) Σₖ |X_k|². Bins 1 to N/2 − 1 each have a twin among N/2 + 1 to N − 1, and bins 0 and N/2 are alone. Keeping 0 to N/2 and doubling 1 to N/2 − 1 therefore keeps the whole sum.
2. In the pass band, H_h(f) ≈ e^(−2πif·M/2) and the impulse contributes e^(−2πif(M−1)/2). The high-pass has H(f) = e^(−2πif(M−1)/2)·(1 − e^(−iπf)). Its modulus is |1 − e^(−iπf)| = √((1 − cos πf)² + sin² πf) = √(2 − 2cos πf) = 2 sin(πf/2). At f = 0.05 that is 0.157, and IX measures 0.1569. With an even order, the impulse falls exactly on h's centre and the two cancel.
3. The update gives P⁺ = P⁻·r/(P⁻ + r), and the prediction P⁻ = P⁺ + q. At the fixed point, P⁻ − q = P⁻·r/(P⁻ + r), so (P⁻ − q)(P⁻ + r) = P⁻·r, which is P⁻² − q·P⁻ − q·r = 0. The positive root is P⁻ = (q + √(q² + 4qr))/2 = (0.01 + √0.0401)/2 = 0.1051249, and K∞ = P⁻/(P⁻ + r) = 0.0951249.
4. At level ℓ, a detail compares the two halves of a block of 2^ℓ samples, 2 to 32 here. When every jump falls on a multiple of 64, no block of 32 or fewer straddles a jump, so both halves are equal and the detail is 0. A jump from a to b = a + h in the middle of a 32-sample block gives (16a − 16b)/√32 = −16h/√32, whose size is 2.83h. Soft thresholding keeps its sign and removes t = 1.86 from its size, so an error of 1.86 in that coefficient remains, whatever h is, as long as 2.83h > 1.86.

</details>

## Sources

- IX at pinned commit `490c395`: [`fft.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/fft.rs), [`spectral.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs), [`filter.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs), [`wavelet.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs), [`kalman.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/kalman.rs), [`window.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/window.rs), [`correlation.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs), [`timeseries.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/timeseries.rs) and [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md).
- J. W. Cooley and J. W. Tukey, ["An algorithm for the machine calculation of complex Fourier series"](https://doi.org/10.1090/S0025-5718-1965-0178586-1), Mathematics of Computation 19, 1965.
- J. C. Schatzman, ["Accuracy of the discrete Fourier transform and the fast Fourier transform"](https://doi.org/10.1137/S1064827593247023), SIAM Journal on Scientific Computing 17, 1996.
- P. D. Welch, ["The use of fast Fourier transform for the estimation of power spectra: a method based on time averaging over short, modified periodograms"](https://doi.org/10.1109/TAU.1967.1161901), IEEE Transactions on Audio and Electroacoustics 15, 1967.
- F. J. Harris, ["On the use of windows for harmonic analysis with the discrete Fourier transform"](https://doi.org/10.1109/PROC.1978.10837), Proceedings of the IEEE 66, 1978.
- R. E. Kalman, ["A new approach to linear filtering and prediction problems"](https://doi.org/10.1115/1.3662552), Journal of Basic Engineering 82, 1960.
- D. L. Donoho and I. M. Johnstone, ["Ideal spatial adaptation by wavelet shrinkage"](https://doi.org/10.1093/biomet/81.3.425), Biometrika 81, 1994.
- SciPy: [`signal.welch`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html), [`signal.butter`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.butter.html), [`signal.firwin`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.firwin.html), [`linalg.solve_discrete_are`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.linalg.solve_discrete_are.html). numpy: [`fft`](https://numpy.org/doc/stable/reference/routines.fft.html), [`hanning`](https://numpy.org/doc/stable/reference/generated/numpy.hanning.html). Rust: [`f64::max`](https://doc.rust-lang.org/std/primitive.f64.html#method.max).
