---
module_id: sem-009-keep-units-in-a-composed-craft-instruction
department: semiotics
course: "Keep Units in a Composed Craft Instruction"
level: intermediate
prerequisites: ["sem-007-preserve-the-meaning-of-a-bend-angle", "phy-005-sheet-thickness-and-scene-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Keep Units in a Composed Craft Instruction

> Draft for human review. The fixed cases below are authored mathematics supported by source inspection. They are not new project measurements. Human technical, artisan, fluent-language and learner judgments remain pending. No scene host, physical sample, GPU, policy executor or learner session was run for this lesson.

## Project question

A craft instruction adds a sheet offset expressed in millimetres to a BRUTAL placement expressed in metres. The syntax accepts numbers, but do the composed instructions refer to the same length? The prerequisite distinguished angle meanings. Here we build a small dimensional ledger for composition: each operand carries quantity, unit and frame before it is added. The ledger is an advisory note, not a proposed parser or new DSL.

[Prerequisite: sem-007-preserve-the-meaning-of-a-bend-angle](../../semiotics/en/sem-007-preserve-the-meaning-of-a-bend-angle.md); [Prerequisite: phy-005-sheet-thickness-and-scene-units](../../physics/en/phy-005-sheet-thickness-and-scene-units.md)

## Read the boundary before calculating

Read the linked prerequisite and project record before doing the arithmetic. Identify which statement comes from inspected source, which is an older recorded result, and which follows only from the premises below. A source comment, a prepared answer and an executed observation have different evidential roles. Preserve the original date and any failed or inconclusive gate when summarizing an older artifact. The direct baseline is a small handwritten calculation and a source-location table; an agent may help locate a definition, but its summary must be checked against that definition. Do not introduce a new language or automation merely to perform this finite comparison.

Addition requires quantities represented in compatible units and the same frame. Convert a physical displacement before adding its numeric representation. A dimensionless scale factor can multiply a length; a length multiplied by a length has area units and cannot silently remain a displacement. Different frames also require a mapping even when both use metres. The pinned frame defines axes and matrix order but does not infer the external sheet ruler. Keep the ruler as a premise and test the composition by an independent round trip. A symmetric zero-offset example is weak because it can conceal an omitted conversion.

## Fixed case and assumptions

```text
base=0.20 m; offset=30 mm; mm_to_m=0.001 m/mm
offset_m=30*0.001=0.03 m
composed=0.20+0.03=0.23 m
wrong=0.20+30=30.20
roundtrip=0.23*1000=230 mm
scale=2; scaled_offset=2*0.03=0.06 m
control_offset=0 mm; control_composed=0.20 m
```

## Corrected exercises

### Exercise 1

Compose the two lengths correctly.

> **Answer:** Convert `30 mm` to `0.03 m`, then add to obtain `0.23 m`. A bare numeric addition does not perform this conversion.

### Exercise 2

Why does the raw addition fail as a physical instruction?

> **Answer:** The numeric result `30.20` mixes representations. Labeling it metres would imply an offset `1000` times too large; the label cannot repair the operation.

### Exercise 3

Check the result through the millimetre path.

> **Answer:** The base is `200 mm`, hence `200+30=230 mm`, agreeing with `0.23 m`. The two routes share declared units and frame.

### Exercise 4

Scale the offset and inspect the zero control.

> **Answer:** The scaled offset is `0.06 m`. With zero offset, both correct and mistaken additions can yield `0.20`, so that control alone would miss the unit error.

### Exercise 5

Are matching unit labels sufficient across different frames?

> **Answer:** No. A displacement must also have a declared frame and direction. The source’s metre convention does not establish a sheet-to-scene mapping or executed adapter.

## Source-assisted learner task

Read the pinned frame definition and the old composition record. Annotate a proposed craft instruction with quantity, unit and frame at every boundary. Compare an assistant’s composition to the manual millimetre round trip. An unequal nonzero round trip falsifies a claim that numeric syntax preserved the instruction’s meaning.

Complete the task with the answer sections hidden. Retain your original answers, intermediate quantities, source locations, uncertainty and every form of assistance, including a hint, a translated term or an agent suggestion. Then compare with the prepared answers and record corrections without replacing the original attempt. Produce a short decision note containing the claim, its assumptions, the calculation, the negative control and the next observation that could falsify it. A correct result with missing units or source identity is incomplete evidence for transfer. The evidence packet contains five prepared learner criteria; their decisions stay null until a real attempt and an authorized review exist. Passing these arithmetic checks would establish only competence on this declared case. It would not establish an implemented adapter, a successful material process, a faster renderer or improved learning in the project. Compare your source-assisted note with the direct manual baseline: if assistance obscures an assumption or removes a refusal, revise the note before proposing any workflow change.

## Sources and validation journal

- [Project record](../../../../code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Primary source](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs)
- [Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
