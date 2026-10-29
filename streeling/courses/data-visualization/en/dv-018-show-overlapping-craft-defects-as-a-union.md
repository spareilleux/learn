---
module_id: "dv-018-show-overlapping-craft-defects-as-a-union"
department: "data-visualization"
course: "Show Overlapping Craft Defects as a Union"
level: "advanced"
prerequisites: ["dv-015-map-missing-stitches-without-inventing-holes"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Show Overlapping Craft Defects as a Union

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A texture report labels a seam mismatch and a color mismatch on overlapping regions. Adding their areas counts the shared region twice and can exaggerate the affected surface. The missing-stitch prerequisite distinguishes absence from unavailable observations. Here all areas are known; the new issue is overlap among categories.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

Partition the canvas into exclusive categories before drawing a stacked display: only the first mask, only the second, both, and neither. Their areas add to the canvas once. [W3C](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/) compositing describes overlap-sensitive region combinations, but the binary masks here are our own set model, not alpha values or rendered defect evidence. The ComfyUI helper returns image bytes and does not prove which regions contain defects. A successful disjoint example is therefore insufficient to validate a summary for overlapping defects.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "canvas_area": 100,
    "mask_a_area": 30,
    "mask_b_area": 25,
    "intersection_area": 10
  },
  "formula": "a_only=A-I; b_only=B-I; both=I; union=A+B-I; neither=canvas-union; naive_sum=A+B",
  "expected": {
    "a_only": 20,
    "b_only": 15,
    "both": 10,
    "union": 45,
    "neither": 55,
    "naive_sum": 55
  },
  "negative_control": {
    "values": {
      "canvas_area": 100,
      "mask_a_area": 30,
      "mask_b_area": 25,
      "intersection_area": 0
    },
    "expected": {
      "a_only": 30,
      "b_only": 25,
      "both": 0,
      "union": 55,
      "neither": 45,
      "naive_sum": 55
    }
  }
}
```

### Exercise 1

Find the exclusive affected areas.

<details><summary>Answer 1</summary>

Only the first is `20`, only the second `15`, and both `10` area units. Keep category meaning separate from color choice.

</details>

### Exercise 2

Compute unique affected area and unaffected area.

<details><summary>Answer 2</summary>

They are `45` and `55`. The exclusive partition sums to `100`.

</details>

### Exercise 3

Quantify the naive sum error.

<details><summary>Answer 3</summary>

The sum is `55`, overstating the union by `10`, exactly the intersection counted again.

</details>

### Exercise 4

Apply the disjoint control.

<details><summary>Answer 4</summary>

The union becomes `55` and neither becomes `45`. Naive addition now agrees because intersection is `0`.

</details>

### Exercise 5

Can two input areas alone determine the union?

<details><summary>Answer 5</summary>

No. The intersection is additional information. Without it, report bounds rather than inventing a unique affected area.

</details>

## Source-assisted learner task

Draw a labelled overlap diagram and its exclusive-area table manually. Inspect the image retrieval boundary, then draft a display with a separate shared category and a declared unknown-intersection state.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

The rule that defect-category areas can always be added is refuted by the overlap case, even though it succeeds for the disjoint control.

## Sources and validation boundary

- [Committed prerequisite: dv-015-map-missing-stitches-without-inventing-holes](../../data-visualization/en/dv-015-map-missing-stitches-without-inventing-holes.md)

- [Retained project source](../../../../code/comfyui/ga-lab/runner/comfy.py)

- [Primary reading](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
