---
module_id: "cog-016-find-the-missing-answer-tipping-count"
department: "cognitive-science"
course: "Find the Missing-Answer Tipping Count"
level: "intermediate"
prerequisites: ["cog-007-separate-unaided-recall-from-assisted-success", "phi-007-test-a-learning-gain-against-counterfactuals"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Find the Missing-Answer Tipping Count

> This lesson uses authored fixed inputs and inspected source passages. The numbers, histories and labels are teaching constructions. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An assisted-review summary omits unanswered offers, then ranks itself above a complete manual comparison. The missing-answer prerequisite already supplies completion bounds. We now ask an operational sensitivity question: how many missing answers would need to be correct before the ranking becomes strictly favorable?

Keep the original denominator of eligible offers. Each hypothetical completion is an assumption, not an observation. Enumerate the possible missing-success counts and compare each completed rate with the fixed manual rate. Equality does not meet a strict-superiority criterion. This integer threshold is easier to audit than a persuasive sentence that silently selects the optimistic endpoint.

The retained learning record distinguishes absent answers from observed wrong answers. W3C provenance motivates keeping the activity that produced a result distinct from a derived summary. Neither source supplies the missing responses. Unlike the counterfactual lesson, the missing quantities here are unrecorded endpoint answers, not each person’s alternative intervention outcome. A favorable completion still would not establish causal benefit or justify a learner acceptance decision.

## Sources and project boundary

The retained Learn helper separates frontmatter, heading and body in `parseModule`, and indexes English module names in `englishModuleKeys`. Those inspected representations let a task name its source and metadata; they do not implement the authored operation. The retained practice record instead distinguishes retrieval metrics from learner evidence. Inspect the particular file linked below and retain only the observation it actually supports. No model input in this lesson was estimated from that file.

[Prerequisite: cog-007-separate-unaided-recall-from-assisted-success](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md)

[Prerequisite: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/en/phi-007-test-a-learning-gain-against-counterfactuals.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Fixed model and control

```json
{
  "values": {
    "offered": 10,
    "observed_successes": 6,
    "missing": 4,
    "comparison_successes": 7,
    "comparison_offered": 10
  },
  "formula": "For k missing successes in integers 0..missing, rate=(successes+k)/offered; strict superiority requires rate>comparison_successes/comparison_offered. Return smallest feasible k or null.",
  "expected": {
    "lower": 0.6,
    "upper": 1,
    "comparison_rate": 0.7,
    "minimum_missing_successes_for_strict_superiority": 2,
    "identified_strict_superiority": false
  },
  "negative_control": {
    "values": {
      "offered": 10,
      "observed_successes": 6,
      "missing": 0,
      "comparison_successes": 7,
      "comparison_offered": 10
    },
    "expected": {
      "lower": 0.6,
      "upper": 0.6,
      "comparison_rate": 0.7,
      "minimum_missing_successes_for_strict_superiority": null,
      "identified_strict_superiority": false
    },
    "why": "Complete inferior results leave no missing-answer assignment that can reverse the ranking."
  },
  "assumptions": [
    "One binary endpoint per eligible offer; comparison complete.",
    "Missing results may be either value; no missingness model."
  ],
  "limits": "Descriptive ranking sensitivity only; no causal benefit, probability for completions or statistical interval.",
  "input_types": {
    "offered": "positive integer",
    "observed_successes": "integer in [0,offered-missing]",
    "missing": "integer in [0,offered]",
    "comparison_successes": "integer",
    "comparison_offered": "positive integer"
  }
}
```

### Exercise 1

Compute the full-offer bounds.

<details><summary>Answer 1</summary>

They are `0.6` and `1`; the complete comparison rate is `0.7`. The interval permits several rankings without choosing among them.

</details>

### Exercise 2

How many missing successes give equality?

<details><summary>Answer 2</summary>

With `1` missing success the completed rate is `0.7`. Equality does not satisfy strict superiority.

</details>

### Exercise 3

Find the tipping count for strict superiority.

<details><summary>Answer 3</summary>

The smallest count is `2`, giving `0.8`. This is a hypothetical completion requirement, not evidence that those answers were correct.

</details>

### Exercise 4

Apply the no-missing control.

<details><summary>Answer 4</summary>

Both bounds are `0.6`, below `0.7`; the minimum count is `null`. No feasible missing assignment can produce a reversal.

</details>

### Exercise 5

Can the tipping count be called a probability of benefit?

<details><summary>Answer 5</summary>

No. We assign no probabilities to completions, and descriptive ranking does not identify a causal effect. Retain the unanswered offers.

</details>

## Source-assisted learner task

Prepare a ranking-sensitivity note for fictional GA assisted and manual review answers.

**Direct manual baseline:** Enumerate integer missing-success counts with the full offer denominator and mark the first strict crossing.

**Falsifier:** Equality is labeled superiority or a hypothetical missing response is reported as observed.

Save a first answer before opening the corrected exercises. Copy the input identities and units, write the intermediate quantities, and distinguish the calculation from the interpretation. A correct number with the wrong denominator, state boundary or counting unit does not meet the task. Retain a surprising intermediate result rather than changing the input to make the final answer look plausible.

Read the cited primary passage within the scope recorded in the packet. Compare its actual definition with the authored rule in the fixed model. The reference may motivate a concept without specifying our entire model. Record the version or date, the passage used and the exact assumption you imported. An accessible page or a successful file read is not evidence that a claim has been verified.

Inspect the retained project artifact and one prerequisite. Separate what the file actually represents from what this new task hypothesizes. Preserve source revision and assistance history. Ask an assistant to challenge an assumption only after saving the manual baseline, then keep its prompt, reply, accepted correction and rejected suggestion. Source lookup and calculator use are permitted assistance, not unaided recall.

Run the changed input through the same reasoning on paper. State the falsifier before proposing an agent abstraction or a composable DSL expression. If an abstraction drops the counterexample or changes the accepted endpoint, it fails this task even if its response is shorter. Compare a direct table or typed record first; no new language or production engine is required.

Submit original and corrected answers together with the control result, source passage and remaining uncertainty. The packet prepares a separate criterion for each exercise, with every learner decision undecided. An answer key, a byte hash and an author self-check are different evidence from an actual learner attempt. A future dogfood comparison must retain actual attempts on the same versioned task and the direct baseline before claiming a useful change.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
