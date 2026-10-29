---
module_id: "pm-010-standardize-dogfood-failures-to-a-declared-task-mix"
department: "product-management"
course: "Standardize Dogfood Failures to a Declared Task Mix"
level: "intermediate"
prerequisites: ["pm-009-separate-release-adoption-from-artifact-downloads", "cog-009-counterbalance-practice-order-before-comparing-interfaces"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Standardize Dogfood Failures to a Declared Task Mix

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A team compares two dogfood reports and celebrates a lower pooled failure percentage. One report may simply contain more routine tasks and fewer difficult edge cases. The adoption prerequisite defines who and what belongs in a denominator; this lesson asks how the mixture of task classes changes the summary even when each class performs identically. A comparison needs a declared target mixture before the pooled headline is interpreted.

Calculate failure rate within each task stratum first. Those rates preserve the different difficulty profiles represented by the authored data. The pooled rate weights strata by the actual attempt counts. The standardized rate instead weights them by the declared target mix. These are different questions: what happened in the sample, and what summary would these stratum rates imply under the target weights? Neither automatically estimates the distribution of future users.

[NIST](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)’s blocking discussion motivates retaining nuisance groups and comparing within them. Our fixed mixture arithmetic is not itself a randomized experiment or a causal adjustment for every confounder. A stratum may still contain varied tasks, assisted attempts or repeated learners. Keep those limitations explicit instead of treating standardization as proof that all comparisons are fair. The target mix is an authored choice requiring a project reason.

The control changes sample counts while keeping both within-stratum rates equal. Its pooled percentage moves toward the standardized value without any improvement in either class. This is the falsifier for a naive improvement headline. The retained project source lists exercise fields but supplies no actual learner-answer events, so it cannot calibrate our counts. Before asking an agent to report a rollout, compute both summaries manually and keep task identity, source revision and assistance visible.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/en/pm-009-separate-release-adoption-from-artifact-downloads.md)

[Prerequisite: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/en/cog-009-counterbalance-practice-order-before-comparing-interfaces.md)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading: NIST/SEMATECH e-Handbook section 5.3.3.2, read 2026-10-24](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

## Fixed model and control

```json
{
  "values": {
    "strata": [
      "routine",
      "edge"
    ],
    "attempts": [
      30,
      10
    ],
    "failures": [
      3,
      4
    ],
    "target_weights": [
      0.9,
      0.1
    ]
  },
  "formula": "rate_i=failures_i/attempts_i; pooled=sum(failures)/sum(attempts); standardized=sum(target_weight_i*rate_i).",
  "expected": {
    "stratum_rates": [
      0.1,
      0.4
    ],
    "pooled_rate": 0.175,
    "standardized_rate": 0.13
  },
  "negative_control": {
    "values": {
      "strata": [
        "routine",
        "edge"
      ],
      "attempts": [
        90,
        10
      ],
      "failures": [
        9,
        4
      ],
      "target_weights": [
        0.9,
        0.1
      ]
    },
    "expected": {
      "stratum_rates": [
        0.1,
        0.4
      ],
      "pooled_rate": 0.13,
      "standardized_rate": 0.13
    },
    "why": "Changing sample mix to match the declared target aligns pooled and standardized rates without improving either stratum."
  },
  "assumptions": [
    "Target weights are authored, nonnegative and sum to unity.",
    "Within-stratum rates are descriptive of supplied attempts; no representativeness guarantee."
  ],
  "limits": "No real dogfood cohort, user distribution, causal improvement or statistical precision was measured."
}
```

### Exercise 1

Calculate the two stratum failure rates.

<details><summary>Answer 1</summary>

Routine rate is `3/30=0.1`; edge rate is `4/10=0.4`. Preserve the task labels and denominators, because the pooled value alone hides the much higher edge-case failure rate.

</details>

### Exercise 2

Compute the pooled rate in the main sample.

<details><summary>Answer 2</summary>

It is `7/40=0.175`. This describes the supplied sample mixture. It does not use the target weights, so it should not be labeled a standardized target-population rate.

</details>

### Exercise 3

Compute the rate standardized to the declared target mix.

<details><summary>Answer 3</summary>

It is `0.9*0.1+0.1*0.4=0.13`. This applies the authored weights to the stratum rates. The calculation does not validate those weights as an actual usage distribution.

</details>

### Exercise 4

Apply the control and determine whether either stratum improved.

<details><summary>Answer 4</summary>

The pooled rate becomes `13/100=0.13`, matching the standardized rate. Stratum rates remain `[0.1,0.4]`. The lower pooled headline results from changed mix, without a within-stratum improvement.

</details>

### Exercise 5

What should a future dogfood comparison retain?

<details><summary>Answer 5</summary>

Keep class definitions, attempts, failures, target weights and their rationale, actual answers, assistance and source revisions. Compare like strata before an aggregate. A changed task mix or invented counts cannot establish a real feature improvement.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
