# Source-assisted learner tasks: weave scene transfer

Status: prepared tasks, not learner results. No participant has completed this packet. Subject, learner and fluent-language review remain pending. Work from the course before opening reviewer-rubric.json. The tasks intentionally permit source inspection; successful completion would not by itself show unaided transfer or a causal benefit from a 3D scene.

## Required inputs and procedure

Use the nine canonical VC008, PHY006 and SEM005 course sources, the teaching adapter at ../../weave-godot/README.md, expected-cases.json and the pinned evaluator/spec identified in public-input-readback.json. Inspect the retained execution report and its named checks before interpreting a scene. If no successful native execution exists for your current run, record that boundary; do not replace it with an expected result. Keep the source-manifest digest, Godot version, command, platform, exit and logs with your answer.

The shared command, from the Learn root with Node.js, Python and Godot 4.6.1 installed on PATH, is:

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

NEW_OUTPUT_DIR must be new and outside the source checkout. Obtain the unchanged external evaluator and spec using the immutable URLs and SHA-256 values in public-input-readback.json. Their cache on the author's machine is not a portable dependency. Preserve any retrieved license with the cache. Only Windows execution is assessed in the retained evidence; Linux/WSL and macOS execution remain to verify. Startup timeouts are run failures and provide no new scene evidence.

## VC008: distinguish construction from a saved-scene roundtrip

Inspect the implementation and the current retained reports. Identify the boundary between creating a live tree and observing reloaded saved bytes. Explain which nodes need owners and what would be missing if the original tree were inspected instead. State the expected object/resource counts and distinguish those counts from a proof of useful visual presentation. Propose the cheaper parity-checker alternative for a task that only asks whether the tile seam preserves alternation. Submit a short evidence-bound handoff, including what you would need before choosing a 3D interface for learners.

## PHY006: audit a proposed ruler change

For the existing scene, derive centre spacing, full thickness, upper/lower surface heights and vertical AABB gap in metres. A proposed alternative fixture doubles pitch to 10 mm while retaining 2 mm box thickness and the same centre heights. Derive the new x position of w3-f0 and the thickness-to-pitch ratio; explain why the adapter's fixed-fixture gate rejects this alternative without establishing that its geometry is physically impossible. Then interpret the wrong-unit builder control using independent metre expectations. State which assumptions make AABB bounds sufficient for this local box calculation and which physical textile claims remain unsupported. Do not modify the fixed-fixture gate to manufacture an observed result.

## SEM005: diagnose a hit with the wrong semantic name

A source-assisted diagnostic report retains the same geometry and expected upper strand but reports a collider crossing_id that differs from the manifest crossing. Explain why a node count, a source digest, a runtime Object instance ID or a hit on the right type of strand cannot repair that mismatch. Identify the field and named gate to inspect, propose a one-field scratch mutation, and describe the records required before accepting a correction. Distinguish a scripted physics ray from a human selecting an object. Do not assert that a full DSL or a 3D interface is required by this single example.

## Record sheet

For each task retain the participant's answer, allowed assistance, inputs/digests, any executed command and actual exit/report, unresolved questions and reviewer criterion decisions. Leave outcomes null until a real participant and reviewer supply them. Timing, accessibility and comparison with a labeled 2D alternative have not been measured.
