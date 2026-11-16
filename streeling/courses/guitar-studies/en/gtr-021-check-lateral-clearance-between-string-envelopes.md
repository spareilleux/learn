---
module_id: gtr-021-check-lateral-clearance-between-string-envelopes
department: guitar-studies
course: "Check Lateral Clearance Between String Envelopes"
level: advanced
prerequisites: ["gtr-013-judge-a-bend-with-an-uncertainty-budget"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Check Lateral Clearance Between String Envelopes

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

A correct bend pitch does not guarantee lateral clearance from a neighboring string. Retain both string radii and both swept displacements before comparing their envelopes. The interval gap includes the closest permitted approach, rather than just the resting center distance. This conservative geometric check could inform a [GA](https://github.com/GuitarAlchemist/ga) fingering explanation or a [Godot](https://godotengine.org/) teaching overlay. It does not reproduce vertical lifting, player technique, elastic collision or the shape along the whole string. A positive modeled gap is a conditional clearance statement.

## Specific assumptions and limits

The check concerns a single lateral slice with independent swept displacement ranges. Touching is not clear, and all lengths share one unit. Vertical avoidance, full-string geometry and a player trial are absent.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short GA review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../guitar-studies/en/gtr-013-judge-a-bend-with-an-uncertainty-budget.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Fixed case and prepared quantities

```json
{
  "values": {
    "centers": [
      0,
      10
    ],
    "radii": [
      1,
      1
    ],
    "displacements": [
      [
        0,
        6
      ],
      [
        -1,
        0
      ]
    ]
  },
  "formula": "interval_i=[center_i+min_displacement_i-radius_i,center_i+max_displacement_i+radius_i]; gap=interval_1.low-interval_0.high; clear=gap>0",
  "expected": {
    "intervals": [
      [
        -1,
        7
      ],
      [
        8,
        11
      ]
    ],
    "gap": 1,
    "clear": true
  },
  "negative_control": {
    "values": {
      "centers": [
        0,
        10
      ],
      "radii": [
        1,
        1
      ],
      "displacements": [
        [
          0,
          8
        ],
        [
          -1,
          0
        ]
      ]
    },
    "expected": {
      "intervals": [
        [
          -1,
          9
        ],
        [
          8,
          11
        ]
      ],
      "gap": -1,
      "clear": false
    }
  }
}
```

### Exercise 1

Calculate the main result and name its convention.

> **Answer:** The swept intervals are `[-1,7]` and `[8,11]`; their gap is 1 and clearance is true.

### Exercise 2

Which quantity must remain separate?

> **Answer:** Resting center distance is not edge clearance; radii and motion ranges both consume it.

### Exercise 3

What assumption prevents a stronger conclusion?

> **Answer:** The independent ranges give a conservative envelope; actual time-correlated motions need a trajectory model.

### Exercise 4

Explain the negative control.

> **Answer:** The control gap is -1, so the envelopes overlap and the clearance claim fails.

### Exercise 5

What observation would reject the proposed claim?

> **Answer:** An admitted displacement producing intersecting envelopes refutes universal lateral clearance in this slice.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
