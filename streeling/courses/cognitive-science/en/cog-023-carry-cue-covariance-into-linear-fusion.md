---
module_id: "cog-023-carry-cue-covariance-into-linear-fusion"
department: "cognitive-science"
course: "Carry Cue Covariance into Linear Fusion"
title: "Carry Cue Covariance into Linear Fusion"
level: "intermediate"
prerequisites: ["cog-005-separate-pitch-estimates-from-listener-reports", "cyb-015-carry-covariance-through-smoothed-telemetry"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Carry Cue Covariance into Linear Fusion

> This is an authored finite mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, native runtime execution, production adoption and publication decisions remain undecided.

A guitar interface may show both a pitch estimate and a visual cue derived partly from the same recording. Treating those estimates as independent can overstate the precision gained by combining them. This lesson assumes that both estimate the same scalar quantity without bias. Their variances and covariance are stipulated, allowing the fusion decision to be examined before collecting any perceptual data.

Write the fused estimate as a weighted sum whose weights add to unity. Expanding its error variance exposes a covariance term. Differentiate that quadratic with respect to the first weight to find the unconstrained minimum. Positive covariance can make an unconstrained weight negative: the noisier cue then helps subtract shared error rather than receiving an ordinary positive reliability vote. This is not a recommendation to deploy negative weights without checking bias and covariance estimates.

The fixed covariance matrix is positive definite. The control removes its off-diagonal terms and recovers inverse-variance weights. Reusing those independent-cue weights in the correlated case gives a worse actual variance. Compare against the better individual cue as well as the other fusion rule. The cited perceptual abstract motivates careful comparator choice; the covariance optimization is derived here, not claimed as an inspected equation from that paper.

## Sources and project boundary

[Prerequisite: cog-005-separate-pitch-estimates-from-listener-reports](../../cognitive-science/en/cog-005-separate-pitch-estimates-from-listener-reports.md)

[Prerequisite: cyb-015-carry-covariance-through-smoothed-telemetry](../../cybernetics/en/cyb-015-carry-covariance-through-smoothed-telemetry.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://pubmed.ncbi.nlm.nih.gov/37730934/)

## Fixed model and negative control

```json
{
  "values": {
    "estimates": [
      10,
      14
    ],
    "variances": [
      1,
      4
    ],
    "covariance": 1.5
  },
  "formula": "For unbiased estimates, w1=(v2-c)/(v1+v2-2*c), w2=1-w1; fused=w1*x1+w2*x2; variance=w1*w1*v1+w2*w2*v2+2*w1*w2*c. Weights are unconstrained real numbers summing to one.",
  "expected": {
    "weights": [
      1.25,
      -0.25
    ],
    "fused": 9,
    "variance": 0.875,
    "independence_weight_variance": 1.28
  },
  "negative_control": {
    "values": {
      "estimates": [
        10,
        14
      ],
      "variances": [
        1,
        4
      ],
      "covariance": 0
    },
    "expected": {
      "weights": [
        0.8,
        0.2
      ],
      "fused": 10.8,
      "variance": 0.8,
      "independence_weight_variance": 0.8
    },
    "why": "Covariance changes the optimum; inverse-variance weights assume independence."
  },
  "input_types": {
    "estimates": "two finite unbiased scalar estimates",
    "variances": "two positive marginal variances",
    "covariance": "finite covariance giving a positive-definite covariance matrix"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No perceptual fusion, actual detector variance, unbiasedness test or deployed interface gain is measured."
}
```

## Source-assisted task and journal

**Direct manual baseline:** Expand the fused-error variance and differentiate the quadratic before selecting weights.

**Falsifier:** A precision claim evaluates correlated cues using a variance formula that drops the covariance term.

Read the prerequisite and the retained project representation before treating this example as a proposed feature. The linked Learn source helper extracts metadata, title and body, then indexes English module identities. That is an actual representation boundary to inspect; it supplies neither the invented inputs nor an implementation of this mathematical operation. Keep the source revision attached to the reading note so that a later change cannot silently inherit this inspection.

For the source-assisted task, reproduce the fixed case directly before asking an assistant to explain it. Use the input types and assumptions in the packet as part of the question, preserve intermediate quantities and compare the declared negative control. Ask the assistant to identify which premise makes the two results differ. A plausible explanation that never calculates the changed input has not demonstrated the operation.

Record the exact question, supplied sources, answer, assistance history and any correction in the journal. The prepared corrected answers below are an answer key, not a learner attempt. An independent model check can establish the finite arithmetic while still missing a poor prompt or a misleading translation. Human technical review, fluent-language review, learner acceptance, native runtime behavior, production adoption and publication decisions therefore remain undecided. Retain a failed check and its diagnosis before recording a successful replay; do not replace an original failure with the corrected result.

## Corrected exercises

### Exercise 1

Find the correlated-case weights.

> **Answer:** Weights `[1.25,-0.25]` sum to `1`; fused estimate is `9` and variance `0.875`. Negative weight is allowed by the stated unconstrained model.

### Exercise 2

Apply the independence control.

> **Answer:** With covariance `0`, weights are `[0.8,0.2]`, estimate `10.8`, variance `0.8`. Those weights yield variance `1.28` under the original covariance.

### Exercise 3

Does a negative weight prove the input is invalid?

> **Answer:** No. The covariance matrix is positive definite and weights are unconstrained. Requiring nonnegative weights would define a different optimization problem.

### Exercise 4

What does the retained project helper actually establish?

> **Answer:** It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.

### Exercise 5

Which acceptance decisions can the corrected answer key close?

> **Answer:** None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

## Prepared learner criteria

These criteria are prepared; every learner decision remains undecided.

- Exercise 1: Weights `[1.25,-0.25]` sum to `1`; fused estimate is `9` and variance `0.875`. Negative weight is allowed by the stated unconstrained model.
- Exercise 2: With covariance `0`, weights are `[0.8,0.2]`, estimate `10.8`, variance `0.8`. Those weights yield variance `1.28` under the original covariance.
- Exercise 3: No. The covariance matrix is positive definite and weights are unconstrained. Requiring nonnegative weights would define a different optimization problem.
- Exercise 4: It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.
- Exercise 5: None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
