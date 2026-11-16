---
module_id: gas-025-separate-active-and-reactive-acoustic-power
department: guitar-acoustics
course: "Separate Active and Reactive Acoustic Power"
level: advanced
prerequisites: ["gas-018-account-for-energy-at-an-impedance-junction"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separate Active and Reactive Acoustic Power

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

Large oscillating pressure and flow do not guarantee large average transferred power. Their phase relation matters. Multiply pressure by conjugate volume velocity and retain the peak-phasor factor before taking the real part. The imaginary part encodes reactive exchange under the chosen sign convention; it is not additional average dissipated power. This port calculation helps review a proposed body-resonator diagnostic while leaving actual pressure calibration and boundary measurements open. Do not replace volume velocity with point particle velocity without also changing the physical quantity.

## Specific assumptions and limits

Use peak phasors with the positive complex-exponential time convention, and pressure and volume velocity at the same port. Flow points into the port. Neither a spatial intensity field nor an actual calibrated power measurement was obtained.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short [GA](https://github.com/GuitarAlchemist/ga) review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../guitar-acoustics/en/gas-018-account-for-energy-at-an-impedance-junction.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Fixed case and prepared quantities

```json
{
  "values": {
    "pressure": [
      2,
      0
    ],
    "volume_velocity": [
      0,
      1
    ],
    "phasor_kind": "peak"
  },
  "formula": "S=0.5*P*conj(U) for peak phasors; active=real(S); reactive=imag(S)",
  "expected": {
    "complex_power": [
      0,
      -1
    ],
    "active": 0,
    "reactive": -1
  },
  "negative_control": {
    "values": {
      "pressure": [
        2,
        0
      ],
      "volume_velocity": [
        1,
        0
      ],
      "phasor_kind": "peak"
    },
    "expected": {
      "complex_power": [
        1,
        0
      ],
      "active": 1,
      "reactive": 0
    }
  }
}
```

### Exercise 1

Calculate the main result and name its convention.

> **Answer:** The main complex power is `-1j`, with active power 0 and reactive power -1.

### Exercise 2

Which quantity must remain separate?

> **Answer:** Reactive power is not added to average dissipation; it records quadrature exchange for the chosen convention.

### Exercise 3

What assumption prevents a stronger conclusion?

> **Answer:** The factor 0.5 belongs to peak phasors; RMS phasors would require another normalization.

### Exercise 4

Explain the negative control.

> **Answer:** In phase, complex power is 1, active power is 1 and reactive power is 0 despite unchanged magnitudes.

### Exercise 5

What observation would reject the proposed claim?

> **Answer:** A magnitude-only rule predicting identical average power for both cases is refuted by their phase difference.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
