---
module_id: gas-017-recover-a-stiffness-coefficient-from-partial-ratios
department: guitar-acoustics
course: "Recover a Stiffness Coefficient from Partial Ratios"
level: advanced
prerequisites: ["gas-010-distinguish-stiff-string-partials-from-harmonics"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Recover a Stiffness Coefficient from Partial Ratios

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

A plausible inharmonic spectrum does not identify a production parameter by inspection. Before recommending a [GA](https://github.com/GuitarAlchemist/ga) dispersion setting, solve the declared inverse model and test a partial that was not used in the fit. This lesson separates parameter recovery from prediction and makes an incompatible observation reject the selected model family.

## Read the retained evidence

The primary text explains dispersive propagation and allpass modeling. Our normalized coefficient comes from the prerequisite’s mathematical example, not from a documented engine calibration. Read the retained dispersion-related state as a software boundary, not a material measurement.

[Prerequisite](../../guitar-acoustics/en/gas-010-distinguish-stiff-string-partials-from-harmonics.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://www.dsprelated.com/freebooks/pasp/Stiff_String.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "squared_normalized_second_ratio": 1.0297029702970297,
    "squared_normalized_third_ratio": 1.0792079207920793
  },
  "formula": "r=(f2/(2*f1))^2; B=(r-1)/(4-r); predicted_third_squared_ratio=(1+9*B)/(1+B); valid=1<=r<4 and B>=0",
  "expected": {
    "B": 0.01,
    "predicted_third_squared_ratio": 1.0792079207920793,
    "held_out_residual": 0,
    "valid": true
  },
  "negative_control": {
    "values": {
      "squared_normalized_second_ratio": 0.99,
      "squared_normalized_third_ratio": 1
    },
    "expected": {
      "B": -0.0033222591362126247,
      "valid": false
    }
  }
}
```

## Separate fitting, prediction and calibration

An inverse calculation can fit its selected observation exactly by construction. That agreement is not an independent validation. The third-partial input is therefore retained outside the fitting equation and compared only after recovering the coefficient. In a real spectrum, the uncertainty and identity of each peak would also matter: swapping a partial index can produce a neat numerical fit to the wrong physical relationship.

The inverse has an admissible region. As its denominator approaches zero, small ratio errors can create large coefficient changes. A finite answer can thus be both algebraically defined and practically unstable. The nonnegative-family guard addresses a different issue: it rejects a sign incompatible with the stipulated family rather than estimating confidence in a valid fit. Keep singularity, admissibility and measurement uncertainty as separate review questions.

Finally, an inferred teaching coefficient is not a software control value. An allpass implementation can parameterize dispersion with filter coefficients whose relationship to partial ratios depends on the whole loop. The retained state establishes that software has dispersion-related quantities; it does not establish a calibrated inverse for them. Before recommending a slider change, a proposed experiment needs a pinned control intervention and held-out measured partials. The manual inverse and its rejection case provide a small baseline for deciding whether that larger calibration effort is warranted.

### Exercise 1

Rearrange the squared second-partial ratio to solve for the coefficient. What must not vanish?

<details><summary>Answer 1</summary>

Move the coefficient terms to obtain the displayed inverse. Its denominator must be nonzero; a singular or excluded ratio cannot be repaired by silently clipping the fit.

</details>

### Exercise 2

Use the main ratio and state the recovered coefficient. What was fitted?

<details><summary>Answer 2</summary>

The expected coefficient is listed below. Only the normalized second-partial relationship was fitted; the overall frequency scale remains anchored by the first partial.

</details>

### Exercise 3

Predict the held-out third-partial ratio. Why retain that separate input?

<details><summary>Answer 3</summary>

The predicted and supplied ratios agree in this authored case. Reusing the second-partial equation as its own validation would not test the family’s higher-partial consequence.

</details>

### Exercise 4

Apply the control. Why reject the coefficient even though algebra returns a number?

<details><summary>Answer 4</summary>

The coefficient is negative and violates the selected nonnegative family. A finite algebraic result does not establish physical admissibility under the declared assumptions.

</details>

### Exercise 5

What would falsify a useful fit before engine calibration?

<details><summary>Answer 5</summary>

A held-out partial ratio inconsistent with the prediction beyond declared estimation uncertainty rejects this fit. Incorrect partial identity also invalidates the input rather than proving an engine defect.

</details>

## Source-assisted learner task

Derive the inverse by hand and retain the held-out check separately. Compare the result with the retained software state. Propose a measurement record with partial identity and uncertainty before any parameter recommendation; leave the engine mapping and audibility unassessed.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
