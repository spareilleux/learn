---
module_id: aud-017-report-ambiguous-correlation-lags
department: audio-engineering
course: "Report Ambiguous Correlation Lags"
level: advanced
prerequisites: ["aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Report Ambiguous Correlation Lags

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

An alignment algorithm can return a precise sample shift even when its objective has several equally good answers. Periodic guitar signals make that risk concrete. Before using a correlation peak to compensate the [GA](https://github.com/GuitarAlchemist/ga) comparison, distinguish the signed objective from its magnitude and preserve ties. A chosen lag is an estimate under a convention, not a source timestamp.

## Read the retained evidence

The official correlation reference defines a linear, zero-padded convention. Our circular sum is deliberately written out instead. Read the runner to see that its retained equality comparison does not estimate a lag; the calculation below proposes a separate review operation.

[Prerequisite](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.correlate.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "x": [
      1,
      0,
      -1,
      0
    ],
    "y": [
      0,
      1,
      0,
      -1
    ],
    "lags": [
      0,
      1,
      2,
      3
    ]
  },
  "formula": "C(k)=sum_n x[n]*y[(n+k)%N]; signed_argmax=argmax(C); absolute_argmax=argmax(abs(C))",
  "expected": {
    "correlation": [
      0,
      2,
      0,
      -2
    ],
    "signed_argmax": [
      1
    ],
    "absolute_argmax": [
      1,
      3
    ]
  },
  "negative_control": {
    "values": {
      "x": [
        1,
        0,
        0,
        0
      ],
      "y": [
        0,
        1,
        0,
        0
      ],
      "lags": [
        0,
        1,
        2,
        3
      ]
    },
    "expected": {
      "correlation": [
        0,
        1,
        0,
        0
      ],
      "signed_argmax": [
        1
      ],
      "absolute_argmax": [
        1
      ]
    }
  }
}
```

## Separate an estimator choice from evidence of uniqueness

Circular correlation treats the last sample as adjacent to the first. That assumption is convenient for this periodic construction but can create a false match across the cut in an ordinary recording. Linear correlation uses another boundary policy. Neither convention should be inferred from a function name alone. Keep the equation with the result and state whether the record was deliberately made periodic or merely cut from a longer take.

Maximizing absolute correlation also grants a polarity reversal as an equally valuable match. That can be appropriate when polarity is a declared nuisance, but it changes the question asked by a comparison that requires unchanged samples. The negative peak has not become positive physical evidence merely because its magnitude is large. The receipt must distinguish the score used to select a shift from the transformations later applied to the signal.

A tie-breaking rule is an engineering choice, useful for reproducible output but separate from identifiability. An earliest-lag rule will always pick an answer from the ambiguous set, even when the data cannot choose among them. The manual vector is the minimal baseline: it exposes every candidate directly. Before automating a search over real takes, declare its admissible lag range, support treatment, objective and tie policy. A capture trigger or independent onset cue may supply missing timing evidence; the periodic record alone cannot.

### Exercise 1

Evaluate the circular sum at every declared lag. Why is the convention part of the answer?

<details><summary>Answer 1</summary>

The correlation vector appears below. Wrapping indices uses another support rule from zero padding, and reversing the lag sign would change its interpretation.

</details>

### Exercise 2

Find every maximum of the signed objective. What does its sign retain?

<details><summary>Answer 2</summary>

The signed maximum selects the positive match. Its sign distinguishes a matching waveform from a polarity-reversed one under the declared product.

</details>

### Exercise 3

Now maximize magnitude. Can the program return one shift as uniquely identified?

<details><summary>Answer 3</summary>

The absolute objective has the listed pair of maximizers. Returning only the first may be deterministic, but does not remove the ambiguity in the data.

</details>

### Exercise 4

Apply the impulse control. What makes its result diagnostically useful?

<details><summary>Answer 4</summary>

Both objectives have the same unique maximum. A method that still reports a tie has mishandled this control; uniqueness here does not validate uniqueness for periodic input.

</details>

### Exercise 5

What would falsify an alignment receipt claiming a unique absolute maximum?

<details><summary>Answer 5</summary>

A second lag with the same retained objective value rejects uniqueness. Keep the full objective, permitted lag range and polarity policy before choosing a compensating shift.

</details>

## Source-assisted learner task

Compute both vectors manually and draft a lag receipt for a proposed GA comparison. Preserve ties and explain when the task permits polarity inversion. Compare that receipt against a direct unaligned comparison; leave actual latency and audio fidelity unresolved.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
