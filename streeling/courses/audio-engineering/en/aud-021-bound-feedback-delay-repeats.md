---
module_id: aud-021-bound-feedback-delay-repeats
department: audio-engineering
course: "Bound Feedback-Delay Repeats"
level: advanced
prerequisites: ["aud-007-translate-attack-coefficients-into-time"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Bound Feedback-Delay Repeats

> Authored model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening result, engine render, parser execution or production adoption is claimed.

An audio proposal reuses a decay coefficient inside a feedback delay and calls the result safe because the initial output is small. The coefficient now acts once per return through the delay, not necessarily once per audio sample. Work through an impulse by hand before comparing decay times or claiming stability. The retained guitar runner motivates preserving render state, but does not execute this new isolated recurrence.

Only samples at successive delay multiples carry the authored impulse echoes. Their amplitudes form a geometric sequence. The delay sets their spacing while the gain sets their ratio; changing either changes the response in a different way. A finite output list shows the first returns. The absolute-sum formula addresses the infinite tail under the stated ideal assumptions, which is a stronger claim requiring a strict gain bound.

The growing control can remain within a sample guard briefly if the input is scaled down. That does not convert its infinite response into a summable one. Conversely, a bounded stable system can still produce peaks beyond a chosen export range for some input. Separate mathematical stability, sample clipping and musical decay. An eventual implementation needs state initialization, sample-clock units and finite-number handling; those concerns remain open after the authored algebra. Keep the sign convention attached to the recurrence when consulting the source, which also presents an alternative denominator notation.

## Read the retained project evidence

The prerequisite supplies the earlier operation and its evidence boundary. Inspect the linked project artifact before using the authored case to propose a change. Its existing observations keep their original scope: a retained source file or fixture does not establish current deployment. The fixed packet records exact inputs, prepared outputs and reading provenance. Local file hashes identify complete bytes; they do not enlarge the bounded passage actually read. A primary web page supports only the specific definition read, with no invented immutable revision or byte hash.

[Prerequisite](../../audio-engineering/en/aud-007-translate-attack-coefficients-into-time.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Primary reading](https://www.dsprelated.com/freebooks/pasp/Feedback_Comb_Filters.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "delay_samples": 2,
    "gain": 0.5,
    "count": 7,
    "impulse": [
      1,
      0,
      0,
      0,
      0,
      0,
      0
    ]
  },
  "formula": "y[n]=x[n]+g*y[n-M]; y[n<0]=0; stable=abs(g)<1; absolute_sum_infinite=1/(1-abs(g)) if stable else null",
  "expected": {
    "output": [
      1,
      0,
      0.5,
      0,
      0.25,
      0,
      0.125
    ],
    "stable": true,
    "absolute_sum_infinite": 2
  },
  "negative_control": {
    "values": {
      "delay_samples": 2,
      "gain": 1.1,
      "count": 7,
      "impulse": [
        1,
        0,
        0,
        0,
        0,
        0,
        0
      ]
    },
    "expected": {
      "output": [
        1,
        0,
        1.1,
        0,
        1.21,
        0,
        1.331
      ],
      "stable": false,
      "absolute_sum_infinite": null
    }
  }
}
```

## Assumptions and evidence limits

Assume zero initial state, an integer positive delay and a real constant feedback gain. No limiter modifies the recurrence. The mathematical infinite tail is distinct from finite-number robustness and export-range checks.

## Interpret the operation before choosing an abstraction

Before revealing the answer key, write the input contract in your own words and derive the main result manually. Keep intermediate quantities or state transitions, rather than copying only a final number. Compare the negative control under the same rule and identify the input that changed. The model is a finite authored example. A matching calculation supports this example’s stated claim; it does not supply an observed user outcome or validate a production feature.

### Exercise 1

Trace the first impulse returns and the intervening samples.

<details><summary>Answer 1</summary>

The listed nonzero returns are separated by the declared delay; all intervening samples remain zero with this initial state.

</details>

### Exercise 2

Which input sets repeat spacing, and which sets its amplitude ratio?

<details><summary>Answer 2</summary>

The delay controls spacing. The constant feedback gain controls the ratio of consecutive impulse returns.

</details>

### Exercise 3

Why is the stable case absolutely summable?

<details><summary>Answer 3</summary>

The absolute gain is strictly below unity, so the echo magnitudes have the displayed convergent geometric sum.

</details>

### Exercise 4

Can a short finite render certify the growing control?

<details><summary>Answer 4</summary>

No. Its finite prefix is finite, but successive returns grow and the infinite absolute sum does not converge.

</details>

### Exercise 5

What falsifies a proposed stable recurrence?

<details><summary>Answer 5</summary>

A gain outside the strict bound, or a trace inconsistent with the declared recurrence, rejects the claim under this model.

</details>

## Source-assisted learner task

Prepare the impulse ledger and separate the mathematical tail bound from a future PCM export gate. Recommend no engine change from this authored case alone.

Retain your unaided answer before consulting a source or calculator. Then identify a precise source passage and revision, record every kind of assistance and keep the original answer alongside any correction. A proposed agent workflow or DSL must preserve the manual result and its countercase before its convenience can be assessed. If required inputs are absent, leave the decision unresolved rather than substituting a plausible value.

Write a falsifier as an observable disagreement with the stated rule, then say what additional observation would be needed at the next boundary. Use the exercise answers as prepared checks, not as a record of your attempt. The fixed packet contains a separate prepared criterion for every exercise; all learner decisions remain undecided until an actual response and review are retained. Report assistance, corrections and remaining limits with the final note so that arithmetic correctness is not confused with independent recall, musician judgment or runtime acceptance.
