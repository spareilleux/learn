---
module_id: "cog-010-use-delayed-transfer-probes-beyond-repeated-items"
department: "cognitive-science"
course: "Use Delayed Transfer Probes Beyond Repeated Items"
title: "Use Delayed Transfer Probes Beyond Repeated Items"
level: "intermediate"
prerequisites: ["cog-007-separate-unaided-recall-from-assisted-success", "cog-008-choose-probes-that-distinguish-reasoning-models"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Use Delayed Transfer Probes Beyond Repeated Items

> **Draft scope.** Source-assisted authored fixed models. Human technical, fluent-language and learner decisions remain pending. No live fleet, production controller, user telemetry or learning improvement is claimed. The validation journal distinguishes tests actually executed from source reading and planned checks.

## Sources to inspect

- [cog-007-separate-unaided-recall-from-assisted-success.md](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md)
- [cog-008-choose-probes-that-distinguish-reasoning-models.md](../../cognitive-science/en/cog-008-choose-probes-that-distinguish-reasoning-models.md)

A practice agent reports strong performance because the learner answers repeated prompts correctly. The team wants to know whether the learner can use the same rule on a new voicing later. Those questions require different observations. The assistance prerequisite retains cue history, and the probe-design prerequisite asks whether a response distinguishes candidate rules. This lesson organizes those distinctions across exposure category and assessment delay.

The fixed packet is a fictional set of counts. Immediate repeated items, delayed repeated items and delayed novel items each have their own denominator. Novel means the exact prompt was not practiced under the declared task definition; it does not guarantee that every underlying feature is unfamiliar. A transfer claim must state what changed and which rule should remain applicable. A delayed score without that description could still measure recognition of the same answer.

One correct novel-item response had the answer exposed beforehand. Under our unaided endpoint it is ineligible, so remove it from both the correct and observed eligible counts. Keep the original raw counts and the exposure reason. Do not convert an excluded success into an observed error. No missing-item total is supplied, so these observed rates must not be represented as rates across everyone invited to participate.

Compare immediate and delayed repeated rates descriptively. Their difference does not estimate forgetting caused by time: the model supplies neither participant histories nor assignment evidence. Likewise, the novel rate is not a causal estimate of transfer produced by GA. The negative control uses only repeated prompts. It can show repeated-item success under its scoring rule, but cannot manufacture a novel-item observation.

For the source-assisted task, inspect the prerequisite's assistance exclusions and its distinction between prediction models. Design a paired GA voicing probe in which surface fingering changes while the required reasoning is named. State the delay and the answer exposure policy before any attempt. The manual baseline is a small matrix of category, delay, eligibility and response. Ask an assistant to critique whether the supposedly novel prompt leaks its answer. Reject a transfer claim if all its evidence comes from repeated items or from assisted responses relabeled unaided.

## Fixed case and expected calculations

```json
{
  "values": {
    "immediate_repeated": {
      "correct": 8,
      "observed": 10
    },
    "delayed_repeated": {
      "correct": 6,
      "observed": 10
    },
    "delayed_novel": {
      "correct": 3,
      "observed": 8
    },
    "novel_exposed_correct": 1
  },
  "formula": "rate=eligible correct/eligible observed; remove exposed item from both numerator and denominator",
  "expected": {
    "immediate_rate": 0.8,
    "delayed_repeated_rate": 0.6,
    "raw_novel_rate": 0.375,
    "eligible_novel_correct": 2,
    "eligible_novel_observed": 7,
    "eligible_novel_rate_fraction": "2/7",
    "repeated_rate_change": -0.2
  },
  "negative_control": "Repeating identical prompts cannot supply evidence of novel-item transfer.",
  "assumptions": [
    "Fictional counts, same rubric, declared delay, observed items only; exposed novel item is correct and ineligible."
  ],
  "limits": "No real learning, causal effect, optimal delay or psychometric validity is inferred."
}
```

## Retain a source-assisted learner attempt

Work from the pinned inputs listed above. Before asking for assistance, write your own prediction for the fixed case and its negative control, including the unit of every quantity and the exact comparison boundary. A short paper table is the direct manual baseline. Keep intermediate values, especially any result that contradicts your first prediction. This is an explanation task using existing sources and fixed data; it does not require installing a package, calling a paid service or introducing a new program.

Next use an assistant to locate the relevant source passage and critique your calculation. Retain the original prompt, the response, the source location it cited and the changes you accepted or rejected. A citation is useful only when its inspected content supports the specific claim. A declared stage, a data type and a prose comment supply different kinds of evidence from an executed outcome. Explain that boundary in the final answer rather than borrowing the authority of a successful-looking label.

Submit the manual baseline, corrected result, control outcome, falsifier and assistance history together. The prepared learner criteria ask whether the scope was identified, the calculation was correct, the counterexample was retained, the source supported the explanation and the conclusion respected its limits. Their decisions remain undecided until an actual learner answer exists. Answer keys below are prepared corrections, not evidence that anyone learned the material. A reviewer should preserve a failed criterion and its reason before any refinement, then judge the revised attempt separately. Runtime evidence and publication evidence, if later collected, need their own revision-bound records.

### Exercise 1

Calculate repeated-item rates.

<details>
<summary>Answer 1</summary>

Immediate `8/10=0.8`; delayed `6/10=0.6`; change `-0.2`.

</details>

### Exercise 2

Calculate raw novel-item performance.

<details>
<summary>Answer 2</summary>

`3/8=0.375`, before excluding answer exposure.

</details>

### Exercise 3

Apply the exposure exclusion.

<details>
<summary>Answer 3</summary>

Eligible correct `2`, observed `7`, rate `2/7`; preserve the excluded correct record.

</details>

### Exercise 4

Can the repeated-only control demonstrate transfer?

<details>
<summary>Answer 4</summary>

No. It contains no novel-item observation under the declared definition.

</details>

### Exercise 5

What must the actual learner record retain?

<details>
<summary>Answer 5</summary>

Prompt identity, changed features, delay, response, assistance and eligibility; no causal learning result is supplied.

</details>

[Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
