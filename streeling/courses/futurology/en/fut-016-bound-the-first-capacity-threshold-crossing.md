---
module_id: "fut-016-bound-the-first-capacity-threshold-crossing"
department: "futurology"
course: "Bound the First Capacity Threshold Crossing"
level: "advanced"
prerequisites: ["fut-010-project-weave-density-before-a-scene-expansion"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Bound the First Capacity Threshold Crossing

> Draft for technical and fluent-language review. All numerical inputs and expected outputs are authored cases. No new material trial, native scene run, learner observation or production outcome is supplied. Human and learner decisions remain undecided.

## Project operation and interpretation

A proposed embroidery scene grows its crossing inventory each planning period. A single date hides uncertainty in that growth premise. Evaluate both stipulated growth endpoints on the same discrete horizon and find the first period at or above capacity. The faster path gives the earliest crossing and the slower path the latest only because every positive-period value is monotone in the growth factor. A missing crossing stays absent; do not extrapolate beyond the declared horizon or label these bounds as confidence limits.

Read the committed prerequisite and the bounded source passage before calculating. Identify the exact operation that the project needs, the meaning of its inputs and the claim that the result could support. The source record retains its revision and inspected scope. A documentation definition, an authored assumption and an observed outcome belong in separate columns. Do not let an assistant replace an absent observation with a plausible story about what the software probably does.

Keep the representation explicit. The JSON below is a finite mathematical specification, not executable project syntax or a new engine feature. Its field names and fixed identity order form part of the teaching case. Read the formula together with the values; a correct-looking number obtained under another interpretation does not answer this task. Preserve intermediate quantities and the changed-input case so a reviewer can locate the first disagreement. The assumptions are deliberately narrow, and extending the domain requires a new justification rather than another confident caption.

## Fixed model and changed-input control

```json
{
  "values": {
    "initial": 8,
    "growth_bounds": [
      1.25,
      1.5
    ],
    "capacity": 18,
    "last_period": 4
  },
  "formula": "load[t]=initial*growth**t for integer t in [0,last_period]; crossing=min(t with load[t]>=capacity), or null; earliest=min(non-null crossings); latest=max(crossings) only if all cross",
  "expected": {
    "paths": [
      [
        8,
        10,
        12.5,
        15.625,
        19.53125
      ],
      [
        8,
        12,
        18,
        27,
        40.5
      ]
    ],
    "crossings": [
      4,
      2
    ],
    "earliest": 2,
    "latest": 4
  },
  "negative_control": {
    "values": {
      "initial": 8,
      "growth_bounds": [
        1.25,
        1.5
      ],
      "capacity": 50,
      "last_period": 4
    },
    "expected": {
      "paths": [
        [
          8,
          10,
          12.5,
          15.625,
          19.53125
        ],
        [
          8,
          12,
          18,
          27,
          40.5
        ]
      ],
      "crossings": [
        null,
        null
      ],
      "earliest": null,
      "latest": null
    }
  }
}
```

### Exercise 1

Identify the inputs and the operation that must be preserved.

<details><summary>Answer 1</summary>

> **Answer:** The ordered factors are `1.25` and `1.5`; the horizon includes period `0`.

</details>

### Exercise 2

Find both first-crossing periods and the bounded crossing window.

<details><summary>Answer 2</summary>

> **Answer:** The first crossings are `[4,2]`, so the bounded crossing window is `[2,4]`. Equality with capacity counts.

</details>

### Exercise 3

Explain the interpretation trap that a summary could conceal.

<details><summary>Answer 3</summary>

> **Answer:** Growth bounds are premises, not observed frequencies or a confidence interval.

</details>

### Exercise 4

Apply the changed-input control and compare the result.

<details><summary>Answer 4</summary>

> **Answer:** At capacity `50`, both crossings are `null`; neither path reaches it through period `4`.

</details>

### Exercise 5

State the limit and the evidence needed before project adoption.

<details><summary>Answer 5</summary>

> **Answer:** Measure workload and calibrated growth before adopting a date; inventory is not render time.

</details>

## Source-assisted task and direct manual baseline

Tabulate both proposed Atlas inventory paths and mark the first capacity crossing inside the retained horizon.

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

- [Committed prerequisite: fut-010-project-weave-density-before-a-scene-expansion](../../futurology/en/fut-010-project-weave-density-before-a-scene-expansion.md)
- [Retained project artifact](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://docs.python.org/3/library/math.html)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
