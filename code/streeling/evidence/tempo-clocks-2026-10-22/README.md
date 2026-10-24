# Tempo maps, clock domains and user-boundary playback latency

This packet supports MCL007, NET008 and PM007 and corrects metadata-body reachability wording in MCL004 and MCL006. The deliverables are course text and fixed data. No MIDI parser patch, scheduler, synchronization service, telemetry DSL, runnable lab or actual playback experiment was delivered.

## Sources and calculations

- `production-plan.md` records the scope after initial source reading and hand-worked examples, before external numerical verification. It does not claim physical-experiment preregistration.
- `primary-readback.json` binds three public GA files at `76efbffd5af82b46c3146957a6bd4504008eeb89` and the earlier MCL004 parser at `dc2e74cbd992a298f67efb928b5b3754615e1924`. All four anonymous downloads match immutable local Git objects. Both parser revisions have identical bytes.
- `primary-reading.json` records actual Microsoft/Mido timing text, the MIDI.org public introduction, dated Web Audio/High Resolution Time working drafts and the HTML timers body. The complete SMF specification PDF, browser support and actual playback are not claimed verified.
- `tempo-map.json` retains exact rational PPQN integration, a spanning note and two streams with different timed tempo changes. Their hypothetical selected-body projection is deliberately identical. It is not actual GA parser output.
- `parser-boundaries.json` enumerates all 256 status bytes: after the high-nibble mask none can match the full meta-event arm label. It also separates unsigned SMPTE-header arithmetic from explicit signed-byte decoding in a limited non-drop example. These are static control-flow/arithmetic witnesses, not a fresh F# run or complete file-format conformance test.
- `clock-map.json` retains two authored anchors, affine predictions, rate/offset/unit distinctions, deterministic error bounds and a held-out contradiction. This rejects the combined model/bound assumptions in the example, without diagnosing hardware drift or measuring a deployed clock mapping.
- `playback-endpoints.json` contains eight invented sequential endpoint records, callback-request versus execution annotations and source-assisted physical-string-index requests. Median computation and user-boundary rankings differ; an authored latency-only rule approves no real release. The annotations are not captured browser or acoustic onsets.
- `source-observations.json` separates selected construction bodies from reachable dispatch, timed note fields from untimed metadata, and requested oscillator starts from measured output. No claim is made that this dashboard demonstrator is the canonical or only GA playback path.

## Corrections and review

The initial source exploration described metadata bodies without tracing the preceding mask. Host inspection caught that distinction before publication. MCL004/006 keep their useful numeric body examples but now state explicitly that they do not predict successful metadata parsing through the shown entry path. A dispatcher repair alone would still leave the separate modeled tempo-location loss. GA source was preserved unchanged.

`data-audit.json` and `content-audit.json` record independent AI checks and exact inspected-input hashes. The new tasks/rubric prepare fifteen learner criteria; no actual learner decision, human technical verdict, musician or fluent-language review is supplied. The amended courses retain their other exercises and history.

## Build and publication

Other receipts record fifteen source files, locale parity, existing generator tests, sync, a complete static build, changed article links/source banners and repeat-sync equality. `official-links.json` preserves direct transport results. One existing publisher URL returned403 to the direct Python request, while a separate web read exposed its actual primary abstract; the full paper remains unread. That fallback does not turn the direct403 into200 or establish access to the PDF.

Use explicit-path commit/push to Draft PR201 and anonymously byte-match every changed file at its exact immutable head. This verifies public source/evidence/generated files, not deployed course HTML or a successful playback/user trial. The original source reference and all three journals remain byte-identical; no dependency install, GPU work, paid service or wmux operation was required.
