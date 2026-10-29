---
module_id: "pm-008-size-a-fifty-course-batch-by-review-capacity"
department: "product-management"
course: "Size a Fifty Course Batch by Review Capacity"
title: "Size a Fifty Course Batch by Review Capacity"
level: "intermediate"
prerequisites: ["pm-003-review-queue-flow-metrics"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Size a Fifty Course Batch by Review Capacity

> **Draft scope.** Source-assisted authored fixed models. Human technical, fluent-language and learner decisions remain pending. No live fleet, production controller, user telemetry or learning improvement is claimed. The validation journal distinguishes tests actually executed from source reading and planned checks.

## Sources to inspect

- [pm-003-review-queue-flow-metrics.md](../../product-management/en/pm-003-review-queue-flow-metrics.md)
- [pm-002-release-evidence-gate.md](../../product-management/en/pm-002-release-evidence-gate.md)
- [production-plan.md](../../../../code/streeling/evidence/batch50-2026-10-23/production-plan.md)
- [batch-plan.json](../../../../code/streeling/evidence/batch50-2026-10-23/batch-plan.json)

The current request specifies a batch of distinct courses, with translations as additional sources rather than additional courses. How much review would that scope require? The queue-flow prerequisite explains why an inventory is not throughput. This lesson uses the actual requested batch size and explicitly fictional review minutes to expose which role would limit a proposed schedule. No human availability is inferred from the number of agents drafting.

Read the production plan and manifest as the scope authority. Count subject review per English course, fluent-language review per translated source, and learner work per course under this teaching scenario. The language workload excludes the source-language technical review already counted separately. These categories are a planning assumption, not a claim that every real course can be reviewed in the same time or that one learner attempt is sufficient for acceptance.

Multiply scope by time per item before dividing by capacity. Keep minutes, sources, courses and days visible. Pooling all reviewer minutes hides specialized roles: spare language time cannot automatically perform the subject or learner work. The optimistic parallel finish is the largest role duration under simultaneous availability and divisible work. Dependencies, limited calendar overlap, failed reviews and repeated learner attempts can only require a more detailed scenario; they were not measured here.

The packet also counts localized exercise-answer pairs and prepared learner criteria. Those are authoring and inspection obligations, not completed observations. A prepared criterion remains undecided until an actual response and assistance history exist. Faster source production therefore cannot authorize a reviewed-course claim. Retain findings and rework instead of erasing failed gates to make the planned throughput appear achieved.

For the source-assisted task, reconcile the manifest's module and locale counts manually, then create a role workload table from the stipulated rates. Ask an assistant to identify the bottlenecks and missing measurements. The direct baseline is that table, without a scheduling DSL. The zero-capacity control must block a finite promise for the required role. Reject a delivery claim if it substitutes these fictional minutes for observed capacity or counts translations as distinct courses.

## Fixed case and expected calculations

```json
{
  "values": {
    "courses": 50,
    "locales": 3,
    "translated_sources": 100,
    "exercises_per_course": 5,
    "subject_minutes_per_course": 20,
    "language_minutes_per_translation": 12,
    "learner_minutes_per_course": 25,
    "subject_minutes_per_day": 100,
    "language_minutes_per_day": 200,
    "learner_minutes_per_day": 125
  },
  "formula": "role_work=scope*minutes_per_item; role_days=role_work/role_capacity; optimistic_parallel_days=max(role_days)",
  "expected": {
    "sources": 150,
    "localized_answer_pairs": 750,
    "prepared_learner_criteria": 250,
    "subject_minutes": 1000,
    "language_minutes": 1200,
    "learner_minutes": 1250,
    "total_minutes": 3450,
    "subject_days": 10,
    "language_days": 6,
    "learner_days": 10,
    "optimistic_parallel_days": 10
  },
  "negative_control": "Zero capacity in any required role admits no finite completion estimate for its positive work.",
  "assumptions": [
    "Actual requested fifty-course scope; all durations/capacities fictional, dedicated roles, divisible work, parallel availability, no rework or waiting."
  ],
  "limits": "Capacity planning scenario, not a deadline, measured team rate, completed review or learner result."
}
```

## Retain a source-assisted learner attempt

Work from the pinned inputs listed above. Before asking for assistance, write your own prediction for the fixed case and its negative control, including the unit of every quantity and the exact comparison boundary. A short paper table is the direct manual baseline. Keep intermediate values, especially any result that contradicts your first prediction. This is an explanation task using existing sources and fixed data; it does not require installing a package, calling a paid service or introducing a new program.

Next use an assistant to locate the relevant source passage and critique your calculation. Retain the original prompt, the response, the source location it cited and the changes you accepted or rejected. A citation is useful only when its inspected content supports the specific claim. A declared stage, a data type and a prose comment supply different kinds of evidence from an executed outcome. Explain that boundary in the final answer rather than borrowing the authority of a successful-looking label.

Submit the manual baseline, corrected result, control outcome, falsifier and assistance history together. The prepared learner criteria ask whether the scope was identified, the calculation was correct, the counterexample was retained, the source supported the explanation and the conclusion respected its limits. Their decisions remain undecided until an actual learner answer exists. Answer keys below are prepared corrections, not evidence that anyone learned the material. A reviewer should preserve a failed criterion and its reason before any refinement, then judge the revised attempt separately. Runtime evidence and publication evidence, if later collected, need their own revision-bound records.

### Exercise 1

Count sources, localized pairs and prepared criteria.

<details>
<summary>Answer 1</summary>

`50*3=150` sources; `50*3*5=750` pairs; `50*5=250` criteria.

</details>

### Exercise 2

Calculate role workloads.

<details>
<summary>Answer 2</summary>

Subject `50*20=1000`, language `100*12=1200`, learner `50*25=1250` minutes; total `3450`.

</details>

### Exercise 3

Calculate role durations and parallel bound.

<details>
<summary>Answer 3</summary>

Subject `10`, language `6`, learner `10` days; optimistic parallel bound `10` days.

</details>

### Exercise 4

Evaluate a required role with zero capacity.

<details>
<summary>Answer 4</summary>

Positive required work has no finite finish estimate; do not divide by zero or call it complete.

</details>

### Exercise 5

Which inputs are actual and which fictional?

<details>
<summary>Answer 5</summary>

The requested batch scope is actual; review times, capacities and resulting calendar scenario are authored.

</details>

[Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
