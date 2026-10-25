---
module_id: gaa-015-keep-uncertainty-with-a-practice-pass-rate
department: guitar-alchemist-academy
course: "Keep Uncertainty with a Practice Pass Rate"
level: advanced
prerequisites: ["gaa-010-define-a-practice-pass-before-counting-success"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Keep Uncertainty with a Practice Pass Rate

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

The same percentage can rest on very different amounts of evidence. A [GA](https://github.com/GuitarAlchemist/ga) practice summary should retain the denominator and an explicitly chosen uncertainty rule before describing a target as established. We calculate a Wilson interval for authored pass counts. These are synthetic outcomes under a binomial assumption, not a learner’s record.

## Read the retained evidence

The primary handbook gives Wilson limits and distinguishes them from a different adjusted interval. Read that formula beside the retained task-specific pass rules. A statistical interval cannot fix an ambiguous pass definition or convert assisted responses into unaided attempts.

[Prerequisite](../../guitar-alchemist-academy/en/gaa-010-define-a-practice-pass-before-counting-success.md)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm)

## Fixed case and prepared quantities

```json
{
  "values": {
    "passes": 8,
    "attempts": 10,
    "z": 1.96,
    "required_lower_bound": 0.7
  },
  "formula": "p=k/n; d=1+z^2/n; center=(p+z^2/(2*n))/d; half=z*sqrt(p*(1-p)/n+z^2/(4*n^2))/d; lower=center-half; upper=center+half; established=lower>=required_lower_bound",
  "expected": {
    "rate": 0.8,
    "lower": 0.49015684672072346,
    "upper": 0.9433190520193067,
    "established": false
  },
  "negative_control": {
    "values": {
      "passes": 80,
      "attempts": 100,
      "z": 1.96,
      "required_lower_bound": 0.7
    },
    "expected": {
      "rate": 0.8,
      "lower": 0.7111690380734976,
      "upper": 0.8666340774409013,
      "established": true
    }
  }
}
```

## Match the uncertainty model to how attempts were collected

A pass rate requires a unit of observation and a stable endpoint. Counting individual notes as independent attempts after defining success for a complete phrase would change the denominator and the target quantity. Likewise, pooling assisted and unassisted attempts can change what the rate describes even when the arithmetic is correct. Keep the raw outcomes and the sampling rule available so a reviewer can reconstruct the counts without guessing.

The selected interval is a frequentist construction under a repeated-sampling model. It does not say that a fixed unknown success probability has the reported probability of lying inside this particular computed interval. Nor does missing the lower-bound threshold establish inferiority. The endpoint rule is a prospective decision convention chosen for this lesson, with assumptions that need examination before use in a real practice report.

Practice is especially likely to violate a common-rate assumption: the learner may improve, tire or remember feedback during the sequence. More repetitions do not automatically repair that model mismatch. A useful report could retain chronological blocks, assistance and item identity, then choose an analysis consistent with that collection process. The manual Wilson calculation is the baseline for understanding the proposed uncertainty statement; an agent should not make the interval look authoritative by omitting the conditions under which it was derived.

### Exercise 1

Compute the main point rate. Why is that insufficient for the declared decision?

<details><summary>Answer 1</summary>

The rate is shown above, but the rule compares the lower interval endpoint with the prospective threshold. A percentage alone does not contain that uncertainty information.

</details>

### Exercise 2

Compute the Wilson limits using the stated constant. Is this the symmetric Wald interval?

<details><summary>Answer 2</summary>

Use the displayed center and half-width. The construction adjusts both denominator and center; replacing it with a point-rate standard-error interval changes the method.

</details>

### Exercise 3

Apply the lower-bound rule. What exactly has not been established?

<details><summary>Answer 3</summary>

The main lower bound misses the threshold. That is a decision under this interval rule, not proof that the underlying rate lies above the threshold.

</details>

### Exercise 4

Apply the control with the same point rate. Why does the decision change?

<details><summary>Answer 4</summary>

The larger stipulated sample narrows the interval and raises its lower endpoint past the threshold. The arithmetic depends on the independence and common-rate assumptions.

</details>

### Exercise 5

What would invalidate reporting this as a learner mastery interval?

<details><summary>Answer 5</summary>

Unknown denominators, changed rubrics, dependent repeated takes or learning during sampling undermine the selected model. An authored count is never evidence that a learner completed those attempts.

</details>

## Source-assisted learner task

Calculate both intervals manually, record the prospective rule and explain its sampling assumptions. Inspect the retained assistance boundary. Propose a report that retains counts and unresolved dependence rather than only a percentage; state when the binomial interpretation must be withdrawn.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
