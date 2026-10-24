---
module_id: dv-012-compute-quantiles-before-combining-latency-cohorts
department: data-visualization
course: "Compute Quantiles Before Combining Latency Cohorts"
level: intermediate
prerequisites: ["dv-003-instrument-cohorts-and-units", "dv-005-baselines-alerts-and-targets"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Compute Quantiles Before Combining Latency Cohorts

> Draft for human review. The fixed cases below are authored mathematics supported by source inspection. They are not new project measurements. Human technical, artisan, fluent-language and learner judgments remain pending. No scene host, physical sample, GPU, policy executor or learner session was run for this lesson.

## Project question

A GA renderer report and a course-publication worker each supply a median duration. May a dashboard average those medians to obtain the median of all requests? The historical BRUTAL record already warns that timing endpoints differed across old reports and that coexistence remained inconclusive. We preserve that boundary and use new authored samples only to study how quantiles behave under pooling.

[Prerequisite: dv-003-instrument-cohorts-and-units](../../data-visualization/en/dv-003-instrument-cohorts-and-units.md); [Prerequisite: dv-005-baselines-alerts-and-targets](../../data-visualization/en/dv-005-baselines-alerts-and-targets.md)

## Read the boundary before calculating

Read the linked prerequisite and project record before doing the arithmetic. Identify which statement comes from inspected source, which is an older recorded result, and which follows only from the premises below. A source comment, a prepared answer and an executed observation have different evidential roles. Preserve the original date and any failed or inconclusive gate when summarizing an older artifact. The direct baseline is a small handwritten calculation and a source-location table; an agent may help locate a definition, but its summary must be checked against that definition. Do not introduce a new language or automation merely to perform this finite comparison.

NIST documents several percentile conventions, so choose the rule before comparing values. Here use the nearest-rank quantile: sort the finite observations and choose the element at the ceiling of probability times count, with ranks starting at one. This is an explicit teaching convention, not a claim that every project metric uses it. Pool raw observations only when units, endpoints and intended populations are comparable. A mean of subgroup quantiles need not be any pooled quantile. Repeated identical values remain separate observations in this finite list; their presence is not evidence of independent measurements or a representative workload.

## Fixed case and assumptions

```text
A_ms=[1,2,100]; B_ms=[3,4,5,6,7]
Q(p,x)=sorted(x)[ceil(p*len(x))-1]
Q(0.5,A)=2; Q(0.5,B)=5; mean_medians=3.5
pooled_ms=[1,2,3,4,5,6,7,100]; Q(0.5,pooled)=4
Q(0.9,A)=100; Q(0.9,B)=7; Q(0.9,pooled)=100
control_A_ms=[2,2]; control_B_ms=[2,2,2]; Q(0.5,control_pooled)=2
```

## Corrected exercises

### Exercise 1

Find the two medians using the declared rule.

> **Answer:** They are `2 ms` and `5 ms`. Their simple mean is `3.5 ms`; that is a new summary, not a pooled median.

### Exercise 2

Compute the pooled median.

> **Answer:** There are `8` sorted observations. Rank `4` gives `4 ms`. The declared rule matters for the even-sized sample.

### Exercise 3

Find the pooled upper quantile in the model.

> **Answer:** At `0.9`, rank `8` gives `100 ms`. Averaging the subgroup values would give `53.5 ms`, which is not this pooled quantile.

### Exercise 4

What does the constant-value control show?

> **Answer:** All medians equal `2 ms`. Agreement can occur, so the lesson rejects a general averaging rule rather than claiming averaging always disagrees.

### Exercise 5

May old different-endpoint renderer timings be pooled after unit conversion?

> **Answer:** No. Units alone do not reconcile different measured intervals. Preserve the historical failed and inconclusive gates; request matched endpoints and raw samples before pooling.

## Source-assisted learner task

Read the historical comparison’s timing-endpoint fields. Write a manual table separating compatible authored samples from old incomparable measurements. Use an assistant to propose a pooled caption, then falsify it if it substitutes averaged medians or silently merges different timing endpoints.

Complete the task with the answer sections hidden. Retain your original answers, intermediate quantities, source locations, uncertainty and every form of assistance, including a hint, a translated term or an agent suggestion. Then compare with the prepared answers and record corrections without replacing the original attempt. Produce a short decision note containing the claim, its assumptions, the calculation, the negative control and the next observation that could falsify it. A correct result with missing units or source identity is incomplete evidence for transfer. The evidence packet contains five prepared learner criteria; their decisions stay null until a real attempt and an authorized review exist. Passing these arithmetic checks would establish only competence on this declared case. It would not establish an implemented adapter, a successful material process, a faster renderer or improved learning in the project. Compare your source-assisted note with the direct manual baseline: if assistance obscures an assumption or removes a refusal, revise the note before proposing any workflow change.

## Sources and validation journal

- [Project record](../../../../code/streeling/evidence/brutal-composition-2026-10-22/historical-comparison.json)
- [Primary source](https://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm)
- [Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
