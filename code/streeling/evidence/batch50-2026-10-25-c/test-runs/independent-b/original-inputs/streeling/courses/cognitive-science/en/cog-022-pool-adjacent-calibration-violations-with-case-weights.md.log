---
module_id: "cog-022-pool-adjacent-calibration-violations-with-case-weights"
department: "cognitive-science"
course: "Pool Adjacent Calibration Violations with Case Weights"
title: "Pool Adjacent Calibration Violations with Case Weights"
level: "intermediate"
prerequisites: ["cog-003-calibrating-fretboard-confidence", "psy-017-calibration-with-six-observations"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Pool Adjacent Calibration Violations with Case Weights

> This is an authored finite mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, native runtime execution, production adoption and publication decisions remain undecided.

An agentic review report sorts confidence bins but its observed success frequencies decrease between neighbouring bins. A monotone calibration fit can remove that ordering conflict while preserving the contribution of each bin. It does not repair sampling bias or prove that the forecasts are reliable. Retain the original frequencies and sample weights beside the fitted curve.

Start with one block per ordered score. When a block mean exceeds the next mean, merge them and replace both by their weighted mean. Recheck the preceding boundary after a merge: a local repair can expose another violation. The final block value minimizes weighted squared error under the nondecreasing constraint. Sorting response values instead would detach outcomes from their original confidence bins.

The central bins in this authored case violate the requested order. Changing their weights moves the pooled level while leaving their order and outcomes intact. Equal weighting would answer a different question. The fixed curve only describes the finite training bins: validation on held-out attempts, assistance tracking and support for unseen scores remain separate obligations. A future DSL stage would need to carry ordered bin identities and weights, not merely a smooth-looking chart.

## Sources and project boundary

[Prerequisite: cog-003-calibrating-fretboard-confidence](../../cognitive-science/en/cog-003-calibrating-fretboard-confidence.md)

[Prerequisite: psy-017-calibration-with-six-observations](../../psychohistory/en/psy-017-calibration-with-six-observations.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://docs.scipy.org/doc/scipy-1.14.0/reference/generated/scipy.optimize.isotonic_regression.html)

## Fixed model and negative control

```json
{
  "values": {
    "y": [
      0.2,
      0.8,
      0.4,
      0.9
    ],
    "weights": [
      1,
      1,
      3,
      1
    ]
  },
  "formula": "Weighted nondecreasing least squares: minimize sum(weights[i]*(fit[i]-y[i])**2) subject to fit[i]<=fit[i+1]. PAVA merges adjacent decreasing block means using summed weights.",
  "expected": {
    "fit": [
      0.2,
      0.5,
      0.5,
      0.9
    ],
    "weighted_squared_error": 0.12
  },
  "negative_control": {
    "values": {
      "y": [
        0.2,
        0.8,
        0.4,
        0.9
      ],
      "weights": [
        1,
        3,
        1,
        1
      ]
    },
    "expected": {
      "fit": [
        0.2,
        0.7,
        0.7,
        0.9
      ],
      "weighted_squared_error": 0.12
    },
    "why": "Changing case weights changes the pooled mean; sorting responses is not weighted fitting."
  },
  "input_types": {
    "y": "ordered finite observed frequencies",
    "weights": "same-length strictly positive case weights"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No held-out calibration, actual learner counts or behavior of a deployed agent is established."
}
```

## Source-assisted task and journal

**Direct manual baseline:** Write weighted block sums and merge every decreasing adjacent boundary on paper.

**Falsifier:** A reported monotone fit uses equal weights despite unequal declared case weights, or sorts outcomes away from their score identities.

Read the prerequisite and the retained project representation before treating this example as a proposed feature. The linked Learn source helper extracts metadata, title and body, then indexes English module identities. That is an actual representation boundary to inspect; it supplies neither the invented inputs nor an implementation of this mathematical operation. Keep the source revision attached to the reading note so that a later change cannot silently inherit this inspection.

For the source-assisted task, reproduce the fixed case directly before asking an assistant to explain it. Use the input types and assumptions in the packet as part of the question, preserve intermediate quantities and compare the declared negative control. Ask the assistant to identify which premise makes the two results differ. A plausible explanation that never calculates the changed input has not demonstrated the operation.

Record the exact question, supplied sources, answer, assistance history and any correction in the journal. The prepared corrected answers below are an answer key, not a learner attempt. An independent model check can establish the finite arithmetic while still missing a poor prompt or a misleading translation. Human technical review, fluent-language review, learner acceptance, native runtime behavior, production adoption and publication decisions therefore remain undecided. Retain a failed check and its diagnosis before recording a successful replay; do not replace an original failure with the corrected result.

## Corrected exercises

### Exercise 1

Compute the pooled block.

> **Answer:** The violating values pool to `(1*0.8+3*0.4)/4=0.5`; the fit is `[0.2,0.5,0.5,0.9]`.

### Exercise 2

Apply the swapped-weight control.

> **Answer:** The pooled value becomes `(3*0.8+1*0.4)/4=0.7`. Both weighted objectives are `0.12`, but the fitted sequences differ.

### Exercise 3

Why keep the original bin order?

> **Answer:** The ordering belongs to confidence scores. Sorting success frequencies would move outcomes to different scores and change the problem.

### Exercise 4

What does the retained project helper actually establish?

> **Answer:** It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.

### Exercise 5

Which acceptance decisions can the corrected answer key close?

> **Answer:** None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

## Prepared learner criteria

These criteria are prepared; every learner decision remains undecided.

- Exercise 1: The violating values pool to `(1*0.8+3*0.4)/4=0.5`; the fit is `[0.2,0.5,0.5,0.9]`.
- Exercise 2: The pooled value becomes `(3*0.8+1*0.4)/4=0.7`. Both weighted objectives are `0.12`, but the fitted sequences differ.
- Exercise 3: The ordering belongs to confidence scores. Sorting success frequencies would move outcomes to different scores and change the problem.
- Exercise 4: It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.
- Exercise 5: None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
