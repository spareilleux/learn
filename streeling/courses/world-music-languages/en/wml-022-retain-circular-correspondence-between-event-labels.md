---
module_id: wml-022-retain-circular-correspondence-between-event-labels
department: world-music-languages
course: "Retain Circular Correspondence Between Event Labels"
level: advanced
prerequisites: ["wml-006-preserve-the-origin-of-an-additive-cycle"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Retain Circular Correspondence Between Event Labels

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

A cyclic phrase can be presented from another starting event without changing its circular label order. Compare all cyclic shifts and retain every valid correspondence. Repeated labels may admit several shifts, so an arbitrary first match invents an anchor. A reversal changes order and is not automatically equivalent to a rotation. This is a finite label-sequence policy for [GA](https://github.com/GuitarAlchemist/ga) practice handoffs. It does not identify a musical tradition, infer actual timing or prove that differently accented phrases are equivalent.

## Specific assumptions and limits

Use equal nonempty label sequences, exact label equality and the displayed directed shift convention. Reversal is a separate operation. Accent and timing are not encoded, so circular equality supplies no performance-equivalence judgment.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short GA review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../world-music-languages/en/wml-006-preserve-the-origin-of-an-additive-cycle.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Fixed case and prepared quantities

```json
{
  "values": {
    "source": [
      "a",
      "b",
      "c",
      "d"
    ],
    "target": [
      "c",
      "d",
      "a",
      "b"
    ]
  },
  "formula": "shifts=[s in range(N) where target[i]==source[(i+s)%N] for every i]; unique=len(shifts)==1",
  "expected": {
    "shifts": [
      2
    ],
    "unique": true
  },
  "negative_control": {
    "values": {
      "source": [
        "a",
        "b",
        "a",
        "b"
      ],
      "target": [
        "a",
        "b",
        "a",
        "b"
      ]
    },
    "expected": {
      "shifts": [
        0,
        2
      ],
      "unique": false
    }
  }
}
```

### Exercise 1

Calculate the main result and name its convention.

> **Answer:** The unique shift is 2 under the declared target-to-source indexing direction.

### Exercise 2

Which quantity must remain separate?

> **Answer:** Circular equivalence and unique anchoring differ; equivalence can hold with several valid shifts.

### Exercise 3

What assumption prevents a stronger conclusion?

> **Answer:** The labels alone omit accent and duration; circular order does not preserve unrecorded musical properties.

### Exercise 4

Explain the negative control.

> **Answer:** The repeated control returns `[0,2]`, so selecting one correspondence would invent a unique origin.

### Exercise 5

What observation would reject the proposed claim?

> **Answer:** More than one valid shift rejects a unique-anchor claim even when circular equivalence holds.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
