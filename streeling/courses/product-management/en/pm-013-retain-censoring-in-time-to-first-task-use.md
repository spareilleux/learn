---
module_id: "pm-013-retain-censoring-in-time-to-first-task-use"
department: "product-management"
course: "Retain Censoring in Time to First Task Use"
level: "intermediate"
prerequisites: ["pm-009-separate-release-adoption-from-artifact-downloads"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Retain Censoring in Time to First Task Use

> This lesson uses authored fixed inputs and inspected source passages. The numbers, histories and labels are teaching constructions. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

Some members of a fictional GA release cohort have less followup than others. A person last observed without using the task is not known never to use it later. A fixed-window event fraction and a time-to-first-use estimate answer different questions when observation ends early. The adoption prerequisite fixes the person and task units; this lesson adds exposure time.

NIST’s Kaplan-Meier reading defines event-time risk sets and product-limit factors for censored histories. We adapt the event label from failure to first eligible task use. This is an authored endpoint, with no actual release telemetry. Remove a censored person from later risk sets, but do not count censoring as an event.

The control extends one non-event followup. Observed event count stays fixed while the later risk set changes, so the estimate changes. A population interpretation also assumes censoring is noninformative for the endpoint. If frustrated users disappear earlier, that assumption can fail. A correct product calculation cannot diagnose that mechanism. Keep individual followup and censor flags in any proposed evidence summary rather than replacing absent future observations with failures or successes.

## Sources and project boundary

The retained Learn helper separates frontmatter, heading and body in `parseModule`, and indexes English module names in `englishModuleKeys`. Those inspected representations let a task name its source and metadata; they do not implement the authored operation. The retained practice record instead distinguishes retrieval metrics from learner evidence. Inspect the particular file linked below and retain only the observation it actually supports. No model input in this lesson was estimated from that file.

[Prerequisite: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/en/pm-009-separate-release-adoption-from-artifact-downloads.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading](https://itl.nist.gov/div898/handbook/apr/section2/apr215.htm)

## Fixed model and control

```json
{
  "values": {
    "followup_days": [
      1,
      2,
      3,
      4
    ],
    "event": [
      1,
      0,
      1,
      0
    ],
    "horizon_days": 3
  },
  "formula": "Event=first eligible task use; zero=censored at followup. At each event time <=horizon, risk=count(followup>=time), failures=count(event=1 at time); S multiplies (1-failures/risk). Report 1-S and raw observed events/N separately.",
  "expected": {
    "event_times": [
      1,
      3
    ],
    "risk_sets": [
      4,
      2
    ],
    "survival": [
      0.75,
      0.375
    ],
    "cumulative_first_use": 0.625,
    "raw_event_fraction": 0.5
  },
  "negative_control": {
    "values": {
      "followup_days": [
        1,
        4,
        3,
        4
      ],
      "event": [
        1,
        0,
        1,
        0
      ],
      "horizon_days": 3
    },
    "expected": {
      "event_times": [
        1,
        3
      ],
      "risk_sets": [
        4,
        3
      ],
      "survival": [
        0.75,
        0.5
      ],
      "cumulative_first_use": 0.5,
      "raw_event_fraction": 0.5
    },
    "why": "Extending the early censored followup changes the later risk set without changing observed event count."
  },
  "assumptions": [
    "Common eligible entry time and exact first-event times; distinct event times.",
    "Independent noninformative censoring is required for a population interpretation; no competing events."
  ],
  "limits": "Authored time-to-event estimate, not observed adoption, causal benefit, retention or uncertainty interval.",
  "input_types": {
    "followup_days": "list<positive real>",
    "event": "same-length list<0|1>",
    "horizon_days": "positive real"
  }
}
```

### Exercise 1

Construct the event-time risk sets.

<details><summary>Answer 1</summary>

At times `[1,3]`, the risk sets have sizes `[4,2]`. The person censored earlier is absent from the later set.

</details>

### Exercise 2

Compute the product-limit survival.

<details><summary>Answer 2</summary>

The values are `[0.75,0.375]`; each event multiplies the preceding survival by its non-event fraction.

</details>

### Exercise 3

Compare cumulative first use and raw fraction.

<details><summary>Answer 3</summary>

The estimate is `0.625`, while the observed event fraction is `0.5`. These quantities use different handling of followup.

</details>

### Exercise 4

Apply the extended-followup control.

<details><summary>Answer 4</summary>

Risk sets become `[4,3]`, survival `[0.75,0.5]` and cumulative first use `0.5`. The raw fraction stays `0.5`.

</details>

### Exercise 5

Can independent censoring be inferred from a correct calculation?

<details><summary>Answer 5</summary>

No. It concerns why followup ends relative to future event times. Actual context and evidence are needed; the finite table stipulates no such observation.

</details>

## Source-assisted learner task

Prepare a first-task-use measurement card for a fictional GA release cohort, retaining censor flags.

**Direct manual baseline:** Sort event times, count who is still observed just before each and multiply the factors by hand.

**Falsifier:** Censoring is counted as an event or someone remains at risk after their followup ends.

Save a first answer before opening the corrected exercises. Copy the input identities and units, write the intermediate quantities, and distinguish the calculation from the interpretation. A correct number with the wrong denominator, state boundary or counting unit does not meet the task. Retain a surprising intermediate result rather than changing the input to make the final answer look plausible.

Read the cited primary passage within the scope recorded in the packet. Compare its actual definition with the authored rule in the fixed model. The reference may motivate a concept without specifying our entire model. Record the version or date, the passage used and the exact assumption you imported. An accessible page or a successful file read is not evidence that a claim has been verified.

Inspect the retained project artifact and one prerequisite. Separate what the file actually represents from what this new task hypothesizes. Preserve source revision and assistance history. Ask an assistant to challenge an assumption only after saving the manual baseline, then keep its prompt, reply, accepted correction and rejected suggestion. Source lookup and calculator use are permitted assistance, not unaided recall.

Run the changed input through the same reasoning on paper. State the falsifier before proposing an agent abstraction or a composable DSL expression. If an abstraction drops the counterexample or changes the accepted endpoint, it fails this task even if its response is shorter. Compare a direct table or typed record first; no new language or production engine is required.

Submit original and corrected answers together with the control result, source passage and remaining uncertainty. The packet prepares a separate criterion for each exercise, with every learner decision undecided. An answer key, a byte hash and an author self-check are different evidence from an actual learner attempt. A future dogfood comparison must retain actual attempts on the same versioned task and the direct baseline before claiming a useful change.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
