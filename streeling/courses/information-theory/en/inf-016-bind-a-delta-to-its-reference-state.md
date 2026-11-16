---
module_id: "inf-016-bind-a-delta-to-its-reference-state"
department: "information-theory"
course: "Bind a Delta to Its Reference State"
level: "intermediate"
prerequisites: ["inf-011-separate-compressed-size-from-preserved-information", "inf-014-retain-message-codebook-versions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Bind a Delta to Its Reference State

> This lesson uses authored fixed inputs and inspected source passages. The numbers, histories and labels are teaching constructions. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An agent sends only the change in a Learn counter to shorten its handoff. The receiver adds the intact change to its own counter and obtains the wrong total. Both sides can agree on the operation while disagreeing on the starting state. Reversible encoding is conditional on the reference, not on the delta alone.

RFC 3284 distinguishes differencing a target relative to a source from compression without source data. We use integer subtraction as a tiny authored analogy, not its wire format. Calculate the sender’s delta once, then apply it to each receiver state. Do not recompute it from the receiver after seeing the desired target.

A trusted immutable base identifier makes the reconstruction precondition explicit. The guard rejects another base rather than pretending an arithmetically valid sum is the intended state. Identity itself still needs an integrity and provenance contract in a real system. A hash label without checked bytes would not establish that premise. This course proposes a handoff check, without creating a synchronization protocol or transport guarantee.

## Sources and project boundary

The retained Learn helper separates frontmatter, heading and body in `parseModule`, and indexes English module names in `englishModuleKeys`. Those inspected representations let a task name its source and metadata; they do not implement the authored operation. The retained practice record instead distinguishes retrieval metrics from learner evidence. Inspect the particular file linked below and retain only the observation it actually supports. No model input in this lesson was estimated from that file.

[Prerequisite: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/en/inf-011-separate-compressed-size-from-preserved-information.md)

[Prerequisite: inf-014-retain-message-codebook-versions](../../information-theory/en/inf-014-retain-message-codebook-versions.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading](https://www.rfc-editor.org/rfc/rfc3284.html)

## Fixed model and control

```json
{
  "values": {
    "sender_base_id": "b1",
    "sender_base": 10,
    "target": 13,
    "receiver_base_id": "b1",
    "receiver_base": 10
  },
  "formula": "delta=target-sender_base; naive=receiver_base+delta; accept iff receiver_base_id==sender_base_id; guarded reconstruction is naive if accepted else null.",
  "expected": {
    "delta": 3,
    "naive_reconstruction": 13,
    "accepted": true,
    "guarded_reconstruction": 13
  },
  "negative_control": {
    "values": {
      "sender_base_id": "b1",
      "sender_base": 10,
      "target": 13,
      "receiver_base_id": "b2",
      "receiver_base": 20
    },
    "expected": {
      "delta": 3,
      "naive_reconstruction": 23,
      "accepted": false,
      "guarded_reconstruction": null
    },
    "why": "An intact delta added to another base produces another value; a base-identity guard rejects it."
  },
  "assumptions": [
    "Integers exact; each trusted base identity denotes one immutable value.",
    "No overflow, missing delta or transport corruption."
  ],
  "limits": "Toy scalar differencing, not VCDIFF encoding, authentic identity or production synchronization.",
  "input_types": {
    "sender_base_id": "string",
    "sender_base": "integer",
    "target": "integer",
    "receiver_base_id": "string",
    "receiver_base": "integer"
  }
}
```

### Exercise 1

Compute the sender’s delta.

<details><summary>Answer 1</summary>

`13-10=3`. The delta describes a relation to the sender’s base; it is not the target value by itself.

</details>

### Exercise 2

Reconstruct the matching-base case.

<details><summary>Answer 2</summary>

`10+3=13`; base identifiers match, so `accepted=true` and the guarded reconstruction is `13`.

</details>

### Exercise 3

Apply the mismatched-base control.

<details><summary>Answer 3</summary>

Naive addition gives `20+3=23`, but `accepted=false` and guarded reconstruction is `null`. The changed base is retained as the reason.

</details>

### Exercise 4

Would a checksum of the delta catch this mistake?

<details><summary>Answer 4</summary>

No. The delta can arrive intact while the reference differs. Retain base identity and validate its associated state.

</details>

### Exercise 5

Is base equality the same as authorization to update?

<details><summary>Answer 5</summary>

No. This arithmetic precondition supplies neither authority nor an atomic update. Those need separate evidence and contracts.

</details>

## Source-assisted learner task

Prepare a reference-state card for fictional Learn counter handoffs and challenge an assistant with the wrong base.

**Direct manual baseline:** Subtract the sender base, then add the unchanged delta to each stated receiver base.

**Falsifier:** A mismatched base produces an accepted target or the delta is silently recomputed at the receiver.

Save a first answer before opening the corrected exercises. Copy the input identities and units, write the intermediate quantities, and distinguish the calculation from the interpretation. A correct number with the wrong denominator, state boundary or counting unit does not meet the task. Retain a surprising intermediate result rather than changing the input to make the final answer look plausible.

Read the cited primary passage within the scope recorded in the packet. Compare its actual definition with the authored rule in the fixed model. The reference may motivate a concept without specifying our entire model. Record the version or date, the passage used and the exact assumption you imported. An accessible page or a successful file read is not evidence that a claim has been verified.

Inspect the retained project artifact and one prerequisite. Separate what the file actually represents from what this new task hypothesizes. Preserve source revision and assistance history. Ask an assistant to challenge an assumption only after saving the manual baseline, then keep its prompt, reply, accepted correction and rejected suggestion. Source lookup and calculator use are permitted assistance, not unaided recall.

Run the changed input through the same reasoning on paper. State the falsifier before proposing an agent abstraction or a composable DSL expression. If an abstraction drops the counterexample or changes the accepted endpoint, it fails this task even if its response is shorter. Compare a direct table or typed record first; no new language or production engine is required.

Submit original and corrected answers together with the control result, source passage and remaining uncertainty. The packet prepares a separate criterion for each exercise, with every learner decision undecided. An answer key, a byte hash and an author self-check are different evidence from an actual learner attempt. A future dogfood comparison must retain actual attempts on the same versioned task and the direct baseline before claiming a useful change.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
