---
module_id: phy-006-check-weave-scene-units
department: physics
course: "Check Weave Scene Units"
level: intermediate
prerequisites: [phy-005-sheet-thickness-and-scene-units]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Check Weave Scene Units

> **AI source draft.** Human subject, fluent-language, and learner reviews remain pending. Public course HTML publication remains pending.

[PHY-005](phy-005-sheet-thickness-and-scene-units.md) requires a declared ruler. This [Godot](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html) adapter applies it to saved weave proxies. Your deliverable is an audit that rejects wrongly scaled scenes. Consult the [lab README](../../../../code/streeling/weave-godot/README.md), [evidence README](../../../../code/streeling/evidence/weave-scene-2026-10-22/README.md), and [learner task](../../../../code/streeling/evidence/weave-scene-2026-10-22/learner-task.md). The evidence README retains execution details and failures.

Verified Windows result: save/load and 36 physics probes passed; scale, collider-binding, and restarted-parity controls failed at their named gates. Earlier launcher failures supply no scene proof.

## 1. Declare the physical interpretation

The pinned [evaluator](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) and [specification](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json) define `odd-tile-seam-a`: 5 mm pitch and 2 mm nominal diameter. A 3 × 3 tile repeated 2 × 2 gives 6 × 6 crossings. Global parity has 0 adjacency violations; restarted parity has 12 and must be refused before scene construction.

The adapter chooses one scene unit per metre and represents diameter by box thickness. Warp extends along Z and weft along X. Crossings contain isolated segments. This interpretation is declared input, not a textile measurement.

### Exercise 1 — Read the ruler

Convert 5 mm pitch and 2 mm thickness to the declared scene convention. Calculate thickness divided by pitch.

> **Answer:** Pitch is `5 × 0.001 = 0.005 m`; thickness is `2 × 0.001 = 0.002 m`. Their dimensionless ratio is `2/5 = 0.4`. The ratio should survive consistent uniform scaling, but it cannot by itself identify the absolute scene scale.

## 2. Check positions and dimensions separately

Crossing indices run from 0 through 5. Therefore `w3-f0` lies at X `3 × 0.005 = 0.015 m`, while the last coordinate is `5 × 0.005 = 0.025 m`. Six crossing centres have five intervening pitches. Calling the centre span 0.030 m confuses a count with an interval count.

Warp box dimensions `(X,Y,Z)` are `(0.002,0.002,0.004) m`; weft dimensions are `(0.004,0.002,0.002) m`. Their different long axes encode the strand directions. Position checks alone would miss a box with the wrong length or swapped axes. The loaded [MeshInstance3D](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) bounds provide a separate size observation.

### Exercise 2 — Diagnose two mistakes

A scene puts `w3-f0` at X 15 and gives both strand boxes `(0.004,0.002,0.002)`. Identify the independent errors.

> **Answer:** X 15 is 1000 times the required 0.015 under the metre convention. The warp's long axis is also wrong: it must extend along Z with `(0.002,0.002,0.004)`. Repairing the position does not repair the dimensions or orientation convention.

## 3. Derive the vertical gap

Upper and lower box centres are at Y `+0.0015 m` and `-0.0015 m`. Thickness is 0.002 m, so each half-thickness is 0.001 m. The upper bottom is `0.0015 - 0.001 = 0.0005 m`; the lower top is `-0.0015 + 0.001 = -0.0005 m`. Their difference is `0.001 m`, or 1 mm.

The trial compares transformed [AABB](https://docs.godotengine.org/en/4.6/classes/class_aabb.html) bounds after loading. These unrotated, axis-aligned boxes make vertical separation inspectable. It does not establish manufacturing clearance, cylinder contact, bending, or a path connecting segments. Rotated or curved geometry requires another argument.

### Exercise 3 — Distinguish gap from centres

Someone reports 3 mm clearance because the centres differ by 3 mm. Correct the calculation.

> **Answer:** Subtract both half-thicknesses from the centre separation: `3 - 1 - 1 = 1 mm`. Centre distance is not surface clearance. The result applies to the declared box proxies and their unrotated placement, not to real cloth.

## 4. Use an independent scale control

If the checker multiplies expected values by the builder's `MM_TO_M`, changing that constant can move both construction and expectation together. The lab instead hardcodes metre expectations independently. In a scratch copy, change only builder `MM_TO_M` from `0.001` to `1`. The named `independent_world_metres` check must reject it; unchanged ratios alone cannot expose this uniform factor of 1000.

With installed [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), [Python](https://docs.python.org/3/using/cmdline.html), and Godot 4.6.1 on `PATH`, use a fresh output directory outside the checkout:

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

The command has the same spelling across systems. Windows is exercised; Linux/WSL and macOS remain to verify. Retain original and mutated source hashes, actual reports, and logs. A runtime startup failure is a different event from a failed metre predicate and supplies no new scene proof.

### Exercise 4 — Test the checker

All ratios remain 0.4 after the mutation. Does that invalidate the negative control?

> **Answer:** No. Ratios are intentionally insensitive to uniform scale. The independent absolute expectation of X 0.015 m at `w3-f0`, along with thickness and centre checks, should fail. If the mutated run cannot start, the intended control outcome remains unassessed.

## 5. Transfer only the bounded claim

Observe, change one quantity, rerun, preserve the failure, and explain its scope. A passing audit would support these loaded coordinates and proxy bounds for these source bytes. It supplies no measured material properties. Check execution status in the evidence README before claiming a pass.

Composing semantic validation, serialization, and dimensional checks is a hypothesis about a useful inspection workflow. The cheaper labeled 2D baseline can display the same ruler and parity. Any claim of better learning requires a separate task comparison, including unassisted mistakes and effort.

### Exercise 5 — Write an honest handoff

Give a two-sentence conclusion when the geometry predicates pass but no learner or material trial exists.

> **Answer:** “For the pinned manifest and declared metre convention, the loaded isolated boxes satisfy the recorded positions, dimensions, and 0.001 m vertical AABB gap. This does not establish continuous-yarn behavior, manufacturing clearance, learner benefit, or completed subject and language review.” Attach the actual run receipt and use conditional wording if execution is still pending.
