---
module_id: "sem-018-interpret-a-multi-shaft-weaving-draft"
department: "semiotics"
course: "Interpret a Multi-Shaft Weaving Draft"
level: "advanced"
prerequisites: ["vc-007-weave-seams-as-scene-contracts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Interpret a Multi-Shaft Weaving Draft

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

An IX craft scene currently has an alternating crossing rule, but a more general woven panel needs to interpret a threading assignment and a sequence of shaft lifts. An alternating parity formula cannot express every row in this example. We declare a rising-shed classroom convention: a raised shaft places each of its assigned warp strands above the weft for that pick. The operation composes those two records into a drawdown without claiming to simulate a loom.

Read a row by following identity through the threading map, then ask whether that shaft belongs to the row’s lift set. Several warp ends can share a shaft, so a lift changes more than one crossing. Keep shaft labels distinct from warp indices: the first is a control assignment, the second a spatial address. The resulting Boolean row says which strand is above under the declared convention. It does not specify strand thickness, contact forces or a manufacturable textile.

The missing-row control is semantically stronger than an appearance comparison. Replacing absent evidence with an empty lift set would fabricate an all-down instruction and a complete panel. Return an incomplete row instead, while retaining the earlier rows that are known. A future composable craft DSL should preserve this distinction at its boundary, but this course asks only for a manual interpretation table. An agent must not promote an incomplete draft to an admitted [Godot](https://docs.godotengine.org/en/4.5/) scene merely because the known rows look coherent.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "threading": [
      0,
      1,
      2,
      0
    ],
    "lift_plan": [
      [
        0,
        2
      ],
      [
        1
      ],
      [
        0,
        1
      ]
    ]
  },
  "formula": "drawdown[pick][warp]=threading[warp] in lift_plan[pick]; a missing lift-plan row yields null and status incomplete rather than false cells",
  "expected": {
    "status": "complete",
    "drawdown": [
      [
        true,
        false,
        true,
        true
      ],
      [
        false,
        true,
        false,
        false
      ],
      [
        true,
        true,
        false,
        true
      ]
    ]
  },
  "negative_control": {
    "values": {
      "threading": [
        0,
        1,
        2,
        0
      ],
      "lift_plan": [
        [
          0,
          2
        ],
        [
          1
        ],
        null
      ]
    },
    "expected": {
      "status": "incomplete",
      "drawdown": [
        [
          true,
          false,
          true,
          true
        ],
        [
          false,
          true,
          false,
          false
        ],
        null
      ]
    }
  }
}
```

### Exercise 1

Interpret the first pick.

<details><summary>Answer 1</summary>

The row is `[true,false,true,true]`: the repeated shaft assignment raises both of its warp ends. Spatial indices are not shaft labels.

</details>

### Exercise 2

Interpret the second pick.

<details><summary>Answer 2</summary>

The row is `[false,true,false,false]`. A lifted shaft affects precisely the warp ends assigned to it, regardless of their array positions.

</details>

### Exercise 3

Interpret the final recorded pick.

<details><summary>Answer 3</summary>

The row is `[true,true,false,true]`. The pattern cannot be recovered from a single alternating parity bit.

</details>

### Exercise 4

Apply the missing-lift control.

<details><summary>Answer 4</summary>

The final row becomes `null` and status `incomplete`. Earlier rows stay available; an absent instruction must not become an empty lift set.

</details>

### Exercise 5

Does a complete drawdown prove a physical weave?

<details><summary>Answer 5</summary>

No. It proves this finite interpretation under its declared rising-shed convention. Yarn mechanics, construction and human reading remain untested.

</details>

## Source-assisted task and direct baseline

Draw shaft columns and pick rows by hand, then derive the crossing table before showing it to an assistant. Compare the arbitrary lift plan with the committed alternating-weave scene and write the missing semantic boundary for a proposed extension.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

Any interpreter producing a definite all-down final row for the missing-row control has fabricated an instruction.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: vc-007-weave-seams-as-scene-contracts](../../visual-computing/en/vc-007-weave-seams-as-scene-contracts.md)
- [Retained project source](../../../../code/streeling/weave-godot/trial.gd)
- [Primary reading](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
