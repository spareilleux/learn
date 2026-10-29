# Bend length, angle meaning and no-stretch development scope

This packet supports PHY011, SEM007 and FUT006. It contains authored ideal geometry and static source/specification interpretation. It is not a new physical forming model in IX, a manufacturing DSL, a calibrated material rule, a CAD unroll or a real fabrication trial.

## Packet contents

- `production-plan.md` records predictions and gates before calculation.
- `primary-readback.json` binds six anonymous IX source/test/ADR downloads at `d7c22fdd6a62becb66b9d7246ea85850e7c55854`, each byte-equal to its immutable local Git object. It separately binds FOLD specification commit `824f9fa6f944248787b0b2077ef622761489201e`.
- `primary-reading.json` records actual Fusion sheet-metal-rule text, Rhino surface-mathematics sections, the Rhino UnrollSrf body including limitations/pitfalls, and the pinned FOLD angle definition. An Autodesk support article open exposed no body; its body/images were not claimed read. No vendor tool or machine was executed.
- `bend-lengths.json` retains 18 authored angle/factor cases, exact multiples of pi, reference-layer substitutions and a conditional factor range. Inner radius4mm, thickness2mm and assumed dimensionless factor0.4 yield neutral radius4.8mm. The straight lengths30and20 end at bend tangencies; the sum is not an outside-dimension formula. No calibration, springback or production tolerance is inferred.
- `angle-meanings.json` retains 11 signed-deviation mappings, an explicitly declared planar included-angle convention, degree/radian error control,35static selected validation-branch cases and distinct dimensionless versus curvature quantities. Passing these numeric conditions is not complete FOLD acceptance or physical meaning preservation.
- `development-scope.json` retains four curvature products, five cylinder patches with arc/chord comparisons and four scope cards. An exact intrinsic no-stretch development is different from preserving spatial chords. A closed cylinder needs an opened seam; zero local Gaussian curvature is not a global cut-free chart or fabrication certificate. Sphere/saddle counterexamples concern regular smooth exact no-stretch assumptions, not all manufacturing or changed faceted targets.
- `source-observations.json` preserves optional angles, arbitrary metadata retention, thickness in crease-pattern units and the ADR's explicit radius/motion limits. Retaining extra annotations does not establish that a selected routine consumes them. Source/test text is not a fresh test or repository-wide capability census.
- `data-audit.json` independently recalculates geometry and source predicates. `content-audit.json` records independent AI source/content review once complete. `learner-task.md` and `reviewer-rubric.json` prepare transfer work, without actual learner decisions.

## Verification and publication

URL transport, source/locale bindings, existing generator tests, source sync, full Astro build, changed article links and repeat-sync equality are recorded separately. Ordinary explicit-path publication to Draft PR201 followed by anonymous immutable byte readback publishes source/evidence/generated files. Public deployed HTML and human technical, artisan, fluent-language and learner reviews remain separate pending gates.

The ideal cylinders/sphere are teaching geometry outside the selected flat-fold analyzer's domain, not IX inputs accepted at runtime. No Rust/fullFOLD/CAD/host/scene/physical forming experiment, dependency install, paid service or new runnable lab was emitted/run. A future candidate must declare domain, reference surface, units, seams and metric tolerances, compare a simpler analytic alternative and preserve its falsifiers and remaining physical obligations. Original `source.json` and three journals are preserved.
