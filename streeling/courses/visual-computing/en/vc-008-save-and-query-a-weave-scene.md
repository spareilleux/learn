---
module_id: vc-008-save-and-query-a-weave-scene
department: visual-computing
course: "Save and Query a Weave Scene"
level: intermediate
prerequisites: [vc-007-weave-seams-as-scene-contracts]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Save and Query a Weave Scene

> **AI source draft.** Human subject, fluent-language, and learner reviews remain pending. Public course HTML publication remains pending.

[VC-007](vc-007-weave-seams-as-scene-contracts.md) checks a synthetic weave before rendering. This follow-up asks whether admitted crossings survive a native [Godot](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html) save/load boundary and remain queryable. Your deliverable is a receipt identifying the saved artifact, loaded observations, and limits of the conclusion. Use the [lab README](../../../../code/streeling/weave-godot/README.md), [evidence README](../../../../code/streeling/evidence/weave-scene-2026-10-22/README.md), and [learner task](../../../../code/streeling/evidence/weave-scene-2026-10-22/learner-task.md). The evidence README retains execution details and failures.

Verified Windows result: save/load and 36 physics probes passed; scale, collider-binding, and restarted-parity controls failed at their named gates. Earlier launcher failures supply no scene proof.

## 1. Admit a declared model

The immutable [evaluator](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) and [specification](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json) describe `odd-tile-seam-a`: a 3 × 3 tile repeated 2 × 2 gives 6 × 6, or 36 crossings. Global parity has 0 adjacency violations; restarted tile parity has 12. Admission rejects the latter before scene creation. A scene cannot repair that semantic failure by looking plausible.

The adapter creates two isolated box segments per crossing. Warp runs along world Z and weft along X. Nominal diameter 2 mm becomes box thickness, not a cylindrical yarn model. Segments do not establish continuous yarn, tension, or cloth contact. This small model makes the transfer inspectable without pretending to implement a general exporter.

### Exercise 1 — Locate the boundary

The restarted variant produces 12 violations but could make an attractive image. Should it reach scene construction?

> **Answer:** No. `semantic_admission` must reject it before a Godot project is created. Retain the semantic report and failure; visual appeal supplies no evidence that the declared alternation survived composition.

## 2. Make persistence observable

A live node tree is insufficient evidence of a saved scene. [PackedScene](https://docs.godotengine.org/en/4.6/classes/class_packedscene.html) packages nodes for instantiation; the adapter assigns owners to crossing nodes, meshes, bodies, and collision shapes so the intended descendants enter that package. It also attaches crossing and strand metadata and the source-manifest digest. Omitting ownership can lose descendants even when the original live tree looks complete.

The trial packs the root, saves `weave.tscn`, frees the original tree, loads the saved bytes, instantiates a new tree, and awaits physics synchronization. Observations then concern the loaded instance. Expected counts are 36 crossing parents and 72 each of meshes, static bodies, and collision shapes. Two shared resources of each mesh, shape, and material kind avoid creating 72 distinct copies; resource sharing is separate from the number of instances.

### Exercise 2 — Challenge a save claim

A report counts 72 meshes before saving and never frees the original. What additional observation is required?

> **Answer:** Remove the original, load and instantiate the saved artifact, then count the loaded descendants and inspect their metadata. A successful save call and a complete original tree do not show that ownership preserved the required descendants.

## 3. Query the loaded representation

Each [MeshInstance3D](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) displays a proxy, while a static body and collision shape make it queryable. After loading, [PhysicsDirectSpaceState3D.intersect_ray](https://docs.godotengine.org/en/4.6/classes/class_physicsdirectspacestate3d.html) sends 36 downward rays through independently expected crossing centres. The collider's metadata must return the requested crossing and its expected upper strand. At `w2-f0`, warp is upper; at `w3-f0`, weft is upper.

These are automated physics probes. They establish neither human selection accuracy nor rendered visibility. A camera, highlight, or screenshot is absent from this task. A correct mesh position also cannot prove the collider is bound to the right source ID.

### Exercise 3 — Interpret a hit

A ray aimed at `w3-f0` hits weft geometry but reports `w2-f0`. Which requirement fails?

> **Answer:** `ray_crossing_identity` fails even if `ray_upper_strand` and geometry checks pass. The scene has resolved the wrong source crossing. Keep both results rather than reducing them to “the ray hit something.”

## 4. Reproduce with provenance

With installed [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), [Python](https://docs.python.org/3/using/cmdline.html), and Godot 4.6.1 on `PATH`, run from the repository root:

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

Use a new output directory outside the checkout and unchanged external inputs. The runner records input and teaching-file SHA-256 hashes, the manifest digest, logs, and reports; the Godot report records the scene digest. Compare those bytes with provenance, not only filenames. The command is common across operating systems; only Windows has been exercised, while Linux/WSL and macOS remain to verify.

### Exercise 4 — Separate failures

Godot times out during startup after semantic admission. Can the semantic result certify the new scene?

> **Answer:** No. Preserve the startup logs and failed run report. An environment or runtime failure is distinct from semantic rejection, but it supplies no new save/load or physics proof. Retry in a new directory and report the actual outcome.

## 5. Retain a useful counterexample

Observe the baseline, change one assumption, rerun, retain the failure, and bound the claim. A scratch mutation of only collider `crossing_id` should fail identity; a mutation of only builder `MM_TO_M` should fail independent metre expectations. Neither control establishes useful teaching by itself. Read the evidence README before describing either as executed.

Composability is a hypothesis tested at this boundary. More connected tools do not automatically produce faster progress. Compare any proposed 3D explanation with the cheaper evaluator plus a labeled 2D grid using the same learner task. Record unassisted answers and maintenance effort before claiming an advantage or proposing a DSL.

### Exercise 5 — Write the release sentence

What may a fully passing roundtrip support, and what further evidence would justify preferring it to 2D?

> **Answer:** It supports persistence and scripted query correctness for these pinned inputs and isolated proxies. A controlled learner comparison is still needed to support educational preference. Subject, language, learner, and publication reviews remain pending; no cloth simulation, production integration, or human interaction result follows from the technical pass.
