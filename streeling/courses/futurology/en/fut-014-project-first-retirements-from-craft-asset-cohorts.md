---
module_id: "fut-014-project-first-retirements-from-craft-asset-cohorts"
department: "futurology"
course: "Project First Retirements from Craft Asset Cohorts"
level: "advanced"
prerequisites: ["fut-010-project-weave-density-before-a-scene-expansion", "psy-021-conservation-claims"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Project First Retirements from Craft Asset Cohorts

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

A future craft library plans to replace old embroidery and sculpture assets when their representations become unsuitable. A total asset count gives no date for that work. Two libraries with the same count may have different introduction dates or retirement-age assumptions. This lesson projects first-retirement workload from retained cohorts. Its fractional masses are authored planning allocations, not observed failures or probabilities estimated from user adoption.

For each introduction cohort, shift the age allocation onto the calendar and scale it by that cohort’s mass. Add the contributions that land in the same period. This finite convolution preserves total mass when the output horizon contains all allocated retirements, but its useful new result is the time profile and peak. The earlier stock-accounting identity does not supply this age schedule. A peak can occur after introductions have already begun declining because older cohorts arrive together.

The shorter-life control retains the introduction sequence and changes only retirement age. It moves and enlarges the peak while preserving total retirement mass. Treat replacement assets carefully: this model stops at their predecessors’ first retirement. Feeding replacements back as new cohorts would create a renewal model with additional assumptions and a longer horizon. A future agentic planning note should therefore bind the introduction ledger, age rule and horizon, then compare the projection with actual retirement decisions if they are later recorded.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "introduced_by_period": [
      2,
      3,
      1,
      0
    ],
    "retirement_age_mass": {
      "2": 0.5,
      "3": 0.5
    },
    "output_periods": 7
  },
  "formula": "first_retirements[t]=sum(introduced[c]*age_mass[t-c] for c in cohort periods, absent ages contribute zero); total=sum(first_retirements)",
  "expected": {
    "first_retirements": [
      0,
      0,
      1,
      2.5,
      2,
      0.5,
      0
    ],
    "total": 6,
    "peak_period": 3,
    "peak_mass": 2.5
  },
  "negative_control": {
    "values": {
      "introduced_by_period": [
        2,
        3,
        1,
        0
      ],
      "retirement_age_mass": {
        "1": 1
      },
      "output_periods": 7
    },
    "expected": {
      "first_retirements": [
        0,
        2,
        3,
        1,
        0,
        0,
        0
      ],
      "total": 6,
      "peak_period": 2,
      "peak_mass": 3
    }
  }
}
```

### Exercise 1

Find the first nonzero retirement period.

<details><summary>Answer 1</summary>

It is period `2`, with mass `1`. Earlier periods contain no cohort old enough under the declared allocation.

</details>

### Exercise 2

Derive the peak by cohort contributions.

<details><summary>Answer 2</summary>

Period `3` combines mass `1` from the earliest cohort and `1.5` from the next, giving `2.5`.

</details>

### Exercise 3

Write the complete first-retirement profile.

<details><summary>Answer 3</summary>

It is `[0,0,1,2.5,2,0.5,0]`, totaling `6`. The horizon includes the final allocated retirement.

</details>

### Exercise 4

Apply the shorter-life control.

<details><summary>Answer 4</summary>

The profile becomes `[0,2,3,1,0,0,0]`, with peak `3` in period `2`. The same total does not imply the same capacity need.

</details>

### Exercise 5

Are repeated retirements of replacements included?

<details><summary>Answer 5</summary>

No. This is first retirement of original cohorts only. A renewal calculation would need a rule for introduction and lifetime of each replacement.

</details>

## Source-assisted task and direct baseline

Draw a cohort-by-calendar table for a proposed embroidery asset library and manually sum its diagonals. Compare that direct schedule with an assistant’s total-count-only forecast, retaining both age rules as hypotheses.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

A forecast claiming identical peak workload whenever introduced totals match is refuted by the lifespan-only control.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: fut-010-project-weave-density-before-a-scene-expansion](../../futurology/en/fut-010-project-weave-density-before-a-scene-expansion.md)
- [Committed prerequisite: psy-021-conservation-claims](../../psychohistory/en/psy-021-conservation-claims.md)
- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
