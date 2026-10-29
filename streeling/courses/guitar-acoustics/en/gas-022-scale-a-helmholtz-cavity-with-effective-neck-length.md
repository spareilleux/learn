---
module_id: gas-022-scale-a-helmholtz-cavity-with-effective-neck-length
department: guitar-acoustics
course: "Scale a Helmholtz Cavity with Effective Neck Length"
level: advanced
prerequisites: ["gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Scale a Helmholtz Cavity with Effective Neck Length

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

A guitar-body redesign changes the sound-hole area as well as cavity volume and neck end correction. Volume alone cannot predict the frequency shift. Use the lumped Helmholtz ratio to separate those contributions. Similar shapes scaled uniformly obey an inverse-length frequency rule because area, volume and effective neck length scale differently. This is a cavity-only approximation: flexible plates and radiation can couple to it. The direct ratio is a review baseline for a future acoustic scene parameter, not an identified body pole.

## Specific assumptions and limits

Assume unchanged sound speed, small acoustic motion and a cavity compact relative to wavelength. All ratios are positive and neck length is effective. No plate vibration, radiation loss or measured guitar resonance is included.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short [GA](https://github.com/GuitarAlchemist/ga) review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Primary reading](https://www.phys.unsw.edu.au/jw/Helmholtz.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "area_ratio": 4,
    "volume_ratio": 8,
    "effective_length_ratio": 2
  },
  "formula": "frequency_ratio=sqrt(area_ratio/(volume_ratio*effective_length_ratio))",
  "expected": {
    "frequency_ratio": 0.5
  },
  "negative_control": {
    "values": {
      "area_ratio": 4,
      "volume_ratio": 8,
      "effective_length_ratio": 1
    },
    "expected": {
      "frequency_ratio": 0.7071067811865476
    }
  }
}
```

### Exercise 1

Calculate the main result and name its convention.

> **Answer:** The frequency ratio is 0.5 from the declared geometric ratios.

### Exercise 2

Which quantity must remain separate?

> **Answer:** Effective neck length includes moving external air; geometric wall thickness alone need not equal it.

### Exercise 3

What assumption prevents a stronger conclusion?

> **Answer:** The compact-cavity approximation excludes arbitrary pressure variation and flexible-body coupling.

### Exercise 4

Explain the negative control.

> **Answer:** Holding length ratio at 1 gives `sqrt(0.5)`, which is not the similarity result 0.5.

### Exercise 5

What observation would reject the proposed claim?

> **Answer:** An independently computed ratio inconsistent with the stated area, volume and effective length rejects the scaling claim.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
