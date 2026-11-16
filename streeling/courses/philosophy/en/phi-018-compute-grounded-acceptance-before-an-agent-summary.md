---
module_id: "phi-018-compute-grounded-acceptance-before-an-agent-summary"
department: "philosophy"
course: "Compute Grounded Acceptance before an Agent Summary"
level: "advanced"
prerequisites: ["phi-001-how-to-argue-well", "phi-008-separate-a-test-oracle-from-a-specification"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Compute Grounded Acceptance before an Agent Summary

> Draft for technical and fluent-language review. All numerical inputs and expected outputs are authored cases. No new material trial, native scene run, learner observation or production outcome is supplied. Human and learner decisions remain undecided.

## Project operation and interpretation

A proposed agent debate contains arguments and directed attacks, yet its summary counts supporters. Compute defense instead: a set defends an argument when it attacks every attacker of that argument. Starting with the empty set, repeatedly collect defended arguments until the finite fixed point is reached. This grounded extension depends on the supplied graph, not vote counts or confidence. The attack graph is authored; acceptance within it cannot verify argument content, source credibility, missing attacks or permission to act. Cyclic disagreement can remain unresolved without making every argument false.

Read the committed prerequisite and the bounded source passage before calculating. Identify the exact operation that the project needs, the meaning of its inputs and the claim that the result could support. The source record retains its revision and inspected scope. A documentation definition, an authored assumption and an observed outcome belong in separate columns. Do not let an assistant replace an absent observation with a plausible story about what the software probably does.

Keep the representation explicit. The JSON below is a finite mathematical specification, not executable project syntax or a new engine feature. Its field names and fixed identity order form part of the teaching case. Read the formula together with the values; a correct-looking number obtained under another interpretation does not answer this task. Preserve intermediate quantities and the changed-input case so a reviewer can locate the first disagreement. The assumptions are deliberately narrow, and extending the domain requires a new justification rather than another confident caption.

## Fixed model and changed-input control

```json
{
  "values": {
    "arguments": [
      "A",
      "B",
      "C"
    ],
    "attacks": [
      [
        "A",
        "B"
      ],
      [
        "B",
        "C"
      ]
    ]
  },
  "formula": "F(S)={a: every b attacking a is attacked by some s in S}; iterate S0=empty,S_next=F(S) until equality; out={a attacked by grounded}; undecided=remaining arguments",
  "expected": {
    "iterations": [
      [],
      [
        "A"
      ],
      [
        "A",
        "C"
      ],
      [
        "A",
        "C"
      ]
    ],
    "grounded": [
      "A",
      "C"
    ],
    "out": [
      "B"
    ],
    "undecided": []
  },
  "negative_control": {
    "values": {
      "arguments": [
        "A",
        "B",
        "C"
      ],
      "attacks": [
        [
          "A",
          "B"
        ],
        [
          "B",
          "C"
        ],
        [
          "C",
          "A"
        ]
      ]
    },
    "expected": {
      "iterations": [
        [],
        []
      ],
      "grounded": [],
      "out": [],
      "undecided": [
        "A",
        "B",
        "C"
      ]
    }
  }
}
```

### Exercise 1

Identify the inputs and the operation that must be preserved.

<details><summary>Answer 1</summary>

> **Answer:** An attack is directed; defense requires counterattacking every attacker.

</details>

### Exercise 2

List the defense iterations and their grounded fixed point.

<details><summary>Answer 2</summary>

> **Answer:** Iteration gives `[[],[A],[A,C],[A,C]]`, with grounded set `[A,C]`.

</details>

### Exercise 3

Explain the interpretation trap that a summary could conceal.

<details><summary>Answer 3</summary>

> **Answer:** The out set `[B]` records attacks from accepted arguments, not proof that a source statement is false.

</details>

### Exercise 4

Apply the changed-input control and compare the result.

<details><summary>Answer 4</summary>

> **Answer:** The control has empty grounded and out sets; `[A,B,C]` remain undecided.

</details>

### Exercise 5

State the limit and the evidence needed before project adoption.

<details><summary>Answer 5</summary>

> **Answer:** Actual content, attack completeness and authority require separate review before adoption.

</details>

## Source-assisted task and direct manual baseline

Draw the proposed agent attack graph and each defense-operator iterate beside the retained advisory evidence boundary.

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

- [Committed prerequisite: phi-001-how-to-argue-well](../../philosophy/en/phi-001-how-to-argue-well.md)
- [Committed prerequisite: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)
- [Retained project artifact](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Primary reading](https://cse-robotics.engr.tamu.edu/dshell/cs631/papers/dung95acceptability.pdf)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
