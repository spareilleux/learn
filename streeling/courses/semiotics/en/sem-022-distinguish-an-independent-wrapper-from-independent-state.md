---
module_id: "sem-022-distinguish-an-independent-wrapper-from-independent-state"
department: "semiotics"
course: "Distinguish an Independent Wrapper from Independent State"
level: "advanced"
prerequisites: ["sem-014-declare-material-patch-precedence", "cs-019-preserve-lexical-bindings-when-composing-fragments"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguish an Independent Wrapper from Independent State

> Draft for technical and fluent-language review. All numerical inputs and expected outputs are authored cases. No new material trial, native scene run, learner observation or production outcome is supplied. Human and learner decisions remain undecided.

## Project operation and interpretation

A proposed material patch node copies a container and assumes later edits are isolated. A new outer wrapper can still refer to the same nested mutable state. Draw the object graph before mutation, distinguish wrapper identity from child identity and compare a shallow copy with a recursive copy of this simple list-only structure. This concerns heap aliasing, not lexical variable capture, field precedence or [Godot](https://docs.godotengine.org/en/stable/classes/class_transform3d.html) resource duplication. No scene object was copied. Intentional sharing, cycles and host-specific copy hooks need additional contracts beyond this example.

Read the committed prerequisite and the bounded source passage before calculating. Identify the exact operation that the project needs, the meaning of its inputs and the claim that the result could support. The source record retains its revision and inspected scope. A documentation definition, an authored assumption and an observed outcome belong in separate columns. Do not let an assistant replace an absent observation with a plausible story about what the software probably does.

Keep the representation explicit. The JSON below is a finite mathematical specification, not executable project syntax or a new engine feature. Its field names and fixed identity order form part of the teaching case. Read the formula together with the values; a correct-looking number obtained under another interpretation does not answer this task. Preserve intermediate quantities and the changed-input case so a reviewer can locate the first disagreement. The assumptions are deliberately narrow, and extending the domain requires a new justification rather than another confident caption.

## Fixed model and changed-input control

```json
{
  "values": {
    "original": [
      [
        1,
        2
      ],
      [
        3
      ]
    ],
    "copy_mode": "shallow",
    "mutation": {
      "row": 0,
      "column": 0,
      "value": 9
    }
  },
  "formula": "copy outer list; shallow retains child references, deep recursively copies list children; mutate copied child at supplied row/column; compare original and copy after mutation",
  "expected": {
    "original_after": [
      [
        9,
        2
      ],
      [
        3
      ]
    ],
    "copy_after": [
      [
        9,
        2
      ],
      [
        3
      ]
    ],
    "same_outer": false,
    "same_first_child": true
  },
  "negative_control": {
    "values": {
      "original": [
        [
          1,
          2
        ],
        [
          3
        ]
      ],
      "copy_mode": "deep",
      "mutation": {
        "row": 0,
        "column": 0,
        "value": 9
      }
    },
    "expected": {
      "original_after": [
        [
          1,
          2
        ],
        [
          3
        ]
      ],
      "copy_after": [
        [
          9,
          2
        ],
        [
          3
        ]
      ],
      "same_outer": false,
      "same_first_child": false
    }
  }
}
```

### Exercise 1

Identify the inputs and the operation that must be preserved.

<details><summary>Answer 1</summary>

> **Answer:** Wrapper identity and nested child identity are different questions.

</details>

### Exercise 2

Determine the original and copied values after the shallow-copy edit.

<details><summary>Answer 2</summary>

> **Answer:** The shallow case changes both values to `[[9,2],[3]]` because the first child is shared.

</details>

### Exercise 3

Explain the interpretation trap that a summary could conceal.

<details><summary>Answer 3</summary>

> **Answer:** `same_outer` is `false` but `same_first_child` is `true`; new wrappers do not prove isolation.

</details>

### Exercise 4

Apply the changed-input control and compare the result.

<details><summary>Answer 4</summary>

> **Answer:** The deep control retains original `[[1,2],[3]]` and changes only the copy to `[[9,2],[3]]`.

</details>

### Exercise 5

State the limit and the evidence needed before project adoption.

<details><summary>Answer 5</summary>

> **Answer:** Other object types and intended sharing require a separate copy contract.

</details>

## Source-assisted task and direct manual baseline

Draw an object-identity diagram for a proposed Atlas material patch before and after a copied-child mutation.

With the answers hidden, draw an operation-specific table or diagram and calculate the main result by hand. This saved first attempt is the direct manual baseline. Include the inputs, the intermediate quantities, the rule used at each step and the reason for any refusal or unresolved value. State the prospective falsifier before asking an assistant to simplify the work. A plain table may already meet the project need; a composable DSL or an agent node needs evidence of an additional benefit.

Then inspect the linked local artifact and primary passage. Record the source location, its revision, the definition actually used and the boundary it does not establish. Ask an assistant to challenge one assumption, retaining the prompt and response. Mark any calculator, translation aid or source lookup as assistance. Compare the assisted result with the original baseline on identical inputs. Reject a shorter explanation if it removes an input identity, a condition or the distinction between an invented example and a project observation.

Treat the negative control as a separate record. Predict its result before opening its correction, then compare which fields changed and which remained invariant. If the answer disagrees, distinguish arithmetic error, semantic error and a limitation of the premises. Retain the failed attempt, diagnosis, correction and replay instead of overwriting the failure. Submit those records with the source-assisted explanation and the remaining uncertainty. This is the small improvement loop that can later support dogfooding; no improvement in a real learner or runtime has been measured here.

The packet prepares a criterion for every exercise, with no learner decisions filled in. Actual learner answer, assistance history, corrected answer and learner decision remain empty until an attempt exists. Technical review, fluent-language review, engine execution, material validation, production adoption and publication have separate evidence requirements. A finite calculation can establish only its declared relation under the stated assumptions. Before using it in a scene or practice product, name the additional observation and its rejection threshold; do not convert a prepared answer key into acceptance.

## Prospective falsifier

A proposed answer is rejected if applying the displayed operation to either retained input yields a result inconsistent with the fixed expected record, or if its explanation presents that record as a completed project observation.

## Prepared learner criteria

- Retain the correct answer and its intermediate reasoning for exercise 1; preserve the claim boundary. Learner decision remains undecided.
- Retain the correct answer and its intermediate reasoning for exercise 2; preserve the claim boundary. Learner decision remains undecided.
- Retain the correct answer and its intermediate reasoning for exercise 3; preserve the claim boundary. Learner decision remains undecided.
- Retain the correct answer and its intermediate reasoning for exercise 4; preserve the claim boundary. Learner decision remains undecided.
- Retain the correct answer and its intermediate reasoning for exercise 5; preserve the claim boundary. Learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: sem-014-declare-material-patch-precedence](../../semiotics/en/sem-014-declare-material-patch-precedence.md)
- [Committed prerequisite: cs-019-preserve-lexical-bindings-when-composing-fragments](../../computer-science/en/cs-019-preserve-lexical-bindings-when-composing-fragments.md)
- [Retained project artifact](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://docs.python.org/3/library/copy.html)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
