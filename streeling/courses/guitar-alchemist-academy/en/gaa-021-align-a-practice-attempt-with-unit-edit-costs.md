---
module_id: "gaa-021-align-a-practice-attempt-with-unit-edit-costs"
department: "guitar-alchemist-academy"
course: "Align a Practice Attempt with Unit Edit Costs"
level: "advanced"
prerequisites: ["gaa-019-retrieve-overlapping-interval-motifs"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Align a Practice Attempt with Unit Edit Costs

> Draft for technical and fluent-language review. All numerical inputs and expected outputs are authored cases. No new material trial, native scene run, learner observation or production outcome is supplied. Human and learner decisions remain undecided.

## Project operation and interpretation

A guitar learner inserts a note before an otherwise correct phrase. Position-by-position comparison turns the insertion into several apparent errors. Declare unit insertion, deletion and substitution costs, then compute the finite Levenshtein table. This permits a minimal alignment score without confusing it with exact contiguous motif retrieval. The score has no timing, fingering or expressive dimension. Equal-cost alignments can exist; unless a tie policy is declared, retain the distance without inventing a uniquely diagnosed sequence of mistakes.

Read the committed prerequisite and the bounded source passage before calculating. Identify the exact operation that the project needs, the meaning of its inputs and the claim that the result could support. The source record retains its revision and inspected scope. A documentation definition, an authored assumption and an observed outcome belong in separate columns. Do not let an assistant replace an absent observation with a plausible story about what the software probably does.

Keep the representation explicit. The JSON below is a finite mathematical specification, not executable project syntax or a new engine feature. Its field names and fixed identity order form part of the teaching case. Read the formula together with the values; a correct-looking number obtained under another interpretation does not answer this task. Preserve intermediate quantities and the changed-input case so a reviewer can locate the first disagreement. The assumptions are deliberately narrow, and extending the domain requires a new justification rather than another confident caption.

## Fixed model and changed-input control

```json
{
  "values": {
    "target": [
      60,
      62,
      64
    ],
    "attempt": [
      60,
      61,
      62,
      64
    ]
  },
  "formula": "D[i,0]=i; D[0,j]=j; D[i,j]=min(D[i-1,j]+1,D[i,j-1]+1,D[i-1,j-1]+(target[i-1]!=attempt[j-1])); distance=D[len(target),len(attempt)]",
  "expected": {
    "table": [
      [
        0,
        1,
        2,
        3,
        4
      ],
      [
        1,
        0,
        1,
        2,
        3
      ],
      [
        2,
        1,
        1,
        1,
        2
      ],
      [
        3,
        2,
        2,
        2,
        1
      ]
    ],
    "distance": 1
  },
  "negative_control": {
    "values": {
      "target": [
        60,
        62,
        64
      ],
      "attempt": [
        64,
        62,
        60
      ]
    },
    "expected": {
      "table": [
        [
          0,
          1,
          2,
          3
        ],
        [
          1,
          1,
          2,
          2
        ],
        [
          2,
          2,
          1,
          2
        ],
        [
          3,
          2,
          2,
          2
        ]
      ],
      "distance": 2
    }
  }
}
```

### Exercise 1

Identify the inputs and the operation that must be preserved.

<details><summary>Answer 1</summary>

> **Answer:** Rows index target prefixes and columns index attempt prefixes; empty prefixes supply the boundary.

</details>

### Exercise 2

Find the main edit distance and give a sequence edit witnessing that cost.

<details><summary>Answer 2</summary>

> **Answer:** The lower-right distance is `1`; removing the inserted pitch `61` is a witness.

</details>

### Exercise 3

Explain the interpretation trap that a summary could conceal.

<details><summary>Answer 3</summary>

> **Answer:** The score depends on ordered symbols, not only pitch-class membership.

</details>

### Exercise 4

Apply the changed-input control and compare the result.

<details><summary>Answer 4</summary>

> **Answer:** The reversed control has distance `2`; a matching pitch set does not imply a matching phrase.

</details>

### Exercise 5

State the limit and the evidence needed before project adoption.

<details><summary>Answer 5</summary>

> **Answer:** The table cannot attribute an error to motor skill, listening or attention without observations.

</details>

## Source-assisted task and direct manual baseline

Fill the phrase-prefix alignment table by hand before proposing feedback on an inserted practice note.

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

- [Committed prerequisite: gaa-019-retrieve-overlapping-interval-motifs](../../guitar-alchemist-academy/en/gaa-019-retrieve-overlapping-interval-motifs.md)
- [Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)
- [Primary reading](https://docs.python.org/3/library/math.html)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
