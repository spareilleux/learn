---
module_id: "inf-022-measure-posterior-movement-with-total-variation"
department: "information-theory"
course: "Measure Posterior Movement with Total Variation"
title: "Measure Posterior Movement with Total Variation"
level: "intermediate"
prerequisites: ["inf-013-value-an-evidence-probe-by-expected-information", "inf-003-verdict-distribution-drift"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Measure Posterior Movement with Total Variation

> This is an authored finite mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, native runtime execution, production adoption and publication decisions remain undecided.

An agent handoff may announce that a new observation changed its belief. How far did the declared distribution actually move? A longer explanation need not move it at all when both hypotheses predict the observation equally. This lesson combines a transparent finite Bayes update with a bounded distance between the prior and posterior.

Multiply each prior mass by the likelihood of the stated observation under that hypothesis. Sum those products to obtain its marginal probability, then normalize. Likelihoods do not need to sum to unity across hypotheses: each belongs to a different conditional experiment. A zero normalizer would make the stated observation impossible under the supplied model and must not be repaired by silently inventing a posterior.

Total variation is half the sum of absolute coordinate differences. It measures the largest changed probability assigned to an event in this finite hypothesis space. The fixed informative likelihood shifts mass toward a hypothesis; the equal-likelihood control leaves the prior unchanged. Neither result proves that the favoured hypothesis is true. Probe identity, model adequacy and whether evidence was counted before remain separate checks. This is a conditional distribution calculation, not an observation from an actual belief service.

## Sources and project boundary

[Prerequisite: inf-013-value-an-evidence-probe-by-expected-information](../../information-theory/en/inf-013-value-an-evidence-probe-by-expected-information.md)

[Prerequisite: inf-003-verdict-distribution-drift](../../information-theory/en/inf-003-verdict-distribution-drift.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://www.cs.cornell.edu/courses/cs2800/2016fa/lectures/lec17-prob.html)

## Fixed model and negative control

```json
{
  "values": {
    "prior": [
      "1/2",
      "1/2"
    ],
    "likelihood": [
      "4/5",
      "1/5"
    ]
  },
  "formula": "Products prior[i]*likelihood[i] give unnormalized mass; normalizer=sum(products)>0; posterior=products/normalizer; total_variation=sum(abs(posterior[i]-prior[i]))/2. All arithmetic is exact rational.",
  "expected": {
    "unnormalized": [
      "2/5",
      "1/10"
    ],
    "normalizer": "1/2",
    "posterior": [
      "4/5",
      "1/5"
    ],
    "total_variation": "3/10"
  },
  "negative_control": {
    "values": {
      "prior": [
        "1/2",
        "1/2"
      ],
      "likelihood": [
        "2/5",
        "2/5"
      ]
    },
    "expected": {
      "unnormalized": [
        "1/5",
        "1/5"
      ],
      "normalizer": "2/5",
      "posterior": [
        "1/2",
        "1/2"
      ],
      "total_variation": "0"
    },
    "why": "An equally predicted observation is not discriminating evidence."
  },
  "input_types": {
    "prior": "nonnegative rational strings summing to one",
    "likelihood": "same-length rational strings in closed unit interval with positive marginal"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No real likelihood calibration, causal claim, posterior truth guarantee or production belief update is observed."
}
```

## Source-assisted task and journal

**Direct manual baseline:** Write the likelihood-weighted probability table, normalization and absolute differences manually.

**Falsifier:** A claimed discriminating update changes equal prior masses under equal likelihoods without introducing any new model premise.

Read the prerequisite and the retained project representation before treating this example as a proposed feature. The linked Learn source helper extracts metadata, title and body, then indexes English module identities. That is an actual representation boundary to inspect; it supplies neither the invented inputs nor an implementation of this mathematical operation. Keep the source revision attached to the reading note so that a later change cannot silently inherit this inspection.

For the source-assisted task, reproduce the fixed case directly before asking an assistant to explain it. Use the input types and assumptions in the packet as part of the question, preserve intermediate quantities and compare the declared negative control. Ask the assistant to identify which premise makes the two results differ. A plausible explanation that never calculates the changed input has not demonstrated the operation.

Record the exact question, supplied sources, answer, assistance history and any correction in the journal. The prepared corrected answers below are an answer key, not a learner attempt. An independent model check can establish the finite arithmetic while still missing a poor prompt or a misleading translation. Human technical review, fluent-language review, learner acceptance, native runtime behavior, production adoption and publication decisions therefore remain undecided. Retain a failed check and its diagnosis before recording a successful replay; do not replace an original failure with the corrected result.

## Corrected exercises

### Exercise 1

Normalize the fixed products.

> **Answer:** Products are `[2/5,1/10]`, normalizer `1/2`, posterior `[4/5,1/5]`.

### Exercise 2

Compute movement and the control.

> **Answer:** Fixed total variation is `3/10`. Equal likelihoods give posterior `[1/2,1/2]` and movement `0`.

### Exercise 3

Should likelihoods be normalized across hypotheses first?

> **Answer:** No. They are probabilities of the same observation conditional on different hypotheses. Normalize the prior-weighted products, retaining the original likelihood model.

### Exercise 4

What does the retained project helper actually establish?

> **Answer:** It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.

### Exercise 5

Which acceptance decisions can the corrected answer key close?

> **Answer:** None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

## Prepared learner criteria

These criteria are prepared; every learner decision remains undecided.

- Exercise 1: Products are `[2/5,1/10]`, normalizer `1/2`, posterior `[4/5,1/5]`.
- Exercise 2: Fixed total variation is `3/10`. Equal likelihoods give posterior `[1/2,1/2]` and movement `0`.
- Exercise 3: No. They are probabilities of the same observation conditional on different hypotheses. Normalize the prior-weighted products, retaining the original likelihood model.
- Exercise 4: It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.
- Exercise 5: None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
