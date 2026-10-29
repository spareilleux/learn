---
module_id: gas-008-separate-beating-from-a-change-in-damping
department: guitar-acoustics
course: "Separate Beating from a Change in Damping"
level: intermediate
prerequisites: ["gas-004-run-open-e-decay-candidate", "gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separate Beating from a Change in Damping

> **Draft scope.** Authored calculations and pinned source reading. Human technical, musician, fluent-language and learner reviews and deployed course HTML verification remain pending. No new recording, engine render or [ComfyUI](https://docs.comfy.org/) workflow was captured.

## The project question

The guitar decay candidate in [GAS-004](gas-004-run-open-e-decay-candidate.md) missed its retained improvement gate. A rising segment of a waveform envelope could tempt an agent to diagnose negative damping. This lesson constructs a counterexample; it does not diagnose that old render. [GAS-007](gas-007-distinguish-body-poles-from-string-partials.md) distinguishes string partials from body sections. Here interference is separated from component damping.

## 1. Two decreasing components can make a beating sum

The [fixed calculation](../../../../code/streeling/evidence/audio-comparison-2026-10-23/beating-envelope.json) defines time in seconds:

```text
x(t) = .25*exp(-t)*(cos(2*pi*100*t) + cos(2*pi*102*t))
     = .5*exp(-t)*cos(2*pi*101*t)*cos(2*pi*t)
E(t) = .5*exp(-t)*abs(cos(2*pi*t))
```

The cosine product identity gives an algebraic modulation envelope E. It is not a measured envelope or a Hilbert-transform estimate. Each component amplitude is .25 times exp(-t), with damping rate 1 per second. The [beat relation](https://openstax.org/books/university-physics-volume-1/pages/17-6-beats) gives a beat frequency of 2 Hz: the absolute modulation repeats every .5 seconds. The carrier average is 101 Hz. No listening threshold or real guitar body is modeled.

### Exercise 1 — Name the quantities

Derive the product and explain why the beat frequency is 2 Hz although the signed modulation cosine has frequency 1 Hz.

> **Answer.** The average and half-difference frequencies are 101 and 1 Hz. The undamped absolute modulation factor repeats twice per second; E also contains the decreasing exponential and is not periodic. Both component damping rates remain 1 per second; neither the carrier nor beat frequency is a damping coefficient.

## 2. A short slope can have the wrong sign

Between t = .2 and t = .4, the computed envelope ratio is about 2.143464939. A naive endpoint fit gives:

```text
alpha_apparent = -ln(E(.4)/E(.2))/.2
               = -3.812118251 per second
```

The modulation is recovering from destructive interference. This does not supply energy to either component or change its positive damping.

### Exercise 2 — Reject a false diagnosis

Does the negative apparent rate establish an unstable resonator? State which assumption of a single-exponential endpoint fit fails.

> **Answer.** No. The total modulation envelope is not one exponential on this interval: its cosine factor changes as well. The ratio and fitted negative rate are correct for the chosen endpoints, but attributing them solely to component damping is unsupported. The authored components still have positive damping rate 1 per second.

## 3. Compare the same beat phase

At t = 0 and t = .5 the absolute cosine factor is the same. The amplitude ratio is exp(-.5), about .606530660; the squared-envelope ratio is exp(-1), about .367879441. The inferred amplitude damping rate is 1 per second.

These two times are not asserted to be local envelope maxima. Multiplication by a decreasing exponential shifts the maxima of the combined envelope away from the undamped modulation extrema.

### Exercise 3 — Keep amplitude and squared amplitude separate

Recover the damping rate from the same-phase amplitude ratio over .5 seconds. What changes if the squared-envelope ratio is used instead?

> **Answer.** Minus the logarithm of exp(-.5), divided by .5, is 1 per second. Applying that same amplitude formula to exp(-1) gives 2 per second. Squaring doubles the logarithmic decay rate; it does not double the component amplitude damping. An energy interpretation would require an appropriate physical model, not just squaring an envelope.

## 4. Zeros are not logarithmic observations

At t = .25 and .75, E is analytically zero. The record distinguishes exact modulation zeros from floating evaluation residue. The logarithm is undefined there. A numerical floor would introduce an analysis choice, not reveal infinite measured damping. Raw waveform zeros also occur when the carrier cosine vanishes; they do not all identify envelope zeros.

### Exercise 4 — Decide what to retain

An agent replaces all zeros with a small constant and reports a finite decay slope. What must its report disclose?

> **Answer.** It must retain the zero status, floor value, affected samples and fitting rule. The resulting slope depends on that rule and is not an observed component damping rate. Carrier zero crossings and modulation zeros must remain distinct. Reject an endpoint logarithm at an exact envelope zero rather than silently treating roundoff as signal.

## 5. Return to the engine with a falsifiable comparison

The pinned [GA engine](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) sums voices, processes shared body sections and reverb, then limits output. Its body frequencies and nonlinear output stage are not this authored pair of tones. The [source observations](../../../../code/streeling/evidence/audio-comparison-2026-10-23/source-observations.json) separate this source reading from the older retained native/Wasm run. The old failed decay gate remains failed.

### Exercise 5 — Prepare an actual next experiment

Using the source, propose evidence that could distinguish interference from a change in damping. What would make the conclusion fail?

> **Answer.** Retain the source revision, sample rate, excitation, selected signal boundary, windows, phase, filters, clipping status and uncertainty. Compare isolated components or a validated multi-component fit against the combined signal before attributing an envelope slope to damping. A changing mixture, clipped output, unresolved components or a poor model fit defeats that attribution. First compare direct analysis with the existing decay procedure; a new DSL or agent does not itself improve the evidence. No such experiment was executed here.

## Learner handoff

Complete the [source-assisted task](../../../../code/streeling/evidence/audio-comparison-2026-10-23/learner-task.md) and keep calculations, source locations and assistance. The [prepared rubric](../../../../code/streeling/evidence/audio-comparison-2026-10-23/reviewer-rubric.json) is not an actual learner result. Continue with [AUD-009](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md) to separate comparison transformations from original signal identity.
