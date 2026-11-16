---
module_id: "cog-019-correct-review-agreement-for-label-marginals"
department: "cognitive-science"
course: "Correct Review Agreement for Label Marginals"
title: "Correct Review Agreement for Label Marginals"
level: "intermediate"
prerequisites: ["cog-011-measure-rubric-disagreement-before-adjudication"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Correct Review Agreement for Label Marginals

> This is an authored mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A Streeling review coordinator sees strong raw agreement and wants to call the rubric reliable. If both raters mostly choose the same label, some matching is expected under a marginal-label model. The earlier disagreement course preserves the paired cells but explicitly stops short of chance correction. This lesson adds that calculation without upgrading an authored table into human review.

Compute observed agreement from the diagonal. Next compute each rater’s own passing and failing fractions. Multiply matching fractions across raters and add them to obtain expected agreement under the stated independent-label model. Normalize the excess agreement by the remaining room above that reference. The denominator matters as much as the numerator; the corrected quantity is not simply raw accuracy with a constant subtracted.

In the fixed case the marginals differ, so using a pooled passing rate would change the comparison model. Keep each marginal attached to its rater and retain the disputed artifacts for adjudication. The control makes every rating a pass. Raw agreement becomes perfect, but the chance-correction denominator vanishes. Report the corrected result as undefined rather than inventing a perfect corrected score.

The scikit-learn documentation defines this empirical-marginal version of kappa. No package is needed for the small exact table, and its definition does not prescribe a release threshold. High agreement can coexist with a shared wrong answer key or copied ratings. The direct task is to report both raw and corrected agreement, the assumptions and the degenerate boundary. A composable review expression must keep that boundary visible instead of converting an undefined score into approval.

## Sources and project boundary

The retained Learn helper separates metadata, title and body, and indexes English module identities. Inspect that representation when naming the artifact and its revision. It does not implement this lesson’s model or supply its invented inputs.

[Prerequisite: cog-011-measure-rubric-disagreement-before-adjudication](../../cognitive-science/en/cog-011-measure-rubric-disagreement-before-adjudication.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://scikit-learn.org/stable/modules/generated/sklearn.metrics.cohen_kappa_score.html)

## Fixed model and negative control

```json
{
  "values": {
    "both_pass": 6,
    "A_only": 2,
    "B_only": 0,
    "both_fail": 2
  },
  "formula": "N=sum(cells); po=(both_pass+both_fail)/N; pA=(both_pass+A_only)/N; pB=(both_pass+B_only)/N; pe=pA*pB+(1-pA)*(1-pB); kappa=(po-pe)/(1-pe), null if pe=1.",
  "expected": {
    "N": 10,
    "observed_agreement": 0.8,
    "expected_agreement": 0.56,
    "kappa_fraction": "6/11"
  },
  "negative_control": {
    "values": {
      "both_pass": 10,
      "A_only": 0,
      "B_only": 0,
      "both_fail": 0
    },
    "expected": {
      "N": 10,
      "observed_agreement": 1,
      "expected_agreement": 1,
      "kappa_fraction": null
    },
    "why": "Unanimous use of one category makes the correction denominator zero."
  },
  "input_types": {
    "both_pass": "nonnegative integer",
    "A_only": "nonnegative integer",
    "B_only": "nonnegative integer",
    "both_fail": "nonnegative integer"
  },
  "assumptions": [
    "Same artifacts and binary rubric for both fictional raters; positive total.",
    "Chance model uses product of empirical per-rater marginals, not an actual random rater experiment."
  ],
  "limits": "Kappa is not validity, independence, fairness or a universal acceptance threshold. No human review occurred."
}
```

### Exercise 1

Compute observed agreement.

<details><summary>Answer 1</summary>

The diagonal has `8` of `10` items, giving `0.8`. This describes matching labels, not correctness of the answers or independent provenance of the ratings.

</details>

### Exercise 2

Compute expected agreement from separate marginals.

<details><summary>Answer 2</summary>

Passing fractions are `0.8` and `0.6`; expected agreement is `0.56`. Pooling the marginals would implement a different reference model.

</details>

### Exercise 3

Calculate the corrected score.

<details><summary>Answer 3</summary>

Kappa is `6/11`. Keep the raw table beside it; a corrected scalar does not identify the disputed artifacts needed for adjudication.

</details>

### Exercise 4

Apply the all-pass control.

<details><summary>Answer 4</summary>

Observed and expected agreement both equal `1`; the corrected score is `null`. The denominator vanishes, so a perfect numeric kappa must not be manufactured.

</details>

### Exercise 5

May the score authorize publication?

<details><summary>Answer 5</summary>

No. Correctness, artifact identity, rating independence and release authority require their own evidence. A statistic cannot replace any missing technical or language review.

</details>

## Source-assisted learner task

Prepare an agreement note for fictional paired Streeling rubric ratings.

**Direct manual baseline:** Fill the paired table, retain both marginals and calculate the correction as an exact fraction.

**Falsifier:** The summary pools distinct marginals or invents a defined corrected score at a zero denominator.

Save a first answer before opening the solutions. Identify the input types, the comparison boundary and the quantity that the task asks you to preserve. Draw the smallest table or diagram that permits every intermediate result to be checked. Keep an unexpected result; editing the premises until a preferred conclusion appears would destroy the counterexample.

Read the linked prerequisite and the bounded primary passage. Record the source revision, the definition actually used and the assumptions you imported. The project artifact supplies a real representation to inspect, while the fixed model supplies invented inputs. Neither a document name nor an accessible URL establishes a production result. Explain what would need to be observed before using the calculation in an operational decision.

State the direct manual baseline and its falsifier before proposing a composable DSL or an agent abstraction. Ask an assistant to challenge your manual answer only after saving it. Retain the prompt, the reply, the source passage it cites and the correction you accept or reject. A shorter expression is useful only if it preserves the operation, the control and the refusal boundary. Compare it with a plain table first.

Submit the original answer, intermediate quantities, corrected answer and control together. Label source consultation and calculator use as assistance. A future dogfood comparison should use the same task version and retain failures as well as successes; otherwise changing the question can masquerade as improvement. The prepared criteria below remain undecided until a learner actually attempts the task. An answer key and an author check establish neither learning nor adoption.

## Prepared learner criteria

- Exercise 1: Compute observed agreement. — Decision undecided.
- Exercise 2: Compute expected agreement from separate marginals. — Decision undecided.
- Exercise 3: Calculate the corrected score. — Decision undecided.
- Exercise 4: Apply the all-pass control. — Decision undecided.
- Exercise 5: May the score authorize publication? — Decision undecided.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
