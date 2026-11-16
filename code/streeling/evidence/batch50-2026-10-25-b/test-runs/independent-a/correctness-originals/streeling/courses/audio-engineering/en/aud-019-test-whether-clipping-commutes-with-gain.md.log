---
module_id: aud-019-test-whether-clipping-commutes-with-gain
department: audio-engineering
course: "Test Whether Clipping Commutes with Gain"
level: advanced
prerequisites: ["aud-005-pcm-guards-and-format-boundaries"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Test Whether Clipping Commutes with Gain

> Authored model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening result, engine render, parser execution or production adoption is claimed.

A GA comparison proposal moves a level adjustment across a protective output stage. The files can pass the same sample-range guard while containing different waveforms. Before accepting the rearrangement, write both orders and compare every retained sample. The new skill is checking an algebraic claim about a nonlinear operator, rather than checking whether a buffer is valid PCM. The runner supplies an actual range-check boundary; the hard clipper here is a deliberately authored substitute, not a recovered engine stage.

In the main case, the large positive and negative inputs reach the clipping boundary in one order but have already lost amplitude in the other. Interior samples still agree. This localized disagreement is useful evidence: a single unequal retained sample is enough to refute universal commutation. A smaller input can make both orders agree without repairing the universal claim. Keep the control’s changed amplitude visible when presenting its success.

Neither route supplies a linear gain estimate for arbitrary inputs. A frequency-response ratio assumes a linear experiment that this operator deliberately violates. Do not infer new harmonics from this short nonperiodic table, or infer listening quality from its residual. A proposed comparison record should retain the original input, both intermediate arrays and the ordering. A final peak alone conceals the location and size of the disagreement.

## Read the retained project evidence

The prerequisite supplies the earlier operation and its evidence boundary. Inspect the linked project artifact before using the authored case to propose a change. Its existing observations keep their original scope: a retained source file or fixture does not establish current deployment. The fixed packet records exact inputs, prepared outputs and reading provenance. Local file hashes identify complete bytes; they do not enlarge the bounded passage actually read. A primary web page supports only the specific definition read, with no invented immutable revision or byte hash.

[Prerequisite](../../audio-engineering/en/aud-005-pcm-guards-and-format-boundaries.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Fixed case and prepared quantities

```json
{
  "values": {
    "samples": [
      -2,
      -0.5,
      0.5,
      2
    ],
    "gain": 0.5,
    "threshold": 1
  },
  "formula": "clip(x)=max(-T,min(T,x)); A=clip(g*x); B=g*clip(x); residual=A-B",
  "expected": {
    "A": [
      -1,
      -0.25,
      0.25,
      1
    ],
    "B": [
      -0.5,
      -0.25,
      0.25,
      0.5
    ],
    "residual": [
      -0.5,
      0,
      0,
      0.5
    ],
    "commutes": false
  },
  "negative_control": {
    "values": {
      "samples": [
        -0.5,
        -0.25,
        0.25,
        0.5
      ],
      "gain": 0.5,
      "threshold": 1
    },
    "expected": {
      "A": [
        -0.25,
        -0.125,
        0.125,
        0.25
      ],
      "B": [
        -0.25,
        -0.125,
        0.125,
        0.25
      ],
      "residual": [
        0,
        0,
        0,
        0
      ],
      "commutes": true
    }
  }
}
```

## Assumptions and evidence limits

Assume real samples, a positive symmetric threshold and memoryless clipping. Reconstruction between samples is excluded. The calculation tests the declared operator only; it supplies no listening result or engine nonlinearity measurement.

## Interpret the operation before choosing an abstraction

Before revealing the answer key, write the input contract in your own words and derive the main result manually. Keep intermediate quantities or state transitions, rather than copying only a final number. Compare the negative control under the same rule and identify the input that changed. The model is a finite authored example. A matching calculation supports this example’s stated claim; it does not supply an observed user outcome or validate a production feature.

### Exercise 1

Calculate both orders for the largest positive sample.

<details><summary>Answer 1</summary>

The two outputs differ because attenuation before clipping retains a value that clipping before attenuation has already removed.

</details>

### Exercise 2

Why do the interior samples agree?

<details><summary>Answer 2</summary>

They remain inside the declared clipping interval throughout both routes, where the operator acts as the identity.

</details>

### Exercise 3

Does the main residual refute a universal reorder claim?

<details><summary>Answer 3</summary>

Yes. A single differing sample is a sufficient counterexample, even though other samples agree.

</details>

### Exercise 4

Does agreement in the smaller-input control prove linearity globally?

<details><summary>Answer 4</summary>

No. It establishes equality only in that tested region; the larger-input witness remains valid.

</details>

### Exercise 5

What rejects the proposed transparent reorder?

<details><summary>Answer 5</summary>

Any retained unequal output sample with the same input and declared operators rejects sample transparency.

</details>

## Source-assisted learner task

Prepare a GA audio-review note retaining both order traces and the exact range guard. Reject an unqualified reorder before proposing an audio-chain DSL.

Retain your unaided answer before consulting a source or calculator. Then identify a precise source passage and revision, record every kind of assistance and keep the original answer alongside any correction. A proposed agent workflow or DSL must preserve the manual result and its countercase before its convenience can be assessed. If required inputs are absent, leave the decision unresolved rather than substituting a plausible value.

Write a falsifier as an observable disagreement with the stated rule, then say what additional observation would be needed at the next boundary. Use the exercise answers as prepared checks, not as a record of your attempt. The fixed packet contains a separate prepared criterion for every exercise; all learner decisions remain undecided until an actual response and review are retained. Report assistance, corrections and remaining limits with the final note so that arithmetic correctness is not confused with independent recall, musician judgment or runtime acceptance.
