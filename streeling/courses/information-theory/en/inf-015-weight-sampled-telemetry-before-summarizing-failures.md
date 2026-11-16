---
module_id: "inf-015-weight-sampled-telemetry-before-summarizing-failures"
department: "information-theory"
course: "Weight Sampled Telemetry Before Summarizing Failures"
level: "intermediate"
prerequisites: ["inf-011-separate-compressed-size-from-preserved-information", "pm-009-separate-release-adoption-from-artifact-downloads"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Weight Sampled Telemetry Before Summarizing Failures

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An agent summarizes a retained telemetry sample as though every event had the same chance of appearing. A sampling policy may retain different classes at different probabilities. The compression prerequisite asks what a smaller representation preserves; the adoption prerequisite fixes event and cohort units. This lesson adds sampling probability as information required to interpret the retained events, rather than counting visible rows as the complete population.

Assign each retained event the reciprocal of its inclusion probability. These adjusted counts represent the number of events attributed to each sampled event under the declared design. Sum them for an adjusted total and sum only failure contributions for adjusted failures. Their ratio is a useful descriptive estimate, but it is not the same operation as taking the mean of the binary sample labels. Keep the event unit and sampling scope fixed throughout.

The [OpenTelemetry](https://opentelemetry.io/docs/specs/otel/trace/tracestate-handling/) specification calls the inverse-probability quantity an adjusted count. Our decimal probabilities are authored inputs, without reading a live trace or decoding its threshold field. The specification supports the weighting concept; it does not supply the probabilities for GA or certify this small sample as representative. The ratio of estimated totals also needs its own uncertainty analysis before a strong population statement.

The equal-probability control removes the unequal weighting and makes the raw and weighted ratios agree. Missing or zero probabilities would instead make the proposed estimator undefined. Do not replace them with convenient defaults after seeing a result. A composable evidence summary may retain inclusion metadata, but first reproduce the weighted table manually. The retained project observations list query fields and distinguish scores from learner retention; they provide no population of user failures to which these invented numbers could be attributed.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/en/inf-011-separate-compressed-size-from-preserved-information.md)

[Prerequisite: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/en/pm-009-separate-release-adoption-from-artifact-downloads.md)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading: OpenTelemetry specification 1.62.0 displayed, read 2026-10-24](https://opentelemetry.io/docs/specs/otel/trace/tracestate-handling/)

## Fixed model and control

```json
{
  "values": {
    "sampled_failures": [
      1,
      0,
      0
    ],
    "inclusion_probabilities": [
      0.5,
      0.25,
      0.25
    ]
  },
  "formula": "weight_i=1/p_i; adjusted_total=sum(weight_i); adjusted_failures=sum(weight_i*failure_i); ratio=adjusted_failures/adjusted_total; raw_rate=sum(failure_i)/n.",
  "expected": {
    "weights": [
      2,
      4,
      4
    ],
    "adjusted_total": 10,
    "adjusted_failures": 2,
    "weighted_ratio": 0.2,
    "raw_rate": 0.3333333333333333
  },
  "negative_control": {
    "values": {
      "sampled_failures": [
        1,
        0,
        0
      ],
      "inclusion_probabilities": [
        1,
        1,
        1
      ]
    },
    "expected": {
      "weights": [
        1,
        1,
        1
      ],
      "adjusted_total": 3,
      "adjusted_failures": 1,
      "weighted_ratio": 0.3333333333333333,
      "raw_rate": 0.3333333333333333
    },
    "why": "Equal inclusion weights make the weighted ratio equal the raw sample rate."
  },
  "assumptions": [
    "Positive known inclusion probabilities correspond to each retained event.",
    "Failure indicators refer to one declared event unit."
  ],
  "limits": "Adjusted counts and ratio are estimates; this finite ratio is not promised unbiased and does not reveal exact population failures."
}
```

### Exercise 1

Calculate the weight assigned to each sampled event.

<details><summary>Answer 1</summary>

The weights are `[2,4,4]`, obtained from reciprocal inclusion probabilities. They are adjusted event counts, not milliseconds, confidence values or copies of actual observed population events.

</details>

### Exercise 2

Compute adjusted total, adjusted failures and their ratio.

<details><summary>Answer 2</summary>

Adjusted total is `10`, adjusted failures `2` and weighted ratio `0.2`. Only the first event contributes to the failure total. The adjusted values are estimates under the assumed sampling design.

</details>

### Exercise 3

Compare the raw sample failure rate and explain the discrepancy.

<details><summary>Answer 3</summary>

The raw rate is `1/3=0.3333333333333333`. It assigns every sampled row equal weight. The weighted ratio gives more contribution to the lower-probability clean events, so it differs on this authored sample.

</details>

### Exercise 4

Apply the equal-probability control.

<details><summary>Answer 4</summary>

Weights become `[1,1,1]`, adjusted total `3`, failures `1` and weighted ratio `0.3333333333333333`, equal to the raw rate. Equal positive weights cancel in this ratio.

</details>

### Exercise 5

Can the weighted ratio be reported as the exact production failure rate?

<details><summary>Answer 5</summary>

No. The population is unobserved, probabilities are stipulated and finite-sample uncertainty remains. A missing probability leaves the calculation unresolved. Preserve the sampling metadata and avoid claiming that a ratio of estimated totals is automatically unbiased.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
