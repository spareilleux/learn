---
execution: knowledge-work
base_learn_commit: 3c82c09677cb14cc73312031562c499c257707aa
source_ga_commit: dc2e74cbd992a298f67efb928b5b3754615e1924
---

# Pitch context production plan

Produce WML005 (declared note-name convention), MCL005 (written and sounding pitch), and GAA006 (capo direction and register) in English, French and Spanish. Each module has five corrected exercises, primary sources, fixed evidence and a prepared learner task. The author owns English/evidence/integration; scoped reviewers and translators own their named outputs. No production code, new runnable lab, dependency installation, full GA build, renderer or audio playback is required.

## Predictions recorded before execution

- The pinned English natural-note grammar contains A through G, not H. Source inspection alone does not execute PitchParser or establish a deployed service revision. A declared German B maps to English Bb while English B maps to B; an unspecified B is ambiguous between these two declared conventions.
- Loading unchanged MusicXmlTypes.fs and MusicXmlParser.fs in installed SDK 10.0.113 should parse authored E3 and E2 into MIDI 52 and 40. Two otherwise identical complete score inputs with and without transpose chromatic 0 / octave-change -1 should produce structurally equal parsed scores and both retain encoded E3. This would demonstrate lost transposition metadata in this pinned parser, not incorrect MusicXML semantics.
- Clef octave metadata should likewise be absent from the parsed Attributes record. A decimal alter 0.5 is expected to become None because the parser calls Int32.TryParse; keep this loss if observed, without claiming complete MusicXML support. A pitch step H should yield no pitch while the surrounding valid-duration note may still survive.
- Independent calculations should give sounding MIDI = written MIDI + chromatic + 12*octave-change for the limited ordinary non-doubled fixture. Explicit guitar written E3 plus -1 octave gives E2; applying the same offset twice gives E1 and fails. Concert-pitch E2 with no transposition already has the intended value.
- For pitch classes 0 through 11, capo 0 through 12 and major/minor qualities, 312 authored cases should preserve quality and recover the starting class after forward and inverse operations. Capo 12 preserves pitch class but raises absolute pitch by an octave. These are arithmetic checks, not a run of CapoSkill or an instrument trial.

## Source and teaching boundaries

Read the actual pinned public GA parser/types, natural/pitch parsers, CapoSkill and tab converter. Read LilyPond 2.24's language table and W3C MusicXML 4.0's pitch/transpose/chromatic/octave-change definitions. Do not copy LilyPond octave syntax into GA or infer encoding from the instrument name or clef alone. No automatic language adapter or application correction is delivered. Any live theory-tool probe is separately recorded with unknown runtime revision.

## Verification and publication

Independent data/source audit, translation parity, independent review of all 45 localized exercise/answer pairs and 15 learner criteria. Preserve failures and pending human/fluent/learner outcomes. Run existing 18 generator tests, source synchronization, Astro build, internal route/anchor readback and repeat-sync byte idempotence. Preserve source.json and all three journals. Stage and commit explicit owned paths, push normally to existing Draft PR201, then anonymously compare every changed file with its immutable Git bytes. Public deployed HTML and human approval remain separate gates for the full 525-course objective.
