---
module_id: "inf-010-keep-joint-outcomes-when-composing-verdicts"
department: "information-theory"
course: "Keep Joint Outcomes When Composing Verdicts"
title: "Keep Joint Outcomes When Composing Verdicts"
level: "intermediate"
prerequisites: ["cs-008-compose-exact-source-review-verdicts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Keep Joint Outcomes When Composing Verdicts

> **Draft scope.** Source-assisted authored fixed models. Human technical, fluent-language and learner decisions remain pending. No live fleet, production controller, user telemetry or learning improvement is claimed. The validation journal distinguishes tests actually executed from source reading and planned checks.

## Sources to inspect

- [cs-008-compose-exact-source-review-verdicts.md](../../computer-science/en/cs-008-compose-exact-source-review-verdicts.md)
- [inf-003-verdict-distribution-drift.md](../../information-theory/en/inf-003-verdict-distribution-drift.md)

A Streeling dashboard shows equal pass rates for two required review checks. Can a release coordinator multiply those rates to estimate how many courses passed both? Not without a joint model. Exact-source receipts define what each verdict covers; the verdict-distribution course examines marginal proportions. This lesson preserves which results belong to the same artifact before composing an all-required decision.

The authored cases below share the same marginal pass rates but pair the labels differently. In the first case, successful labels coincide. In the second, many successful labels occur on different artifacts. Build a paired table before computing a headline. Every row represents the same source identity under both checks, and each artifact appears once. Pairing arbitrary successful records from different revisions would not satisfy the consumer's requirement.

Read the prerequisite's review-kind boundary. A subject verdict and a language verdict are distinct claims, and this binary model intentionally compresses each to pass or fail for arithmetic. It cannot authenticate the reviewers or infer a missing learner judgment. Even a joint pass in the model is only the result of its specified two-check policy. It is not blanket permission to publish or a representation of every real release gate.

The product of marginal rates corresponds to an independence assumption. Here the supplied paired counts directly determine the joint rate, so replacing them with that product discards available evidence. The resulting estimate can be too low or too high depending on the pairing. The negative control supplies a separate table constructed to have the product relationship. That control tests the arithmetic without pretending independence was discovered in the other cases.

For the source-assisted task, inspect the receipt kinds in the exact-source lesson and reproduce both paired tables manually. Ask an assistant to compute all-required eligibility without multiplying unless the assumption is explicitly supplied. Retain the failed product estimates alongside the correct joint values. Reject a dashboard proposal if it reports the same joint eligibility for both tables merely because their marginal summaries match.

## Fixed case and expected calculations

```json
{
  "values": {
    "total": 10,
    "case_X": {
      "both_pass": 6,
      "A_only": 0,
      "B_only": 0,
      "both_fail": 4
    },
    "case_Y": {
      "both_pass": 2,
      "A_only": 4,
      "B_only": 4,
      "both_fail": 0
    }
  },
  "formula": "all_required_pass=both_pass/total; marginal_A=(both_pass+A_only)/total",
  "expected": {
    "A_rate": 0.6,
    "B_rate": 0.6,
    "X_joint_rate": 0.6,
    "Y_joint_rate": 0.2,
    "independence_product": 0.36,
    "X_product_error": -0.24,
    "Y_product_error": 0.16
  },
  "negative_control": "An explicitly independent authored table with total25 and cells9,6,6,4 gives joint9/25 equal to(15/25)^2.",
  "assumptions": [
    "Same ten fictional artifacts per table; paired verdicts use identical scope; all-input policy requires both passes."
  ],
  "limits": "No actual approval prevalence or independence is measured; valid verdicts still require identity and authority checks."
}
```

## Retain a source-assisted learner attempt

Work from the pinned inputs listed above. Before asking for assistance, write your own prediction for the fixed case and its negative control, including the unit of every quantity and the exact comparison boundary. A short paper table is the direct manual baseline. Keep intermediate values, especially any result that contradicts your first prediction. This is an explanation task using existing sources and fixed data; it does not require installing a package, calling a paid service or introducing a new program.

Next use an assistant to locate the relevant source passage and critique your calculation. Retain the original prompt, the response, the source location it cited and the changes you accepted or rejected. A citation is useful only when its inspected content supports the specific claim. A declared stage, a data type and a prose comment supply different kinds of evidence from an executed outcome. Explain that boundary in the final answer rather than borrowing the authority of a successful-looking label.

Submit the manual baseline, corrected result, control outcome, falsifier and assistance history together. The prepared learner criteria ask whether the scope was identified, the calculation was correct, the counterexample was retained, the source supported the explanation and the conclusion respected its limits. Their decisions remain undecided until an actual learner answer exists. Answer keys below are prepared corrections, not evidence that anyone learned the material. A reviewer should preserve a failed criterion and its reason before any refinement, then judge the revised attempt separately. Runtime evidence and publication evidence, if later collected, need their own revision-bound records.

### Exercise 1

Calculate both marginal rates.

<details>
<summary>Answer 1</summary>

In both cases A and B each pass `6/10=0.6`.

</details>

### Exercise 2

Calculate the joint pass rates.

<details>
<summary>Answer 2</summary>

X gives `6/10=0.6`; Y gives `2/10=0.2`.

</details>

### Exercise 3

Compare the product estimate.

<details>
<summary>Answer 3</summary>

`0.6*0.6=0.36`; estimate minus truth is X `-0.24`, Y `0.16`.

</details>

### Exercise 4

Verify the independent control.

<details>
<summary>Answer 4</summary>

Cells `9,6,6,4` total `25`; `9/25=(15/25)^2=0.36`.

</details>

### Exercise 5

Does joint pass authorize publication?

<details>
<summary>Answer 5</summary>

No. Identity, review scope, other gates and effect authority remain distinct requirements.

</details>

[Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
