---
module_id: "sem-019-distinguish-knot-diagram-reversal-from-mirroring"
department: "semiotics"
course: "Distinguish Knot Diagram Reversal from Mirroring"
level: "advanced"
prerequisites: ["sem-005-bind-scene-hits-to-crossing-identity"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguish Knot Diagram Reversal from Mirroring

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

A mirrored knot ornament and the same ornament traversed backward can retain every crossing identifier while changing different aspects of meaning. The older crossing-binding course cannot decide whether a signed diagram annotation should change. We now declare an oriented screen convention and calculate a crossing sign from the determinant of its over and under tangent vectors. This finite tangent table is authored; it is not a reconstructed physical knot or proof that the listed crossings form an embedded closed curve.

Sum the signs to obtain diagram writhe. Reversing the traversal of the whole single component reverses both tangents at each crossing, so the determinant sign stays fixed. Reflecting one screen coordinate reverses the orientation of the plane and flips every determinant sign instead. Keep the over/under ordering fixed during both operations. Swapping those roles accidentally would introduce another sign reversal and conceal the mirror effect.

Calegari’s notes distinguish diagram writhe from an ambient knot invariant: adding a Reidemeister curl changes it. The lesson therefore supports a bounded annotation about this diagram and its declared transformations, not a universal knot-identity test. A future [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) or [Godot](https://docs.godotengine.org/en/4.5/) ornament should retain crossing referents, screen orientation and transformation history beside the number. An assistant must not infer that equal writhe proves equal knots or that a changed writhe proves a different physical knot type.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "over_tangents": [
      [
        1,
        0
      ],
      [
        0,
        1
      ],
      [
        1,
        1
      ]
    ],
    "under_tangents": [
      [
        0,
        1
      ],
      [
        1,
        0
      ],
      [
        -1,
        1
      ]
    ],
    "operation": "reverse"
  },
  "formula": "crossing_sign=sign(det(over,under)) in a declared oriented screen frame; writhe=sum(signs); reverse negates both tangents at every crossing; mirror negates x components; recompute signs and writhe",
  "expected": {
    "original_signs": [
      1,
      -1,
      1
    ],
    "original_writhe": 1,
    "transformed_signs": [
      1,
      -1,
      1
    ],
    "transformed_writhe": 1
  },
  "negative_control": {
    "values": {
      "over_tangents": [
        [
          1,
          0
        ],
        [
          0,
          1
        ],
        [
          1,
          1
        ]
      ],
      "under_tangents": [
        [
          0,
          1
        ],
        [
          1,
          0
        ],
        [
          -1,
          1
        ]
      ],
      "operation": "mirror"
    },
    "expected": {
      "original_signs": [
        1,
        -1,
        1
      ],
      "original_writhe": 1,
      "transformed_signs": [
        -1,
        1,
        -1
      ],
      "transformed_writhe": -1
    }
  }
}
```

### Exercise 1

Calculate the original determinants and signs.

<details><summary>Answer 1</summary>

Determinants are `[1,-1,2]`, giving signs `[1,-1,1]`. Magnitude does not weight the signed crossing sum.

</details>

### Exercise 2

Compute diagram writhe.

<details><summary>Answer 2</summary>

The result is `1`. Count each declared crossing once, rather than each traversal encounter with that crossing.

</details>

### Exercise 3

Reverse both tangents.

<details><summary>Answer 3</summary>

Signs remain `[1,-1,1]` and writhe `1`. Bilinearity gives the same determinant when both arguments are negated.

</details>

### Exercise 4

Apply the mirror control.

<details><summary>Answer 4</summary>

Signs become `[-1,1,-1]` and writhe `-1`. This flips planar orientation without changing the declared over/under referents.

</details>

### Exercise 5

May writhe certify knot type?

<details><summary>Answer 5</summary>

No. A Reidemeister-I curl changes diagram writhe while preserving ambient knot type. Equal sums also discard the crossing arrangement.

</details>

## Source-assisted task and direct baseline

Draw the oriented tangent pairs on paper and preserve the crossing labels during reversal and mirroring. Prepare a proposed knot-ornament caption that states exactly which diagram transformation the signed number tests.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

An annotation claiming that traversal reversal flips all crossing signs is refuted by the unchanged determinant products.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: sem-005-bind-scene-hits-to-crossing-identity](../../semiotics/en/sem-005-bind-scene-hits-to-crossing-identity.md)
- [Retained project source](../../../../code/streeling/weave-godot/trial.gd)
- [Primary reading](https://math.uchicago.edu/~dannyc/notes/knot_theory.pdf)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
