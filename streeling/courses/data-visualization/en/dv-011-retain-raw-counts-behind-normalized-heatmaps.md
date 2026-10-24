---
module_id: dv-011-retain-raw-counts-behind-normalized-heatmaps
department: data-visualization
course: "Retain Raw Counts Behind Normalized Heatmaps"
level: intermediate
prerequisites: ["dv-002-denominators-and-test-populations", "dv-008-streeling-evidence-stage-map"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Retain Raw Counts Behind Normalized Heatmaps

> Draft for human review. The fixed cases below are authored mathematics supported by source inspection. They are not new project measurements. Human technical, artisan, fluent-language and learner judgments remain pending. No scene host, physical sample, GPU, policy executor or learner session was run for this lesson.

## Project question

A Learn review dashboard normalizes every row of an evidence-status heatmap. Two rows look equally successful, yet one covers a tiny group and the other a larger group. What can still be reconstructed from the displayed colors? The old advisory-schema replay is an actual stored record of a narrow check; it is not an observation of the invented review cells here. We use the dashboard problem to study an information-losing display operation.

[Prerequisite: dv-002-denominators-and-test-populations](../../data-visualization/en/dv-002-denominators-and-test-populations.md); [Prerequisite: dv-008-streeling-evidence-stage-map](../../data-visualization/en/dv-008-streeling-evidence-stage-map.md)

## Read the boundary before calculating

Read the linked prerequisite and project record before doing the arithmetic. Identify which statement comes from inspected source, which is an older recorded result, and which follows only from the premises below. A source comment, a prepared answer and an executed observation have different evidential roles. Preserve the original date and any failed or inconclusive gate when summarizing an older artifact. The direct baseline is a small handwritten calculation and a source-location table; an agent may help locate a definition, but its summary must be checked against that definition. Do not introduce a new language or automation merely to perform this finite comparison.

Divide each cell by its row total only when that total is positive. Store the original matrix, row labels, population definition and normalization rule beside the display. Multiplying a whole positive row by any factor preserves its normalized values, so the color map cannot identify the original count. Keeping a row total permits reconstruction before rounding; rounded percentages may leave several integer possibilities. An empty row has no empirical proportion and should remain missing rather than appear as a measured failure row. This extends the prerequisite’s weighted-rate arithmetic with a many-to-one transformation and an explicit reconstruction condition.

## Fixed case and assumptions

```text
columns=["pass","fail"]
A=[1,1]; B=[20,20]; Empty=[0,0]
row_normalized_A=[0.5,0.5]; row_normalized_B=[0.5,0.5]
raw_column_totals=[21,21]; raw_total=42
control_C=[2,8]; normalized_C=[0.2,0.8]
Empty_normalized=null
```

## Corrected exercises

### Exercise 1

Normalize the two nonempty balanced rows.

> **Answer:** Both become `[0.5,0.5]`, although their totals are `2` and `40`. Matching colors do not establish matching evidence volume.

### Exercise 2

Can the normalized rows alone recover the raw totals?

> **Answer:** No. `[1,1]` and `[20,20]` are distinct preimages. Retain the raw counts or exact totals with unrounded proportions.

### Exercise 3

Aggregate the raw balanced rows.

> **Answer:** The column totals are `[21,21]` over `42` records. The overall pass proportion is `0.5`, with its denominator retained.

### Exercise 4

Normalize the unbalanced control and the empty row.

> **Answer:** The control is `[0.2,0.8]`; the empty row is `null`. Filling it with `[0,0]` would disguise an undefined proportion as measured values.

### Exercise 5

Does a normalized review-status cell establish an authorized review?

> **Answer:** No. Its count still needs the underlying record and exact-source join. Normalization changes presentation, not the authority or validity of a receipt.

## Source-assisted learner task

Read the stored schema replay and locate its accepted empty-evidence case. Design a manual raw-count table for a proposed Learn status heatmap; label the authored cells as hypothetical. Ask an assistant for a caption and reject it if it infers equal sample sizes or human approval from equal normalized colors.

Complete the task with the answer sections hidden. Retain your original answers, intermediate quantities, source locations, uncertainty and every form of assistance, including a hint, a translated term or an agent suggestion. Then compare with the prepared answers and record corrections without replacing the original attempt. Produce a short decision note containing the claim, its assumptions, the calculation, the negative control and the next observation that could falsify it. A correct result with missing units or source identity is incomplete evidence for transfer. The evidence packet contains five prepared learner criteria; their decisions stay null until a real attempt and an authorized review exist. Passing these arithmetic checks would establish only competence on this declared case. It would not establish an implemented adapter, a successful material process, a faster renderer or improved learning in the project. Compare your source-assisted note with the direct manual baseline: if assistance obscures an assumption or removes a refusal, revise the note before proposing any workflow change.

## Sources and validation journal

- [Project record](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Primary source](https://github.com/spareilleux/learn/blob/8f13637ae4596b614c2ba493b596b6a08e1cf43a/scripts/streeling-lib.mjs)
- [Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
