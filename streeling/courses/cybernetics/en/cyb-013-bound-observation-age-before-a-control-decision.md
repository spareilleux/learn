---
module_id: "cyb-013-bound-observation-age-before-a-control-decision"
department: "cybernetics"
course: "Bound Observation Age Before a Control Decision"
level: "intermediate"
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "net-008-map-clock-domains-before-ordering-events"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Bound Observation Age Before a Control Decision

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A dashboard still displays a harmless-looking value while an agent prepares a correction. The display may be current, or it may be the last successful sample. The observation prerequisite asks whether evidence exists; the clock prerequisite asks whether timestamps are comparable. This lesson adds a quantitative question: how much could the value have changed since the observation under an explicitly assumed rate bound?

The model treats the observation as exact at its timestamp and permits either direction of change afterward. Multiply elapsed time by the maximum absolute change rate to obtain a radius around the old value. This is a reachable interval under a bound, not a fitted prediction and not a confidence interval. Its endpoints are possibilities allowed by the assumptions; they are not measurements of the current system.

A threshold decision must inspect the whole interval. If its upper endpoint exceeds the allowed limit, the old sample cannot certify that the current value is safe. That does not establish a violation: a constant trajectory remains possible. Conversely, a wholly acceptable interval supports the stated bound-based certificate only while the rate assumption remains valid. An assistant should preserve this asymmetry between unknown and unsafe.

The retained project record separates a repeated summary from a new probe. Use it to challenge a status report that refreshes a document timestamp without refreshing the underlying observation. A proposed composable observation envelope may carry both timestamps, but first keep them separate manually. The control changes freshness while keeping the displayed value fixed. If a helper produces the same interval, it has discarded decision-relevant age rather than demonstrated robustness.

The pinned [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) block updates `gpuSmooth` only inside the successful timing-query branch. A failed query does not refresh that stored value in the inspected block. Its source therefore gives a concrete reason to distinguish reading a stored value from observing a fresh sample; it supplies no measured rate bound.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: cyb-004-observe-before-correcting-a-feedback-loop](../../cybernetics/en/cyb-004-observe-before-correcting-a-feedback-loop.md)

[Prerequisite: net-008-map-clock-domains-before-ordering-events](../../network-science/en/net-008-map-clock-domains-before-ordering-events.md)

[Retained project artifact](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Primary reading: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Primary reading: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Fixed model and control

```json
{
  "values": {
    "now_seconds": 10,
    "observed_at_seconds": 6,
    "observed_value": 4,
    "max_change_per_second": 0.5,
    "upper_limit": 5
  },
  "formula": "age=now-observed_at; radius=max_change_per_second*age; possible current interval=[observed_value-radius,observed_value+radius]; safe iff interval upper<=upper_limit.",
  "expected": {
    "age_seconds": 4,
    "radius": 2,
    "interval": [
      2,
      6
    ],
    "safe_certified": false
  },
  "negative_control": {
    "values": {
      "now_seconds": 10,
      "observed_at_seconds": 9,
      "observed_value": 4,
      "max_change_per_second": 0.5,
      "upper_limit": 5
    },
    "expected": {
      "age_seconds": 1,
      "radius": 0.5,
      "interval": [
        3.5,
        4.5
      ],
      "safe_certified": true
    },
    "why": "Same displayed value with a younger timestamp gives a smaller worst-case interval."
  },
  "assumptions": [
    "Same monotonic clock; exact initial measurement.",
    "Absolute rate bound holds throughout the elapsed interval.",
    "Safe means at or below the authored upper limit."
  ],
  "limits": "Failure to certify is uncertainty, not observed violation. No rate bound or real sensor was measured."
}
```

### Exercise 1

Compute age and the worst-case radius for the main case.

<details><summary>Answer 1</summary>

Age is `4` seconds and radius is `2` value units. The rate has units of value units per second, so multiplying by elapsed seconds gives a compatible displacement bound, not a new observed value.

</details>

### Exercise 2

What current interval follows, and can safety be certified?

<details><summary>Answer 2</summary>

The interval is `[2,6]`. Since its upper endpoint exceeds `5`, `safe_certified=false`. The sample cannot establish the desired certificate under the declared rate bound.

</details>

### Exercise 3

Does this failure to certify prove a current violation?

<details><summary>Answer 3</summary>

No. The constant path at `4` and paths up to `6` are both allowed. The conclusion is unresolved current safety, not an observed threshold breach or an instruction to actuate.

</details>

### Exercise 4

Apply the fresher-observation control and compare the decision.

<details><summary>Answer 4</summary>

Age becomes `1`, radius `0.5` and interval `[3.5,4.5]`. Therefore `safe_certified=true`. Identical displayed values can support different certificates because their ages differ.

</details>

### Exercise 5

What source and measurement fields must a real dogfood attempt retain?

<details><summary>Answer 5</summary>

Keep the underlying observation identity and timestamp, reading time, clock mapping, units and evidence for the rate bound. A newly written summary is insufficient. No real sensor, bound validation or corrective action was observed here.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
