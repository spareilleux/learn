# Weave-to-scene transfer experiment

## Project question and alternative

Can a source-bound crossing manifest survive native Godot scene serialization, keep its intended units, and identify the upper strand in a scripted physics probe? Existing VC007 proves a synthetic parity distinction without a renderer; this exercise tests a different boundary. The simpler alternative is that checker plus a labeled2D diagram. Native3D earns no educational or product preference until an actual task comparison supports it.

## Declared teaching model

Use the pinned Demerzel odd-tile plain-weave fixture:3by3 base tile repeated2by2, phase0, spacing5mm, nominal diameter2mm. Unchanged evaluator distinguishes global parity (0adjacency violations) from restarted local parity (12violations). It is neither an IX weave DSL nor a textile mechanics model.

Represent each of36crossings by two box segments. Warp runs along worldZ, weft along worldX; use2mm box thickness as an explicit visual proxy for the nominal diameter. The centre heights are+1.5mm and-1.5mm, leaving1mm of vertical AABB gap. These separate segments do not make continuous yarn or establish tension, bending, manufacturing clearance or cloth contact.

The scene convention is1unit per metre. Independently expected values include crossingw3-f0 at worldX0.015, the last grid coordinate0.025 and box thickness0.002. Coordinate magnitudes are representations under that declared ruler, not physical measurements of a manufactured sample.

## Execution and failure criteria

Create a standalone native Godot project in a fresh output directory. Save a PackedScene with owners and metadata, remove the original live tree, reload the saved scene, instantiate it and await physics synchronization. Inspect loaded transforms/mesh bounds and perform36downward physics rays at the crossing centres. Expected w2-f0 upper strand iswarp; w3-f0 isweft. Check all identities and declared upper strands against the manifest. These are automated physics queries, not user clicks or a GPU capture.

Require36unique crossing IDs,72thread representations, correct declared coordinates and separation, a source-manifest hash binding and no mismatched ray result. Wrong units in the builder and wrong hit-to-crossing metadata must be rejected by named checks in temporary mutations; restarted parity is rejected by the existing semantic checker. Use no hidden production test flags and change no GA/IX/Godot product code.

## Assumptions, costs and limits

The central assumption is that these proxies are enough to inspect the crossing-to-object transfer. The strongest counterargument is that a labeled2D checker explains the relation with lower cost. IDs across edits, axes, scene ownership, serialization, collision geometry, input selection and accessibility add maintenance. Reject this adapter case if its declared data do not survive save/load or its queries resolve the wrong ID or upper strand. A technically correct scene remains unassessed for learner benefit, visual clarity, frame cost and continuous-textile behavior.

No Blender/GLB export, observatory integration, browser/WASM export, forked DLSS execution, listening, human learner result or public course HTML readback is established by this plan. A future DSL remains advisory; the simplest manifest and small adapter must be the baseline.
