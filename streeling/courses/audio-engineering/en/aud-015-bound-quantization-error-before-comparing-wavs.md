---
module_id: aud-015-bound-quantization-error-before-comparing-wavs
department: audio-engineering
course: "Bound Quantization Error Before Comparing WAVs"
level: intermediate
prerequisites: ["aud-005-pcm-guards-and-format-boundaries"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Bound Quantization Error Before Comparing WAVs

> Authored example and source reading. No new guitar performance, audio or parser execution, participant response or production adoption is claimed. Human technical, fluent-language and learner decisions remain pending.

The retained guitar runner keeps raw floating samples and also writes an integer WAV. These are different representations of the same proposed render. A byte difference in the raw buffers can disappear after integer conversion; a small decoded difference can also arise from the conversion itself. Before an agent interprets two WAVs as equivalent engines, it must identify the quantizer, its rounding rule and the assumptions behind any error bound.

## Read the retained evidence

Read the actual `pcm16Wav` expression and its decoder in the retained project artifact. The encoder multiplies by `32767` and uses `Math.round`; the decoder divides the stored signed integer by the same scale. This is a source observation at the retained revision. The lesson studies that explicit convention, rather than substituting a familiar textbook scale or claiming support for every WAV format.

[Prerequisite](../../audio-engineering/en/aud-005-pcm-guards-and-format-boundaries.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

### Exercise 1

Define `q=floor(scale*x+0.5)` with `scale=32767`, matching the selected rounding direction for these finite examples. Adjacent decoded levels differ by `1/32767`. Provided rounding stays within representable output and no clamp intervenes, the magnitude of conversion error is at most `1/65534`. This is an amplitude bound in normalized sample units, not a frequency or a duration.

What are the quantization step and half-step bound?

<details><summary>Answer 1</summary>

They are `1/32767` and `1/65534`. The bound applies to the declared un-clipped nearest-level conversion, not to arbitrary invalid inputs.

</details>

### Exercise 2

The authored samples are `[0,0.00001,0.5,-0.5]`. Their encoded integers are `[0,0,16384,-16383]`. The two half-amplitude values expose the tie rule: positive and negative midpoint cases do not produce symmetric integers. A reviewer who silently changes to ties-to-even would be checking another converter even if ordinary samples often agree.

Encode the samples and explain the asymmetric midpoint results.

<details><summary>Answer 2</summary>

The integers are `[0,0,16384,-16383]`. Rounding ties toward positive infinity gives the shown midpoint pair; the selected rule must remain part of the source contract.

</details>

### Exercise 3

Decode by dividing the integers by `32767`. The tiny positive sample becomes exactly `0`, so its signed error is `-0.00001`. The half-amplitude samples have errors `16384/32767-0.5` and `-16383/32767+0.5`. Both remain within the declared half-step magnitude. Vanishing after conversion means the integer representation cannot resolve that difference, not that the original floating samples were identical.

What is lost when the tiny sample becomes zero?

<details><summary>Answer 3</summary>

Its nonzero floating amplitude is lost at this representation boundary. Error is `-0.00001`; integer equality afterward cannot establish raw floating equality beforehand.

</details>

### Exercise 4

The negative control supplies `1.1`, outside the normalized input contract. The rounding expression yields integer `36044`, which a signed integer field of this width cannot represent. The retained guard rejects out-of-range samples before writing; the mathematical nearest-level bound must not be stretched into a promise about overflow or clipping behavior.

Does the half-step bound certify this control's stored output?

<details><summary>Answer 4</summary>

No. Integer `36044` is outside the signed destination range. The input contract is violated, so rejection belongs before conversion; no valid stored sample is claimed.

</details>

### Exercise 5

Dither would deliberately change the sample before quantization and would require its own distribution, level and measurement scope. This course neither adds it nor promises that the bounded errors are inaudible. For a native/Wasm comparison, retain raw samples and encoded bytes separately, and state whether the question concerns numerical equality, integer reproducibility or a listening decision.

What evidence would falsify a claim of bit-exact raw equality inferred from equal WAVs?

<details><summary>Answer 5</summary>

Two retained raw samples that differ while encoding to the same integer are a counterexample. The tiny-sample case supplies that construction; an auditory conclusion still needs an actual listening task.

</details>

## Source-assisted learner task

Write a conversion note for the existing runner. Compute the integer table and signed errors manually using its stated rule, then inspect the encoder and decoder expressions. Include the out-of-range control and explain why it is a rejected input rather than a measured engine defect. Recommend which artifacts to retain when raw equality and WAV equality disagree, without inventing a listening result.

First retain your answer before revealing the prepared corrections. Use the manual table or calculation as the baseline for any calculator, source lookup or agent assistance, and record that assistance. Keep the original response and the corrected response separately. Match each exercise to a prepared criterion in the fixed packet; those criteria have no learner decisions yet. Record an actual source passage and its revision, then distinguish what it establishes from your proposed next step. Report any missing input as unresolved. A mathematically correct answer supports the stated example; human review, runtime execution and learner acceptance require their own retained observations.
