---
module_id: phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh
department: physics
course: "Preserve Mass Assumptions When Scaling a Craft Mesh"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preserve Mass Assumptions When Scaling a Craft Mesh

> Draft for human review. The fixed cases below are authored mathematics supported by source inspection. They are not new project measurements. Human technical, artisan, fluent-language and learner judgments remain pending. No scene host, physical sample, GPU, policy executor or learner session was run for this lesson.

## Project question

A craft scene is doubled in width and height. Should its mass double, quadruple or increase eightfold? The answer depends on whether thickness scales and whether density or total mass is held fixed. The inspected BRUTAL model describes boxes, transforms and surfaces; those descriptions are not material-density measurements. This lesson adds a mass ledger to a geometric scaling discussion without turning a visual material name into a physical specification.

[Prerequisite: phy-005-sheet-thickness-and-scene-units](../../physics/en/phy-005-sheet-thickness-and-scene-units.md)

## Read the boundary before calculating

Read the linked prerequisite and project record before doing the arithmetic. Identify which statement comes from inspected source, which is an older recorded result, and which follows only from the premises below. A source comment, a prepared answer and an executed observation have different evidential roles. Preserve the original date and any failed or inconclusive gate when summarizing an older artifact. The direct baseline is a small handwritten calculation and a source-location table; an agent may help locate a definition, but its summary must be checked against that definition. Do not introduce a new language or automation merely to perform this finite comparison.

Assume a homogeneous rectangular sheet with no holes, constant thickness and uniform stipulated density. Its volume is the product of its dimensions and mass is density times volume. Multiplying every dimension by the same factor cubes that factor in volume. Enlarging only the planar dimensions squares it. These are alternative authored models of a mesh edit, not competing observations. A third policy can preserve total mass, but then its implied density changes if volume changes. The packet makes that contradiction visible before an agent proposes carrying physics settings through a scene adapter.

## Fixed case and assumptions

```text
w=0.20 m; h=0.10 m; t=0.001 m; rho=800 kg/m^3
V=w*h*t=0.00002 m^3; m=rho*V=0.016 kg
s=2
V_all=s^3*V=0.00016 m^3; m_all=0.128 kg
V_planar=s^2*V=0.00008 m^3; m_planar=0.064 kg
rho_fixed_mass=0.016/0.00016=100 kg/m^3
```

## Corrected exercises

### Exercise 1

Compute the original mass.

> **Answer:** The volume is `0.00002 m^3`; multiplying by density gives `0.016 kg`, or `16 g`. These are stipulated material values.

### Exercise 2

Scale every dimension. What is the mass ratio?

> **Answer:** The ratio is `8`; mass becomes `0.128 kg`. Thickness is part of this geometric enlargement.

### Exercise 3

Keep stock thickness fixed while enlarging the plane.

> **Answer:** Mass increases by `4` to `0.064 kg`. This is the negative control against automatically using a cubic factor.

### Exercise 4

Keep original mass after full enlargement. What density is implied?

> **Answer:** It implies `100 kg/m^3`, one eighth of the stipulated original density. Fixed density and fixed mass cannot both hold for this changed volume.

### Exercise 5

Does a stone surface name justify the density?

> **Answer:** No. The source surface descriptor supplies a rendering category. The numeric density is an authored assumption requiring a separate material basis for a physical claim.

## Source-assisted learner task

Inspect the pinned model’s size and surface definitions. Annotate a proposed doubled scene with a chosen thickness policy and a separate density assumption. Compare the manual volume ledger with an agent summary. Reject the summary if it preserves both density and total mass under the enlarged volume.

Complete the task with the answer sections hidden. Retain your original answers, intermediate quantities, source locations, uncertainty and every form of assistance, including a hint, a translated term or an agent suggestion. Then compare with the prepared answers and record corrections without replacing the original attempt. Produce a short decision note containing the claim, its assumptions, the calculation, the negative control and the next observation that could falsify it. A correct result with missing units or source identity is incomplete evidence for transfer. The evidence packet contains five prepared learner criteria; their decisions stay null until a real attempt and an authorized review exist. Passing these arithmetic checks would establish only competence on this declared case. It would not establish an implemented adapter, a successful material process, a faster renderer or improved learning in the project. Compare your source-assisted note with the direct manual baseline: if assistance obscures an assumption or removes a refusal, revise the note before proposing any workflow change.

## Sources and validation journal

- [Project record](../../../../code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Primary source](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs)
- [Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
