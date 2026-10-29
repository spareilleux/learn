# Pitch-context teaching evidence

Three project-grounded source modules: WML005 (declared spelling vocabulary), MCL005 (encoded and sounding pitch), GAA006 (capo direction, quality and register). Each has five corrected exercises in English, French and Spanish. This packet is fixed evidence and review material, not a new runnable lab or production correction.

## Inputs and observations

- `production-plan.md`: scope and predictions written before execution.
- `primary-readback.json`: six anonymously fetched public GA files, pinned to dc2e74cbd992a298f67efb928b5b3754615e1924 and byte-matched against immutable local Git objects. The source snapshot is not the deployed service revision.
- `authored-xml-inputs.json`: ten teaching XML inputs. They were not MusicXML-schema validated; H and missing-octave controls are intentionally deficient.
- `native-parser-results.json`, `native-stdout.txt`, `native-stderr.txt`, `execution.json`: actual fresh standalone FSI execution of two unchanged pinned source files using SDK 10.0.113. All ten outer parses succeeded. Two notes lacked pitches. Transpose and clef-octave changes disappeared from otherwise equal records; decimal alter 0.5 became absent and converted as 0. Sentinel -999 is observation-wrapper notation for absence, never a musical output.
- `language-decisions.json`: six authored convention decisions, not implementation or a claim about every speaker.
- `capo-arithmetic.json`: 312 authored major/minor pitch-class cases and explicit controls. These calculations do not execute CapoSkill, prove routing or measure playability.
- `transposition-arithmetic.json`: limited ordinary-note examples with explicitly declared offsets; no doubling or per-staff/time-varying transpose handling is asserted.
- `theory-tool-probes.json`: actual chord-transposition responses, unknown service revision; not CapoSkill execution.
- `official-links.json`: URL transport results plus primary-document reading provenance. A transport check is not evidence of application behavior.

## Review and publication boundaries

`data-audit.json` independently checks sources, native observations and arithmetic. `content-audit.json` checks all 45 localized exercise/answer pairs and 15 prepared learner criteria. `bindings.json` binds reviewed canonical sources; `locale-checks.json` checks mechanical parity. Generated-site tests/build, local rendered article links/anchors, repeat synchronization and source inventory are recorded separately. Public immutable source-byte readback is kept in an external receipt to avoid a self-reference cycle.

Human technical approval, fluent-language approval, learner attempts, real guitar playing, full application MusicXML import, notation rendering, playback and deployed course HTML remain unperformed. No production bug fix, dependency installation, GPU job or private BRUTAL source is included. An independently checked draft source is not a completed reviewed-and-deployed course for the 525-course goal.
