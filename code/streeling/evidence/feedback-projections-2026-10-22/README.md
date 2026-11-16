# Feedback and projection courses — 2026-10-22

## Scope

New draft courses INF005, NET006 and CYB004 explain three different decisions using retained project artifacts: what a PCM16 projection distinguishes, which graph a shared scene resource defines, and what a measured feedback result permits an agent to correct. English, French and Spanish sources remain subject to human subject, fluent-language and learner review. Public course HTML publication is not established by source existence or a build.

This tranche performs new arithmetic and static graph analysis. It does not rerender guitar audio, rerun Godot, modify a product controller, execute an IX exporter or establish ComfyUI/Blender/Godot integration. The original native/WASM and saved-scene runtime receipts remain separately available at their pinned source commit.

## Primary inputs and replay boundary

`primary-input-readback.json` records eight anonymous HTTP 200 responses whose bytes exactly match Learn commit `7eaa68f8d4d32e8d1b495a93775d18135e709811`. These include the original PCM encoder, guitar measurements, saved native scene and launcher receipts. Official language/runtime documentation was read separately. Failed Caltech textbook probes are retained as unused research probes, not cited as successful reading.

The four generated float32 caches used for full-sample arithmetic have exactly the SHA-256 digests recorded in the original guitar results. They remain in the original external scratch directory, without redistributing the recorded reference input. To reproduce them, follow the existing [guitar runtime lab](../../guitar-runtime/README.md) with its pinned inputs and teaching compiler flags. Only the recorded Windows/toolchain execution is verified; other runtimes may produce different raw bytes. The small captured pairs and all source hashes needed for the lesson's arithmetic are included in `quantization.json`. The deliberately constructed 0.25 pair is labeled separately from captured samples.

For every paired finite float32 sample, apply the original encoder's `Math.round(sample * 32767)`, compare its signed integer result, and reconstruct a normalized value by dividing by 32767. Count unequal input pairs separately from unequal integer outputs; calculate the maximum reconstruction error separately from the maximum input-pair distance. These are different quantities. The new host Node calculation reproduced the original raw-difference counts and exact committed PCM payloads. A separate host Python implementation decoded the same buffers with `struct`, used `floor(value * 32767 + 0.5)` for the resulting integer and matched every payload byte and maximum error. `analysis-crosscheck.json` records that comparison; it is not an independent reviewer or a new rendering trial. Python's built-in round was deliberately not substituted for ECMAScript rounding.

## Quantization results

Each arm has 176400 samples. Native versus WASM differs at 2918 baseline and 2926 candidate float32 values, with maximum difference 2.9802322387695312e-8. The paired PCM16 code differences are zero. The baseline native maximum reconstruction error is 0.000015258982790783415 and the candidate maximum is 0.00001525887933261083, below the ideal-real half-step bound 1/(2*32767). These observations do not identify unique input values from equal codes, compute source entropy in bits, establish a noise model or show auditory equivalence.

The accepted finite normalized domain and chosen multiplier emit integers from -32767 through 32767, giving 65535 possible codes. That is a property of this encoder, not the whole signed int16 storage range. Rounding halfway toward positive infinity differs from Python's default tie rule; signed zero is also a Number-level distinction that is lost when stored as a signed integer zero. Real-arithmetic bin formulas need qualification at floating-point boundaries.

## Resource graphs

`resource-graphs.json` lists the extracted references from exact `native-scene.tscn` bytes. Its hierarchy has 253 scene nodes: 37 Node3D, 72 MeshInstance3D, 72 StaticBody3D and 72 CollisionShape3D. The six resources are two meshes, two shapes and two materials; they are not additional scene nodes.

The chosen reference graph includes 144 scene nodes with one of the three selected properties and 6 resource nodes. It has 216 directed references: 72 mesh, 72 shape and 72 material references. Each resource has 36 incoming references. A different mesh-only projection connects two MeshInstance3D nodes exactly when their mesh properties share a resource. Its 72 nodes form two 36-node cliques, with 1260 edges. Neither graph counts draw calls or proves live coordination edges. Removing one mesh-resource vertex in this analytical model removes 36 reference edges; no actual scene was edited or engine failure observed. Verify any proposed extraction by comparing its resource declarations, property references and node-type totals with the saved file, not by counting the same conceptual objects under different names.

## Feedback decisions

`feedback-decisions.json` recomputes the existing audio acceptance arithmetic. A completed experiment has exit 0 while its candidate improves absolute decline error by only 0.11416614959438576 dB against a declared 1 dB requirement. Its candidate error 2.723137239012459 exceeds the allowable 1.8373033886068448 dB for that gate. Other perceptual/product acceptance remains unknown. One candidate and one observed change provide no convergence rate or exponential-improvement result.

The Godot launcher failure also illustrates absent observation: a startup timeout supplied no new native scene result. The earlier PATH-parent attempt still chose the same launcher and was not an effective direct-launch comparison. The explicit resolved executable then passed against the same copied project; the cached trial script still matches the failed run's recorded input digest. Final controller checks are retained in the prior weave tranche. This local record supports a bounded correction, not an all-platform performance or C# reliability conclusion.

## Review and delivery

`learner-task.md` and the separate 15-criterion `reviewer-rubric.json` prepare source-assisted tasks; all participant/reviewer outcomes remain null. Their overlap with the lessons prevents a claim of unaided transfer or causal teaching benefit. Bindings, source counts, language parity, AI review, build and rendered-link checks are recorded when completed. No pre-existing journal or source-copy provenance is rewritten.

The course work emits no new production or lab code; no code simplification pipeline is needed for this documentation/data tranche. Native factual review and AI content review are distinct from human approval. The full 525-course reviewed/published objective remains incomplete.
