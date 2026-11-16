# Fifty-course production journal — 2026-10-24

## Progress

- [x] Freeze 50 distinct courses and full EN/FR/ES sources.
- [x] Independently review all 750 answer pairs and 250 prepared criteria.
- [x] Execute independent model/control checks, retain failures and replay.
- [x] Review delivered test code and verify final bindings.
- [x] Synchronize, build, inspect changed HTML and verify repeat-sync equality.
- [ ] Publish owned commits to Draft PR201 and anonymously read back exact bytes.

## QA

| Scope and expectation | Actual defect | Correction, measurement and retained evidence |
| --- | --- | --- |
| Generator source contract | 32 C translation filenames lacked locale suffixes; 18 A duration scalars differed from EN metadata. | Canonical paths/scalars corrected. Same private 50-wrong-input snapshot: old title test accepted it; strengthened test rejected all 50 wrong cases. See `test-runs/locale-contract-before-guard.json` and `locale-contract-after-guard.json`; canonical metadata now 150 passes. |
| Distinct curriculum operations | CS018 duplicate replay, CYB012 delay and FUT011 hysteresis overlapped prior lessons. | Explicit prior-art credit plus merge algebra, full delayed-gain interval and interval-valued reachable-state propagation. Old/new packet/source records retained in unit B/C review amendments; independent review accepted the bounded new operations. |
| True interpretation of FUT011 data | Two supplied widths were called midpoints; true midpoint trace has one switch rather than three. | Real premise probe failed, then corrected admissible-point claim passed without changing numeric inputs/results. `test-runs/fut011-midpoint-before-fix.json`, `fut011-point-label-after-fix.json`, `unit-c-point-label-correction.json`. This is a course-text defect, not a measured renderer failure. |
| AUD014 proof enforces aligned inputs | Ordinary zip dropped an unmatched sample; the malformed model still passed. | One diagnostic length observation now precedes rejection. Same private snapshot was accepted before and rejected after. `test-runs/alignment-before-fix.json`, `alignment-after-fix.json`; actual CE finding 1 and separate independent fix verification remain in `review-artifacts/`. |
| Local binding schema | Root iteration raised `KeyError: path` on 11 rendered-URL readings with null byte hashes. | Preserved original A review; moved those unchanged records to primary-source readings, without inventing raw-body hashes. Source/answer decisions unchanged; narrow changed test binding renewed after identical observations. See `review-a-binding-renewal.json`. |

## Experiments

| Question and advance expectation | Actual result | Verdict and scope |
| --- | --- | --- |
| Can the old metadata checker detect wrong paths/scalars? A private probe expected its blind spot before strengthening. | 150 accepted before, then 100 valid passes and 50 bad-input failures on the same snapshot; real sources 150 passes. | Detector improved; intentional wrong-input failures are not failing final courses. |
| Are supplied FUT011 values centres, as the draft asserted? | Samples 1 and 5 are not centres; exact decimal-rational midpoint replay has 1 switch versus 3 for supplied points. | Draft premise refuted. Admissible-point wording verified; no measured uncertainty or benefit follows. |
| Does the reviewed proof reject an unmatched audio sample? | Before accepted; after rejected, with one prior length diagnostic. Identical mutated-input SHA in both attempts. | Detector fixed; canonical packet unchanged. |
| Do all final authored model/control cases match separate fixed expectations? | 50 tests, 100 observations, complete coverage; no assertion failure. | Pass for finite examples, not engine, material, listening or learner trials. |

## 2026-10-24 — Baseline and production route

Catalogue/publication baseline: b7a402c162c15e77fd76e6c57360994308e33279, 281/525 core sources. Existing PR201 was actually read as OPEN/draft with that exact head. Canonical Learn checkout was clean, branch codex/streeling-craft-transfer-20261022, origin https://github.com/spareilleux/learn.git. Plan/allocation commit: 212ffe4351633588efbe46938cbceec80aded31e. No prior uncommitted Learn files belong to the batch. A read-only command accidentally inspected the default GA checkout's status; its unrelated dirty files were left untouched and excluded from this Learn work.

Three native author units have disjoint source prefixes: A18, B16, C16. Both checkout CE config files were absent; no external author worker was started. Galactic status and inbox returned Transport closed; remote session state was not established. All worker claims are backed by file evidence later rather than inferred from a running wrapper.

Existing generator tests were actually executed: 18 passed, zero failed. This entry records a retrospective regression check, not a scientific preregistration or new domain-model result. The complete command, actual Node version, seven immutable input hashes and full output are in test-runs/generator-initial.json and its .log. The metadata-title checker is reused byte-identically from the independently reviewed preceding batch; new-course tests will be independently written after author freeze.

### Novelty correction during topic selection

The craft author found that minimax regret was already taught in FUT004's retained scenario artifact. The proposed FUT011 repetition was rejected before authoring and replaced by representation switching with separate entry/exit hysteresis thresholds. This is source-driven topic refinement, not a measured renderer improvement. The author's self-check will retain the exact prior-art reading.

### Author progress and infrastructure history

Units B and C materialized 96 localized sources and then reported final author freeze. B reports 32 model/control recomputations and at least 927 English prose words excluding fenced blocks; C reports 32 recomputations and at least 697. These are author checks, not independent test verdicts. Their final source and packet hashes must be inspected and rebound by review before publication. Unit A completed all authored trilingual records externally before materializing its own sources; its tokenized-word check was clarified to use actual whitespace-separated source counts and substantive interpretation rather than punctuation counts or generic padding.

The C worker was interrupted by a workspace routing-discovery timeout. It recovered the same saved 16-course data helper, completed the assigned files and retained the timeout in its self-check. No task result or course failure is inferred from that infrastructure event. An early read of the shared author packet appeared truncated to B; a fresh read verified the complete 7,950-byte contract before authoring.

Coordinator setup also encountered a nonexistent guessed CS017 source filename during a read-only pattern lookup; no source-reading claim is made for that failed lookup. Actual course paths are taken from the catalogue/allocation and final author manifests. One attempted multi-file temporary-helper patch failed an expected-context check before mutation; a narrowed corrected patch succeeded. These are setup/helper diagnostics, not domain-model failures.

## 2026-10-24 — Assembly failures, source corrections and detector refinement

The first actual manifest assembly failed on the C French path `streeling/courses/physics/fr/phy-016-bound-a-fold-hinge-sweep.md`: the generator reads `<stem>.<locale>.md` (actual source inspection at scripts/sync-streeling.mjs:298-299). All 32 C FR/ES files needed canonical suffixes. The coordinator then mistakenly ran the dependent source checker despite the failed assembly; its FileNotFoundError for the missing manifest is a dependency-order/helper failure, not a second course defect. Later dependent checks are gated on the preceding exit status. The C author corrected only its new paths, verified they were within the canonical checkout and absent from the baseline, and retained original freeze hashes and corrected replays.

After assembly passed, whole-source preflight caught A prerequisite URLs that differed by locale. The 36 FR/ES hrefs were aligned to the EN source URLs; labels and lesson content stayed translated, and the generator still localizes rendered routes. A second preflight caught 18 Spanish duration scalars translated to `55 minutos` instead of the canonical `55 minutes` metadata. A full 150-source collector confirmed these were the only remaining parity mismatches; `source-preflight-before-final-fixes.json` retains the actual 18 failures. The author corrected the scalars and expanded its helper to compare every non-title metadata field and every ordered href. Question/answer/model values did not change.

Final actual source preflight passed: 50 distinct courses, 150 locale files, 750 exercise/answer pairs and inventory 331/525 (194 core gaps). Locale counts are 332 each when the extra IX Research module is included. This is source/format verification, not an independent technical or learner verdict.

The initially reused metadata checker tested localized titles but would not detect the observed filename or shared-metadata defects. A prospective private probe copied the 150 final sources and deliberately reproduced 32 wrong C paths and 18 wrong A duration scalars. The old checker accepted all 150 cases, exit 0. It was strengthened to enforce the actual generator source path and equality of non-title metadata with the EN source. The identical private snapshot was then rejected: 100 passes, 50 failures, exit 1. Canonical data was unchanged by both probes. `test-runs/locale-contract-before-guard.json` and `locale-contract-after-guard.json` bind the same input snapshot and full raw outputs. This is evidence that the detector improved; the intentional failures are not failures of the final courses.

The strengthened checker on actual final sources passed all 150 cases (`test-runs/metadata-initial.json`). Independent test-code review is still pending at this entry; no review completion is inferred from green execution.

### Primary-access correction

Root independently received HTTP 402 from the Blender4.5 manual and Blender homepage. A guessed lowercase `readme.rst` at the official v4.5.0 GitHub tag returned 404. Actual root-directory API inspection identified `README.md`; the complete official raw README then returned 200, 1,233 bytes, SHA256 `2c2d0bf49d847dfed85d7a5d419d25bd1b008e05ca6485f66aa4afae7ac75b06`. It was actually read and retained outside the repo, then independently read by C. All 48 C first-mention Blender links use that versioned official README for tool identity only. No Blender API/rendering claim relies on it. Prior 402/404 failures remain in the author history; no successful manual read is claimed.

All new fixed-model and negative-control tests, content/code review, build/link/sync/publication checks and actual learner/human/runtime evidence are pending at this initial entry. Prepared learner decisions remain null. Later entries must preserve failed attempts and distinguish author calculations from independent tests and actual software/material/listening trials.

## 2026-10-24 — locale-contract-before-guard: before detector probe

Question: can the localized-title checker accept valid translated titles while the generator's file/metadata contracts are violated? Inspection of scripts/sync-streeling.mjs:298-299 confirms the required .fr.md/.es.md lookup. A private copy deliberately removes suffixes from 32 Unit C translation paths and changes only the canonical duration scalar to its Spanish display string in 18 Unit A sources; all titles, questions, answers and model values remain unchanged. These reproduce two observed preflight defect classes without mutating canonical files. The current check is expected to wrongly accept all 150 cases. Dependency/root/plan imports are redirected only in the private checker. Canonical course, plan and test bytes stay untouched by this probe.

Observed: exit 0, 150 passes, 0 failures. Full output and exact source/private/input hashes: test-runs/locale-contract-before-guard.log and .json. Incorrect layout rejected: False.

## 2026-10-24 — locale-contract-after-guard: before detector probe

Question: can the localized-title checker accept valid translated titles while the generator's file/metadata contracts are violated? Inspection of scripts/sync-streeling.mjs:298-299 confirms the required .fr.md/.es.md lookup. A private copy deliberately removes suffixes from 32 Unit C translation paths and changes only the canonical duration scalar to its Spanish display string in 18 Unit A sources; all titles, questions, answers and model values remain unchanged. These reproduce two observed preflight defect classes without mutating canonical files. The current check is expected to reject all 50 bad cases while the other 100 pass. Dependency/root/plan imports are redirected only in the private checker. Canonical course, plan and test bytes stay untouched by this probe.

Observed: exit 1, 100 passes, 50 failures. Full output and exact source/private/input hashes: test-runs/locale-contract-after-guard.log and .json. Incorrect layout rejected: True.

## 2026-10-24 — metadata-initial: before metadata regression

UTC: 2026-10-24T15:35:41.060056+00:00. Expected contract: every localized page title equals the course metadata used in its generated description. The previous batch exposed this bug; the byte-identical reviewed checker now tests the new batch without assuming another defect. It does not test the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-24/tests/test_course_metadata.mjs`.

Observed: exit 0, 150 passed, 0 failed. Complete output: `test-runs/metadata-initial.log`; source/test hashes: `test-runs/metadata-initial.json`. This attempt is preserved even if a later correction passes.

## 2026-10-24 — Independent review and preliminary static integration

Author source freeze committed as `2a3e80b33dbfcea7ee35869c757674131922268f`. Three fresh independent reviewers own disjoint course prefixes, their own test and review receipt; root alone updates shared records and Git. Review includes actual prerequisites, answers, criteria and negative controls. Neither author completion nor source-format checks count as an independent pass.

Pre-review synchronization exited 0 with 332 modules per locale. The static build exited 0 with 2,266 pages; the built-HTML inspection found no unresolved internal links across 210 changed articles, 4,434 article links and 150 canonical source banners. All 35 final direct reference URLs returned HTTP200, which establishes transport only. Full preliminary sync/build outputs remain in `test-runs/sync-pre-review.log` and `build-pre-review.log`; final source corrections require a new integration run. Galactic status/inbox again returned `Transport closed`; no remote status or acknowledgement is inferred. A broad read-only temporary-file name lookup was interrupted after taking longer than expected, with no repository mutation.

Documentation correction: the inherited `metadata-initial` wrapper paragraph called its checker byte-identical to the prior reviewed checker and described title-only coverage. That paragraph was stale: the actual test hash and retained wrong-input probe prove the filename/metadata guards had already changed. The initial log/receipt are preserved; the wrapper now states the real source-path, shared-metadata and title contract. No old run is relabeled as a new test execution.

Review already identified wording to tighten in selective prediction: lowering a threshold weakly increases coverage on a fixed eligible set, while conditional risk can move either way. It also found that CYB008 already introduces a one-update delay, contradicting the author's proposed CYB012 novelty statement. Unit B is correcting the lesson to derive the full delayed scalar stability interval and explicitly credit the prior recurrence; this finding is open until the final source, packet and test are reviewed and rebound. C is checking a minor French rendering term. These are actual content-review findings, not invented failing runtime observations.

## 2026-10-24 — metadata-after-review: before metadata regression

UTC: 2026-10-24T16:16:01.006645+00:00. Expected contract: all 150 localized sources have valid translated titles, canonical generator filenames and non-title metadata matching EN. The inherited title checker was strengthened after the retained wrong-input probe exposed its filename/metadata blind spots. This run checks those final source contracts; it does not test the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-24/tests/test_course_metadata.mjs`.

Observed: exit 0, 150 passed, 0 failed. Complete output: `test-runs/metadata-after-review.log`; source/test hashes: `test-runs/metadata-after-review.json`. This attempt is preserved even if a later correction passes.

## 2026-10-25 — resumed-20261025-all: before execution

Recorded UTC: 2026-10-25T14:33:27.935817+00:00. Claim: the declared authored model and negative-control checks for the 50 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-24/tests -p test_unit_*.py -v`. Input/test hashes will be retained in `test-runs/resumed-20261025-all.json`.

### resumed-20261025-all: observed result

Exit 0; 50 tests; 100 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/resumed-20261025-all.log`; exact tested source/data/test hashes and observations: `test-runs/resumed-20261025-all.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-25 — final-metadata-20261025: before metadata regression

UTC: 2026-10-25T14:40:23.134291+00:00. Expected contract: all 150 localized sources have valid translated titles, canonical generator filenames and non-title metadata matching EN. The inherited title checker was strengthened after the retained wrong-input probe exposed its filename/metadata blind spots. This run checks those final source contracts; it does not test the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-24/tests/test_course_metadata.mjs`.

Observed: exit 0, 150 passed, 0 failed. Complete output: `test-runs/final-metadata-20261025.log`; source/test hashes: `test-runs/final-metadata-20261025.json`. This attempt is preserved even if a later correction passes.

## 2026-10-25 — final-claims-20261025: before execution

Recorded UTC: 2026-10-25T14:40:45.996297+00:00. Claim: the declared authored model and negative-control checks for the 50 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-24/tests -p test_unit_*.py -v`. Input/test hashes will be retained in `test-runs/final-claims-20261025.json`.

### final-claims-20261025: observed result

Exit 0; 50 tests; 100 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/final-claims-20261025.log`; exact tested source/data/test hashes and observations: `test-runs/final-claims-20261025.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-25 — claims-after-review-fix-20261025: before execution

Recorded UTC: 2026-10-25T14:55:03.975772+00:00. Claim: the declared authored model and negative-control checks for the 50 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-24/tests -p test_unit_*.py -v`. Input/test hashes will be retained in `test-runs/claims-after-review-fix-20261025.json`.

### claims-after-review-fix-20261025: observed result

Exit 0; 50 tests; 100 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/claims-after-review-fix-20261025.log`; exact tested source/data/test hashes and observations: `test-runs/claims-after-review-fix-20261025.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-25 — Completed independent review, detector correction and final integration

The resumed session observed no live handles for the interrupted prior batch reviewers. It preserved all existing source/test/evidence edits and dispatched fresh read-only B/C reviewers to finish actual content inspection. They produced final receipts rather than inheriting a running status. A's completed original content review remained valid; only its receipt schema and the narrow final test binding needed root maintenance. Galactic status and inbox again returned `Transport closed`; no remote session state, claim acknowledgement or wmux activity is inferred. Current CE3.32.1 native route remained selected; checkout config files were absent.

All 50 courses, 150 localized sources, 750 exercise/answer pairs and 250 prepared criteria were independently inspected. Final source/prerequisite/local-support bindings pass. Eleven A rendered reference readings are recorded without fabricated byte hashes. Original A review bytes remain under `test-runs/independent-a/review-a-original.json`; its course/answer/criterion/calculation decisions are unchanged. Earlier B/C focused/mutation attempts remain under `test-runs/previous-b/` and `previous-c/`, explicitly historical rather than relabeled final interval evidence. Current independent outputs and receipts are under `test-runs/independent-a/`, `independent-b/`, `independent-c/`.

The actually completed CE focused code review (`20261025-103528-74e0378c`) returned Ready with fixes and one reproduced P2. A native adversarial context completed separately; the bundled cross-model worker could not preserve this four-file scope or include the three untracked test files, so no external peer review is claimed. The raw original review is unchanged in `review-artifacts/review.json`. Root applied only finding 1: AUD014 prints invalid array lengths and asserts alignment before zip. An independent follow-up verified that small delta and the same wrong-input probe; `finding-resolution.json` closes the finding, and `test-code-review-summary.json` binds all four final proof tests with no open finding. No fresh full review is claimed after that correction.

Final authoritative replay: `test-runs/claims-after-review-fix-20261025.json`, 50 tests and 100 observations, exit 0. All 100 observations are identical to the pre-guard canonical run; the new check changes only malformed aligned-array rejection. Final metadata: `test-runs/final-metadata-20261025.json`, 150 passes, zero failures. The last claim replay intentionally updates only this detailed batch journal, leaving already-built global entries linked to the earlier actual runs they describe. This avoids silently changing evidence or rewriting historical entries. `final-claim-runs.json` selects the final attempts; all earlier actual failed checks and deliberate mutant outputs remain retained. Inherited date headings for the resumed runs were corrected to the actual October 25 client/run date; their raw receipts always carried actual UTC timestamps. The fragment correction record preserves before/after labels.

Generator regression: 18 passes. Actual full static build: 2266 pages, exit 0, 137.591 seconds including the wrapper. Original full output and warnings are retained byte-for-byte in `test-runs/static-build.log`. The built-HTML check inspected 210 changed articles, 4485 links and 150 source banners: zero unresolved internal links; deliberately missing page/anchor controls detected. Repeat sync was byte-identical across 1,070 generated Markdown/lock/sidebar/preserved-journal files. All 35 final reference URLs returned HTTP200; actual reading scope belongs to author/reviewer records and is not inferred from transport. No dependency install, service launch, new engine/scene/material/listening/learner trial or interactive browser validation occurred. No package lint/typecheck command is configured; the generator regressions and Astro build are the local integration gates.

Source inventory: 331/525 core English modules, 194 remaining; 332 per locale including the extra IX Research module. `streeling/source.json` is unchanged. Stripping this batch's additive-fragment ledger recovers the exact pre-batch bytes and checklist decisions of all three global journals. `validation.json` checks all final review/test/log bindings and distinguishes the original completed code review from its independently verified correction.

The publication step must compare the remote Draft PR201 head before normal push and anonymously read back every owned path at the final immutable commit. That receipt is written outside this commit to avoid self-reference; no deployed HTML, merge, human, fluent-language or learner acceptance is inferred. The local journal snapshot therefore keeps the publication checkbox open rather than claiming an event before it happens.

### Final calculated cases (previews)

Full untruncated values, expected results, environment, inputs and raw output remain in `test-runs/claims-after-review-fix-20261025.json` and its log. Previews below are intentionally shortened; all rows come from actual final observations, not inferred Cartesian passes.

| Course | Model observation preview | Negative-control observation preview |
| --- | --- | --- |
| AUD013 | `{"duration_s":1.0,"output_frames":48000.0,"relabeled_duration_s":0.91875,"relabeled_tone_hz":1088.4353741496598}` | `{"duration_s":1.0,"output_frames":44100.0,"relabeled_duration_s":1.0,"relabeled_tone_hz":1000.0}` |
| AUD014 | `{"raw":[1.6,-1.6,0.8],"mixed":[0.8,-0.8,0.4],"peak":0.8,"clipped_raw":[1,-1,0.8]}` | `{"raw":[0.0,0.0,0.0],"mixed":[0.0,0.0,0.0],"peak":0.0,"clipped_raw":[0.0,0.0,0.0]}` |
| AUD015 | `{"integers":[0,0,16384,-16383],"decoded":[0.0,0.0,0.500015259254738,-0.499984740745262],"errors":[0.0,-1e-05,1.5259254737998162e-05,1.5259254737998162e-05],"...` | `{"integer_before_int16_write":36044,"int16_representable":false}` |
| COG012 | `{"accuracy":0.7,"alert_rate":0.6,"false_alarm_rate":0.4,"hit_rate":0.8,"separation":0.4}` | `{"accuracy":0.5,"alert_rate":1,"false_alarm_rate":1,"hit_rate":1,"separation":0}` |
| COG013 | `{"assisted_miss_rate":0.75,"assisted_only_misses":["b","c"],"manual_miss_rate":0.25,"manual_only_misses":[],"paired_excess":0.5}` | `{"assisted_miss_rate":0.25,"assisted_only_misses":[],"manual_miss_rate":0.25,"manual_only_misses":[],"paired_excess":0}` |
| COG014 | `{"accepted":3,"accepted_indices":[0,1,2],"coverage":0.6,"errors":1,"risk":0.3333333333333333}` | `{"accepted":0,"accepted_indices":[],"coverage":0,"errors":0,"risk":null}` |
| CS018 | `{"conflict":false,"sum":8,"unique_count":2}` | `{"conflict":true,"sum":null,"unique_count":2}` |
| CS019 | `{"captured_result":8,"lexical_result":14,"renamed_result":14}` | `{"captured_result":8,"lexical_result":8,"renamed_result":8}` |
| CS020 | `{"distinct_artifacts":2,"joined_rows":5,"rows_per_artifact":{"a":4,"b":1}}` | `{"distinct_artifacts":2,"joined_rows":3,"rows_per_artifact":{"a":2,"b":1}}` |
| CYB012 | `{"asymptotically_stable":true,"root_modulus":0.7071067811865476,"trace_from_k0":[1,0.5,0,-0.25,-0.25,-0.125,0]}` | `{"asymptotically_stable":false,"root_modulus":0.9999999999999999,"trace_from_k0":[1,0,-1,-1,0,1,1]}` |
| CYB013 | `{"age_seconds":4,"interval":[2,6],"radius":2,"safe_certified":false}` | `{"age_seconds":1,"interval":[3.5,4.5],"radius":0.5,"safe_certified":true}` |
| CYB014 | `{"action_count":1,"final_error":-0.4,"trace":[0.6,-0.4,-0.4,-0.4,-0.4]}` | `{"action_count":4,"final_error":0.6,"trace":[0.6,-0.4,0.6,-0.4,0.6]}` |
| DV014 | `{"contact_count":1,"mean_absolute_mm":0.35000000000000003,"minimum_mm":-0.4,"overlap_count":1}` | `{"contact_count":1,"mean_absolute_mm":0.35000000000000003,"minimum_mm":0,"overlap_count":0}` |
| DV015 | `{"absent":2,"missing":1,"observed":5,"observed_absence_fraction":0.4,"present":3}` | `{"absent":3,"missing":0,"observed":6,"observed_absence_fraction":0.5,"present":3}` |
| DV016 | `{"delta_px":[2,-5,2],"mean_delta_px":-0.3333333333333333,"worsened_views":["front","back"],"worst_after_px":4,"worst_before_px":8}` | `{"delta_px":[1,-4,2],"mean_delta_px":-0.3333333333333333,"worsened_views":["front","back"],"worst_after_px":4,"worst_before_px":8}` |
| FUT010 | `{"base_crossings":24,"base_strands":10,"crossing_ratio":4,"future_crossings":96,"future_strands":20,"strand_ratio":2.0}` | `{"base_crossings":24,"base_strands":10,"crossing_ratio":2,"future_crossings":48,"future_strands":16,"strand_ratio":1.6}` |
| FUT011 | `{"ambiguous_samples":[1,2,3,4,5,6],"mesh_states":[true,true,true,true,false,false,true],"possible_mesh_states":[[false,true],[false,true],[false,true],[false...` | `{"ambiguous_samples":[2],"mesh_states":[true,false,true,false,false,false,true],"possible_mesh_states":[[true],[false,true],[true],[false],[false],[false],[t...` |
| GAA011 | `{"total":10,"correct":7,"accuracy":0.7,"recall":[0.75,0.6666666666666666],"majority_baseline":0.6}` | `{"total":10,"correct":3,"accuracy":0.3,"recall":[0.25,0.3333333333333333],"majority_baseline":0.6}` |
| GAA012 | `{"total_trials":8,"cell_counts":[2,2,2,2],"covered_cells":4,"balanced_complete":true}` | `{"total_trials":8,"cell_counts":[4,0,0,4],"covered_cells":2,"balanced_complete":false}` |
| GAA013 | `{"distinct_pitch_class_sets":1,"distinct_voicings":3,"distinct_bass_classes":2,"pitch_class_keys":[[0,4,7]]}` | `{"distinct_pitch_class_sets":2,"distinct_voicings":3,"distinct_bass_classes":2,"pitch_class_keys":[[0,4,7],[0,4,5,7]]}` |
| GAS012 | `{"omega_rad_per_s":[10.0,20.0],"frequencies_hz":[1.5915494309189535,3.183098861837907]}` | `{"omega_rad_per_s":[10.0,10.0],"frequencies_hz":[1.5915494309189535,1.5915494309189535]}` |
| GAS013 | `{"initial_frequency_hz":100.0,"target_tension_n":180.0,"tension_ratio":2.25}` | `{"initial_frequency_hz":150.0,"target_tension_n":80.0,"tension_ratio":1.0}` |
| GAS014 | `{"delay_s":0.001,"first_opposition_hz":500.0,"spacing_hz":1000.0,"magnitude_at_opposition":0}` | `{"delay_s":0.001,"first_opposition_hz":500.0,"spacing_hz":1000.0,"magnitude_at_opposition":0.5}` |
| GTR012 | `{"surviving_modes":[3,6],"frequencies_hz":[330,660],"lowest_surviving_hz":330}` | `{"surviving_modes":[2,4,6],"frequencies_hz":[220,440,660],"lowest_surviving_hz":220}` |
| GTR013 | `{"target_cents":200,"target_frequency_hz":123.47082531403103,"signed_error_cents":-5,"worst_abs_error_cents":8,"established_within_tolerance":true}` | `{"target_cents":200,"target_frequency_hz":123.47082531403103,"signed_error_cents":-9,"worst_abs_error_cents":12,"established_within_tolerance":false}` |
| GTR014 | `{"pitches":[64,67,64,69],"note_events":4,"pick_attacks":2,"legato_changes":2}` | `{"pitches":[64,67,64,69],"note_events":4,"pick_attacks":3,"legato_changes":1}` |
| INF013 | `{"expected_posterior_bits":1.0,"information_gain_bits":1.0,"outcome_probabilities":{"left":0.5,"right":0.5},"prior_bits":2.0}` | `{"expected_posterior_bits":2.0,"information_gain_bits":0.0,"outcome_probabilities":{"same":1},"prior_bits":2.0}` |
| INF014 | `{"intended":["fail","pass","pass"],"mismatches":3,"received":["pass","fail","fail"]}` | `{"intended":["fail","pass","pass"],"mismatches":0,"received":["fail","pass","pass"]}` |
| INF015 | `{"adjusted_failures":2,"adjusted_total":10,"raw_rate":0.3333333333333333,"weighted_ratio":0.2,"weights":[2,4,4]}` | `{"adjusted_failures":1,"adjusted_total":3,"raw_rate":0.3333333333333333,"weighted_ratio":0.3333333333333333,"weights":[1,1,1]}` |
| MCL012 | `{"sounding_events":[{"pitch":60,"onset_beats":0,"duration_beats":2},{"pitch":62,"onset_beats":2,"duration_beats":1}],"attacks":2,"total_span_beats":3}` | `{"sounding_events":[{"pitch":60,"onset_beats":0,"duration_beats":1},{"pitch":60,"onset_beats":1,"duration_beats":1},{"pitch":62,"onset_beats":2,"duration_bea...` |
| MCL013 | `{"per_note_ticks":160.0,"total_ticks":480.0,"total_quarters":1.0}` | `{"per_note_ticks":360.0,"total_ticks":1080.0,"total_quarters":2.25}` |
| MCL014 | `{"grace_each_s":0.05,"main_start_s":1.1,"main_duration_s":0.4,"next_boundary_s":1.5}` | `{"grace_each_s":0.05,"main_start_s":1.1,"main_duration_s":0.5,"next_boundary_s":1.6}` |
| NET012 | `{"conditional_branch_union":0.98,"marginal_a":0.76,"marginal_b":0.855,"naive_independent":0.9652,"success":0.931}` | `{"conditional_branch_union":0.98,"marginal_a":0.4,"marginal_b":0.45,"naive_independent":0.67,"success":0.49}` |
| NET013 | `{"a_before_b":false,"a_before_receive":true,"b_before_a":false,"concurrent":true,"receive_clock":[2,4]}` | `{"a_before_b":true,"a_before_receive":true,"b_before_a":false,"concurrent":false,"receive_clock":[3,2]}` |
| PHI010 | `{"indistinguishable":true,"observation_a":[0,0],"observation_b":[0,0],"requirement_a":true,"requirement_b":false}` | `{"indistinguishable":false,"observation_a":[0,0],"observation_b":[1,0],"requirement_a":true,"requirement_b":false}` |
| PHI011 | `{"average_mesh":-2.0,"diagonal":2,"interaction":0,"mesh_flat":-2,"mesh_lit":-2}` | `{"average_mesh":0.0,"diagonal":6,"interaction":4,"mesh_flat":-2,"mesh_lit":2}` |
| PHY016 | `{"endpoint_mm":[50.000000000000014,86.60254037844386],"radial_margin_mm":10,"swept_displacement_mm":99.99999999999999}` | `{"endpoint_mm":[100.0,0.0],"radial_margin_mm":10,"swept_displacement_mm":0.0}` |
| PHY017 | `{"growth_mm":0.2,"remaining_gap_mm":0.09999999999999998}` | `{"growth_mm":0.4,"remaining_gap_mm":-0.10000000000000003}` |
| PHY018 | `{"inside_support":true,"margin_m":0.020000000000000004,"x_cm_m":0.09999999999999999}` | `{"inside_support":false,"margin_m":-0.07999999999999999,"x_cm_m":0.19999999999999998}` |
| PM010 | `{"pooled_rate":0.175,"standardized_rate":0.13,"stratum_rates":[0.1,0.4]}` | `{"pooled_rate":0.13,"standardized_rate":0.13,"stratum_rates":[0.1,0.4]}` |
| PM011 | `{"automated_minutes_per_item":10,"automated_total_minutes":460,"equal_cost_items":30,"manual_total_minutes":480,"minimum_integer_items_for_strict_saving":31,...` | `{"automated_minutes_per_item":12,"automated_total_minutes":540,"equal_cost_items":null,"manual_total_minutes":480,"minimum_integer_items_for_strict_saving":n...` |
| SEM012 | `{"commute":false,"rotate_after_translate_mm":[0.0,2.0],"translate_after_rotate_mm":[1.0,1.0]}` | `{"commute":true,"rotate_after_translate_mm":[0.0,1.0],"translate_after_rotate_mm":[0.0,1.0]}` |
| SEM013 | `{"compatible":true,"joint_period_cells":6,"phase_remainders":[0,0]}` | `{"compatible":false,"joint_period_cells":6,"phase_remainders":[1,0]}` |
| SEM014 | `{"AB":{"metallic":1,"roughness":0.6},"BA":{"metallic":1,"roughness":0.3},"commute":false}` | `{"AB":{"metallic":1,"roughness":0.3},"BA":{"metallic":1,"roughness":0.3},"commute":true}` |
| VC014 | `{"focal_px":500.00000000000006,"meets_declared_threshold":false,"width_px":1.0000000000000002}` | `{"focal_px":500.00000000000006,"meets_declared_threshold":true,"width_px":2.0000000000000004}` |
| VC015 | `{"acceptable":false,"perimeter_mm":621.1657082460498,"sagitta_mm":3.407417371093169}` | `{"acceptable":true,"perimeter_mm":626.5257226562476,"sagitta_mm":0.8555138626189618}` |
| VC016 | `{"effective_gutter_px":2.0,"meets_declared_margin":true}` | `{"effective_gutter_px":1.0,"meets_declared_margin":false}` |
| WML011 | `{"pitch_classes":[0,4,7,10],"third_offset":4,"seventh_offset":10}` | `{"pitch_classes":[0,4,7,11],"third_offset":4,"seventh_offset":11}` |
| WML012 | `{"step_allowed":[true,true,false,true],"accepted":false,"union":[0,2,3,4,7,9]}` | `{"step_allowed":[true,true,true,true],"accepted":true,"union":[0,2,3,4,7,9]}` |
| WML013 | `{"residual_ratio":1.0136432647705078,"residual_cents":23.460010384649014,"closes_exactly":false}` | `{"residual_ratio":1.0000000000000002,"residual_cents":3.8441118045779003e-13,"closes_exactly":true}` |

## To verify

Local production, independent AI review, model/control replay, metadata, build, static links and repeat synchronization are complete in this snapshot. Exact GitHub source/evidence publication and anonymous readback are the next action; the resulting immutable-commit receipt stays outside this commit. The original 525-course objective remains incomplete.

## Open questions

Human technical and fluent-language review, actual learner responses and assistance records, listening/material trials and native engine/scene execution remain undecided or not run. Prepared learner decisions stay null. The user will designate a reviewer; no repeated request is made here.
