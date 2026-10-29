---
module_id: wml-021-find-common-partials-without-equating-fundamentals
department: world-music-languages
course: "Find Common Partials Without Equating Fundamentals"
level: advanced
prerequisites: ["wml-008-retain-register-in-drone-relative-intervals"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Find Common Partials Without Equating Fundamentals

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

Different fundamentals can share an exact partial in an ideal harmonic model. Construct both finite inventories with source indices before taking their intersection. A shared frequency is evidence of a shared modeled component, not proof that the notes are identical or that their relationship belongs to a named tradition. The upper partial bound matters: absence from a bounded list does not establish absence from the infinite series. This operation can make a [GA](https://github.com/GuitarAlchemist/ga) drone explanation explicit without discarding register or replacing acoustic coincidence with pitch-class equality.

## Specific assumptions and limits

Fundamentals are positive integers and partials are ideal harmonic multiples with a finite index cap. Equality is exact. No uncertainty, inharmonicity, consonance judgment or cultural interpretation is represented by the intersection.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short GA review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../world-music-languages/en/wml-008-retain-register-in-drone-relative-intervals.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Primary reading](https://www.phys.unsw.edu.au/jw/strings.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "fundamentals_hz": [
      100,
      150
    ],
    "max_partial": 4
  },
  "formula": "partials_i=[(n,n*f_i) for n=1..max_partial]; common=[(freq,n_left,n_right) where frequencies exactly equal]",
  "expected": {
    "common": [
      [
        300,
        3,
        2
      ]
    ]
  },
  "negative_control": {
    "values": {
      "fundamentals_hz": [
        100,
        151
      ],
      "max_partial": 4
    },
    "expected": {
      "common": []
    }
  }
}
```

### Exercise 1

Calculate the main result and name its convention.

> **Answer:** The common frequency is 300 with source indices 3 and 2; the fundamentals remain different.

### Exercise 2

Which quantity must remain separate?

> **Answer:** A shared partial is not a shared fundamental or equal pitch class; each claim has a different relation.

### Exercise 3

What assumption prevents a stronger conclusion?

> **Answer:** Finite search bounds and exact equality exclude later coincidences and near matches.

### Exercise 4

Explain the negative control.

> **Answer:** The 151 control has no common frequency inside the retained bound; that is not an infinite-series impossibility proof.

### Exercise 5

What observation would reject the proposed claim?

> **Answer:** A reported common partial lacking matching source indices in both inventories rejects the intersection report.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
