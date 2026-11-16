# Weave material response, reference normals and generator scope

Execution: knowledge-work. Produce PHY012, SEM008 and FUT007 in English, French and Spanish, with five corrected exercises and a source-assisted learner task per module. The full goal remains 25 reviewed and published courses in each of the original 21 departments, 525 total.

## Baseline and chronology

Learn baseline is `eebf49cb0b69a314bd13015340335a983aa64bfe`: 219 core English sources, 220 in each locale with IX Research separate. This plan follows source reading and hand-worked model choices, before external numerical verification. It is not a preregistration of a physical experiment. No new runnable lab, simulation, adapter, material solver, training run or DSL is delivered.

## Primary inputs

Read five IX source/test/ADR files at `d7c22fdd6a62becb66b9d7246ea85850e7c55854`: thickness, layer rules, transformation controls, thickness tests and the parallel-panel ADR. Read Demerzel's existing parity evaluator/specification at `f23ccae6c049d9066a1be2221c68f3b0bcf48373`. Read the existing Learn teaching scene and its README at the Learn baseline, using this canonical checkout's Git objects. All nine anonymous source downloads match immutable local Git objects; the two Demerzel hashes also match the earlier retained teaching README.

Read the pinned FOLD specification at `824f9fa6f944248787b0b2077ef622761489201e`, especially reference-normal and swapped-triple definitions. Read actual Godot4.6 rendering-anisotropy and physics-material definitions. Read the MIT OpenCourseWare linear spring lecture transcript's force/stiffness and energy passages; a web screenshot attempt failed with a cache miss, so do not claim the PDF was visually inspected or a lecture video watched.

## Course models and predictions

- PHY012: use an authored two-degree-of-freedom linear spring response with stiffness diagonal4/1 N/mm and energy one-half displacement transpose times stiffness times displacement. Define an active mathematical planar rotation. Rotate response and material axes together; check90-degree and45-degree cases, off-diagonal forces and energy covariance. This is not a measured woven material, continuum constitutive tensor or Godot cloth model. Distinguish optical anisotropy, collision friction and mechanical stiffness.
- SEM008: use an authored flat-layer relation with known signs of face normals relative to one global up axis. FOLD's triple refers to the second face's normal. Derive global-order conversion, swapping arguments with equal/opposite normals and turning the entire model over. A role rename, recoloring, argument reversal and normal-frame change are different operations. Unknown order remains unknown. Build on SEM004/006 rather than repeat their permutation/winding examples.
- FUT007: use exact known crossings in a6-by-6 preview as stronger evidence than an image. Construct a rule agreeing there but differing outside. Count unconstrained extensions on an8-by-8 domain, then separately impose complete alternation constraints and an origin value. Distinguish sample agreement, structural proof in a declared class and actual learned or manufacturing generalization. The authored adversarial rule is not a supported Demerzel variant or an actual learned model.

## Verification and limits

Keep authored matrices, relation tables and finite grids separate from actual source/test text. Independently audit equations, all chosen cases and the pinned bytes. Review all45 localized answer pairs and15 prepared learner criteria. Human technical, artisan, fluent-language and actual learner decisions remain unperformed.

Run only existing generator tests, source sync, a full static build, changed article/source-banner link checks and repeat-sync equality. No new Godot/IX/native/GPU/material test or dependency install is required. Preserve `streeling/source.json` and all three journals. Commit explicit owned files, push normally to Draft PR201 and anonymously byte-match every changed file at the immutable resulting head. Deployed course HTML remains a separate gate.

The strongest objection to a new material/semantic/generation DSL is that the current inspection goal may be met by a typed manifest, a table and a small independent validator. Reject claims that confuse render parameters with calibrated mechanics, relative signs with absolute height, or one preview with unrestricted capability. Keep proposed adapter fields advisory until a measured comparison and independent review justify them.
