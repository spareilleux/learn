---
module_id: wml-020-audit-hocket-as-exclusive-voice-occupancy
department: world-music-languages
course: "Audit Hocket as Exclusive Voice Occupancy"
level: advanced
prerequisites: ["wml-019-distribute-onsets-with-a-floor-lattice"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Audit Hocket as Exclusive Voice Occupancy

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

A combined onset list can hide whether two voices alternate, collide or leave a gap. Retain voice identity and count occupancy at every declared pulse. The strict authored policy asks for exactly one occupied voice at each slot. It is a small hocket-style scheduling exercise, not a complete historical or cultural definition of hocket and not an evaluation of real performance. A [GA](https://github.com/GuitarAlchemist/ga) practice generator can use the occupancy witness before proposing expressive articulation or cultural attribution. Onset counts alone cannot preserve the voice allocation.

## Specific assumptions and limits

The grid is finite with unique integer slots inside each voice. Occupancy means instantaneous onset presence; sustained duration overlap is not inferred. The strict policy is authored and establishes no historical, cultural or expressive acceptance.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short GA review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../world-music-languages/en/wml-019-distribute-onsets-with-a-floor-lattice.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/voice/)

## Fixed case and prepared quantities

```json
{
  "values": {
    "slots": 4,
    "voices": {
      "A": [
        0,
        2
      ],
      "B": [
        1,
        3
      ]
    }
  },
  "formula": "occupancy[t]=number of voices containing t; collisions=slots with count>1; gaps=slots with count==0; exclusive_complete=all(count==1)",
  "expected": {
    "occupancy": [
      1,
      1,
      1,
      1
    ],
    "collisions": [],
    "gaps": [],
    "exclusive_complete": true
  },
  "negative_control": {
    "values": {
      "slots": 4,
      "voices": {
        "A": [
          0,
          2
        ],
        "B": [
          2,
          3
        ]
      }
    },
    "expected": {
      "occupancy": [
        1,
        0,
        2,
        1
      ],
      "collisions": [
        2
      ],
      "gaps": [
        1
      ],
      "exclusive_complete": false
    }
  }
}
```

### Exercise 1

Calculate the main result and name its convention.

> **Answer:** Occupancy is `[1,1,1,1]`; the main grid is both exclusive and complete.

### Exercise 2

Which quantity must remain separate?

> **Answer:** Voice allocation differs from the flattened event count; retain the voice key for every onset.

### Exercise 3

What assumption prevents a stronger conclusion?

> **Answer:** Instantaneous slot occupancy does not imply nonoverlap of sustained notes; durations need another rule.

### Exercise 4

Explain the negative control.

> **Answer:** The control collides at 2 and leaves a gap at 1, despite the same total event count.

### Exercise 5

What observation would reject the proposed claim?

> **Answer:** Any declared slot with count other than unity rejects the strict exclusive-complete policy.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
