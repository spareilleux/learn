---
module_id: sem-010-distinguish-stable-course-identity-from-display-names
department: semiotics
course: "Distinguish Stable Course Identity from Display Names"
level: intermediate
prerequisites: ["sem-004-face-identity-under-reindexing", "dv-008-streeling-evidence-stage-map"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguish Stable Course Identity from Display Names

> Draft for human review. The fixed cases below are authored mathematics supported by source inspection. They are not new project measurements. Human technical, artisan, fluent-language and learner judgments remain pending. No scene host, physical sample, GPU, policy executor or learner session was run for this lesson.

## Project question

Learn translates a course title and later revises its wording. Should that create a new course, a new locale, or a new content version? The pinned module reader extracts metadata and a heading, while module-key logic removes locale suffixes from filenames. The task is to interpret these separate signs without counting translations as new core courses. Source identity and a human-facing label answer different questions.

[Prerequisite: sem-004-face-identity-under-reindexing](../../semiotics/en/sem-004-face-identity-under-reindexing.md); [Prerequisite: dv-008-streeling-evidence-stage-map](../../data-visualization/en/dv-008-streeling-evidence-stage-map.md)

## Read the boundary before calculating

Read the linked prerequisite and project record before doing the arithmetic. Identify which statement comes from inspected source, which is an older recorded result, and which follows only from the premises below. A source comment, a prepared answer and an executed observation have different evidential roles. Preserve the original date and any failed or inconclusive gate when summarizing an older artifact. The direct baseline is a small handwritten calculation and a source-location table; an agent may help locate a definition, but its summary must be checked against that definition. Do not introduce a new language or automation merely to perform this finite comparison.

Use an authored table with stable identity, locale, display title and content revision. Count distinct stable identities for the core inventory, distinct identity-locale pairs for coverage, and distinct content revisions only for version tracking. Two titles can match while identifying different courses; two titles can differ while identifying translations of one course. Conversely, a reused identity does not prove unchanged content. The source helper offers an indexing convention, not a global guarantee that every producer supplies unique identifiers. Duplicate detection and source-bound review remain necessary when assembling a catalogue.

## Fixed case and assumptions

```text
rows=[
 {"id":"course-a","locale":"en","title":"Clearance","revision":"r1"},
 {"id":"course-a","locale":"fr","title":"Jeu","revision":"r1"},
 {"id":"course-a","locale":"es","title":"Holgura","revision":"r1"},
 {"id":"course-b","locale":"en","title":"Clearance","revision":"r1"}
]
rows_count=4; distinct_ids=2; distinct_id_locale_pairs=4
rename_course_a_en_title="Panel Clearance"
renamed_distinct_ids=2
control_duplicate={"id":"course-a","locale":"en","revision":"r2"}
```

## Corrected exercises

### Exercise 1

Count core identities and locale coverage rows.

> **Answer:** There are `2` identities and `4` identity-locale pairs. The row count is not the distinct-course count.

### Exercise 2

Rename the first display title. What inventory count changes?

> **Answer:** Neither count changes: identities remain `2` and coverage pairs `4`. A title edit may still alter reviewed bytes and require a new content check.

### Exercise 3

Can equal titles merge the two identities?

> **Answer:** No. The shared display word does not establish common course identity. Retain both keys and investigate accidental duplicates separately.

### Exercise 4

Append the duplicate control. Does coverage increase?

> **Answer:** Rows become `5` but distinct pairs remain `4`. The repeated identity-locale has conflicting revisions and needs reconciliation, not credit as another translation.

### Exercise 5

Does stable identity carry old review approval to changed bytes?

> **Answer:** No. Identity supports correspondence; review applies to its exact target content. Preserve content hashes and the applicable verdict separately from titles.

## Source-assisted learner task

Inspect parseModule and moduleKey in the pinned Learn helper. Manually trace one existing course and its translations through filename, metadata and heading. Compare an assistant’s inventory count with the distinct-key table. Counting a renamed title or duplicate locale as a new course falsifies the proposed inventory rule.

Complete the task with the answer sections hidden. Retain your original answers, intermediate quantities, source locations, uncertainty and every form of assistance, including a hint, a translated term or an agent suggestion. Then compare with the prepared answers and record corrections without replacing the original attempt. Produce a short decision note containing the claim, its assumptions, the calculation, the negative control and the next observation that could falsify it. A correct result with missing units or source identity is incomplete evidence for transfer. The evidence packet contains five prepared learner criteria; their decisions stay null until a real attempt and an authorized review exist. Passing these arithmetic checks would establish only competence on this declared case. It would not establish an implemented adapter, a successful material process, a faster renderer or improved learning in the project. Compare your source-assisted note with the direct manual baseline: if assistance obscures an assumption or removes a refusal, revise the note before proposing any workflow change.

## Sources and validation journal

- [Project record](../../../../scripts/streeling-lib.mjs)
- [Primary source](https://github.com/spareilleux/learn/blob/8f13637ae4596b614c2ba493b596b6a08e1cf43a/scripts/streeling-lib.mjs)
- [Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
