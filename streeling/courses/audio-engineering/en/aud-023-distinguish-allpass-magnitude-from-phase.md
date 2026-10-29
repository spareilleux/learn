---
module_id: aud-023-distinguish-allpass-magnitude-from-phase
department: audio-engineering
course: "Distinguish Allpass Magnitude from Phase"
level: advanced
prerequisites: ["aud-008-measure-a-filter-with-paired-input-and-output"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguish Allpass Magnitude from Phase

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

A spectral magnitude overlay can make an allpass stage look like an identity operator. The numerator and denominator have equal squared magnitude on the unit circle, yet their complex quotient changes phase. In a guitar feedback loop that phase can change tuning even when magnitude stays flat. Compare the complex response with a bypass before proposing an allegedly transparent composition. A frequency witness does not establish the audible size of a transient change.

## Specific assumptions and limits

The real coefficient has magnitude below unity, ensuring the declared pole is stable. Evaluate a steady complex response; do not infer finite cropped impulse energy or audible transparency. No compiled filter or loop tuning was tested.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short [GA](https://github.com/GuitarAlchemist/ga) review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../audio-engineering/en/aud-008-measure-a-filter-with-paired-input-and-output.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Primary reading](https://www.dsprelated.com/freebooks/filters/Allpass_Filters.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "a": 0.5,
    "omega_over_pi": 0.5,
    "numerator_scale": 1
  },
  "formula": "z_inv=exp(-j*pi*omega_over_pi); H=numerator_scale*(a+z_inv)/(1+a*z_inv); magnitude=abs(H)",
  "expected": {
    "H_real": 0.8,
    "H_imag": -0.6,
    "magnitude": 1,
    "identity": false
  },
  "negative_control": {
    "values": {
      "a": 0.5,
      "omega_over_pi": 0.5,
      "numerator_scale": 2
    },
    "expected": {
      "H_real": 1.6,
      "H_imag": -1.2,
      "magnitude": 2,
      "identity": false
    }
  }
}
```

### Exercise 1

Compute the complex response.

> **Answer:** It is `0.8-0.6j`, with magnitude 1 and a nonzero imaginary part.

### Exercise 2

Why is equal magnitude insufficient for identity?

> **Answer:** Identity also requires the complex response to equal 1; the displayed imaginary component disproves that.

### Exercise 3

Which expression establishes flat magnitude?

> **Answer:** Both squared magnitudes are `1+a*a+2*a*cos(omega)` before the extra numerator scaling.

### Exercise 4

What does the scaled control show?

> **Answer:** Its magnitude is 2, so stability of the unchanged pole alone does not certify an allpass magnitude.

### Exercise 5

What falsifies sample-transparent bypass?

> **Answer:** A nonidentity complex response at an admitted frequency is a counterexample to universal identity.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
