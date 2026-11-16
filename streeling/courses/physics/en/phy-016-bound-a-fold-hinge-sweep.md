---
module_id: phy-016-bound-a-fold-hinge-sweep
department: physics
course: "Bound a Fold Hinge Sweep"
level: intermediate
prerequisites: ["phy-013-check-torque-when-moving-a-scene-pivot"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Bound a Fold Hinge Sweep

> Draft for technical and language review. Every scene, count, temperature, timing and outcome introduced below is an authored example. Source inspection and arithmetic do not constitute a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/) import, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://docs.comfy.org/) run or a learner observation. Human and runtime decisions remain undecided.

## Project question

A folded panel can finish clear of a neighbour while passing through it. For a proposed origami sculpture in Godot, an endpoint picture therefore answers a narrower question than a motion path. This lesson follows one marked point around an ideal hinge and separates its distance from the hinge from the distance it travels away from its starting position. Neither quantity is a material strain.

## Read the retained boundary

The retained Atlas helper declares its modeling frame and object parenting. That makes a hinge hierarchy a concrete future integration question, but the inspected lines contain no origami hinge or collision test.

Read the prerequisite and the retained project artifact before interpreting the model. The source has its own revision and purpose; it supplies the boundary described here, not the new classroom inputs. Keep a small evidence table separating an inspected field, an assumption, a derived quantity and a proposed scene effect. An agent summary must point back to the field it interprets. A source filename alone cannot establish an earlier result.

## Interpret the model

Place the hinge at the origin and the marked point on positive X. Rotation preserves its radius, while its endpoint coordinates change. The chord from the starting position is shorter than the circular arc except at the zero-angle limit. Our margin compares two radii only; it does not describe a finite obstacle’s position. A reviewer must therefore refuse to treat a positive radial margin as proof of an unobstructed path. The Godot reference distinguishes local rotation from rotation relative to a parent; this classroom calculation declares the plane independently of any imported asset.

The direct baseline is a labelled sketch and a hand calculation with the answer panels closed. Preserve intermediate values and units, then apply the changed input in the negative control. A disagreement is useful evidence: locate whether it comes from the definition, arithmetic, representation or intended task before changing the model. Agreement on the main case alone does not establish a universal rule. These finite examples deliberately expose an assumption that a smooth preview could conceal.

```text
{"radius_mm":100,"angle_deg":60,"obstacle_radius_mm":90}
x=r*cos(theta*pi/180); y=r*sin(theta*pi/180); swept_displacement=2*r*sin(abs(theta)*pi/360); radial_margin=r-obstacle_radius
```

## Corrected exercises

### Exercise 1

Compute the endpoint of the marked point. Which coordinate has remained fixed?

<details><summary>Answer 1</summary>

The endpoint is `(50,86.60254037844386) mm`. Neither coordinate is fixed; the hinge and radius remain fixed. Rounding should be declared rather than changing the construction.

</details>

### Exercise 2

Calculate straight displacement from the starting point, and compare it with the radius.

<details><summary>Answer 2</summary>

The chord displacement is `100 mm`, equal to this case’s radius. That equality depends on the chosen angle; it is not the definition of a rotation.

</details>

### Exercise 3

What does the radial margin establish about a nearby obstacle?

<details><summary>Answer 3</summary>

It is `10 mm` under the radial comparison. Without an angular extent and occupied volume, this number cannot establish that the moving panel avoids the obstacle.

</details>

### Exercise 4

Apply the zero-angle negative control. Does unchanged radius imply unchanged endpoint in every case?

<details><summary>Answer 4</summary>

The control endpoint is `(100,0) mm` and displacement is `0 mm`. The main case already changes the endpoint despite preserving the same radius.

</details>

### Exercise 5

What additional information would a scene handoff require to test motion clearance?

<details><summary>Answer 5</summary>

Give the hinge frame, occupied panel geometry, obstacle geometry, complete angle interval and contact convention. A single marked point and final capture are insufficient.

</details>

## Source-assisted learner task

Draw the start, end and connecting arc before checking the answers. Annotate a proposed parent-child hinge in the Atlas helper without editing it. Your falsifier for endpoint-based clearance is an obstacle intersecting an intermediate panel position while both endpoints remain clear.

Retain your original answer, source locations, assistance history and any later correction as separate records. State the observable result that would falsify your recommendation before proposing automation. Compare the source-assisted result with your direct manual baseline, including any extra uncertainty it introduces. The fixed packet contains five prepared criteria; each decision stays null until an actual learner attempt and review exist. Prepared answers are checks, not evidence that a learner performed the task.

## Sources and validation journal

- [Prerequisite: phy-013-check-torque-when-moving-a-scene-pivot](../../physics/en/phy-013-check-torque-when-moving-a-scene-pivot.md)
- [Retained project artifact](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
