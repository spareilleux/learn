---
module_id: "dv-019-choose-a-minimal-view-set-for-declared-features"
department: "data-visualization"
course: "Choose a Minimal View Set for Declared Features"
level: "advanced"
prerequisites: ["phi-010-state-what-a-craft-view-cannot-distinguish", "dv-016-compare-paired-silhouette-residuals"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Choose a Minimal View Set for Declared Features

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A turntable can produce many captures while leaving a hidden craft feature unexamined. The projection prerequisite demonstrates information loss in an individual view; this lesson chooses a smallest collection from an explicit feature-visibility table. Minimality concerns the declared feature set and costs, rather than a universal number of cameras.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

Treat each camera as a set of visible feature IDs and combine cameras with set union. Search small subsets before larger subsets, preserving every tied minimum. A sum of visible-feature counts can count shared features repeatedly and cannot prove coverage. The cleanup script exposes a frame count, without supplying our binary visibility matrix. Godot depth documentation establishes a camera-dependent observation boundary, not these visibility claims. A future scene trial must validate each matrix entry before using this selection.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "required": [
      "A",
      "B",
      "C",
      "D"
    ],
    "views": {
      "front": [
        "A",
        "B"
      ],
      "side": [
        "B",
        "C"
      ],
      "top": [
        "C",
        "D"
      ],
      "back": [
        "A",
        "D"
      ]
    }
  },
  "formula": "For each subset of sorted view names union feature sets; retain subsets covering required; minimize cardinality; return all tied minima in lexicographic order; if impossible return minimum_count=null and covers=[]; uncovered=required-union(all views)",
  "expected": {
    "minimum_count": 2,
    "covers": [
      [
        "back",
        "side"
      ],
      [
        "front",
        "top"
      ]
    ],
    "uncovered": []
  },
  "negative_control": {
    "values": {
      "required": [
        "A",
        "B",
        "C",
        "D"
      ],
      "views": {
        "front": [
          "A",
          "B"
        ],
        "side": [
          "B",
          "C"
        ],
        "top": [
          "C"
        ],
        "back": [
          "A"
        ]
      }
    },
    "expected": {
      "minimum_count": null,
      "covers": [],
      "uncovered": [
        "D"
      ]
    }
  }
}
```

### Exercise 1

Can one view cover all required features?

<details><summary>Answer 1</summary>

No. Each supplied view covers only a proper subset. Counting its marks does not add missing identities.

</details>

### Exercise 2

Find every minimum cover.

<details><summary>Answer 2</summary>

The minimum is `2`: `[back,side]` and `[front,top]`. Both cover the complete required set.

</details>

### Exercise 3

Does choosing one tied pair establish unique optimality?

<details><summary>Answer 3</summary>

No. Preserve both tied pairs under the equal-cost rule. A preference requires an additional declared criterion.

</details>

### Exercise 4

Apply the missing-feature control.

<details><summary>Answer 4</summary>

Feature `[D]` is uncovered; minimum count is `null` and covers are `[]`. Adding more of the listed views cannot reveal it.

</details>

### Exercise 5

What would a physical or rendered trial add?

<details><summary>Answer 5</summary>

Validate visibility for the specific geometry, camera and feature recognition task. A binary authored table does not prove that a learner recognizes the feature.

</details>

## Source-assisted learner task

Draw the feature-by-view table, enumerate subsets manually and retain the tied solutions. Inspect the pipeline frame argument and identify the missing visibility measurements. State an unobservable-feature refusal before proposing automatic camera selection.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

A claim that increasing the count of listed captures guarantees feature coverage is refuted when the required feature is absent from every supplied view.

## Sources and validation boundary

- [Committed prerequisite: phi-010-state-what-a-craft-view-cannot-distinguish](../../philosophy/en/phi-010-state-what-a-craft-view-cannot-distinguish.md)

- [Committed prerequisite: dv-016-compare-paired-silhouette-residuals](../../data-visualization/en/dv-016-compare-paired-silhouette-residuals.md)

- [Retained project source](../../../../code/blender/scripts/glb_pipeline.py)

- [Primary reading](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
