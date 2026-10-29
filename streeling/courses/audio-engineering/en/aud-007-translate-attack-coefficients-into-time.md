---
module_id: aud-007-translate-attack-coefficients-into-time
department: audio-engineering
course: "Translate Attack Coefficients into Time"
level: intermediate
prerequisites: ["aud-005-pcm-guards-and-format-boundaries", "gas-002-brightness-control-and-evaluation-gate"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Translate Attack Coefficients into Time

> **Draft scope.** Pinned public source and isolated real-arithmetic envelope calculations. Human technical, fluent-language, musician and learner reviews and deployed course HTML verification remain pending. No new native/WASM render, browser capture or [ComfyUI](https://docs.comfy.org/) processing was performed.

## The project question

A coefficient is copied from one audio setup to another. Does the attack last the same number of milliseconds? The answer depends on what the source multiplies and which clock advances it. We inspect GA commit `76efbffd5af82b46c3146957a6bd4504008eeb89`; older fixture profiles are not silently substituted for this revision.

## 1. Trace the effective coefficient

The [constructor and profile selection](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L184-L260) first initialize attack decay to 0.988, then call profile 0, which writes 0.986. The [per-voice render path](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L426-L478) computes `r=clamp(base_attack_decay-0.004*f_norm,0.97,0.993)`. The frequency normalization rises from 0 at 82 Hz to 1 at 330 Hz.

For the authored 82 Hz anchor, velocity 1 and profile 0, initial attack level is 0.06 and r is 0.986. The anchor is exactly 82 Hz; it is not the more precise E2 value 82.4069 Hz used in earlier audio fixtures. The [fixed envelope table](../../../../code/streeling/evidence/pluck-coordinates-2026-10-22/attack-clock.json) retains both frequencies separately.

### Practice exercise 1: select the actual starting value

An agent reads the constructor's 0.988 and calls it profile 0's effective 82 Hz attack multiplier. What overwrites it? Give the correct base and effective values for this anchor. What is r at 330 Hz?

> **Answer:** Profile selection overwrites the constructor field with 0.986. At the 82 Hz anchor, frequency normalization is 0, so base and effective multiplier are both 0.986. At 330 Hz, normalization is 1 and the effective multiplier is 0.982 after subtracting 0.004. Neither result is an observed audio decay.

## 2. Convert updates into seconds

While the voice is active and the attack level exceeds its threshold, the source multiplies it once per output sample. In the isolated real-arithmetic model, `A[n]=A0*r^n`, where n counts completed multiplications and `A[0]` is the initial state. For positive r below 1, the exact continuous-extension time constant is `tau=-1/(Fs*ln(r))` seconds. This follows the [one-pole time-constant derivation](https://www.dsprelated.com/freebooks/filters/Time_Constant_One_Pole.html).

For r 0.986, tau is approximately 1.6083309868956657 ms at 44100 samples per second and 1.4776540942103929 ms at 48000. One time constant means an amplitude factor of `1/e`; it is not the time to silence, a 60 dB decay time, or the duration of the whole guitar sound. The noise signal, string feedback, body and reverb have other states.

### Practice exercise 2: compare clocks

Keep r at 0.986 and change the sample rate from 44100 to 48000. Which time constant is shorter, and why? Does this calculation predict the entire rendered note's duration?

> **Answer:** The 48000 case is shorter: approximately 1.4776540942103929 ms versus 1.6083309868956657 ms. More multiplications occur per second with the same per-sample multiplier. The calculation describes the isolated attack state only, so it does not predict the complete note, body response or reverb duration.

## 3. Respect the source's stopping threshold

The [attack branch](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L467-L478) runs only while the current state exceeds `1e-3`. For A0 0.06 and r 0.986, the first integer n with `A0*r^n<=1e-3` is 291. After 290 updates it is approximately 0.0010056725203252386; after 291 it is approximately 0.0009915931050406854. Contributions in this isolated trace use pre-update states indexed 0 through 290, then the branch stops.

Those 291 sample updates occupy approximately 6.598639455782313 ms at 44100 and 6.0625 ms at 48000. The source retains the state after crossing; it does not continue multiplying it toward zero in this branch. Its voice-deactivation condition also requires attack level below `5e-5`, which this retained value does not satisfy. This is a source-derived lifecycle concern for the selected path, retained in the [observation record](../../../../code/streeling/evidence/pluck-coordinates-2026-10-22/source-observations.json). No runtime reproduction, CPU effect or production fix is claimed.

### Practice exercise 3: count the final update

How many attack contributions precede the threshold stop in the isolated trace? Is the retained state zero? Can its retained value satisfy the attack-level part of the inspected voice-deactivation check?

> **Answer:** There are 291 contributions using indices 0 through 290, each followed by an update. The retained state is approximately 0.0009915931050406854, not zero. It is above `5e-5`, so it does not satisfy that part of the deactivation condition. This source/model reasoning is not a reproduced runtime failure or proof about every lifecycle path.

## 4. Translate a target duration deliberately

To preserve this isolated time constant, set `r_new=r_old^(Fs_old/Fs_new)`. Translating effective r 0.986 from 44100 to 48000 gives approximately 0.9871301472688642. That changes the multiplier deliberately to preserve milliseconds. It does not preserve the same integer threshold count automatically, because the final crossing is rounded to sample updates.

The translation concerns the effective coefficient. At other frequencies, the source subtracts its frequency-dependent term and clamps again; copying this number into a base setter is not automatically a general compensation. Profile selection can overwrite a setter too. A whole-engine change would need a defined policy, tests at several frequencies and velocities, and checks on all other sample-dependent state.

### Practice exercise 4: translate the coefficient

Which effective multiplier preserves the 44100-rate r 0.986 time constant at 48000? Does that calculation alone establish a complete sample-rate-invariant engine or a production patch?

> **Answer:** Approximately 0.9871301472688642. It preserves the isolated continuous-extension time constant under the stated formula. Threshold quantization, frequency adjustment, profile order and other DSP states still need their own policy and tests; no whole-engine invariance or production patch was established.

## 5. Follow the host clock into the test

The [Web Audio bridge](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/src/audio/audioEngine.js#L14-L35) passes `audioContext.sampleRate` into its initialization message. The [worklet](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/src/audio/guitar-worklet.js#L11-L30) forwards the numeric supplied rate to engine initialization, with a host-rate fallback. The [Web Audio specification](https://www.w3.org/TR/webaudio/#dom-baseaudiocontext-samplerate) defines the context's sample-rate property. These source reads do not observe the current rate or capture of a live browser.

A future trial should record the actual context rate, initialized status, selected profile, setter order, note settings, raw sample format and output identity. Compare attack-state traces separately from the whole waveform; the stochastic signal is not a positive exponential envelope. If an offline ComfyUI candidate is resampled, preserve that conversion and compare the intended physical time windows. Its existence does not change the engine's coefficient semantics.

### Practice exercise 5: write the next check

A report says “same decay setting, same attack time” but omits the sample rate and profile order. Name the missing evidence and a useful negative control. Has a two-rate browser comparison been performed here?

> **Answer:** Record actual host sample rate, successful initialization, profile and setter order, effective frequency-dependent coefficient, note/velocity, sample format and output identity. A fixed-r two-rate envelope calculation is a negative control because it must change milliseconds; a duration-preserving translation should keep the stated isolated time constant. No two-rate browser capture or perceptual comparison was performed here.
