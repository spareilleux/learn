# Fifty-course production journal — 2026-10-24

## Progress

- [ ] Freeze 50 distinct courses and full EN/FR/ES sources.
- [ ] Independently review all 750 answer pairs and 250 prepared criteria.
- [ ] Execute independent model/control checks, retain failures and replay.
- [ ] Review delivered test code and verify final bindings.
- [ ] Synchronize, build, inspect changed HTML and verify repeat-sync equality.
- [ ] Publish owned commits to Draft PR201 and anonymously read back exact bytes.

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

## To verify

## 2026-10-24 — Assembly failures, source corrections and detector refinement

The first actual manifest assembly failed on the C French path `streeling/courses/physics/fr/phy-016-bound-a-fold-hinge-sweep.md`: the generator reads `<stem>.<locale>.md` (actual source inspection at scripts/sync-streeling.mjs:298-299). All 32 C FR/ES files needed canonical suffixes. The coordinator then mistakenly ran the dependent source checker despite the failed assembly; its FileNotFoundError for the missing manifest is a dependency-order/helper failure, not a second course defect. Later dependent checks are gated on the preceding exit status. The C author corrected only its new paths, verified they were within the canonical checkout and absent from the baseline, and retained original freeze hashes and corrected replays.

After assembly passed, whole-source preflight caught A prerequisite URLs that differed by locale. The 36 FR/ES hrefs were aligned to the EN source URLs; labels and lesson content stayed translated, and the generator still localizes rendered routes. A second preflight caught 18 Spanish duration scalars translated to `55 minutos` instead of the canonical `55 minutes` metadata. A full 150-source collector confirmed these were the only remaining parity mismatches; `source-preflight-before-final-fixes.json` retains the actual 18 failures. The author corrected the scalars and expanded its helper to compare every non-title metadata field and every ordered href. Question/answer/model values did not change.

Final actual source preflight passed: 50 distinct courses, 150 locale files, 750 exercise/answer pairs and inventory 331/525 (194 core gaps). Locale counts are 332 each when the extra IX Research module is included. This is source/format verification, not an independent technical or learner verdict.

The initially reused metadata checker tested localized titles but would not detect the observed filename or shared-metadata defects. A prospective private probe copied the 150 final sources and deliberately reproduced 32 wrong C paths and 18 wrong A duration scalars. The old checker accepted all 150 cases, exit 0. It was strengthened to enforce the actual generator source path and equality of non-title metadata with the EN source. The identical private snapshot was then rejected: 100 passes, 50 failures, exit 1. Canonical data was unchanged by both probes. `test-runs/locale-contract-before-guard.json` and `locale-contract-after-guard.json` bind the same input snapshot and full raw outputs. This is evidence that the detector improved; the intentional failures are not failures of the final courses.

The strengthened checker on actual final sources passed all 150 cases (`test-runs/metadata-initial.json`). Independent test-code review is still pending at this entry; no review completion is inferred from green execution.

### Primary-access correction

Root independently received HTTP 402 from the Blender4.5 manual and Blender homepage. A guessed lowercase `readme.rst` at the official v4.5.0 GitHub tag returned 404. Actual root-directory API inspection identified `README.md`; the complete official raw README then returned 200, 1,233 bytes, SHA256 `2c2d0bf49d847dfed85d7a5d419d25bd1b008e05ca6485f66aa4afae7ac75b06`. It was actually read and retained outside the repo, then independently read by C. All 48 C first-mention Blender links use that versioned official README for tool identity only. No Blender API/rendering claim relies on it. Prior 402/404 failures remain in the author history; no successful manual read is claimed.

All new fixed-model and negative-control tests, content/code review, build/link/sync/publication checks and actual learner/human/runtime evidence are pending at this initial entry. Prepared learner decisions remain null. Later entries must preserve failed attempts and distinguish author calculations from independent tests and actual software/material/listening trials.

## Open questions

Actual learner responses, assistance records and authorized human reviews have not yet been supplied. No acceptance is inferred from course production.

## 2026-10-24 — locale-contract-before-guard: before detector probe

Question: can the localized-title checker accept valid translated titles while the generator's file/metadata contracts are violated? Inspection of scripts/sync-streeling.mjs:298-299 confirms the required .fr.md/.es.md lookup. A private copy deliberately removes suffixes from 32 Unit C translation paths and changes only the canonical duration scalar to its Spanish display string in 18 Unit A sources; all titles, questions, answers and model values remain unchanged. These reproduce two observed preflight defect classes without mutating canonical files. The current check is expected to wrongly accept all 150 cases. Dependency/root/plan imports are redirected only in the private checker. Canonical course, plan and test bytes stay untouched by this probe.

Observed: exit 0, 150 passes, 0 failures. Full output and exact source/private/input hashes: test-runs/locale-contract-before-guard.log and .json. Incorrect layout rejected: False.

## 2026-10-24 — locale-contract-after-guard: before detector probe

Question: can the localized-title checker accept valid translated titles while the generator's file/metadata contracts are violated? Inspection of scripts/sync-streeling.mjs:298-299 confirms the required .fr.md/.es.md lookup. A private copy deliberately removes suffixes from 32 Unit C translation paths and changes only the canonical duration scalar to its Spanish display string in 18 Unit A sources; all titles, questions, answers and model values remain unchanged. These reproduce two observed preflight defect classes without mutating canonical files. The current check is expected to reject all 50 bad cases while the other 100 pass. Dependency/root/plan imports are redirected only in the private checker. Canonical course, plan and test bytes stay untouched by this probe.

Observed: exit 1, 100 passes, 50 failures. Full output and exact source/private/input hashes: test-runs/locale-contract-after-guard.log and .json. Incorrect layout rejected: True.

## 2026-10-24 — metadata-initial: before metadata regression

UTC: 2026-10-24T15:35:41.060056+00:00. Expected contract: every localized page title equals the course metadata used in its generated description. The previous batch exposed this bug; the byte-identical reviewed checker now tests the new batch without assuming another defect. It does not test the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-24/tests/test_course_metadata.mjs`.

Observed: exit 0, 150 passed, 0 failed. Complete output: `test-runs/metadata-initial.log`; source/test hashes: `test-runs/metadata-initial.json`. This attempt is preserved even if a later correction passes.
