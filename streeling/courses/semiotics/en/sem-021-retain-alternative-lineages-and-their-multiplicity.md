---
module_id: "sem-021-retain-alternative-lineages-and-their-multiplicity"
department: "semiotics"
course: "Retain Alternative Lineages and Their Multiplicity"
level: "advanced"
prerequisites: ["sem-003-status-signs-and-evidence"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Retain Alternative Lineages and Their Multiplicity

> Draft for technical and fluent-language review. All numerical inputs and expected outputs are authored cases. No new material trial, native scene run, learner observation or production outcome is supplied. Human and learner decisions remain undecided.

## Project operation and interpretation

A proposed craft evidence node merges alternative derivations into a set of source names. That set loses conjunction and repeated ways to produce an output. Represent each alternative derivation as a product of source tokens, then sum alternatives without idempotently discarding repeated products. Collect equal monomials with natural-number coefficients. This polynomial records how the authored derivations use sources, not their reliability. W3C PROV supplies provenance background rather than defining this algebra; the primary semiring paper supplies the symbolic interpretation. Repeated derivations do not become independent witnesses.

Read the committed prerequisite and the bounded source passage before calculating. Identify the exact operation that the project needs, the meaning of its inputs and the claim that the result could support. The source record retains its revision and inspected scope. A documentation definition, an authored assumption and an observed outcome belong in separate columns. Do not let an assistant replace an absent observation with a plausible story about what the software probably does.

Keep the representation explicit. The JSON below is a finite mathematical specification, not executable project syntax or a new engine feature. Its field names and fixed identity order form part of the teaching case. Read the formula together with the values; a correct-looking number obtained under another interpretation does not answer this task. Preserve intermediate quantities and the changed-input case so a reviewer can locate the first disagreement. The assumptions are deliberately narrow, and extending the domain requires a new justification rather than another confident caption.

## Fixed model and changed-input control

```json
{
  "values": {
    "derivations": [
      [
        "a",
        "b"
      ],
      [
        "a",
        "b"
      ],
      [
        "c"
      ]
    ],
    "valuation": {
      "a": 1,
      "b": 1,
      "c": 0
    }
  },
  "formula": "sort tokens inside products; collect equal monomials with integer multiplicity; evaluate sum over products of supplied token values; do not erase repeated derivations",
  "expected": {
    "coefficients": {
      "a*b": 2,
      "c": 1
    },
    "evaluated_multiplicity": 2
  },
  "negative_control": {
    "values": {
      "derivations": [
        [
          "a",
          "b"
        ],
        [
          "c"
        ]
      ],
      "valuation": {
        "a": 1,
        "b": 1,
        "c": 0
      }
    },
    "expected": {
      "coefficients": {
        "a*b": 1,
        "c": 1
      },
      "evaluated_multiplicity": 1
    }
  }
}
```

### Exercise 1

Identify the inputs and the operation that must be preserved.

<details><summary>Answer 1</summary>

> **Answer:** Tokens denote source occurrences in a declared algebra, not trusted probabilities.

</details>

### Exercise 2

Collect the main polynomial and evaluate its multiplicity.

<details><summary>Answer 2</summary>

> **Answer:** The collected polynomial is `2*a*b+c` and its evaluated multiplicity is `2`.

</details>

### Exercise 3

Explain the interpretation trap that a summary could conceal.

<details><summary>Answer 3</summary>

> **Answer:** A set `[a,b,c]` loses joint versus alternative use and repeated derivations.

</details>

### Exercise 4

Apply the changed-input control and compare the result.

<details><summary>Answer 4</summary>

> **Answer:** The control polynomial is `a*b+c` and evaluates to `1`; source-name membership is unchanged.

</details>

### Exercise 5

State the limit and the evidence needed before project adoption.

<details><summary>Answer 5</summary>

> **Answer:** The algebra supplies neither independent corroboration nor a deployed lineage implementation.

</details>

## Source-assisted task and direct manual baseline

Draw alternative derivation paths for a proposed craft evidence handoff, retaining repeated paths before collecting monomials.

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

- [Committed prerequisite: sem-003-status-signs-and-evidence](../../semiotics/en/sem-003-status-signs-and-evidence.md)
- [Retained project artifact](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Primary reading](https://www.cs.ucdavis.edu/~green/papers/pods07.pdf)
- [W3C PROV](https://www.w3.org/TR/prov-dm/)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
