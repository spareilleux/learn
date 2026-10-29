---
module_id: gas-024-track-avoided-crossings-through-detuning
department: guitar-acoustics
course: "Track Avoided Crossings Through Detuning"
level: advanced
prerequisites: ["gas-012-distinguish-coupling-from-parallel-resonance"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Track Avoided Crossings Through Detuning

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

Two spectral peaks can exchange their dominant physical character as a body parameter passes through a string resonance. Sorting peaks by frequency does not preserve a component label. Follow the eigenbranches of a declared symmetric squared-frequency matrix across a detuning sweep. The off-diagonal coupling opens a minimum gap in squared frequency. That gap is not a damping width, and its square roots have a different separation. The exercise provides an authored continuation table for [GA](https://github.com/GuitarAlchemist/ga) diagnostics without fitting an actual guitar.

## Specific assumptions and limits

The matrix is real symmetric and its selected squared-frequency eigenvalues stay positive. There is no damping. The minimum reported is over the supplied finite detuning sweep; no fitted physical coupling is claimed.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short GA review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../guitar-acoustics/en/gas-012-distinguish-coupling-from-parallel-resonance.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Fixed case and prepared quantities

```json
{
  "values": {
    "center": 10,
    "detunings": [
      -3,
      0,
      3
    ],
    "coupling": 2
  },
  "formula": "matrix=[[c+d,g],[g,c-d]]; eigenvalues=c+-sqrt(d*d+g*g); gap=2*sqrt(d*d+g*g)",
  "expected": {
    "lower": [
      6.39444872453601,
      8,
      6.39444872453601
    ],
    "upper": [
      13.60555127546399,
      12,
      13.60555127546399
    ],
    "gaps": [
      7.211102550927978,
      4,
      7.211102550927978
    ],
    "minimum_gap": 4
  },
  "negative_control": {
    "values": {
      "center": 10,
      "detunings": [
        -3,
        0,
        3
      ],
      "coupling": 0
    },
    "expected": {
      "lower": [
        7,
        10,
        7
      ],
      "upper": [
        13,
        10,
        13
      ],
      "gaps": [
        6,
        0,
        6
      ],
      "minimum_gap": 0
    }
  }
}
```

### Exercise 1

Calculate the main result and name its convention.

> **Answer:** At zero detuning the squared-frequency branches are 8 and 12; their gap is 4.

### Exercise 2

Which quantity must remain separate?

> **Answer:** Squared-frequency separation differs from ordinary or angular frequency separation; retain the coordinate before taking roots.

### Exercise 3

What assumption prevents a stronger conclusion?

> **Answer:** This finite sweep contains the symmetric minimum, but it does not identify damping or a real guitar coupling.

### Exercise 4

Explain the negative control.

> **Answer:** With coupling 0 the two branches meet at 10, so the minimum gap becomes 0.

### Exercise 5

What observation would reject the proposed claim?

> **Answer:** A zero detuning gap of 0 with the retained nonzero coupling would reject the displayed eigenbranch prediction.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
