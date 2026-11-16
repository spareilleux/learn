---
module_id: vc-009-budget-brutal-scene-expansion
department: visual-computing
course: "Budget BRUTAL Scene Expansion Before Rendering"
level: intermediate
prerequisites: ["vc-008-save-and-query-a-weave-scene", "cs-014-compose-brutal-scene-descriptions"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Budget BRUTAL Scene Expansion Before Rendering

> **Draft scope.** Fresh CPU scene-generation and refusal results from public source. Human technical review, fluent-language review, learner attempts and public course HTML verification remain pending. No graphics window, GPU, renderer or stream was started.

## The project question

An agent composes a recursive scene for the [BRUTAL evaluation](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md). How can the system reject excessive expansion before creating rendering resources? A small description can generate many boxes. Bounding the description's growth is a concrete graphics preparation task, even though it does not predict frame time.

[CS-014](../../computer-science/en/cs-014-compose-brutal-scene-descriptions.md) introduces the typed Lego blocks. This lesson examines their [limits and issues](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L133-L195), [generation guards](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Generate.fs) and [validation boundary](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Validate.fs). All code observations use public GA commit `76efbffd5af82b46c3146957a6bd4504008eeb89`.

## 1. Count the representation that actually expands

The standard source limits are maximum depth 8, maximum block instances 4096 and maximum boxes 20000. They constrain different things. A block can emit several boxes without adding another block instance; nesting can exceed the depth limit while remaining small in total geometry.

The [actual CPU descriptions](../../../../code/streeling/evidence/brutal-composition-2026-10-22/cpu-descriptions.json) show a four-column colonnade with five instances and 53 boxes. Explicitly selecting its second column version keeps five instances but raises the box count to 85. A budget based only on instances would miss that geometry increase.

### Practice exercise 1: choose the relevant counter

Compare the two colonnades. What changes, what remains fixed and why is the instance count alone insufficient as a box budget?

> **Answer:** Instances remain five: the root and four columns. Boxes increase from 53 to 85, a difference of 32, because the selected column version emits more geometry. An instance counter tracks expansion nodes; it does not bound geometry per node without an additional rule. Preserve both counters.

## 2. Convert to a declared geometric cost

The source describes each box as 12 triangles. Under that representation, 53 boxes correspond to 636 triangles and 85 to 1020; the difference is 384. The standard 20000-box limit corresponds to a 240000-triangle box budget.

These are representation-level counts. They do not establish draw calls, unique vertices, GPU memory, overdraw, ray-tracing cost or frame time. A host may instance geometry, add other objects or use other passes. State which quantity a budget controls before turning it into a product performance claim.

### Practice exercise 2: calculate the budget

Using 12 triangles per box, compute both colonnade costs, their difference and the standard box-triangle budget. Can the resulting numbers establish the scene's frames per second?

> **Answer:** Costs are `53*12 = 636` and `85*12 = 1020`; the increase is `32*12 = 384`. The standard budget is `20000*12 = 240000` triangles in the declared box representation. Frames per second require a measured rendering workload, host and timing method; these counts alone do not supply them.

## 3. Understand where refusal occurs

The [execution receipt](../../../../code/streeling/evidence/brutal-composition-2026-10-22/cpu-execution.json) records 20 passing existing Release tests. Selected CLI requests also ran separately. Sanctuary level 2 was accepted with 756 instances and 8505 boxes, corresponding to 102060 box triangles. Level 3 returned exit 2 and `lego-errors/1` with a `too-many-boxes` issue. The refused output does not contain a completed accepted scene count.

Generation increments its box counter before checking whether the limit was crossed. The guard therefore allows a counter value up to 20001 under the standard limit, while retaining at most 20000 placed boxes. Those are source-derived upper bounds, not a claim that the intended full level 3 scene contains 20001 boxes. The existing test checks bounded stopping; validation refuses the partial draft when it has problems.

### Practice exercise 3: distinguish the attempted count from a scene

Why can a counter reach one beyond the box limit without approving an oversized scene? What do the accepted level 2 result and refused level 3 result establish?

> **Answer:** The implementation counts an attempted box, detects that the counter exceeds 20000, records the issue and stops retaining further geometry. The counter can therefore reach 20001 while retained boxes stay at most 20000. Level 2 produced an accepted 8505-box, 756-instance description. Level 3 was refused; its error is not a complete-scene size or a rendering result.

## 4. Make the depth convention visible

The root has depth 0. Maximum depth 1 allows the root and its immediate children, then refuses deeper expansion. The captured temple request with that limit returned `too-deep`; a separate request limited to 10 instances returned `too-many-instances`. The test suite also verifies that depth 2 is sufficient for the tested temple.

A limit of depth 8 therefore means eight nesting steps below the root, rather than eight nodes including the root along every path. Keep that convention in a handoff or UI. Renaming a field “levels” without defining its origin can create an off-by-one disagreement between producer and consumer.

### Practice exercise 4: read a depth refusal

Does maximum depth 1 allow a grandchild at depth 2? Why should an agent keep the distinction between `too-deep` and `too-many-instances`, even if both stop the same requested temple?

> **Answer:** No. With root depth 0, an immediate child at depth 1 is allowed, but a grandchild at depth 2 crosses the limit. The two issues identify different constraints. Increasing instance allowance cannot by itself repair a depth refusal, and increasing depth cannot guarantee the instance budget will hold. Change an explicit requirement and rerun its check.

## 5. Compose validation with a separate rendering gate

The public [Colossus entry-point comments](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L37-L41) describe generation and validation before window creation. That is source evidence for the intended integration. This course executed the pure CLI, not that graphics host. An accepted description is ready for the next boundary; it has not passed a GPU or coexistence test.

[PM-005](../../product-management/en/pm-005-interpret-brutal-coexistence-experiments.md) explains why a historical high frame rate in one process is insufficient to approve running it beside the Observatory. Carry source, seed, versions, arguments, limits, format, exit status and description hash into the next experiment instead of substituting one counter for all those facts.

### Practice exercise 5: write the handoff

An agent reports “8505 boxes, therefore fast and safe to display beside [Godot](https://docs.godotengine.org/en/stable/).” Replace that with a supported result and the next gate.

> **Answer:** The pinned public CPU-only CLI accepted sanctuary level 2 with 8505 boxes and 756 instances under the recorded limits. Preserve its request, output format, exit 0 and hash. Rendering speed, resource disposal and coexistence with the adjacent Godot task need a separate measured host experiment. The accepted description supplies no observed GPU result.

## Evidence boundary

The [calculation record](../../../../code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json) separates actual descriptions, arithmetic and guard-derived bounds. These finite checks do not prove every possible block terminates, every parameter is safe, every host respects the limits or any learner can transfer the method. Only public source and scoped CPU results support this draft.
