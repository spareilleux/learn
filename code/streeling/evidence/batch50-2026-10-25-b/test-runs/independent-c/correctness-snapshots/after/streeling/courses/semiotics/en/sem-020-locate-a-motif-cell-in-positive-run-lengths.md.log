---
module_id: "sem-020-locate-a-motif-cell-in-positive-run-lengths"
department: "semiotics"
course: "Locate a Motif Cell in Positive Run Lengths"
level: "advanced"
prerequisites: ["sem-013-align-two-motif-periods-at-a-textile-seam", "inf-011-separate-compressed-size-from-preserved-information"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Locate a Motif Cell in Positive Run Lengths

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

An embroidered border repeats a motif stored as runs rather than one symbol per cell. Treating a run index as a cell index changes what an address refers to: a long warp run spans several cells, while the following weft run may span only one. The operation locates a global cell by reducing its phase-adjusted address into the period and searching cumulative run ends. It is a paper meaning contract, not a production parser or new compression format.

Validate lengths before computing the period. Each length must be a positive integer, so the cumulative ends strictly increase. A cell belongs to the first end strictly greater than its reduced offset; equality with an end belongs to the next run. This preserves half-open ownership at internal boundaries without confusing it with negative-tile floor indexing. Modulo handles repetition after the period, while the run search handles the unequal internal regions.

The zero-run control asks for refusal, not a guessed motif repair. Changing the valid main run length from one to zero would reduce its length sum from `6` to `5` if accepted. Deleting that zero-length record does not further change the sum or expanded symbols; it erases the malformed instruction and its provenance. The declared positive-length contract therefore rejects the input before assigning it a period. A future IX craft-to-scene handoff may keep two adjacent identical-symbol runs if they have different provenance; merging them should be an explicit rewrite with an appropriate correspondence. An assistant can explain or propose that rewrite, but cannot declare the malformed input accepted merely because a preview still looks striped.

The committed compression prerequisite already teaches run expansion and stored-size accounting. Our new operation is indexed cell lookup with phase and internal-boundary ownership; it makes no new compression or round-trip claim.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "runs": [
      [
        "warp",
        2
      ],
      [
        "weft",
        1
      ],
      [
        "warp",
        3
      ]
    ],
    "indices": [
      0,
      2,
      5,
      6,
      8
    ],
    "phase": 0
  },
  "formula": "reject any run length <=0 or non-integer; period=sum(lengths); offset=(index+phase)%period; choose first cumulative end strictly greater than offset",
  "expected": {
    "status": "valid",
    "period": 6,
    "samples": [
      "warp",
      "weft",
      "warp",
      "warp",
      "weft"
    ]
  },
  "negative_control": {
    "values": {
      "runs": [
        [
          "warp",
          2
        ],
        [
          "weft",
          0
        ],
        [
          "warp",
          3
        ]
      ],
      "indices": [
        0,
        2,
        5,
        6,
        8
      ],
      "phase": 0
    },
    "expected": {
      "status": "invalid_run",
      "period": null,
      "samples": null
    }
  }
}
```

### Exercise 1

Compute the period.

<details><summary>Answer 1</summary>

It is `6`. Sum cell lengths, not the number of run records; the latter counts a different object.

</details>

### Exercise 2

Resolve the internal boundary query.

<details><summary>Answer 2</summary>

At index `2`, the symbol is `weft`. Equality with the earlier cumulative end transfers ownership to the next run.

</details>

### Exercise 3

Resolve all requested cells.

<details><summary>Answer 3</summary>

The symbols are `[warp,weft,warp,warp,weft]`. Global repetition is reduced before searching the unequal runs.

</details>

### Exercise 4

Apply the zero-run control.

<details><summary>Answer 4</summary>

Return `invalid_run`, with period and samples `null`. Removing a zero-length record does not change its arithmetic contribution, but silently accepting the remainder would conceal the violated positive-length contract.

</details>

### Exercise 5

Should identical adjacent symbols always be merged?

<details><summary>Answer 5</summary>

No. Cell values may survive merging while source provenance does not. State the permitted equivalence and retain a correspondence before proposing that rewrite.

</details>

## Source-assisted task and direct baseline

Expand the border by hand and label both cell addresses and run identities. Compare lookup before and after the malformed control, retaining the refusal rather than repairing it. Propose the smallest evidence note for an IX motif handoff.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

An interpreter that reports `valid` for the zero-run input violates the declared positive-length contract. Deletion cannot repair the missing provenance or establish the intended motif.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: sem-013-align-two-motif-periods-at-a-textile-seam](../../semiotics/en/sem-013-align-two-motif-periods-at-a-textile-seam.md)
- [Committed prerequisite: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/en/inf-011-separate-compressed-size-from-preserved-information.md)
- [Retained project source](../../../../code/streeling/weave-godot/trial.gd)
- [Primary reading](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
