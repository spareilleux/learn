---
module_id: vc-016-track-uv-gutters-through-mip-levels
department: visual-computing
course: "Track UV Gutters through Mip Levels"
level: intermediate
prerequisites: ["vc-010-preserve-packed-texture-channel-contracts"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Track UV Gutters through Mip Levels

> Draft for technical and language review. Every scene, count, temperature, timing and outcome introduced below is an authored example. Source inspection and arithmetic do not constitute a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/) import, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://docs.comfy.org/) run or a learner observation. Human and runtime decisions remain undecided.

## Project question

A woven or embroidered atlas can have correct channel meanings and still mix neighbouring patches at a distance. This lesson follows a declared gutter width as an ideal mip chain shrinks the texture. It adds spatial separation to the prerequisite’s channel contract. The result tells an author where a chosen margin stops holding; it does not predict every texture filter or prove that a rendered seam appears.

## Read the retained boundary

Atlas’s material helper assigns visual material inputs but the inspected lines contain no UV gutter guarantee. The Godot image-import page describes mipmap settings; its warning about an unimplemented limit belongs to that documented version and is not a report about the user’s fork.

Read the prerequisite and the retained project artifact before interpreting the model. The source has its own revision and purpose; it supplies the boundary described here, not the new classroom inputs. Keep a small evidence table separating an inspected field, an assumption, a derived quantity and a proposed scene effect. An agent summary must point back to the field it interprets. A source filename alone cannot establish an earlier result.

## Interpret the model

A mip level halves each image axis relative to its predecessor in our ideal construction. Therefore a base-image gutter is divided by a power of the same factor. Preserve whether the quantity denotes a gutter between islands or padding on each side: confusing them changes the available distance. A surviving numeric margin is still conditional on sampling footprints, wrap rules and generated mip content. Texture-channel correctness and atlas isolation compose as separate requirements. A normal, roughness or height field may be decoded correctly while pulling values from the wrong neighbouring material region.

The direct baseline is a labelled sketch and a hand calculation with the answer panels closed. Preserve intermediate values and units, then apply the changed input in the negative control. A disagreement is useful evidence: locate whether it comes from the definition, arithmetic, representation or intended task before changing the model. Agreement on the main case alone does not establish a universal rule. These finite examples deliberately expose an assumption that a smooth preview could conceal.

```text
{"gutter_px":16,"mip_level":3,"required_gutter_px":2}
effective_gutter_px=gutter_px/(2**mip_level); meets_declared_margin=effective_gutter_px>=required_gutter_px
```

## Corrected exercises

### Exercise 1

Compute the effective gutter in the main case.

<details><summary>Answer 1</summary>

The effective gutter is `2 px`, exactly the declared `2 px` requirement. Equality passes this authored comparison but provides no extra reserve.

</details>

### Exercise 2

Apply the coarser-level negative control.

<details><summary>Answer 2</summary>

The gutter becomes `1 px`, below the requirement. The same base atlas therefore passes one declared level and fails the next.

</details>

### Exercise 3

Does passing the margin prove the absence of visible texture bleeding?

<details><summary>Answer 3</summary>

No. The model omits actual filters, compression, UV derivatives, wrap rules and content. It bounds a stated ideal gutter quantity rather than a complete sampling process.

</details>

### Exercise 4

Why must the handoff distinguish total gutter from padding per island?

<details><summary>Answer 4</summary>

The two definitions allocate different separation between regions. A shared number without its spatial definition may halve or double the assumed protection.

</details>

### Exercise 5

Can a correctly decoded packed map rescue a failed spatial contract?

<details><summary>Answer 5</summary>

No. Correct channel interpretation does not prevent sampling from a neighbouring island. Preserve both the channel roles and the atlas-space separation requirement.

</details>

## Source-assisted learner task

Draw two atlas islands and label the total gutter at the base and changed levels. Calculate the ideal widths manually. Locate the material helper’s limited scope, then write the additional atlas evidence a future import would need. A coarser level violating the declared margin falsifies an all-level margin claim.

Retain your original answer, source locations, assistance history and any later correction as separate records. State the observable result that would falsify your recommendation before proposing automation. Compare the source-assisted result with your direct manual baseline, including any extra uncertainty it introduces. The fixed packet contains five prepared criteria; each decision stays null until an actual learner attempt and review exist. Prepared answers are checks, not evidence that a learner performed the task.

## Sources and validation journal

- [Prerequisite: vc-010-preserve-packed-texture-channel-contracts](../../visual-computing/en/vc-010-preserve-packed-texture-channel-contracts.md)
- [Retained project artifact](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_images.html)
- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
