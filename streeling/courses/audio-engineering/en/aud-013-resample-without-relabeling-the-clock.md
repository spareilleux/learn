---
module_id: aud-013-resample-without-relabeling-the-clock
department: audio-engineering
course: "Resample Without Relabeling the Clock"
level: intermediate
prerequisites: ["aud-011-count-valid-frames-separately-from-block-padding"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Resample Without Relabeling the Clock

> Authored example and source reading. No new guitar performance, audio or parser execution, participant response or production adoption is claimed. Human technical, fluent-language and learner decisions remain pending.

A guitar reference and an offline Wasm render can use different sample rates. A comparison becomes misleading if an agent changes the rate label while keeping every sample unchanged. The waveform then occupies a different clock, even though its byte hash may remain identical. This lesson derives a duration-preserving conversion contract before choosing an implementation. Unlike the prerequisite's final-block accounting, the question is how sample coordinates refer to physical time when the rate itself changes.

## Read the retained evidence

In the retained runner, read the fixed rate and the WAV header writer together. The declared rate governs both rendering and interpretation. The Web Audio specification defines buffer duration from frame count divided by sample rate and describes resampling decoded data to the context rate. Those statements define quantities, rather than certifying a particular interpolation filter. Our case below is authored; no converter was executed.

[Prerequisite](../../audio-engineering/en/aud-011-count-valid-frames-separately-from-block-padding.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Primary reading](https://www.w3.org/TR/2026/WD-webaudio-1.1-20260922/)

### Exercise 1

Start with `44100` frames at `44100 Hz`, containing a stipulated `1000 Hz` tone. Duration is `N_in/F_in`. A frame count alone cannot tell a reviewer whether an excerpt represents a complete second. Retain the original rate with the samples before any comparison or workflow node changes their representation.

What is the input duration, and which two fields determine it?

<details><summary>Answer 1</summary>

It is `1 s`, determined by `44100` frames and `44100 Hz`. Neither the filename nor a raw-byte hash supplies that clock relationship.

</details>

### Exercise 2

The requested destination rate is `48000 Hz`. Preserving duration requires `N_out=duration*F_out`, giving `48000` output frames. This count specifies the intended time support, not the values between existing samples. An interpolation method and a band-limit policy remain necessary for a real converter, including how it handles the beginning and end of the buffer.

What output count preserves the declared duration?

<details><summary>Answer 2</summary>

Use `48000` frames for `1 s`. The count is a contract to test; it is not evidence that a resampling filter produced correct samples.

</details>

### Exercise 3

For the failure case, retain the original `44100` samples but label them `48000 Hz`. Playback now lasts `0.91875 s`. The stipulated tone scales to `1088.43537414966 Hz` under `f*F_out/F_in`. This is a clock error, not a guitarist playing sharp, and level normalization cannot restore the lost timing.

Give the relabeled duration and frequency, and diagnose the change.

<details><summary>Answer 3</summary>

They are `0.91875 s` and `1088.43537414966 Hz`. Relabeling compresses time and raises frequency; it does not perform duration-preserving resampling.

</details>

### Exercise 4

Use the structured negative control with output rate `44100 Hz`. Now the required output count is `44100`; keeping the original samples produces `1 s` and `1000 Hz`. A test suite containing only equal-rate cases would therefore tolerate the faulty relabeling shortcut. Controls must exercise the specific mismatch the proposed operation claims to handle.

Why does this control pass the shortcut without validating it?

<details><summary>Answer 4</summary>

Equal input and output rates remove the mismatch. The result is `1 s` at `1000 Hz`, so this case cannot distinguish relabeling from a genuine conversion.

</details>

### Exercise 5

For a downsampling proposal, duration agreement alone is insufficient: content above the destination Nyquist boundary needs a declared filtering policy. Keep that requirement separate from the clock arithmetic. A future ComfyUI or audio-tool handoff should name rate, valid frames, interpolation/filter scope and preserved duration, then retain an actual output probe before asserting fidelity.

What would falsify the claimed duration-preserving conversion?

<details><summary>Answer 5</summary>

A retained output whose frame-count/rate duration differs from the input, or whose known test tone shifts as in the relabeling case, falsifies that claim. Alias rejection requires its own spectral observation.

</details>

## Source-assisted learner task

Draft a review of a reference-to-Wasm comparison. Manually derive the main and control timelines, then locate the runner's rate declaration and header field. Propose a handoff record with the original and destination clocks and a duration check. State which observed tone or frame result would reject the proposal. Keep interpolation quality unresolved until an actual converter and its output are inspected.

First retain your answer before revealing the prepared corrections. Use the manual table or calculation as the baseline for any calculator, source lookup or agent assistance, and record that assistance. Keep the original response and the corrected response separately. Match each exercise to a prepared criterion in the fixed packet; those criteria have no learner decisions yet. Record an actual source passage and its revision, then distinguish what it establishes from your proposed next step. Report any missing input as unresolved. A mathematically correct answer supports the stated example; human review, runtime execution and learner acceptance require their own retained observations.
