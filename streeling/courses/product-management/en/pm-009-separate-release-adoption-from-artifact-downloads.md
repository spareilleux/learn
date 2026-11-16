---
module_id: "pm-009-separate-release-adoption-from-artifact-downloads"
department: "product-management"
course: "Separate Release Adoption from Artifact Downloads"
title: "Separate Release Adoption from Artifact Downloads"
level: "intermediate"
prerequisites: ["pm-002-release-evidence-gate", "pm-006-test-a-pilot-against-its-decision-horizon"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Separate Release Adoption from Artifact Downloads

> **Draft scope.** Source-assisted authored fixed models. Human technical, fluent-language and learner decisions remain pending. No live fleet, production controller, user telemetry or learning improvement is claimed. The validation journal distinguishes tests actually executed from source reading and planned checks.

## Sources to inspect

- [pm-002-release-evidence-gate.md](../../product-management/en/pm-002-release-evidence-gate.md)
- [pm-006-test-a-pilot-against-its-decision-horizon.md](../../product-management/en/pm-006-test-a-pilot-against-its-decision-horizon.md)

A release artifact receives many downloads and an agent reports broad adoption. Downloads can include retries, automation, mirrors and users outside the target cohort. A release gate tells us whether an artifact is ready or readable; it does not supply a product-use denominator. The pilot-horizon prerequisite asks which decisions reuse evidence. This lesson asks which people and actions belong to an adoption claim.

The packet gives fictional event and user counts in one fixed observation window. The eligible active cohort is defined separately from distinct downloaders. Enabled users are within that cohort, task attempts are within the enabled subset, and successful tasks are within those attempts. These nesting assumptions permit the stated ratios. The downloader population is not declared to be the cohort, so its count cannot replace the denominator without changing the question.

Define adoption here as enabling the release within the eligible active cohort. This is a teaching endpoint, not a universal product definition. Report task-attempt coverage and observed task success separately. A feature can be enabled without being used, and an observed successful task need not demonstrate sustained use or learning. Choosing a stricter adoption endpoint later requires a new numerator and an explicit comparison boundary.

The downloads-to-cohort ratio is numerically calculable but has units of events per cohort member. It cannot be interpreted as a fraction of users who adopted, because the events may repeat and may come from outside the cohort. Even distinct downloader counts can exceed the eligible cohort. A dashboard should preserve the event and person units instead of capping a nonsensical percentage and calling the problem solved.

The negative control increases mirror downloads while holding every cohort action fixed. The adoption and task ratios must remain unchanged. For the source-assisted task, inspect the release-evidence lesson's distinctions and draft a measurement card naming release identity, cohort, window, event unit and outcome. Calculate the ratios manually before asking an assistant to produce a status sentence. Reject that sentence if it equates public readability with use or claims actual telemetry from these authored counts.

## Fixed case and expected calculations

```json
{
  "values": {
    "download_events": 120,
    "distinct_downloaders": 70,
    "eligible_active_cohort": 50,
    "enabled_in_cohort": 30,
    "task_attempted_in_enabled_cohort": 18,
    "task_success_in_attempted": 12
  },
  "formula": "adoption=enabled_in_cohort/eligible_active_cohort; attempted_coverage=attempted/enabled; observed_task_success=success/attempted",
  "expected": {
    "adoption": 0.6,
    "attempted_coverage": 0.6,
    "task_success_fraction": "2/3",
    "cohort_task_success_rate": 0.24,
    "downloads_per_cohort_member": 2.4
  },
  "negative_control": "A mirrored artifact can have more download events without any change in the eligible cohort or enabled users.",
  "assumptions": [
    "Fictional counts in one fixed window, stable release and cohort identity, nested enabled/attempted/success sets, downloader set not identical to eligible cohort."
  ],
  "limits": "No real telemetry, causal benefit, retention, sustained adoption or user-learning improvement was measured."
}
```

## Retain a source-assisted learner attempt

Work from the pinned inputs listed above. Before asking for assistance, write your own prediction for the fixed case and its negative control, including the unit of every quantity and the exact comparison boundary. A short paper table is the direct manual baseline. Keep intermediate values, especially any result that contradicts your first prediction. This is an explanation task using existing sources and fixed data; it does not require installing a package, calling a paid service or introducing a new program.

Next use an assistant to locate the relevant source passage and critique your calculation. Retain the original prompt, the response, the source location it cited and the changes you accepted or rejected. A citation is useful only when its inspected content supports the specific claim. A declared stage, a data type and a prose comment supply different kinds of evidence from an executed outcome. Explain that boundary in the final answer rather than borrowing the authority of a successful-looking label.

Submit the manual baseline, corrected result, control outcome, falsifier and assistance history together. The prepared learner criteria ask whether the scope was identified, the calculation was correct, the counterexample was retained, the source supported the explanation and the conclusion respected its limits. Their decisions remain undecided until an actual learner answer exists. Answer keys below are prepared corrections, not evidence that anyone learned the material. A reviewer should preserve a failed criterion and its reason before any refinement, then judge the revised attempt separately. Runtime evidence and publication evidence, if later collected, need their own revision-bound records.

### Exercise 1

Calculate the defined adoption rate.

<details>
<summary>Answer 1</summary>

`30/50=0.6` within the eligible active cohort.

</details>

### Exercise 2

Calculate attempted-task coverage.

<details>
<summary>Answer 2</summary>

`18/30=0.6` among enabled cohort members.

</details>

### Exercise 3

Calculate task success with both denominators.

<details>
<summary>Answer 3</summary>

Among attempts `12/18=2/3`; across the full cohort `12/50=0.24`.

</details>

### Exercise 4

Interpret downloads divided by cohort size.

<details>
<summary>Answer 4</summary>

`120/50=2.4` events per cohort member; this is not a user-adoption fraction.

</details>

### Exercise 5

Evaluate the mirror-download control.

<details>
<summary>Answer 5</summary>

Adoption and task ratios stay unchanged because every cohort numerator and denominator stays fixed.

</details>

[Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
