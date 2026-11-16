---
module_id: phi-008-separate-a-test-oracle-from-a-specification
department: philosophy
course: "Separate a Test Oracle from a Specification"
level: intermediate
prerequisites: ["phi-001-how-to-argue-well", "phi-005-test-idempotence-beyond-replayed-values"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separate a Test Oracle from a Specification

> Draft for human review. The fixed cases below are authored mathematics supported by source inspection. They are not new project measurements. Human technical, artisan, fluent-language and learner judgments remain pending. No scene host, physical sample, GPU, policy executor or learner session was run for this lesson.

## Project question

A Demerzel advisory record passes a schema test even though its evidence list is empty. Has the broader requirement for justified advice been satisfied? The stored replay actually recorded that acceptance at its pinned schema revision. We use it to separate a machine test’s oracle from a specification’s intended property. A green check is informative only about the condition its oracle decides.

[Prerequisite: phi-001-how-to-argue-well](../../philosophy/en/phi-001-how-to-argue-well.md); [Prerequisite: phi-005-test-idempotence-beyond-replayed-values](../../philosophy/en/phi-005-test-idempotence-beyond-replayed-values.md)

## Read the boundary before calculating

Read the linked prerequisite and project record before doing the arithmetic. Identify which statement comes from inspected source, which is an older recorded result, and which follows only from the premises below. A source comment, a prepared answer and an executed observation have different evidential roles. Preserve the original date and any failed or inconclusive gate when summarizing an older artifact. The direct baseline is a small handwritten calculation and a source-location table; an agent may help locate a definition, but its summary must be checked against that definition. Do not introduce a new language or automation merely to perform this finite comparison.

Define an authored requirement as having a well-formed record and at least one relevant, source-bound evidence reference. Define a weaker oracle as checking form alone. These are explicit predicates for the classroom table, not a replacement governance policy. A false positive is an oracle acceptance where the requirement is false. A false negative is an oracle rejection where it is true. Merely copying an implementation into an expected-answer function can make the two agree while preserving their shared error. Seek an independent counterexample and explain which premise it tests. The stored missing-field negative control checks form; it does not supply the missing relevance judgment.

## Fixed case and assumptions

```text
cases=["A","B","C","D"]
well_formed=[true,true,false,false]
relevant_evidence=[true,false,true,false]
spec=well_formed AND relevant_evidence
spec_values=[true,false,false,false]
weak_oracle=[true,true,false,false]
true_positive=1; false_positive=1; true_negative=2; false_negative=0
control_missing_required_field: well_formed=false
```

## Corrected exercises

### Exercise 1

Evaluate the authored specification on every case.

> **Answer:** The result is `[true,false,false,false]`. Relevant evidence alone cannot repair malformed structure under this conjunction.

### Exercise 2

Locate the weak oracle’s false positive.

> **Answer:** Case B passes form but lacks relevant evidence. It is the single false positive; the other cases give `1` true positive and `2` true negatives.

### Exercise 3

Does the actual stored schema acceptance contradict its form-only contract?

> **Answer:** No. The schema permits the empty array. The error is treating form acceptance as sufficient evidence of a broader justified-advice property.

### Exercise 4

What does removing a required field test?

> **Answer:** It supplies a form-negative control. Rejection is expected, but that success does not distinguish an empty-evidence record from a justified record.

### Exercise 5

How can a passing test share the implementation’s mistake?

> **Answer:** If both use the same weakened predicate, agreement verifies their consistency rather than the intended requirement. Keep an independently derived counterexample and specification rationale.

## Source-assisted learner task

Read the stored schema replay and required-field definitions. Write a manual requirement-to-oracle table, keeping the invented relevance predicate distinct from actual schema checks. Ask an assistant to justify the green result, then falsify any broader claim with case B. Retain the narrower correct test result.

Complete the task with the answer sections hidden. Retain your original answers, intermediate quantities, source locations, uncertainty and every form of assistance, including a hint, a translated term or an agent suggestion. Then compare with the prepared answers and record corrections without replacing the original attempt. Produce a short decision note containing the claim, its assumptions, the calculation, the negative control and the next observation that could falsify it. A correct result with missing units or source identity is incomplete evidence for transfer. The evidence packet contains five prepared learner criteria; their decisions stay null until a real attempt and an authorized review exist. Passing these arithmetic checks would establish only competence on this declared case. It would not establish an implemented adapter, a successful material process, a faster renderer or improved learning in the project. Compare your source-assisted note with the direct manual baseline: if assistance obscures an assumption or removes a refusal, revise the note before proposing any workflow change.

## Sources and validation journal

- [Project record](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Primary source](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/schemas/advisory-decision.schema.json)
- [Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
