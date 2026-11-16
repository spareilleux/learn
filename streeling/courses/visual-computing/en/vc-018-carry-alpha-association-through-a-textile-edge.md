---
module_id: "vc-018-carry-alpha-association-through-a-textile-edge"
department: "visual-computing"
course: "Carry Alpha Association through a Textile Edge"
level: "advanced"
prerequisites: ["phy-009-distinguish-linear-color-from-display-encoding", "vc-010-preserve-packed-texture-channel-contracts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Carry Alpha Association through a Textile Edge

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A transparent embroidered cutout can acquire a dark fringe if a consumer multiplies color by alpha twice. Channel order and color encoding do not specify whether RGB has already been associated with alpha. This lesson adds that missing representation tag to a proposed ComfyUI-to-scene texture handoff.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

Start with straight color, form its associated contribution once, and use the premultiplied source-over equation. The backdrop contribution is reduced by the uncovered fraction. The [W3C](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/) reference defines these representations; the inspected ComfyUI helper retrieves image bytes without declaring the alpha association of their pixels. A successful download therefore cannot settle the question. An opaque sample is a weak diagnostic because association and double multiplication agree there.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "source_straight": [
      1,
      0,
      0
    ],
    "source_alpha": 0.25,
    "backdrop_straight": [
      0,
      0,
      1
    ],
    "backdrop_alpha": 1
  },
  "formula": "premul=source_alpha*source_straight; out=premul+(1-source_alpha)*backdrop_alpha*backdrop_straight; out_alpha=source_alpha+(1-source_alpha)*backdrop_alpha; double_multiplied=source_alpha*premul+(1-source_alpha)*backdrop_alpha*backdrop_straight",
  "expected": {
    "source_premultiplied": [
      0.25,
      0,
      0
    ],
    "out_premultiplied": [
      0.25,
      0,
      0.75
    ],
    "out_alpha": 1,
    "double_multiplied": [
      0.0625,
      0,
      0.75
    ]
  },
  "negative_control": {
    "values": {
      "source_straight": [
        1,
        0,
        0
      ],
      "source_alpha": 1,
      "backdrop_straight": [
        0,
        0,
        1
      ],
      "backdrop_alpha": 1
    },
    "expected": {
      "source_premultiplied": [
        1,
        0,
        0
      ],
      "out_premultiplied": [
        1,
        0,
        0
      ],
      "out_alpha": 1,
      "double_multiplied": [
        1,
        0,
        0
      ]
    }
  }
}
```

### Exercise 1

Associate the source color once.

<details><summary>Answer 1</summary>

The contribution is `[0.25,0,0]`. Keep that representation label attached to the vector.

</details>

### Exercise 2

Compute the source-over result.

<details><summary>Answer 2</summary>

The result is `[0.25,0,0.75]` with alpha `1`. On this opaque backdrop the associated output also equals the straight output.

</details>

### Exercise 3

Compute the erroneous second multiplication.

<details><summary>Answer 3</summary>

It gives `[0.0625,0,0.75]`, reducing the source contribution again. This is a representation error, not evidence of a bad dye or material.

</details>

### Exercise 4

Apply the opaque control.

<details><summary>Answer 4</summary>

Both paths give `[1,0,0]` with alpha `1`. Agreement in the control cannot validate translucent boundaries.

</details>

### Exercise 5

What must a texture handoff name?

<details><summary>Answer 5</summary>

Declare color domain, channel roles, alpha association and compositing order. Retrieval success alone supplies none of those pixel semantics.

</details>

## Source-assisted learner task

Make a manual contribution table before inspecting the byte-fetch helper. Propose an edge diagnostic with both translucent and opaque cases, then record the association metadata that a future importer would need.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

A claim that opaque agreement proves correct alpha handling is refuted by the unequal translucent results under the same arithmetic.

## Sources and validation boundary

- [Committed prerequisite: phy-009-distinguish-linear-color-from-display-encoding](../../physics/en/phy-009-distinguish-linear-color-from-display-encoding.md)

- [Committed prerequisite: vc-010-preserve-packed-texture-channel-contracts](../../visual-computing/en/vc-010-preserve-packed-texture-channel-contracts.md)

- [Retained project source](../../../../code/comfyui/ga-lab/runner/comfy.py)

- [Primary reading](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
