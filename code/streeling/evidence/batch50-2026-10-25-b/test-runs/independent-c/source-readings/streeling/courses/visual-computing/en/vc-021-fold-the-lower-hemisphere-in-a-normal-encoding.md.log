---
module_id: "vc-021-fold-the-lower-hemisphere-in-a-normal-encoding"
department: "visual-computing"
course: "Fold the Lower Hemisphere in a Normal Encoding"
level: "advanced"
prerequisites: ["phy-008-keep-surface-normals-perpendicular"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Fold the Lower Hemisphere in a Normal Encoding

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

A chased metal relief has normals pointing both toward and away from a chosen reference axis. Storing only the first coordinates after normalization loses the hemisphere. The proposed compact handoff therefore needs an explicit map and inverse, not an assumption that a normal texture always faces forward. This lesson derives a real-valued octahedral encoding case. It deliberately stops before integer quantization, shader sampling or a storage-performance claim.

First divide by the sum of absolute components. That places the direction on an octahedron. For a direction in the lower hemisphere, fold the coordinate pair outward using both original components. Decoding reconstructs a depth component from the absolute coordinate sum and unfolds the pair when that depth is negative. The final Euclidean normalization restores unit length. In-place updates are dangerous: using an already modified first coordinate to compute the second changes the declared map.

The omitted-fold control retains the same input direction and decoder. Its plausible reconstructed unit length cannot detect the hemisphere error, whereas the dot agreement with the original direction can. For a future [ComfyUI](https://docs.comfy.org/)-to-[Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) or [Godot](https://docs.godotengine.org/en/4.5/) asset, retain the encoding convention and texture interpretation with the normal data. Unit length is necessary for the intended direction representation but does not certify the direction, tangent frame or appearance of embroidered fibres. A source-assisted reviewer should ask which predicate actually notices this control.

At an exactly zero component, this authored map uses `sign(0)=1`. Both folded coordinates use the old pair simultaneously; the negative-depth branch is tested before Euclidean renormalization.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "vector": [
      1,
      2,
      -1
    ],
    "fold_lower": true
  },
  "formula": "p=v/(abs(x)+abs(y)+abs(z)); uv=(p.x,p.y); if p.z<0 and fold_lower: uv=((1-abs(p.y))*sign(p.x),(1-abs(p.x))*sign(p.y)); q=(u,v,1-abs(u)-abs(v)); if q.z<0 unfold xy using old coordinates; decoded=q/length(q); agreement=dot(decoded,original/length(original))",
  "expected": {
    "encoded": [
      0.5,
      0.75
    ],
    "decoded_normal": [
      0.4082482904638631,
      0.8164965809277261,
      -0.4082482904638631
    ],
    "agreement": 1
  },
  "negative_control": {
    "values": {
      "vector": [
        1,
        2,
        -1
      ],
      "fold_lower": false
    },
    "expected": {
      "encoded": [
        0.25,
        0.5
      ],
      "decoded_normal": [
        0.4082482904638631,
        0.8164965809277261,
        0.4082482904638631
      ],
      "agreement": 0.6666666666666666
    }
  }
}
```

### Exercise 1

Find the octahedron coordinates.

<details><summary>Answer 1</summary>

They are `[0.25,0.5,-0.25]`. The negative final component requires the lower-hemisphere branch before storage.

</details>

### Exercise 2

Compute the stored pair.

<details><summary>Answer 2</summary>

It is `[0.5,0.75]`. Both components must be computed from the original pair, rather than sequentially overwriting it.

</details>

### Exercise 3

Check the decoded direction.

<details><summary>Answer 3</summary>

Its depth component remains negative and agreement is `1`. Renormalization changes magnitude while preserving the decoded direction.

</details>

### Exercise 4

Evaluate the omitted-fold control.

<details><summary>Answer 4</summary>

The pair becomes `[0.25,0.5]`; decoded depth becomes positive and agreement falls to `0.6666666666666666`. Unit length alone still passes.

</details>

### Exercise 5

Does this establish an engine texture format?

<details><summary>Answer 5</summary>

No. The model has no integer quantizer, channel convention or shader execution. Bind those separately before claiming a correct asset import.

</details>

## Source-assisted task and direct baseline

Prepare a paper encoding-and-decoding trace for one relief normal. Compare a unit-length-only check with the original-direction check, and propose the missing texture metadata for an asset handoff.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

A claim that dropping the depth component preserves this direction is refuted by the control’s changed hemisphere and dot agreement.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: phy-008-keep-surface-normals-perpendicular](../../physics/en/phy-008-keep-surface-normals-perpendicular.md)
- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://pbr-book.org/4ed/Geometry_and_Transformations/Spherical_Geometry)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
