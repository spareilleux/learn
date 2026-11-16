---
module_id: "dv-025-check-overlay-contrast-from-linear-luminance"
department: "data-visualization"
course: "Check Overlay Contrast from Linear Luminance"
level: "advanced"
prerequisites: ["dv-006-position-length-area-comparisons", "vc-001-accessible-fretboard-paths"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Check Overlay Contrast from Linear Luminance

> Draft for technical and fluent-language review. All numerical inputs and expected outputs are authored cases. No new material trial, native scene run, learner observation or production outcome is supplied. Human and learner decisions remain undecided.

## Project operation and interpretation

A proposed [Godot](https://docs.godotengine.org/en/stable/classes/class_transform3d.html) embroidery annotation appears lighter than its background in a screenshot, but appearance alone does not supply a contrast calculation. Given already linear relative luminances, apply the [WCAG](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) ratio and a declared text threshold. The brighter value belongs in the numerator regardless of which is called foreground. Encoded RGB channels are not these luminances. The calculation checks only the specified opaque color pair; it certifies neither a rendered scene nor complete accessibility.

Read the committed prerequisite and the bounded source passage before calculating. Identify the exact operation that the project needs, the meaning of its inputs and the claim that the result could support. The source record retains its revision and inspected scope. A documentation definition, an authored assumption and an observed outcome belong in separate columns. Do not let an assistant replace an absent observation with a plausible story about what the software probably does.

Keep the representation explicit. The JSON below is a finite mathematical specification, not executable project syntax or a new engine feature. Its field names and fixed identity order form part of the teaching case. Read the formula together with the values; a correct-looking number obtained under another interpretation does not answer this task. Preserve intermediate quantities and the changed-input case so a reviewer can locate the first disagreement. The assumptions are deliberately narrow, and extending the domain requires a new justification rather than another confident caption.

## Fixed model and changed-input control

```json
{
  "values": {
    "foreground_luminance": 0.2,
    "background_luminance": 1,
    "threshold": 4.5
  },
  "formula": "ratio=(max(foreground_luminance,background_luminance)+0.05)/(min(foreground_luminance,background_luminance)+0.05); passes=ratio>=threshold",
  "expected": {
    "ratio": 4.2,
    "passes": false
  },
  "negative_control": {
    "values": {
      "foreground_luminance": 0.1,
      "background_luminance": 1,
      "threshold": 4.5
    },
    "expected": {
      "ratio": 7,
      "passes": true
    }
  }
}
```

### Exercise 1

Identify the inputs and the operation that must be preserved.

<details><summary>Answer 1</summary>

> **Answer:** Inputs are linear relative luminances and an explicit text threshold, not RGB bytes.

</details>

### Exercise 2

Calculate the contrast ratio and its decision at the declared threshold.

<details><summary>Answer 2</summary>

> **Answer:** The ratio is `4.2`, below `4.5`; the specified pair fails this criterion.

</details>

### Exercise 3

Explain the interpretation trap that a summary could conceal.

<details><summary>Answer 3</summary>

> **Answer:** A screenshot impression or keyboard test cannot substitute for the specified luminance calculation.

</details>

### Exercise 4

Apply the changed-input control and compare the result.

<details><summary>Answer 4</summary>

> **Answer:** The changed foreground produces ratio `7` and passes the same declared threshold.

</details>

### Exercise 5

State the limit and the evidence needed before project adoption.

<details><summary>Answer 5</summary>

> **Answer:** Rendered compositing, background variation and other accessibility criteria require separate observations.

</details>

## Source-assisted task and direct manual baseline

Prepare an opaque text/background color note for a proposed Atlas scene overlay using the supplied linear luminances.

With the answers hidden, draw an operation-specific table or diagram and calculate the main result by hand. This saved first attempt is the direct manual baseline. Include the inputs, the intermediate quantities, the rule used at each step and the reason for any refusal or unresolved value. State the prospective falsifier before asking an assistant to simplify the work. A plain table may already meet the project need; a composable DSL or an agent node needs evidence of an additional benefit.

Then inspect the linked local artifact and primary passage. Record the source location, its revision, the definition actually used and the boundary it does not establish. Ask an assistant to challenge one assumption, retaining the prompt and response. Mark any calculator, translation aid or source lookup as assistance. Compare the assisted result with the original baseline on identical inputs. Reject a shorter explanation if it removes an input identity, a condition or the distinction between an invented example and a project observation.

Treat the negative control as a separate record. Predict its result before opening its correction, then compare which fields changed and which remained invariant. If the answer disagrees, distinguish arithmetic error, semantic error and a limitation of the premises. Retain the failed attempt, diagnosis, correction and replay instead of overwriting the failure. Submit those records with the source-assisted explanation and the remaining uncertainty. This is the small improvement loop that can later support dogfooding; no improvement in a real learner or runtime has been measured here.

The packet prepares a criterion for every exercise, with no learner decisions filled in. Actual learner answer, assistance history, corrected answer and learner decision remain empty until an attempt exists. Technical review, fluent-language review, engine execution, material validation, production adoption and publication have separate evidence requirements. A finite calculation can establish only its declared relation under the stated assumptions. Before using it in a scene or practice product, name the additional observation and its rejection threshold; do not convert a prepared answer key into acceptance.

## Prospective falsifier

A proposed answer is rejected if applying the displayed operation to either retained input yields a result inconsistent with the fixed expected record, or if its explanation presents that record as a completed project observation.

## Prepared learner criteria

- Retain the correct answer and its intermediate reasoning for exercise 1; preserve the claim boundary. Learner decision remains undecided.
- Retain the correct answer and its intermediate reasoning for exercise 2; preserve the claim boundary. Learner decision remains undecided.
- Retain the correct answer and its intermediate reasoning for exercise 3; preserve the claim boundary. Learner decision remains undecided.
- Retain the correct answer and its intermediate reasoning for exercise 4; preserve the claim boundary. Learner decision remains undecided.
- Retain the correct answer and its intermediate reasoning for exercise 5; preserve the claim boundary. Learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: dv-006-position-length-area-comparisons](../../data-visualization/en/dv-006-position-length-area-comparisons.md)
- [Committed prerequisite: vc-001-accessible-fretboard-paths](../../visual-computing/en/vc-001-accessible-fretboard-paths.md)
- [Retained project artifact](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
