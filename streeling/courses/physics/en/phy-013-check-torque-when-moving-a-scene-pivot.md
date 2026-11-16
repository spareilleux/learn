---
module_id: phy-013-check-torque-when-moving-a-scene-pivot
department: physics
course: "Check Torque When Moving a Scene Pivot"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Check Torque When Moving a Scene Pivot

> Draft for human review. The fixed cases below are authored mathematics supported by source inspection. They are not new project measurements. Human technical, artisan, fluent-language and learner judgments remain pending. No scene host, physical sample, GPU, policy executor or learner session was run for this lesson.

## Project question

A future IX craft viewer moves an object origin while keeping the visible panel fixed. Does the load moment stay unchanged? A coordinate edit can preserve geometry while changing the point about which torque is reported. The pinned BRUTAL frame uses metres; it does not supply mass, applied forces or a physical hinge. Those must be explicit teaching assumptions.

[Prerequisite: phy-005-sheet-thickness-and-scene-units](../../physics/en/phy-005-sheet-thickness-and-scene-units.md)

## Read the boundary before calculating

Read the linked prerequisite and project record before doing the arithmetic. Identify which statement comes from inspected source, which is an older recorded result, and which follows only from the premises below. A source comment, a prepared answer and an executed observation have different evidential roles. Preserve the original date and any failed or inconclusive gate when summarizing an older artifact. The direct baseline is a small handwritten calculation and a source-location table; an agent may help locate a definition, but its summary must be checked against that definition. Do not introduce a new language or automation merely to perform this finite comparison.

The torque definition in OpenStax uses the vector from the chosen origin to the application point crossed with force. In the authored planar case, calculate the signed component perpendicular to the page. Move the reporting origin without moving the force application point. This differs from translating the entire physical configuration, where both points move together and their difference is unchanged. A pivot name is therefore insufficient for a mechanical handoff. Record its position and whether it is merely a modeling origin or an actual support. The scene-orientation record motivates explicit frames but contains no force experiment.

## Fixed case and assumptions

```text
P=(0.30,0,0) m; O=(0,0,0) m; O2=(0.10,0,0) m
F=(0,-20,0) N
r=P-O; tau=r cross F
tau_z=-6 N*m; tau2_z=-4 N*m
P3=(0.40,0,0) m; O3=(0.10,0,0) m; tau3_z=-6 N*m
```

## Corrected exercises

### Exercise 1

Compute the original moment and its sign.

> **Answer:** The lever arm is `0.30 m`; the moment is `-6 N*m`. The sign follows the declared axes and cross-product order.

### Exercise 2

Keep the panel fixed and use the second origin. What changes?

> **Answer:** The arm becomes `0.20 m` and the moment `-4 N*m`. The force is unchanged; its reporting point changed.

### Exercise 3

Translate both points using the control. Does torque change?

> **Answer:** No: `0.40-0.10=0.30 m`, hence `-6 N*m`. A common translation preserves the relative arm.

### Exercise 4

Move the reporting origin to the force application point. Is there no force?

> **Answer:** The arm and moment are `0`, but the applied force remains `20 N` downward. Zero moment about that point is not zero load.

### Exercise 5

May this calculation certify a craft hinge?

> **Answer:** No. It gives a moment about declared points. Support reactions, material strength and motion are missing; no load capacity was measured.

## Source-assisted learner task

Using the project record and the pinned BRUTAL frame definition, prepare a pivot handoff distinguishing a fixed panel from a translated assembly. Recompute the model with the reporting origin at the application point. A claim that every origin gives the same moment is falsified by the unequal moments above.

Complete the task with the answer sections hidden. Retain your original answers, intermediate quantities, source locations, uncertainty and every form of assistance, including a hint, a translated term or an agent suggestion. Then compare with the prepared answers and record corrections without replacing the original attempt. Produce a short decision note containing the claim, its assumptions, the calculation, the negative control and the next observation that could falsify it. A correct result with missing units or source identity is incomplete evidence for transfer. The evidence packet contains five prepared learner criteria; their decisions stay null until a real attempt and an authorized review exist. Passing these arithmetic checks would establish only competence on this declared case. It would not establish an implemented adapter, a successful material process, a faster renderer or improved learning in the project. Compare your source-assisted note with the direct manual baseline: if assistance obscures an assumption or removes a refusal, revise the note before proposing any workflow change.

## Sources and validation journal

- [Project record](../../../../code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json)
- [Primary source](https://openstax.org/books/university-physics-volume-1/pages/10-6-torque)
- [Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
