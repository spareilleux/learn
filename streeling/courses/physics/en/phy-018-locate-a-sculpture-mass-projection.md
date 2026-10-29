---
module_id: phy-018-locate-a-sculpture-mass-projection
department: physics
course: "Locate a Sculpture Mass Projection"
level: intermediate
prerequisites: ["phy-013-check-torque-when-moving-a-scene-pivot"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Locate a Sculpture Mass Projection

> Draft for technical and language review. Every scene, count, temperature, timing and outcome introduced below is an authored example. Source inspection and arithmetic do not constitute a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/) import, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://docs.comfy.org/) run or a learner observation. Human and runtime decisions remain undecided.

## Project question

An asymmetrical metal sculpture can look balanced because its mesh origin is centered. That origin is a modeling choice. This lesson places the projection of a declared mass model relative to a support interval, so a future Godot annotation can distinguish visual centering from a static mechanical premise. It extends pivot reasoning by weighting component locations, rather than treating every component or vertex as equally massive.

## Read the retained boundary

Atlas’s object helper accepts a location and an optional parent. These are spatial properties, not measured component masses. The inspected material helper also supplies no density. We therefore introduce explicit lumped masses for the classroom model.

Read the prerequisite and the retained project artifact before interpreting the model. The source has its own revision and purpose; it supplies the boundary described here, not the new classroom inputs. Keep a small evidence table separating an inspected field, an assumption, a derived quantity and a proposed scene effect. An agent summary must point back to the field it interprets. A source filename alone cannot establish an earlier result.

## Interpret the model

OpenStax defines center of mass by mass-weighted positions. Our section ignores the other horizontal coordinate and assumes gravity is vertical. Under the stated contact assumptions, the projection must lie inside the support interval for a positive static support margin. Equality is a boundary, not a reserve. A sculpture’s geometric center or object origin cannot replace the weighted calculation. Moving a small number of mesh vertices could change their arithmetic mean without moving any material; conversely, moving a heavy component changes this model even if a decorative bounding box stays centered.

The direct baseline is a labelled sketch and a hand calculation with the answer panels closed. Preserve intermediate values and units, then apply the changed input in the negative control. A disagreement is useful evidence: locate whether it comes from the definition, arithmetic, representation or intended task before changing the model. Agreement on the main case alone does not establish a universal rule. These finite examples deliberately expose an assumption that a smooth preview could conceal.

```text
{"masses_kg":[2,1],"x_m":[0,0.3],"support_m":[-0.12,0.12]}
x_cm=sum(m_i*x_i)/sum(m_i); margin=min(x_cm-support_min,support_max-x_cm)
```

## Corrected exercises

### Exercise 1

Find the total mass and projected center for the main case.

<details><summary>Answer 1</summary>

The total mass is `3 kg`, and the projected center is `0.1 m`. The component at the origin contributes to the denominator even though its weighted position is zero.

</details>

### Exercise 2

Compute the nearest support-edge margin. What does its sign encode?

<details><summary>Answer 2</summary>

The nearest-edge margin is `0.02 m`. It is positive because the projection is strictly inside the declared interval; it is not a measured safety factor.

</details>

### Exercise 3

Move only the decorative component according to the control.

<details><summary>Answer 3</summary>

The projection becomes `0.2 m`, with margin `-0.08 m`. It lies outside the support despite the unchanged total mass and unchanged support interval.

</details>

### Exercise 4

Would averaging all mesh vertices give the same justified quantity?

<details><summary>Answer 4</summary>

No. Vertex density follows tessellation, not mass. A mass interpretation requires component masses or a density-and-volume model; the object origin supplies neither.

</details>

### Exercise 5

What claims remain unavailable even with a positive margin?

<details><summary>Answer 5</summary>

Dynamic response, frictional sliding, joint strength, deformation and real manufacturing stability remain untested. The result addresses only the declared static support section.

</details>

## Source-assisted learner task

Make a component-and-support diagram and calculate its weighted projection manually. Identify where Atlas stores placement and where the required mass data is absent. A projection outside the support falsifies a claim of positive support margin for this model; it does not record a real sculpture falling.

Retain your original answer, source locations, assistance history and any later correction as separate records. State the observable result that would falsify your recommendation before proposing automation. Compare the source-assisted result with your direct manual baseline, including any extra uncertainty it introduces. The fixed packet contains five prepared criteria; each decision stays null until an actual learner attempt and review exist. Prepared answers are checks, not evidence that a learner performed the task.

## Sources and validation journal

- [Prerequisite: phy-013-check-torque-when-moving-a-scene-pivot](../../physics/en/phy-013-check-torque-when-moving-a-scene-pivot.md)
- [Retained project artifact](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://openstax.org/books/university-physics-volume-1/pages/9-6-center-of-mass)
- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
