---
module_id: inf-006-know-what-scene-bounds-forget
department: information-theory
course: "Know What Scene Bounds Forget"
level: intermediate
prerequisites: ["inf-004-information-loss-in-agent-handoffs", "vc-009-budget-brutal-scene-expansion"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Know What Scene Bounds Forget

> **Draft scope.** Fresh CPU validation and bounds calls on authored BRUTAL drafts, plus exact ideal-geometry and finite-prior calculations. Human technical, fluent-language and learner reviews and deployed course HTML verification remain pending. No renderer, collision engine, Blender/Godot adapter or GPU was run.

## The project question

An agent receives two scene boxes and an axis-aligned bounding box, then says that the scene is unchanged. The summary may be sufficient to frame a preview, but it does not identify all the geometry inside. This lesson makes the lost information concrete before choosing what agents should exchange.

The pinned [BRUTAL Scene model](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L236-L257) transforms all eight corners of every local box and reduces their componentwise minima and maxima. Its boxes are floor-based: X/Z span half-size on either side, and Y runs from zero to height. [VC-009](../../visual-computing/en/vc-009-budget-brutal-scene-expansion.md) explains the separate box budget. Here equal budget and bounds will deliberately conceal a geometric difference.

## 1. Find all the transformed extrema

For the authored child yaw of 45 degrees under parent scale `(2,1,1)`, a unit floor-based box has aggregate minimum `(-sqrt2,0,-1/sqrt2)` and maximum `(sqrt2,1,1/sqrt2)`. The [actual native cases](../../../../code/streeling/evidence/scene-frames-2026-10-22/native-cases.json) retain the float32 bounds. A separate exact calculation and absolute-basis formula agree within the declared `1e-5` tolerance.

Transforming only the opposing local endpoints `(-0.5,0,-0.5)` and `(0.5,1,0.5)` would instead give Z equal to zero in exact arithmetic and miss the other corners' extrema. An affine map need not preserve which corner maximizes a coordinate. The [bounds comparison](../../../../code/streeling/evidence/scene-frames-2026-10-22/bounds-comparison.json) retains this failing shortcut. These claims concern affine boxes, not a general perspective or nonlinear deformation.

### Practice exercise 1: reject the two-corner shortcut

What Z interval should the complete transformed box have, and what interval does the opposing-endpoint shortcut report? Why is the latter not a conservative bound?

> **Answer:** The complete exact Z interval is from `-1/sqrt2` to `1/sqrt2`; the shortcut gives only zero. It excludes actual transformed corners and therefore cannot safely enclose this box. Transforming all eight corners, or an equivalent valid affine-box formula, addresses this case; checking two endpoints does not.

## 2. Construct two scenes with one shared summary

Use identity orientation and metres for this authored two-scene example:

| Scene | Box sizes | X translations | Y/Z translation |
| --- | --- | --- | --- |
| A | `(1,2,2)` for each box | -0.5 and 0.5 | 0 for both axes |
| B | `(0.2,2,2)` for each box | -0.9 and 0.9 | 0 for both axes |

The actual public validator accepts both teaching drafts, and the native Scene properties return box count 2 and the same bounds: minimum `(-1,0,-1)`, maximum `(1,2,1)`. Scene A fills that box with two touching halves. Scene B leaves an interior gap between thin side slabs. The [counterexample record](../../../../code/streeling/evidence/scene-frames-2026-10-22/summary-counterexample.json) separates native observations from exact ideal-decimal geometry. Float32 size representations are not claimed to have exact rational volumes.

### Practice exercise 2: recover what the summary omits

Calculate each scene's ideal union volume and the shared bounding-box volume. Does equality of count and bounds establish equality of geometry or a scene-hash collision?

> **Answer:** Scene A has volume `2*1*2*2=8`; B has `2*0.2*2*2=1.6`, or `8/5`. Their shared bounding-box volume is `2*2*2=8`. The same count/bounds summary therefore does not identify the interior. No full-scene hash equality or collision was claimed or measured.

## 3. A bound can reject a candidate without proving contact

Use closed boxes for these authored membership probes. The centre `(0,1,0)` belongs to A's union on the halves' shared boundary and lies outside B, although both aggregate bounding boxes include it. The outside control `(1.2,1,0)` lies outside both. These are authored point-membership checks for these box unions, not an executed production collision test.

When two aggregate bounds are disjoint in the same declared frame and units, their enclosed geometry cannot overlap. The converse fails: overlapping bounds can enclose separated geometry. Boundary conventions also matter for exact contact. A broad-phase candidate is a reason for a more precise check, not a confirmed collision or a manufactured clearance guarantee.

### Practice exercise 3: interpret a positive broad-phase result

An agent uses only B's aggregate bound to report material at the centre. Give the counterexample and one useful conclusion the same bound can still support.

> **Answer:** B's side slabs leave the centre `(0,1,0)` empty even though its aggregate bound includes that point. The bound can reject `(1.2,1,0)` as outside all enclosed geometry. A positive aggregate-bound test alone cannot establish material occupancy, surface contact or physical clearance.

## 4. Quantify loss under a declared prior

For a deliberately small information-theory example, suppose A and B are the only alternatives, each with probability 0.5. Their initial scene-choice entropy is 1 bit. Let the message contain only count 2 and the shared bounds. Both alternatives produce that message, so conditional scene-choice entropy remains 1 bit and mutual information about the choice is 0 bits.

Append the declared centre-membership result. It is true for A and false for B, so under this two-alternative prior it identifies the scene: conditional entropy becomes 0 and mutual information becomes 1 bit. This does not mean one bit identifies every scene or that the bounds have no value for another task. The alternatives and prior define the calculation.

### Practice exercise 4: state the information claim precisely

Compute initial entropy, conditional entropy after the shared summary and mutual information. How do these values change after the centre probe, and what assumption prevents generalizing the result to all scenes?

> **Answer:** They are initially 1 bit, then 1 bit conditional entropy and 0 bits mutual information after the shared summary. Adding the centre result gives 0 conditional bits and 1 bit of mutual information. Those values rely on exactly two equally likely alternatives with the stated deterministic responses. They are not a general scene entropy, measured compression ratio or universal one-bit encoding.

## 5. Choose a message for the actual decision

For camera framing, the common bound may be sufficient. For material occupancy, the recipient needs the appropriate geometry or a justified query result. For shading or side interpretation, [PHY-008](../../physics/en/phy-008-keep-surface-normals-perpendicular.md) and [SEM-006](../../semiotics/en/sem-006-preserve-orientation-across-scene-frames.md) identify other missing distinctions. A summary should declare the question it can answer and retain source/frame/unit context.

The strongest objection to always sending complete geometry is its transfer and inspection cost. A simpler alternative is a bounded task-specific summary plus a way to request more evidence. Our centre probe suffices for the authored choice; it is not an implemented general query protocol. [INF-004](inf-004-information-loss-in-agent-handoffs.md) explains why an economical handoff should still preserve the distinctions required by its recipient.

### Practice exercise 5: design a sufficient handoff

The recipient first needs a camera frame, then asks whether material occupies the centre. What should the agent retain or add at each step? State a criterion that would reject the proposed summary for a new task.

> **Answer:** Keep the bound with its frame, units and source context for framing. Add the explicitly scoped centre-membership result and its geometric basis for the later question, or provide the relevant geometry for an actual precise test. Reject the summary as sufficient when two admissible scenes produce the same message but require different answers to the recipient's task. No new adapter, production query service or host result was implemented here.
