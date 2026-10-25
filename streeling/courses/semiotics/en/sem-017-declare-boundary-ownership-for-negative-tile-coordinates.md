---
module_id: "sem-017-declare-boundary-ownership-for-negative-tile-coordinates"
department: "semiotics"
course: "Declare Boundary Ownership for Negative Tile Coordinates"
level: "advanced"
prerequisites: ["sem-013-align-two-motif-periods-at-a-textile-seam", "cs-015-compose-overlapping-chunks-without-duplicate-frames"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Declare Boundary Ownership for Negative Tile Coordinates

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A repeated craft motif extends across the world origin. A tile lookup that truncates toward zero appears correct on positive coordinates but assigns a point just left of the origin to the wrong tile. Period alignment preserves repeating phases; it does not define which tile owns each spatial boundary.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

Define each cell as a half-open interval with an included lower endpoint. Flooring the normalized coordinate then identifies its unique owner, including on the negative side. The [Python](https://docs.python.org/3/library/math.html) reference defines floor; no scene runtime follows from that definition. Atlas stores local positions without supplying this tile-index rule. The changed-rule control deliberately violates the same ownership contract, rather than quietly changing both implementation and specification. A future adapter also needs an explicit numerical tolerance policy around computed boundaries. The chunk prerequisite already adopts half-open frame intervals. Its union operation does not derive a cell address from a negative real coordinate; that additional quotient operation is the subject here.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "coordinates": [
      -0.1,
      0,
      0.999,
      1
    ],
    "origin": 0,
    "pitch": 1,
    "index_rule": "floor"
  },
  "formula": "index=floor((x-origin)/pitch) for floor, otherwise trunc((x-origin)/pitch); lower=origin+index*pitch; owns=(lower<=x<lower+pitch); list failing coordinates",
  "expected": {
    "indices": [
      -1,
      0,
      0,
      1
    ],
    "ownership": [
      true,
      true,
      true,
      true
    ],
    "violating_coordinates": []
  },
  "negative_control": {
    "values": {
      "coordinates": [
        -0.1,
        0,
        0.999,
        1
      ],
      "origin": 0,
      "pitch": 1,
      "index_rule": "trunc"
    },
    "expected": {
      "indices": [
        0,
        0,
        0,
        1
      ],
      "ownership": [
        false,
        true,
        true,
        true
      ],
      "violating_coordinates": [
        -0.1
      ]
    }
  }
}
```

### Exercise 1

Find the floor-based tile indices.

<details><summary>Answer 1</summary>

They are `[-1,0,0,1]`. Every supplied point belongs to its declared half-open interval.

</details>

### Exercise 2

Who owns the point at the shared boundary?

<details><summary>Answer 2</summary>

The point `1` belongs to tile `1`; tile `0` excludes that upper boundary. There is no double ownership.

</details>

### Exercise 3

Apply the truncation control.

<details><summary>Answer 3</summary>

It gives `[0,0,0,1]`. Coordinate `-0.1` violates the assigned tile interval, so its ownership check is `false`.

</details>

### Exercise 4

Can positive-only examples detect the error?

<details><summary>Answer 4</summary>

No. The supplied nonnegative coordinates agree under both rules. A negative coordinate is a discriminating probe.

</details>

### Exercise 5

What must a composed placement carry?

<details><summary>Answer 5</summary>

Preserve origin, pitch, coordinate frame, boundary convention and indexing rule. A repeating motif label alone cannot reconstruct them.

</details>

## Source-assisted learner task

Draw adjacent intervals across the origin, place each coordinate manually and compare indexing rules. Inspect Atlas local positions and identify the missing ownership convention before proposing a tile DSL.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

The assertion that truncation and floor are interchangeable for tile ownership is refuted by the negative-coordinate witness.

## Sources and validation boundary

- [Committed prerequisite: sem-013-align-two-motif-periods-at-a-textile-seam](../../semiotics/en/sem-013-align-two-motif-periods-at-a-textile-seam.md)

- [Committed prerequisite: cs-015-compose-overlapping-chunks-without-duplicate-frames](../../computer-science/en/cs-015-compose-overlapping-chunks-without-duplicate-frames.md)

- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)

- [Primary reading](https://docs.python.org/3/library/math.html)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
