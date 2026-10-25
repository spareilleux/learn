---
module_id: "inf-020-separate-parity-detection-from-correction"
department: "information-theory"
course: "Separate Parity Detection from Correction"
title: "Separate Parity Detection from Correction"
level: "intermediate"
prerequisites: ["inf-014-retain-message-codebook-versions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Separate Parity Detection from Correction

> This is an authored mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An agent receives a compact evidence tag and observes that the record parses correctly. Parsing does not establish that the transmitted bits were preserved. The codebook lesson examines a different problem, where intact bits are interpreted under the wrong mapping. Here sender and receiver agree on meaning, and the channel changes selected bits before decoding.

Append a bit chosen to make the total number of set bits even. On reception, compute the same parity condition. Flipping one bit changes the total parity, so the checker detects a violated condition. It does not reveal which position changed. Multiple candidate original messages can satisfy the condition, so choosing a repair without extra information would be guessing.

The fixed input changes one data position. The control changes two positions and passes the parity check while carrying a different message. Keep both the syndrome and actual Hamming distance in the teaching record: the sender-side comparison knows which bits changed, whereas an ordinary receiver does not possess that reference. A zero syndrome means only that this check did not detect a violation.

The University of New Brunswick course states the single-error detection and even-error limitation. Our short codeword makes both boundaries inspectable by hand. It supplies neither a cryptographic digest nor a transport recommendation for Demerzel evidence. A production receipt needs identity, authorization and semantic revision binding as separate questions. Before adding a composable check stage, name its failure model and ensure its output says detection status rather than claiming a correct, trusted or repaired message.

## Sources and project boundary

The retained Learn helper separates metadata, title and body, and indexes English module identities. Inspect that representation when naming the artifact and its revision. It does not implement this lesson’s model or supply its invented inputs.

[Prerequisite: inf-014-retain-message-codebook-versions](../../information-theory/en/inf-014-retain-message-codebook-versions.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://www.ece.unb.ca/tervo/ece4253/ecc.shtml)

## Fixed model and negative control

```json
{
  "values": {
    "data": [
      1,
      0,
      1,
      1
    ],
    "flip_indices": [
      1
    ]
  },
  "formula": "Append p=sum(data)%2, giving even total parity. Flip each distinct zero-based index in codeword. syndrome=sum(received)%2; detected iff syndrome=1. hamming_distance counts changed bits; no correction attempted.",
  "expected": {
    "parity_bit": 1,
    "codeword": [
      1,
      0,
      1,
      1,
      1
    ],
    "received": [
      1,
      1,
      1,
      1,
      1
    ],
    "syndrome": 1,
    "detected": true,
    "hamming_distance": 1
  },
  "negative_control": {
    "values": {
      "data": [
        1,
        0,
        1,
        1
      ],
      "flip_indices": [
        1,
        2
      ]
    },
    "expected": {
      "parity_bit": 1,
      "codeword": [
        1,
        0,
        1,
        1,
        1
      ],
      "received": [
        1,
        1,
        0,
        1,
        1
      ],
      "syndrome": 0,
      "detected": false,
      "hamming_distance": 2
    },
    "why": "Two substitutions preserve even parity despite altering the message."
  },
  "input_types": {
    "data": "finite binary integer list",
    "flip_indices": "distinct valid zero-based codeword indices"
  },
  "assumptions": [
    "Known codeword boundary; only bit substitutions, no insertions or deletions.",
    "Receiver checks parity but has no additional information about error location."
  ],
  "limits": "This toy parity check is not a production integrity mechanism, semantic validation, authentication or error correction."
}
```

### Exercise 1

Encode the data with even parity.

<details><summary>Answer 1</summary>

The parity bit is `1`, and the complete codeword is `[1,0,1,1,1]`. Count the appended bit as part of the checked word, not as another data symbol.

</details>

### Exercise 2

Check the single substitution.

<details><summary>Answer 2</summary>

The received word is `[1,1,1,1,1]`, syndrome `1`, and detection `true`. Its Hamming distance from the reference is `1`; the syndrome alone does not name the position.

</details>

### Exercise 3

Apply the double-substitution control.

<details><summary>Answer 3</summary>

The received word is `[1,1,0,1,1]`, syndrome `0`, detection `false`, and Hamming distance `2`. A passing parity condition can accompany altered data.

</details>

### Exercise 4

Can the receiver correct a detected error?

<details><summary>Answer 4</summary>

Not from this syndrome alone. It does not identify the changed bit. Retain the refusal to guess a correction and request the information required by the actual channel protocol.

</details>

### Exercise 5

Does passing establish trusted evidence?

<details><summary>Answer 5</summary>

No. The check addresses a narrow corruption pattern. It establishes neither sender identity, revision meaning, authorization nor the truth of the encoded claim.

</details>

## Source-assisted learner task

Explain the exact claim of a proposed parity stage in an illustrative evidence handoff.

**Direct manual baseline:** Count bits and mark changed positions against the authored reference word manually.

**Falsifier:** A zero syndrome is reported as proof of unchanged or authenticated data.

Save a first answer before opening the solutions. Identify the input types, the comparison boundary and the quantity that the task asks you to preserve. Draw the smallest table or diagram that permits every intermediate result to be checked. Keep an unexpected result; editing the premises until a preferred conclusion appears would destroy the counterexample.

Read the linked prerequisite and the bounded primary passage. Record the source revision, the definition actually used and the assumptions you imported. The project artifact supplies a real representation to inspect, while the fixed model supplies invented inputs. Neither a document name nor an accessible URL establishes a production result. Explain what would need to be observed before using the calculation in an operational decision.

State the direct manual baseline and its falsifier before proposing a composable DSL or an agent abstraction. Ask an assistant to challenge your manual answer only after saving it. Retain the prompt, the reply, the source passage it cites and the correction you accept or reject. A shorter expression is useful only if it preserves the operation, the control and the refusal boundary. Compare it with a plain table first.

Submit the original answer, intermediate quantities, corrected answer and control together. Label source consultation and calculator use as assistance. A future dogfood comparison should use the same task version and retain failures as well as successes; otherwise changing the question can masquerade as improvement. The prepared criteria below remain undecided until a learner actually attempts the task. An answer key and an author check establish neither learning nor adoption.

## Prepared learner criteria

- Exercise 1: Encode the data with even parity. — Decision undecided.
- Exercise 2: Check the single substitution. — Decision undecided.
- Exercise 3: Apply the double-substitution control. — Decision undecided.
- Exercise 4: Can the receiver correct a detected error? — Decision undecided.
- Exercise 5: Does passing establish trusted evidence? — Decision undecided.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
