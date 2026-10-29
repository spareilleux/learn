---
execution: knowledge-work
base_learn_commit: 79f2034a6abc3d8607bbd0c74abcf02869e5fa11
source_ga_commit: 76efbffd5af82b46c3146957a6bd4504008eeb89
---

# Color and data-texture course production plan

Produce PHY009 (linear color versus display encoding), VC010 (packed data-texture channel contracts) and COG006 (pixel tests versus appearance judgments) in English/French/Spanish. Each has five corrected exercises, exact primary sources, fixed calculations and a prepared learner task. Root owns English/evidence/integration; scoped reviewers and translators own their named outputs. No renderer, Blender/ComfyUI/Godot application, GPU, display calibration or human study is executed. No new runnable lab or production import/shader change is delivered.

## Predictions before calculation or figure generation

- The pinned public bake script declares sRGB albedo and Non-Color normal/roughness/height output. RG stores normal X/Y, B roughness, A an albedo-derived height proxy. Program.cs reads RG/B for the examined concrete/facade/cladding/machine material paths; no packed-alpha displacement is implemented in those paths. The source's generated height is not measured physical geometry.
- Piecewise sRGB reference decoding maps encoded0.5 to about0.214, while a2.2 power gives about0.218. Averaging black/white in encoded coordinates gives0.5; averaging in linear coordinates gives linear0.5, encoded about0.735, rounded bytes128 and188 respectively. Keep unquantized and quantized calculations distinct. Linear light here is an RGB coordinate model, not a measured cd/m2 luminance value.
- The source uses a manual2.2 albedo power on selected paths, UNorm texture storage and a separate filmic rational curve named aces followed by grading/vignette/1over2.2 encoding/grain. Isolated scalar calculations do not reproduce a complete frame or establish ACES conformance. Exposure and that nonlinear curve should not commute.
- An authored packed texel128,128,128,64, interpreted as normalized data, has signed RG near0.00392 and blue roughness near0.502. Applying an sRGB color decode to its data channels should change the signed RG to approximately-0.568 and corrupt the blue value. Alpha height is not opacity and the packed blue is not normal Z. Do not apply a standard normal-map contract blindly to this packed format.
- Read two existing public concrete PNGs at the pinned commit only to inspect their actual byte format/chunks and ranges. Do not run the bake script or infer its live environment. Source output-tag declarations and actual stored file metadata are separate evidence.
- Generate one original tagged-sRGB teaching PNG containing byte128 versus188 midpoint swatches and two byte-identical128 target squares on different32/224 surrounds. The target crops should be exactly equal. This is an authored contextual display control, not Adelson's checker-block stimulus or a replication of a perception study. No observer response or effect magnitude is predicted as measured.

## Sources and synthesis

Read four public GA text files and two public PNGs at the pinned commit. Read the dated W3C Color4 draft2026-10-20 sRGB transfer reference, Godot4.6 source_color documentation, Blender4.5 Non-Color guidance and Lovell etal2026 primary study abstract/introduction for task/appearance distinctions. The study's stimulus and outcomes are not copied into our new control. Failed transport routes must be recorded separately from actual content reads. A display/reflection judgment needs its own operational question and observer evidence beyond byte equality.

## Verification and publication

Independent data/source/PNG audit, independent review of all45localized exercise-answer pairs and15learnercriteria. Keep human/fluent/learner/import/display outcomes null. Publish the audited original PNG in a separate explicit asset commit; anonymously check raw MIME, decoded pixels and exact bytes, with a200HTML negative control. Then use its immutable raw URL in all locales. Existing18generator tests, sync, Astro build, actual rendered image URLs/internal links/anchors and repeat-sync byte equality. Preserve source.json and three journals. Explicit owned commits and normal push to existing Draft201, no PR title/body rewrite or auto-merge. Public immutable source readback is distinct from deployed course HTML and human review under the full525-course objective.
