---
module_id: vc-010-preserve-packed-texture-channel-contracts
department: visual-computing
course: "Preserve Packed Texture Channel Contracts"
level: intermediate
prerequisites: ["vc-005-craft-details-through-blender-to-godot", "phy-009-distinguish-linear-color-from-display-encoding"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preserve Packed Texture Channel Contracts

> **Draft scope.** Pinned public producer/consumer source, two existing public PNG inspections and an authored texel calculation. Human technical review, fluent-language review, learner attempts and deployed course HTML verification remain pending. No fresh bake, [ComfyUI](https://docs.comfy.org/) generation, shader/import execution or displacement result was observed.

## The project question

An agent exports a crafted surface as “one RGBA texture.” That description omits what every channel means. The public [BRUTAL texture bake](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/textures/bake_blender.py) packs two normal-map components, roughness and a height proxy together. Its [generation script](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/textures/generate_comfyui.py) describes an upstream [ComfyUI](https://docs.comfy.org/) workflow; neither script was executed for this lesson. All project observations use public GA commit `76efbffd5af82b46c3146957a6bd4504008eeb89`.

[PHY-009](../../physics/en/phy-009-distinguish-linear-color-from-display-encoding.md) established why color coordinates need a declared encoding. Packed data needs an additional contract: the same four stored numbers may have no color or transparency meaning at all.

## 1. Write down the producer's channel roles

The script declares the packed output as Non-Color, while declaring its albedo output sRGB. Its packing order is explicit:

| Channel | Producer value | Intended interpretation |
| --- | --- | --- |
| R | baked normal X | encoded directional component |
| G | baked normal Y | encoded directional component |
| B | baked roughness first channel | roughness data |
| A | weighted albedo-buffer RGB | height proxy |

The alpha field is not opacity, and blue is not normal Z. The baked normal Z is omitted. Height is derived from image values; no physical thickness, displacement scale or measured topography follows from it. The [Blender 4.5 color-management guidance](https://docs.blender.org/manual/en/4.5/render/color_management.html) likewise distinguishes non-color normal/displacement data from color images. This lesson makes no assumption about a host's current default view transform.

### Practice exercise 1: reject the wrong generic importer

An importer treats RGB as a complete normal vector and alpha as opacity. Which two channel meanings conflict with this producer? Does the packed map contain the baked normal Z?

> **Answer:** Blue is roughness, not normal Z; alpha is a height proxy, not opacity. The producer does not pack baked normal Z. A generic normal-plus-opacity importer would impose a different contract and cannot be assumed to preserve this map.

## 2. Decode normalized data without a color transform

The [authored texel](../../../../code/streeling/evidence/color-contract-2026-10-22/packed-texel-calculations.json) has bytes 128, 128, 128 and 64. Dividing by 255 gives approximately 0.5019607843137255 for each RGB channel and 0.25098039215686274 for alpha. Decoding signed RG with `2*v-1` gives approximately 0.0039215686274509665 per component. Byte 128 is near, rather than exactly at, the signed midpoint.

Applying the piecewise sRGB color decode to RGB first would instead give approximately 0.21586050011389926 and signed RG approximately -0.5682789997722015. That is a changed data interpretation. It is not a harmless display correction to a color photograph.

### Practice exercise 2: detect transformed data

Decode the authored red byte 128 as normalized signed data. Compare with decoding it as sRGB first. Should alpha byte 64 automatically make the material partially transparent?

> **Answer:** Direct normalized-data decoding gives approximately 0.0039215686274509665; color decoding first gives approximately -0.5682789997722015 after the signed mapping. Alpha is the height proxy under this contract, so byte 64 does not declare transparency.

## 3. Follow the consumer, not only the filename

The pinned [material shader](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L587-L655) reads RG as a signed bump signal and B as roughness on the examined concrete, facade, cladding and machine paths. Those paths do not read packed alpha as height displacement or reconstruct normal Z there. Do not describe their bump signal as a lossless complete unit-normal reconstruction.

Facade uses the blue value directly. Concrete, ignoring its separate rain adjustment for this control, maps blue through `0.75+0.2*B`. The authored blue therefore gives approximately 0.850392156862745 for that concrete expression. Incorrect sRGB decoding first would give approximately 0.7931721000227798. Parameter interpretation and material-specific remapping are distinct stages.

### Practice exercise 3: distinguish preservation from use

The alpha height proxy survives in the PNG. Does that establish that the examined shader displaces geometry? Calculate the concrete roughness expression for the authored blue under the stated no-rain control.

> **Answer:** No. Stored data is not proof of consumer use; the examined paths do not read packed alpha for displacement. The no-rain expression gives approximately 0.850392156862745. That isolated value is not an observed material render or a complete rain-affected output.

## 4. Check the actual artifact's metadata separately

The [existing-file inspection](../../../../code/streeling/evidence/color-contract-2026-10-22/public-texture-inspection.json) reads pinned concrete albedo and packed PNGs. Both are 512 by 512, RGBA, 8-bit files, and both contain sRGB, gAMA and cHRM chunks. The packed file's color metadata therefore does not communicate the script's stated Non-Color data contract.

This discrepancy is evidence to retain. It does not prove that this exact script and environment generated the checked file, that the values have already been color-decoded by a particular host or that all project assets share the same metadata. The inspected BRUTAL loader reads supported pixel bytes without interpreting those color chunks; other importers may have different policies. A file extension or tag alone does not establish channel semantics.

### Practice exercise 4: reconcile a declaration with a file

The script declares Non-Color but the pinned packed PNG contains an sRGB chunk. May an agent assume a fresh correct bake or silently remove the discrepancy from its handoff? State the bounded observation.

> **Answer:** No. Retain that the inspected 512 by 512 RGBA 8-bit packed file has color metadata while the script declares a non-color output. No fresh bake or exact generation history was established. The destination's interpretation must be tested rather than inferred from the declaration alone.

## 5. Prepare a host-specific transfer check

[Godot 4.6's shader documentation](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shading_language.html#using-source-color) distinguishes sRGB color textures using `source_color` from normal, roughness and height data. Its renderer-specific guidance matters; this is not evidence that a particular import was tested. Applying a standard normal-map hint blindly to this whole packed map would also ignore that blue contains roughness.

A proposed transfer packet should identify the asset revision, per-channel roles, numeric ranges, color/data policy and consumer remapping. Test a known texel after import and verify the intended channel independently before judging the full surface. Adding a height channel to a file does not implement geometry displacement, and recognizing the contract does not authorize an untested production shader change.

### Practice exercise 5: choose the next verifiable action

An agent proposes treating the entire packed texture as albedo with `source_color`, then declares the craft transfer complete. What is the smaller discriminating import test, and what remains unperformed?

> **Answer:** Use a known packed texel and verify that the destination preserves its data values and the declared RG/B/A roles under a deliberate import/sampling policy. A color decode of the whole data texture is not the declared contract. Actual host import, shader use, displacement, rendered material quality and learner outcomes remain unperformed here.

## Source-assisted learner task

Complete the [prepared task](../../../../code/streeling/evidence/color-contract-2026-10-22/learner-task.md) by tracing a texel through producer, stored metadata and intended consumer. Keep the metadata disagreement visible and propose one concrete target-host check.
