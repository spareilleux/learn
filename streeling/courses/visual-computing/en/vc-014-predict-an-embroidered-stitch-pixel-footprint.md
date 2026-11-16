---
module_id: vc-014-predict-an-embroidered-stitch-pixel-footprint
department: visual-computing
course: "Predict an Embroidered Stitch Pixel Footprint"
level: intermediate
prerequisites: ["vc-005-craft-details-through-blender-to-godot"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Predict an Embroidered Stitch Pixel Footprint

> Draft for technical and language review. Every scene, count, temperature, timing and outcome introduced below is an authored example. Source inspection and arithmetic do not constitute a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/) import, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://docs.comfy.org/) run or a learner observation. Human and runtime decisions remain undecided.

## Project question

A thread survives Blender cleanup but disappears in a proposed Godot overview. Geometric retention and screen visibility answer different questions. This lesson predicts the projected width of one embroidered stitch before selecting a geometry or texture representation. The calculation supplies a camera-dependent footprint, not a claim that a person can recognize the stitch, and not a benchmark for a renderer or an upscaler.

## Read the retained boundary

The cleanup script exposes a resolution argument for its captures. That parameter does not establish a Godot viewport or a camera field of view. The camera model below is separately authored; the Godot reference explains projection modes and field-of-view axis selection.

Read the prerequisite and the retained project artifact before interpreting the model. The source has its own revision and purpose; it supplies the boundary described here, not the new classroom inputs. Keep a small evidence table separating an inspected field, an assumption, a derived quantity and a proposed scene effect. An agent summary must point back to the field it interprets. A source filename alone cannot establish an earlier result.

## Interpret the model

Use viewport height with vertical field of view, so focal length is expressed in pixel units. Divide physical stitch width by camera distance, then multiply by that focal length. Both lengths must use the same unit. This projection assumes the feature is parallel to the image plane; a slanted stitch has a different projected width. The declared threshold is a design question awaiting observation. It does not encode human acuity, contrast, material shading or temporal stability. An orthographic camera would require another model, because its projected size does not shrink with distance in this way.

The direct baseline is a labelled sketch and a hand calculation with the answer panels closed. Preserve intermediate values and units, then apply the changed input in the negative control. A disagreement is useful evidence: locate whether it comes from the definition, arithmetic, representation or intended task before changing the model. Agreement on the main case alone does not establish a universal rule. These finite examples deliberately expose an assumption that a smooth preview could conceal.

```text
{"width_m":0.002,"distance_m":1,"viewport_height_px":1000,"vertical_fov_deg":90,"required_px":2}
focal_px=viewport_height_px/(2*tan(vertical_fov_deg*pi/360)); width_px=focal_px*width_m/distance_m; meets_declared_threshold=width_px>=required_px
```

## Corrected exercises

### Exercise 1

Compute focal length in pixel units for the main case.

<details><summary>Answer 1</summary>

The focal length is `500 px`. Pairing vertical field of view with horizontal viewport size would answer a different and generally incorrect projection question.

</details>

### Exercise 2

Find projected stitch width and compare it with the declared threshold.

<details><summary>Answer 2</summary>

Its width is `1 px`, below the `2 px` threshold. This rejects only the authored geometric requirement; it does not demonstrate actual invisibility.

</details>

### Exercise 3

Apply the closer-camera control without changing the mesh.

<details><summary>Answer 3</summary>

Projected width becomes `2 px` and meets the declared threshold. Identical geometry can support different screen footprints at different camera distances.

</details>

### Exercise 4

Would this formula transfer unchanged to an orthographic view?

<details><summary>Answer 4</summary>

No. The pinhole distance division belongs to perspective. An orthographic model needs its view size and viewport mapping; distance alone does not supply this scaling.

</details>

### Exercise 5

Can meeting the threshold establish a DLSS or recognition result?

<details><summary>Answer 5</summary>

No. Neither an upscaler nor a viewer was tested. Retain contrast, sampling, camera motion and recognition as separate questions for a future observation.

</details>

## Source-assisted learner task

Prepare a stitch card with physical width, camera axis convention, distance, viewport and predicted width. Calculate by hand before consulting the packet. Falsify an unconditional visibility claim by changing only the view distance; propose a matched-camera capture as future evidence, not an executed trial.

Retain your original answer, source locations, assistance history and any later correction as separate records. State the observable result that would falsify your recommendation before proposing automation. Compare the source-assisted result with your direct manual baseline, including any extra uncertainty it introduces. The fixed packet contains five prepared criteria; each decision stays null until an actual learner attempt and review exist. Prepared answers are checks, not evidence that a learner performed the task.

## Sources and validation journal

- [Prerequisite: vc-005-craft-details-through-blender-to-godot](../../visual-computing/en/vc-005-craft-details-through-blender-to-godot.md)
- [Retained project artifact](../../../../code/blender/scripts/glb_pipeline.py)
- [Primary reading](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
