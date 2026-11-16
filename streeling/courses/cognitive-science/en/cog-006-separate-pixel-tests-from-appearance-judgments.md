---
module_id: cog-006-separate-pixel-tests-from-appearance-judgments
department: cognitive-science
course: "Separate Pixel Tests from Appearance Judgments"
level: intermediate
prerequisites: ["phy-009-distinguish-linear-color-from-display-encoding"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separate Pixel Tests from Appearance Judgments

> **Draft scope.** An original digital control, exact pixel comparisons, pinned public capture-source inspection and primary perception reading. Human technical review, fluent-language review, learner attempts and deployed course HTML verification remain pending. No observer participated, no display luminance was measured and no cited perception experiment was replicated.

## The project question

An agent compares a captured craft scene with its source texture and says, “the colors match.” That could mean matching bytes, matching interpreted coordinates, similar apparent brightness or similar implied material reflectance. These are different questions. [PHY-009](../../physics/en/phy-009-distinguish-linear-color-from-display-encoding.md) established the coordinate distinction; this lesson specifies what a pixel test can and cannot answer.

The [2026 primary study by Lovell and colleagues](https://pmc.ncbi.nlm.nih.gov/articles/PMC12876641/) examines brightness/lightness responses with manipulated cues in a checker-block stimulus. Its abstract and introduction motivate distinguishing perceived light intensity from inferred surface reflectance. We do not copy its stimulus or treat our simpler two-surround control as a replication, measured effect or prediction of every observer's response.

## 1. Ask the pixel question precisely

The original image's lower panel contains two 160 by 160 target squares. Each target contains 25600 pixels with RGB bytes 128, 128, 128. The left surround is byte 32 and the right surround byte 224. The [pixel audit](../../../../code/streeling/evidence/color-contract-2026-10-22/figure-pixel-audit.json) binds half-open crop coordinates, image bytes, matching target-crop hashes and the tagged sRGB interpretation.

![Authored midpoint and identical-target context controls](https://raw.githubusercontent.com/spareilleux/learn/50a9e9d5604dfe60c37f4a52d6bfa5e2ca376e63/code/streeling/evidence/color-contract-2026-10-22/color-context-controls.png)

The shared figure has English labels. Its upper panel illustrates coordinate arithmetic; its lower panel supplies equal target bytes in unequal contexts. The targets are verified digital regions, not measured light outputs from the user's display.

### Practice exercise 1: define the comparison region

How many pixels are in each target? What does equality of their cropped RGB bytes establish? Does it establish equality of the complete surrounding panels or a participant's judgment?

> **Answer:** Each target has 25600 pixels. Their cropped RGB byte arrays are equal under the declared coordinates. The surroundings differ, and byte equality establishes no participant judgment or instrument-measured display luminance.

## 2. Separate numerical equality from the requested experience

Brightness is a perceptual judgment about apparent light intensity; lightness concerns perceived surface reflectance. Neither is simply a file byte. A request about whether two target crops contain identical RGB values is answered by the pixel audit. A request about whether a woven surface looks like the same material under changed lighting requires a separate operational question and suitable context.

The [prepared task design](../../../../code/streeling/evidence/color-contract-2026-10-22/appearance-task-design.json) asks which target appears brighter, while allowing left, right, equal and unsure responses. It contains zero participants and no response data. The correct exercise answer is not a prescribed illusion direction. Record what an observer actually reports, together with the viewing conditions and the question asked.

### Practice exercise 2: avoid inventing an answer key

A learner verifies identical target bytes. Must a later observer answer “equal” to the appearance question? Is “the same painted material” the same question as “the same apparent light intensity”?

> **Answer:** No observer response is forced by the byte test. Record the actual answer rather than scoring an assumed illusion direction as truth. Implied material reflectance and apparent light intensity are distinct judgments and need separately specified questions.

## 3. Do not infer the whole display path from a screenshot

The public [BRUTAL capture writer](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L4308-L4337), at commit `76efbffd5af82b46c3146957a6bd4504008eeb89`, converts swapchain BGRA bytes to RGB PNG data. Its inspected writer emits image chunks without a color-space chunk. This source observation is not a new capture or proof of how an actual browser interpreted a file.

Our original control explicitly carries an sRGB chunk. That tag declares an intended interpretation; it does not calibrate the monitor, establish ambient lighting or measure the radiance reaching an eye. Scaling, color-management settings and the display path must be recorded when they matter to the comparison. Matching file bytes cannot stand in for those missing observations.

### Practice exercise 3: interpret metadata at its scope

The authored PNG carries an sRGB chunk. The inspected project capture-writer source does not emit one. Can either fact establish a calibrated visual match between the two workflows?

> **Answer:** No. One declares an image interpretation, and the other identifies a source-level metadata omission. Neither supplies an actual capture comparison, browser/display configuration, measured luminance or an observer result. No calibrated match was tested.

## 4. Control layout without claiming an experiment occurred

The prepared design proposes swapping dark and light surrounds between left and right while keeping target bytes and sizes fixed. This helps separate a possible side preference from a context-linked response. Only the first layout is rendered in this packet; the swapped version is planned, not an executed trial or a second published stimulus.

Do not tell participants which target should look brighter. Keep equal and unsure available, preserve actual responses and exclusions, and record the image/view transform, scale and viewing conditions. The small control does not establish a population effect, an effect magnitude, the realism of a craft material or the transfer of a result from the cited checker-block study.

### Practice exercise 4: repair a biased procedure

A proposed trial always puts the dark surround on the left and asks, “Can you see that the left target is brighter?” Give two changes and state what the current packet actually contains.

> **Answer:** Counterbalance surround side and use a neutral question with equal and unsure options. The packet contains one authored layout and exact pixel checks, but no swapped-layout rendering, participants or responses. The revised procedure remains a proposal until performed.

## 5. Return separate evidence to the agent

An agent handoff can report target-crop byte equality, declared color encoding, known display-path settings and an observer outcome as separate fields. Missing observer evidence stays missing. This is a proposed task record, not a new normative ecosystem schema. A positive pixel test can support an artifact check while leaving a material-quality decision unresolved.

[VC-010](../../visual-computing/en/vc-010-preserve-packed-texture-channel-contracts.md) shows why even the interpretation of RGBA bytes can depend on a channel contract. An identical numeric tuple used as normal/roughness/height data is not the same kind of statement as an identical tuple used as displayed color.

### Practice exercise 5: write an evidence-bounded conclusion

An agent has the image hash and matching target-crop bytes but no observer record. Write the supported conclusion and one next action for evaluating the crafted surface's appearance.

> **Answer:** The authored target crops are byte-identical under the recorded coordinates and tagged image interpretation. No observer outcome or material-quality equivalence is established. Define the intended appearance question and collect an appropriately controlled target-host/viewing observation before claiming that broader result.

## Source-assisted learner task

Complete the [prepared task](../../../../code/streeling/evidence/color-contract-2026-10-22/learner-task.md). Explain how a valid pixel test and an unresolved appearance question can coexist, without replacing an absent response with a numerical default.
