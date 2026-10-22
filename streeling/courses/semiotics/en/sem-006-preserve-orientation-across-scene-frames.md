---
module_id: sem-006-preserve-orientation-across-scene-frames
department: semiotics
course: "Preserve Orientation Across Scene Frames"
level: intermediate
prerequisites: ["sem-004-face-identity-under-reindexing", "cs-014-compose-brutal-scene-descriptions"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preserve Orientation Across Scene Frames

> **Draft scope.** Pinned BRUTAL source, actual CPU matrix/validation checks and authored triangle arithmetic. Human technical, fluent-language and learner reviews and deployed course HTML verification remain pending. No Blender/Godot import, camera test, GPU or manufacturing trial was performed.

## The project question

A craft agent labels a component's side “positive X” or “front.” Another agent mirrors the part for a scene. Does the label still identify the same material side, the same world direction, or the face a camera will see? Those interpretations can disagree without the component losing its identity.

[SEM-004](sem-004-face-identity-under-reindexing.md) carries material references through renumbering. Here the change is spatial: the pinned [BRUTAL frame convention](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs) declares metres, positive Y upward, positive X east and positive Z south. Local face names and world-axis descriptions must be interpreted in that context, rather than treated as interchangeable strings.

## 1. Name the object and the interpretation

Use an authored local positive-X side of a solid. Its material reference identifies which side was chosen; its local normal expresses that side's direction before placement. A world normal describes the transformed direction. Triangle winding describes a vertex-order convention, while visibility depends additionally on camera, material and host rules. A human-facing word such as “front” does not determine all these fields.

In the composed placement of [PHY-008](../../physics/en/phy-008-keep-surface-normals-perpendicular.md), the same local positive-X face has world normal `(1/sqrt5,0,-2/sqrt5)`. Calling it “world positive X” would therefore change the interpretation. Preserving the material selection does not require pretending its world direction stayed fixed.

### Practice exercise 1: repair an ambiguous side label

An agent reports “The front is unchanged after placement.” Which distinctions are missing? Rewrite the claim for the authored positive-X side.

> **Answer:** It omits the selected material side, source frame, transform, output direction and meaning of front. A bounded claim is that the same authored local positive-X side is selected after the declared placement, with world normal `(1/sqrt5,0,-2/sqrt5)`. Camera-facing visibility and a host's front-face classification were not tested. Selection identity does not imply a fixed world direction.

## 2. A reflection changes orientation

Take the authored triangle with vertices `(1,-1,-1)`, `(1,1,-1)` and `(1,-1,1)`. Its ordered edge cross product is `(4,0,0)`, aligned with a chosen positive-X outward side. Reflect X while retaining the vertex order. All vertices move to X equal to -1, but their ordered cross product remains `(4,0,0)`. The transformed outward direction is negative X, so the retained winding and that outward interpretation now disagree.

Swapping the final two vertex indices changes the cross product to `(-4,0,0)`. This repairs the agreement for the stated outward convention. It is not proof of a particular renderer's front-face classification. The [orientation record](../../../../code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json) preserves the authored triangle, determinant and cross-product reasoning separately from native matrix observations.

### Practice exercise 2: track the reflected triangle

Give the original cross product, the unchanged-order cross after X reflection and the cross after swapping the last two indices. Which direction was stipulated as the reflected outward side?

> **Answer:** They are `(4,0,0)`, `(4,0,0)` and `(-4,0,0)`, respectively. The reflected outward side is negative X. Reflection changes the relationship between unchanged vertex ordering and the stipulated outward orientation; it does not erase the material reference or make a camera observation.

## 3. Two sign flips need not be a reflection

The native matrix controls give determinant -1 for an X-only reflection, +1 for simultaneous X/Z sign flips and +1 for yaw 180 degrees. Positive and negative determinant distinguish preserved and reversed orientation for these invertible maps. Zero determinant is a separate singular case; it cannot be classified as an invertible frame change.

The inspected [Colossus placement](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L2273-L2278) includes a yaw of pi. It flips X and Z together as a rotation. Calling it a handedness conversion merely because X changes sign would misdescribe the map. Native float32 yaw arithmetic is checked with tolerance `1e-5`, rather than requiring its sine at 180 degrees to be represented as exact zero.

### Practice exercise 3: distinguish rotation, reflection and collapse

Classify X-only scale `(-1,1,1)`, double-negative scale `(-1,1,-1)` and zero-X scale `(0,1,1)` by determinant. Which one can be described as the same orientation-preserving rotation effect as yaw 180 degrees?

> **Answer:** Their determinants are -1, +1 and 0. The first reverses orientation; the second preserves it and has the same ideal axis effect as yaw 180 degrees; the third collapses a dimension and has no inverse. A sign change in one named coordinate is insufficient to classify the whole transformation.

## 4. Interpret the receiving host's convention

The official [Godot SurfaceTool reference](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html) declares clockwise winding for front faces of triangle primitive modes. That is a host convention to consult during a real adapter test. It does not let this CPU example infer front/back visibility without the complete geometry, camera and material conditions. A mathematical cross-product direction and a front-face rule must be reconciled explicitly.

BRUTAL's inspected [ray-instance path](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L4520) disables triangle-facing culling. That source setting neither proves every other path uses the same policy nor establishes general reflected or singular geometry support. No host was run for this lesson.

### Practice exercise 4: bound the adapter claim

An agent changes a normal vector's sign, reads the Godot convention and reports that mirrored geometry imports correctly. What is still missing?

> **Answer:** The actual converted vertex/index order, normals, full transform, receiving primitive/material/culling settings and a controlled host observation are missing. A changed normal alone does not rewrite triangle indices, and a documentation statement does not execute an import. Test the actual adapter with known rotation/reflection controls before claiming correct import or visibility.

## 5. Carry the meaning needed by the next decision

A useful handoff can retain the selected material reference, local frame, complete transform, chosen outward convention, index order and the intended receiving-host rule. These are candidate information requirements for an adapter, not a new implemented schema. The objection is that carrying every field may be unnecessary for a task that only frames a camera around bounds. The simpler alternative is to declare that narrow task and preserve only sufficient data, without promoting it to a surface-orientation guarantee.

The [native receipt](../../../../code/streeling/evidence/scene-frames-2026-10-22/native-execution.json) records matrix and validator calls on teaching drafts. It establishes neither a persistent side-ID service nor a scene export. [INF-006](../../information-theory/en/inf-006-know-what-scene-bounds-forget.md) shows why a bounds summary can remain useful while losing interior geometry.

### Practice exercise 5: write an orientation-aware handoff

Write a short handoff for the reflected authored triangle. Include a condition under which its information would be insufficient for the next task.

> **Answer:** Retain the local positive-X material-side reference, X-reflection transform with determinant -1, reflected outward direction negative X and the actual index order, stating whether the last two indices were swapped. Mark host import and visibility untested. These fields still do not specify UVs, shading tangents, materials or every host rule; a task depending on them needs additional evidence rather than an unsupported compatibility claim.
