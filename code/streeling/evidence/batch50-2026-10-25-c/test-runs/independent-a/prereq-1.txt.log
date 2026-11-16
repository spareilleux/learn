---
module_id: aud-008-measure-a-filter-with-paired-input-and-output
department: audio-engineering
course: "Measure a Filter with Paired Input and Output"
level: intermediate
prerequisites: ["aud-006-calibrate-spectral-amplitudes", "cs-013-preserve-spectral-axes-and-units", "gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Measure a Filter with Paired Input and Output

> **Draft scope.** Authored periodic-signal calculations and pinned source inspection. Human technical, fluent-language, musician and learner reviews and deployed course HTML verification remain pending. No new recording, engine render or [ComfyUI](https://docs.comfy.org/) workflow was captured.

## The project question

An agent doubles a rendered partial's amplitude and announces a better body filter. Did the filter change, or did its input change? [GAS-007](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md) identifies a concrete input/output boundary before reverb. [AUD-006](aud-006-calibrate-spectral-amplitudes.md) handles amplitude calibration. Here we keep excitation and response together.

## 1. Declare the experiment before dividing spectra

Use a deliberately small authored finite impulse response, unrelated to any claim of measured guitar realism:

```text
h = [3/4, 1/4]
y[n] = (3/4)*x[n] + (1/4)*x[n-1]
H(omega) = 3/4 + (1/4)*exp(-i*omega)
```

For the following experiment x is periodic with period N = 8; x[-1] means x[7]. Observe one complete period in steady state. The [DFT convention](https://www.dsprelated.com/freebooks/mdft/DFT_Definition.html) is the unscaled forward transform with a negative exponential. At bin k = 2, omega = pi/2, so H = 0.75 - 0.25i and its magnitude is about 0.790569415.

This example uses neither a Hann window nor a truncated startup. [CS-013](../../computer-science/en/cs-013-preserve-spectral-axes-and-units.md) explains the axes and framing metadata needed outside this small example.

### Exercise 1 — Identify the measurement conditions

Why does x[-1] = x[7] matter? What assumptions allow Y[k] = H[k]X[k] at the selected bins?

> **Answer.** It supplies the preceding sample from the same periodic steady input. The system is the declared LTI filter and the record contains a full period with matching transform conventions. This is circular filtering of a periodic input, not the first eight samples of zero-initial linear convolution. Finite records with other boundaries need separate treatment.

## 2. A larger output can come entirely from a larger input

The [paired fixture](../../../../code/streeling/evidence/filter-phase-2026-10-22/paired-transfer.json) uses cosines at k = 2 with input amplitudes 0.25 and 0.50:

| Input cosine amplitude | X[2] | Y[2] | Output cosine amplitude, approximately |
| --- | --- | --- | --- |
| 0.25 | 1 | 0.75 - 0.25i | 0.197642354 |
| 0.50 | 2 | 1.50 - 0.50i | 0.395284708 |

Dividing the paired complex coefficients gives the same filter response in both trials. Dividing output magnitudes across trials gives 2, which describes output scaling, not a doubled filter gain. No loudness or preference is measured.

### Exercise 2 — Resolve the apparent improvement

Calculate Y[2]/X[2] in both trials. Does the output-amplitude ratio of 2 establish a change in H?

> **Answer.** Both ratios are 0.75 - 0.25i, with magnitude about 0.790569415. The filter is unchanged. Doubling the excitation doubles the output of this linear filter; the output-only comparison confounds input strength with response.

## 3. An unexcited frequency is not a measured rejection

At k = 1 the cosine fixture has analytically zero input and output coefficients. Tiny floating-point DFT residues can remain in a numerical computation. Their ratio does not establish the response. In fact the same filter's theoretical response at that frequency is nonzero.

The situation is also fragile near zero. Let X = 0.000001 at k = 2 and add an authored output noise coefficient of 0.01. Then the apparent ratio becomes 10000.75 - 0.25i although the true H is still 0.75 - 0.25i. This is a sensitivity example, not a measured noise floor or a universal rejection threshold.

### Exercise 3 — Refuse an unsupported ratio

An agent records X[1] = 0 and Y[1] = 0, then stores a filter gain of 0. What should it store instead? Explain how the weak-excitation example changes its acquisition plan.

> **Answer.** Store the ratio as undefined or unmeasured with an insufficient-excitation reason, not a zero gain. Use adequate excitation and an explicit noise and conditioning policy for frequencies of interest. The 0.01 noise term divided by 0.000001 input contributes 10000 to the false estimate. A threshold must follow the actual measurement conditions.

## 4. Truncation can change the answer even with the correct filter

For a separate control, use amplitude 0.25 and starting phase pi/4, still at k = 2. Now start the filter with a zero preceding input and retain only N = 8 output samples. The full finite linear convolution has 9 samples; the last sample has been discarded. Dividing the truncated eight-point spectra gives 0.71875 - 0.21875i, not 0.75 - 0.25i.

### Exercise 4 — Diagnose the boundary mismatch

Does the truncated ratio prove that the filter implementation changed? Give two valid ways to formulate a new comparison.

> **Answer.** No. The control changed the boundary and discarded a nonzero tail. Either acquire a declared periodic steady-state record, or retain the complete finite convolution and zero-pad input and output to a common transform length sufficient for linear convolution. Keep sample alignment and transform scaling consistent. For long recursive responses, define settling and tail tolerances; an arbitrary short crop is insufficient.

## 5. Preserve the representation required by the question

At pinned IX commit `bd1336b7c4045e427dcdbe80b102790e45da5ce1`, [stft](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L7-L30) returns complex spectra. The following [spectrogram projection](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L32-L54) returns magnitudes or their decibel values. That projection discards each coefficient's phase.

This source distinction does not guarantee that arbitrary windowed, transient STFT frame ratios are exact transfer functions. Window boundaries, unobserved filter memory, nonlinearities and time variation still matter. A statistical transfer estimate for noisy data requires a declared estimator and assumptions beyond the noiseless example here.

### Exercise 5 — Specify the next captured artifact

For a proposed body-filter test in GA or ComfyUI, list what to retain so another agent can distinguish gain, phase and excitation changes. Which source stage should be isolated, and what is still untested?

> **Answer.** Retain paired input/output samples or their matched complex transforms, sample rate, timing and alignment, record and transform lengths, window and scale conventions, excitation, filter parameters, source revision and noise/settling decisions. Isolate the normalized string-sum to pre-reverb dry boundary identified by GAS-007; downstream reverb and clipping need separate trials. Magnitude-only outputs can support a qualified magnitude question but cannot supply the missing complex phase. No capture or adapter was implemented by this course. [INF-008](../../information-theory/en/inf-008-keep-phase-when-waveform-identity-matters.md) gives an exact phase counterexample.

## Source-assisted learner task

Write an acquisition plan that could reject the claim “larger output means larger filter gain.” Include both paired trials, an unexcited-bin refusal, the weak-excitation calculation, a boundary-mismatch control and the representation needed for phase. Record assistance and unresolved conditions. The [reviewer rubric](../../../../code/streeling/evidence/filter-phase-2026-10-22/reviewer-rubric.json) contains prepared criteria, not learner outcomes.

The [source receipt](../../../../code/streeling/evidence/filter-phase-2026-10-22/primary-readback.json) binds the selected files. Authored arithmetic does not establish an actual guitar response, a working audio graph, an engine improvement or a perceptual result.
