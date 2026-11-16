---
module_id: "vc-019-measure-directional-uv-stretch-before-reusing-a-motif"
department: "visual-computing"
course: "Measure Directional UV Stretch before Reusing a Motif"
level: "advanced"
prerequisites: ["vc-016-track-uv-gutters-through-mip-levels"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Measure Directional UV Stretch before Reusing a Motif

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A circular embroidered motif can become elongated even when two UV patches have the same area scale. Gutter width tracks separation in a texture atlas; it does not characterize directional distortion inside an island. This lesson compares the two independent stretches of a declared affine patch before a proposed Blender-to-Godot reuse.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

The diagonal map sends the coordinate axes to orthogonal surface directions. Each diagonal magnitude is a directional stretch, while their product is area scale. A circle follows both stretches and becomes an ellipse unless the magnitudes agree. [PBRT](https://pbr-book.org/4ed/Shapes/Triangle_Meshes) explains affine UV derivatives for triangles. Atlas creates mesh objects, but the inspected helper gives no exported-UV quality result. Our simplified derivative table is authored and must not be mistaken for a measurement from a generated asset.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "dx_du": 4,
    "dy_dv": 1,
    "uv_radius": 0.1
  },
  "formula": "J=diag(dx_du,dy_dv); stretches=[abs(dx_du),abs(dy_dv)]; area_scale=abs(dx_du*dy_dv); anisotropy=max(stretches)/min(stretches); ellipse_axes=uv_radius*stretches",
  "expected": {
    "stretches": [
      4,
      1
    ],
    "area_scale": 4,
    "anisotropy": 4,
    "ellipse_axes": [
      0.4,
      0.1
    ]
  },
  "negative_control": {
    "values": {
      "dx_du": 2,
      "dy_dv": 2,
      "uv_radius": 0.1
    },
    "expected": {
      "stretches": [
        2,
        2
      ],
      "area_scale": 4,
      "anisotropy": 1,
      "ellipse_axes": [
        0.2,
        0.2
      ]
    }
  }
}
```

### Exercise 1

Find the main directional stretches and area scale.

<details><summary>Answer 1</summary>

The stretches are `[4,1]` and area scale is `4`. Their product alone loses the difference between directions.

</details>

### Exercise 2

Map the UV circle.

<details><summary>Answer 2</summary>

Its semiaxes become `[0.4,0.1]` scene units, with anisotropy `4`. These are radii, not full diameters.

</details>

### Exercise 3

Apply the equal-area control.

<details><summary>Answer 3</summary>

The stretches become `[2,2]`, area scale stays `4`, semiaxes are `[0.2,0.2]`, and anisotropy becomes `1`.

</details>

### Exercise 4

Would sufficient atlas gutter solve this distortion?

<details><summary>Answer 4</summary>

No. Gutter prevents a different kind of cross-island contamination. It cannot change the affine derivative within the patch.

</details>

### Exercise 5

What breaks the diagonal shortcut?

<details><summary>Answer 5</summary>

Shear or nonorthogonal derivatives require singular values of the full local map. Curved patches require position-dependent derivatives; this case does not assess them.

</details>

## Source-assisted learner task

Draw the two transformed circles on a common ruler, inspect Atlas mesh creation, and identify the missing UV derivative evidence. Make the area-only recommendation first, then challenge it with the control before suggesting automation.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

Equal area scale as a guarantee of preserved motif shape is refuted by the two maps: the area products agree while anisotropy differs.

## Sources and validation boundary

- [Committed prerequisite: vc-016-track-uv-gutters-through-mip-levels](../../visual-computing/en/vc-016-track-uv-gutters-through-mip-levels.md)

- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)

- [Primary reading](https://pbr-book.org/4ed/Shapes/Triangle_Meshes)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
