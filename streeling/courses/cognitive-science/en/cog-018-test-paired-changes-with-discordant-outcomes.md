---
module_id: "cog-018-test-paired-changes-with-discordant-outcomes"
department: "cognitive-science"
course: "Test Paired Changes with Discordant Outcomes"
title: "Test Paired Changes with Discordant Outcomes"
level: "intermediate"
prerequisites: ["cog-009-counterbalance-practice-order-before-comparing-interfaces", "cog-011-measure-rubric-disagreement-before-adjudication"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Test Paired Changes with Discordant Outcomes

> This is an authored mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A GA practice agent reports that a revised explanation answered more items correctly. If old and new explanations are judged on the same items, the outcomes are paired. Treating the two totals as unrelated samples discards the matching. Preserve which items change direction before choosing a statistical comparison or claiming useful assistance.

Create the paired table with shared successes, shared failures and the two discordant directions. The accuracy difference uses every matched item. The conditional directional test uses only discordant pairs: shared outcomes supply no information about which explanation wins among the changes. Under the declared null, either direction is equally likely for each independent discordant pair.

The exact calculation doubles the smaller binomial tail and caps it at unity. The fixed case has a substantial descriptive accuracy difference, yet its two-sided probability remains above the familiar conventional threshold. That is not a contradiction; effect size and evidence under a null model answer different questions. Avoid reporting a large percentage change as if it guaranteed a decisive test.

The control balances the discordant directions while keeping the number of matched items unchanged. The prerequisite already teaches raw paired disagreement; this operation adds a probabilistic comparison with explicit independence and allocation assumptions. An item that both versions miss still matters for usefulness, even though it does not enter the conditional sample size. No learner tried these explanations, and no interface was allocated. For a future dogfood comparison, preserve hidden scoring, order control, item identity and every failed pair before asking an assistant to summarize improvement.

## Sources and project boundary

The retained Learn helper separates metadata, title and body, and indexes English module identities. Inspect that representation when naming the artifact and its revision. It does not implement this lesson’s model or supply its invented inputs.

[Prerequisite: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/en/cog-009-counterbalance-practice-order-before-comparing-interfaces.md)

[Prerequisite: cog-011-measure-rubric-disagreement-before-adjudication](../../cognitive-science/en/cog-011-measure-rubric-disagreement-before-adjudication.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binomtest.html)

## Fixed model and negative control

```json
{
  "values": {
    "both_correct": 2,
    "old_only": 1,
    "new_only": 7,
    "both_wrong": 2
  },
  "formula": "n=old_only+new_only; k=min(old_only,new_only); exact two-sided p=min(1,2*sum(comb(n,j),j=0..k)/2**n) for n>0; if n=0 set p=1. Total includes all four cells. Report accuracy difference=(new_only-old_only)/total.",
  "expected": {
    "paired": 12,
    "discordant": 8,
    "old_correct": 3,
    "new_correct": 9,
    "accuracy_difference": 0.5,
    "p_value": 0.0703125
  },
  "negative_control": {
    "values": {
      "both_correct": 2,
      "old_only": 4,
      "new_only": 4,
      "both_wrong": 2
    },
    "expected": {
      "paired": 12,
      "discordant": 8,
      "old_correct": 6,
      "new_correct": 6,
      "accuracy_difference": 0,
      "p_value": 1
    },
    "why": "Balanced discordant directions remove the directional evidence while keeping pair count fixed."
  },
  "input_types": {
    "both_correct": "nonnegative integer",
    "old_only": "nonnegative integer",
    "new_only": "nonnegative integer",
    "both_wrong": "nonnegative integer"
  },
  "assumptions": [
    "Independent pairs; under the null each discordant direction is equally likely.",
    "Same binary criterion for matched items; no missing pairs; test and alternatives declared in advance."
  ],
  "limits": "Authored counts are not learner responses. This is not a causal effect without an appropriate allocation and observation design."
}
```

### Exercise 1

Which denominator belongs to each calculation?

<details><summary>Answer 1</summary>

There are `12` matched items but `8` discordant pairs. Accuracy uses the full matched set; the conditional binomial test uses the discordant set.

</details>

### Exercise 2

Compute the descriptive change.

<details><summary>Answer 2</summary>

Old correct is `3`, new correct is `9`, and the difference is `0.5`. Keep the paired table: these totals alone do not retain which items changed.

</details>

### Exercise 3

Compute the exact two-sided probability.

<details><summary>Answer 3</summary>

It is `0.0703125`, obtained from both symmetric tails. It is not a posterior probability that the explanations are equivalent or that assistance failed.

</details>

### Exercise 4

Apply the balanced control.

<details><summary>Answer 4</summary>

Both versions have `6` correct, the difference is `0`, and the probability is `1`. The control still contains disagreements; they simply balance in direction.

</details>

### Exercise 5

What causal conclusion is justified?

<details><summary>Answer 5</summary>

None from invented counts alone. A real comparison needs appropriate allocation, matched identities, common scoring and an independence argument; repeated items from one learner may violate that argument.

</details>

## Source-assisted learner task

Plan the paired analysis of a fixed GA explanation comparison before collecting any learner responses.

**Direct manual baseline:** Fill the paired table and enumerate the symmetric binomial tail with integer combinations.

**Falsifier:** The proposed summary changes the paired denominator or drops the discordant direction.

Save a first answer before opening the solutions. Identify the input types, the comparison boundary and the quantity that the task asks you to preserve. Draw the smallest table or diagram that permits every intermediate result to be checked. Keep an unexpected result; editing the premises until a preferred conclusion appears would destroy the counterexample.

Read the linked prerequisite and the bounded primary passage. Record the source revision, the definition actually used and the assumptions you imported. The project artifact supplies a real representation to inspect, while the fixed model supplies invented inputs. Neither a document name nor an accessible URL establishes a production result. Explain what would need to be observed before using the calculation in an operational decision.

State the direct manual baseline and its falsifier before proposing a composable DSL or an agent abstraction. Ask an assistant to challenge your manual answer only after saving it. Retain the prompt, the reply, the source passage it cites and the correction you accept or reject. A shorter expression is useful only if it preserves the operation, the control and the refusal boundary. Compare it with a plain table first.

Submit the original answer, intermediate quantities, corrected answer and control together. Label source consultation and calculator use as assistance. A future dogfood comparison should use the same task version and retain failures as well as successes; otherwise changing the question can masquerade as improvement. The prepared criteria below remain undecided until a learner actually attempts the task. An answer key and an author check establish neither learning nor adoption.

## Prepared learner criteria

- Exercise 1: Which denominator belongs to each calculation? — Decision undecided.
- Exercise 2: Compute the descriptive change. — Decision undecided.
- Exercise 3: Compute the exact two-sided probability. — Decision undecided.
- Exercise 4: Apply the balanced control. — Decision undecided.
- Exercise 5: What causal conclusion is justified? — Decision undecided.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
