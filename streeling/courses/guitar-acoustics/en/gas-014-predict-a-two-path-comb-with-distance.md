---
module_id: gas-014-predict-a-two-path-comb-with-distance
department: guitar-acoustics
course: "Predict a Two-Path Comb from Distance"
level: intermediate
prerequisites: ["aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Predict a Two-Path Comb from Distance

> Authored example and source reading. No new guitar performance, audio or parser execution, participant response or production adoption is claimed. Human technical, fluent-language and learner decisions remain pending.

A hollow region in a guitar spectrum can come from combining delayed copies of the same source. It need not indicate that the string failed to generate that frequency. In a room or a synthetic reflection model, path difference changes phase with frequency. This lesson predicts an authored two-path comb before anyone labels a spectral dip as an instrument defect. It also shows why an accurately predicted opposition frequency does not guarantee a complete measured null.

## Read the retained evidence

Read the retained Rust early-reflection taps and their conversion from seconds to sample indices. Those are synthetic model parameters, not measured microphone distances. OpenStax's interference discussion supports adding delayed waves and interpreting phase opposition. We now introduce our own distances and sound speed. The prerequisite's alignment decision remains useful, but automatically aligning these paths would erase the very propagation effect under study.

[Prerequisite](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Primary reading](https://openstax.org/books/university-physics-volume-1/pages/16-5-interference-of-waves)

### Exercise 1

The first path is `1 m`; the second is `1.343 m`; sound speed is stipulated as `343 m/s`. The excess distance is `0.343 m`. Divide excess distance by speed to obtain `tau=(d_b-d_a)/c`, or `0.001 s`. Absolute source onset is unnecessary for this difference, provided both signals share the same underlying excitation and clock.

What relative delay follows from the distances?

<details><summary>Answer 1</summary>

The relative delay is `0.001 s`. It describes excess propagation time, not an absolute microphone or engine latency measurement.

</details>

### Exercise 2

At a frequency whose period is twice the delay, the delayed copy is half a cycle behind. The first positive opposition is `1/(2*tau)=500 Hz`. With equal gains and otherwise identical signals, that pair cancels. This statement depends on the two-path assumptions; a guitar recording with many reflections need not exhibit an isolated exact zero there.

Where is the first predicted cancellation for equal gains?

<details><summary>Answer 2</summary>

It is `500 Hz`, with magnitude `0` in the ideal equal-gain two-path model. That is a prediction, not an observed recording feature.

</details>

### Exercise 3

Phase repeats whenever frequency increases by `1/tau=1000 Hz`. Thus opposition recurs at `1500 Hz` after the first at `500 Hz`. The spacing and first opposition answer different questions. A claimed comb spacing should not be reported as the first notch, and discrete spectral bins may not fall exactly on either predicted frequency.

Give the spacing and the next opposition frequency.

<details><summary>Answer 3</summary>

The spacing is `1000 Hz`; the next opposition is `1500 Hz`. A finite spectral grid requires a declared sampling and window method before comparing a measured minimum.

</details>

### Exercise 4

The negative control keeps both paths but changes the second path gain to `0.5`. At opposition the magnitude is `abs(1-g)=0.5`, rather than `0`. Geometry still predicts `500 Hz`; amplitude mismatch changes the depth. This is why a notch location alone cannot certify microphone matching, path gain or perfect cancellation.

Which prediction survives and which fails in the control?

<details><summary>Answer 4</summary>

Opposition remains at `500 Hz` with spacing `1000 Hz`. Complete cancellation fails: the predicted residual magnitude is `0.5`. Phase opposition and zero amplitude are different claims.

</details>

### Exercise 5

A practical review should retain raw channels or paths before summation, distance assumptions, gain and any alignment. If the task is to hear the room effect, removing relative delay changes the intended experiment. If the task is to compare engines after compensation, compensation must be declared. Neither purpose is established merely by a smoother spectrum after processing.

What would falsify this ideal two-path account?

<details><summary>Answer 5</summary>

A measured transfer inconsistent with its predicted delay, periodicity or gain-dependent residual beyond a stated uncertainty would reject the account for that capture. Unknown extra paths prevent attributing the discrepancy to the guitar alone.

</details>

## Source-assisted learner task

Draw the authored paths and calculate delay, first opposition, spacing and unequal-gain residual manually. Inspect the synthetic tap declaration and explain why its seconds are not a room survey. Propose a capture retaining both paths and a transfer measurement capable of rejecting the model. State whether alignment is part of the intended question before suggesting an audio workflow or a new control.

First retain your answer before revealing the prepared corrections. Use the manual table or calculation as the baseline for any calculator, source lookup or agent assistance, and record that assistance. Keep the original response and the corrected response separately. Match each exercise to a prepared criterion in the fixed packet; those criteria have no learner decisions yet. Record an actual source passage and its revision, then distinguish what it establishes from your proposed next step. Report any missing input as unresolved. A mathematically correct answer supports the stated example; human review, runtime execution and learner acceptance require their own retained observations.
