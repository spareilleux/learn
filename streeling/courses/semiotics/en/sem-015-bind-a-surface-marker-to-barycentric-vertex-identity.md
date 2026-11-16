---
module_id: "sem-015-bind-a-surface-marker-to-barycentric-vertex-identity"
department: "semiotics"
course: "Bind a Surface Marker to Barycentric Vertex Identity"
level: "advanced"
prerequisites: ["sem-004-face-identity-under-reindexing"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Bind a Surface Marker to Barycentric Vertex Identity

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A review pin can stay on the same named face yet slide across it after vertex reordering. Face identity identifies the containing surface, while barycentric weights identify an interior attachment relative to an ordered vertex triple. The earlier reindexing course preserves face meaning; this lesson carries the extra binding needed for a precise surface marker.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

Reordering vertices is harmless only if the corresponding weights move with their vertex identities. The weighted point then remains unchanged because the same contributions are merely listed differently. [PBRT](https://pbr-book.org/4ed/Shapes/Triangle_Meshes) shows barycentric hit and texture interpolation. Atlas builds meshes from vertex collections, but its helper is not a persistent annotation system. Keeping the face ID while retaining obsolete weight positions changes the denoted point. A remesh is a stronger operation and requires a separate correspondence argument.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "vertices": [
      [
        0,
        0
      ],
      [
        4,
        0
      ],
      [
        0,
        2
      ]
    ],
    "weights": [
      0.25,
      0.5,
      0.25
    ],
    "new_vertex_order": [
      0,
      2,
      1
    ],
    "remap_weights": true
  },
  "formula": "p=sum(weights[i]*vertices[i]); vertices_new=vertices[order]; weights_new=weights[order] if remap else weights; p_new=sum(weights_new[i]*vertices_new[i]); preserved=(p_new==p)",
  "expected": {
    "original": [
      2,
      0.5
    ],
    "remapped_weights": [
      0.25,
      0.25,
      0.5
    ],
    "new_point": [
      2,
      0.5
    ],
    "preserved": true
  },
  "negative_control": {
    "values": {
      "vertices": [
        [
          0,
          0
        ],
        [
          4,
          0
        ],
        [
          0,
          2
        ]
      ],
      "weights": [
        0.25,
        0.5,
        0.25
      ],
      "new_vertex_order": [
        0,
        2,
        1
      ],
      "remap_weights": false
    },
    "expected": {
      "original": [
        2,
        0.5
      ],
      "remapped_weights": [
        0.25,
        0.5,
        0.25
      ],
      "new_point": [
        1,
        1
      ],
      "preserved": false
    }
  }
}
```

### Exercise 1

Locate the original marker.

<details><summary>Answer 1</summary>

It is `[2,0.5]` in the declared planar units. The weights refer to the original vertex order.

</details>

### Exercise 2

Reorder vertices and weights together.

<details><summary>Answer 2</summary>

The new weights are `[0.25,0.25,0.5]`, giving `[2,0.5]`; `preserved=true`.

</details>

### Exercise 3

Apply the stale-slot control.

<details><summary>Answer 3</summary>

Unchanged weights `[0.25,0.5,0.25]` give `[1,1]`; `preserved=false`. The named face can remain identical.

</details>

### Exercise 4

Is a sum of weights equal to unity enough for an interior pin?

<details><summary>Answer 4</summary>

No. Nonnegativity is also required for a point inside the triangle, and correspondence with the intended vertices must be retained.

</details>

### Exercise 5

What must an annotation handoff carry?

<details><summary>Answer 5</summary>

Bind the surface revision, ordered vertex identities and weights. A new triangulation needs a justified transfer method rather than blind index reuse.

</details>

## Source-assisted learner task

Draw the triangle and both marker positions manually. Inspect Atlas mesh creation, then write a source-bound annotation proposal carrying vertex identities. Challenge face-ID-only preservation with the control.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

The claim that preserving face identity alone preserves an interior marker is refuted by unchanged face geometry and the stale-weight point.

## Sources and validation boundary

- [Committed prerequisite: sem-004-face-identity-under-reindexing](../../semiotics/en/sem-004-face-identity-under-reindexing.md)

- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)

- [Primary reading](https://pbr-book.org/4ed/Shapes/Triangle_Meshes)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
