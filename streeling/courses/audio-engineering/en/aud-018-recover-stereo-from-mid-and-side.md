---
module_id: aud-018-recover-stereo-from-mid-and-side
department: audio-engineering
course: "Recover Stereo from Mid and Side"
level: advanced
prerequisites: ["aud-010-preserve-channels-before-downmixing"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Recover Stereo from Mid and Side

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

A stereo guitar reference can be re-expressed without losing information if both transformed channels survive. Keeping only their sum loses the difference, even when the exporter writes a stereo file afterward. We construct an invertible channel change and then remove its side component. This makes the storage requirement and the energy cost visible before a workflow offers a width control.

## Read the retained evidence

The prerequisite demonstrates destructive downmixing. The retained runner declares mono WAV output, so it cannot serve as evidence of this stereo operation. The matrix below is an authored extension for a review proposal, not newly delivered runtime support.

[Prerequisite](../../audio-engineering/en/aud-010-preserve-channels-before-downmixing.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

## Fixed case and prepared quantities

```json
{
  "values": {
    "left": [
      1,
      0
    ],
    "right": [
      0,
      1
    ],
    "side_gain": 1
  },
  "formula": "M=(L+R)/sqrt(2); S=(L-R)/sqrt(2); L_out=(M+g*S)/sqrt(2); R_out=(M-g*S)/sqrt(2); E=sum(L_out^2+R_out^2)",
  "expected": {
    "mid": [
      0.7071067811865476,
      0.7071067811865476
    ],
    "side": [
      0.7071067811865476,
      -0.7071067811865476
    ],
    "left_out": [
      1,
      0
    ],
    "right_out": [
      0,
      1
    ],
    "input_energy": 2,
    "output_energy": 2
  },
  "negative_control": {
    "values": {
      "left": [
        1,
        0
      ],
      "right": [
        0,
        1
      ],
      "side_gain": 0
    },
    "expected": {
      "mid": [
        0.7071067811865476,
        0.7071067811865476
      ],
      "side": [
        0.7071067811865476,
        -0.7071067811865476
      ],
      "left_out": [
        0.5,
        0.5
      ],
      "right_out": [
        0.5,
        0.5
      ],
      "input_energy": 2,
      "output_energy": 1
    }
  }
}
```

## Preserve the coordinate pair until the question permits loss

The transform changes coordinates in the channel plane. It does not by itself identify a physical source at the center or sides of a room. Those labels are useful names for the sum and difference directions, with a declared channel order. Exchanging left and right leaves the central coordinate unchanged and reverses the lateral coordinate, so even a numerically reversible record needs that orientation information.

An orthonormal change preserves the sum of squared coordinates at each frame, and therefore across the complete finite record. This algebraic property is stronger than checking only the peak, but narrower than a perceptual claim. The peak of an individual transformed channel can differ from the peak of either original channel. Subsequent limiting, quantization or a gain change would need another accounting step before exact recovery could be promised.

The zero-side control illustrates a projection rather than a reversible coordinate change. Writing the resulting average into two channels does not restore the missing coordinate. Many different original pairs share that average. Retain both arrays if later work might compare room differences or original stereo samples. A direct matrix table already resolves this storage choice; a proposed audio workflow should earn its added complexity by making channel order, normalization and any deliberate side processing explicit in the saved record.

### Exercise 1

Form the mid and side arrays. Why specify the normalization?

<details><summary>Answer 1</summary>

Both arrays are listed above. The square-root normalization makes this particular matrix orthonormal; another common convention would need different inverse and energy formulas.

</details>

### Exercise 2

Invert the main case and compare every original channel sample.

<details><summary>Answer 2</summary>

The inverse restores both original arrays. Retaining mid and side preserves the missing difference that a mono average alone cannot reconstruct.

</details>

### Exercise 3

Check total squared energy before and after the main transform. Does this prove equal loudness?

<details><summary>Answer 3</summary>

The displayed energies agree. This follows from the orthonormal matrix, while perceived loudness also depends on reproduction and listening conditions.

</details>

### Exercise 4

Apply the zero-side control. Can two equal output channels reconstruct the originals?

<details><summary>Answer 4</summary>

No. Both outputs become the same average and energy decreases by the displayed amount. The side information has been discarded, not stored redundantly.

</details>

### Exercise 5

What would reject a proposed lossless stereo handoff?

<details><summary>Answer 5</summary>

Failure to recover any retained sample with the declared inverse rejects numerical losslessness. A mono runner result cannot establish the stereo handoff in the first place.

</details>

## Source-assisted learner task

Draw the forward and inverse channel maps manually. Compare retaining both coordinates with retaining only their sum, and inspect the mono header declaration. Propose the smallest reversible record before recommending a width workflow; preserve original channel order and scaling.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
