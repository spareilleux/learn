---
module_id: "vc-020-intersect-a-scene-picking-ray-with-box-slabs"
department: "visual-computing"
course: "Intersect a Scene Picking Ray with Box Slabs"
level: "advanced"
prerequisites: ["vc-008-save-and-query-a-weave-scene"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Intersect a Scene Picking Ray with Box Slabs

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

The weave scene already distinguishes a hit’s crossing identity from its strand label. Before a future picker examines detailed embroidery or sculpture geometry, it may reject candidates whose enclosing boxes the ray cannot reach. A box intersection is a broad-phase operation: it can eliminate a candidate but cannot certify a surface hit. This lesson calculates the permitted ray-parameter interval manually, retaining that evidential asymmetry.

Treat the box as the intersection of coordinate slabs. Each nonparallel coordinate gives an interval of parameters for which the ray lies between that coordinate’s minimum and maximum. Intersect those intervals with the forward segment. A parallel coordinate requires a different branch: its origin is either already inside the entire slab or it never enters. Replacing division by zero with an arbitrary large number hides that distinction. The control places the origin outside a parallel slab while leaving the travelling coordinate unchanged.

The parameter is distance only when the direction vector has the corresponding normalization and unit convention. A future scene handoff must carry the frame of the box and ray, the forward limit and the detailed predicate that follows a box hit. BRUTAL group bounds could nominate a sculpture for closer inspection; they cannot report which chased mark was selected. Keep a missed box, an untested mesh and a confirmed detailed hit as different outcomes.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "minimum": [
      0,
      0,
      0
    ],
    "maximum": [
      2,
      2,
      2
    ],
    "origin": [
      -2,
      1,
      1
    ],
    "direction": [
      1,
      0,
      0
    ],
    "t_max": 10
  },
  "formula": "start=[0,t_max]; for each nonzero direction intersect with sorted((minimum-origin)/direction,(maximum-origin)/direction); zero direction outside slab rejects; hit iff resulting interval nonempty",
  "expected": {
    "hit": true,
    "t_enter": 2,
    "t_exit": 4
  },
  "negative_control": {
    "values": {
      "minimum": [
        0,
        0,
        0
      ],
      "maximum": [
        2,
        2,
        2
      ],
      "origin": [
        -2,
        3,
        1
      ],
      "direction": [
        1,
        0,
        0
      ],
      "t_max": 10
    },
    "expected": {
      "hit": false,
      "t_enter": null,
      "t_exit": null
    }
  }
}
```

### Exercise 1

Find the travelling-axis interval.

<details><summary>Answer 1</summary>

It is `[2,4]`. Sort the boundary parameters before intersecting so negative directions would also be handled.

</details>

### Exercise 2

Handle the parallel coordinates.

<details><summary>Answer 2</summary>

Both origins lie inside their closed slabs, so they add no restriction. No division by a zero direction is needed.

</details>

### Exercise 3

Apply the forward limit.

<details><summary>Answer 3</summary>

The interval remains `[2,4]` inside `[0,10]`, so the model reports a box hit. The exit belongs to the closed box.

</details>

### Exercise 4

Evaluate the displaced-origin control.

<details><summary>Answer 4</summary>

It misses because the parallel origin lies outside the slab. Entry and exit are `null`; the travelling-axis interval cannot rescue it.

</details>

### Exercise 5

Does a box hit establish a crossing selection?

<details><summary>Answer 5</summary>

No. A detailed surface query and source-bound identity correspondence remain separate predicates; the box contains empty space as well as geometry.

</details>

## Source-assisted task and direct baseline

Draw the ray and slabs for a proposed sculpture picker before asking an assistant to summarize the scene trial. Produce a manual interval table and specify the detailed identity query needed after acceptance.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

Any picker explanation admitting the control merely because its travelling-axis interval overlaps is refuted by the parallel slab.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: vc-008-save-and-query-a-weave-scene](../../visual-computing/en/vc-008-save-and-query-a-weave-scene.md)
- [Retained project source](../../../../code/streeling/weave-godot/trial.gd)
- [Primary reading](https://pbr-book.org/4ed/Shapes/Basic_Shape_Interface)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
