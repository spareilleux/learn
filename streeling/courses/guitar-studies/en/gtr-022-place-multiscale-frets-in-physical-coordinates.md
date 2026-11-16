---
module_id: gtr-022-place-multiscale-frets-in-physical-coordinates
department: guitar-studies
course: "Place Multiscale Frets in Physical Coordinates"
level: advanced
prerequisites: ["gtr-006-keep-picking-distance-relative-to-frets"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Place Multiscale Frets in Physical Coordinates

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

The same fret number need not have the same physical coordinate on every string of a multiscale guitar. Each string retains its nut origin and scale length. Apply the equal-tempered fraction in that local coordinate, then return to a common scene axis. A line joining fret contacts can be angled even when the musical interval is identical. This construction helps review a proposed [GA](https://github.com/GuitarAlchemist/ga) fretboard scene without equating a rendered straight line to a compensated manufactured fret.

## Specific assumptions and limits

Assume straight parallel string axes, a common length unit and ideal equal-tempered fret ratios. The control deliberately borrows the first string scale for every string. Compensation, fretwire fitting and manufacturing tolerances remain untested.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short GA review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../guitar-studies/en/gtr-006-keep-picking-distance-relative-to-frets.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/fret/)

## Fixed case and prepared quantities

```json
{
  "values": {
    "nuts": [
      0,
      20
    ],
    "scales": [
      600,
      660
    ],
    "transverse": [
      0,
      10
    ],
    "fret": 12,
    "use_common_scale": false
  },
  "formula": "x_i=nut_i+L_i*(1-2^(-fret/12)); slope=(x_1-x_0)/(y_1-y_0)",
  "expected": {
    "positions": [
      300,
      350
    ],
    "slope": 5
  },
  "negative_control": {
    "values": {
      "nuts": [
        0,
        20
      ],
      "scales": [
        600,
        660
      ],
      "transverse": [
        0,
        10
      ],
      "fret": 12,
      "use_common_scale": true
    },
    "expected": {
      "positions": [
        300,
        320
      ],
      "slope": 2
    }
  }
}
```

### Exercise 1

Calculate the main result and name its convention.

> **Answer:** The positions are `[300,350]` and the line slope is 5 in the common coordinate axes.

### Exercise 2

Which quantity must remain separate?

> **Answer:** Nut origin and vibrating scale are independent inputs; changing one does not automatically change the other.

### Exercise 3

What assumption prevents a stronger conclusion?

> **Answer:** Ideal fret ratios omit stiffness, action and compensation; the coordinates do not certify intonation.

### Exercise 4

Explain the negative control.

> **Answer:** The common-scale control gives `[300,320]` and slope 2, so the second contact is misplaced.

### Exercise 5

What observation would reject the proposed claim?

> **Answer:** A scene contact differing from the independent per-string coordinate rejects faithful geometric mapping.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
