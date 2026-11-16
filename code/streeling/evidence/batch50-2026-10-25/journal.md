# Fifty-course production journal — 2026-10-25

## Progress

- [x] Freeze 50 distinct courses and full EN/FR/ES sources.
- [x] Independently review all 750 answer pairs and 250 prepared criteria.
- [x] Execute independent model/control checks, retain failures and replay.
- [x] Review delivered test code and verify final bindings.
- [x] Synchronize, build, inspect changed HTML and verify repeat-sync equality.
- [ ] Publish owned commits to Draft PR201 and anonymously read back exact bytes.

## QA

| Expectation | Actual observation | Correction and retained evidence |
| --- | --- | --- |
| Source-byte contract | All 54 author A Markdown sources used CRLF. | Raw gate rejected them, root normalized only line endings and replay passed. `test-runs/source-contract-initial.json`, `source-contract-after-lf.json`, `unit-a-byte-normalization.json` and `source-freeze-boundaries.json` preserve exact scope and reversible old bytes. |
| Independent review findings | Per-unit content, reference, wording and proof-output findings are retained individually. | See `review-a.json`, `review-b.json`, `review-c.json` and their exact original/mutation/focused logs under `test-runs/independent-*/`. Author-stage checks are historical, not relabeled final review evidence. |
| Operation vocabulary in proof tests | Unknown tokens silently passed as forward/subtract in two course models. | The expected-rejection probe first failed twice, then passed both cases after explicit enum checks and prior diagnostics. All 100 normal observations are unchanged; original review and independently verified finding1 resolution remain in `review-artifacts/`. |

## Experiments

| Question and expected result | Actual result | Verdict and limits |
| --- | --- | --- |
| Do the actual source bytes meet the declared LF contract? | Initial integrated source gate failed on A; newline-only replay passed all 150 sources. | Detector found a format issue that a normalized text check missed. No audio result follows. |
| Do independently implemented fixed model/control calculations agree? | 50 actual tests, 100 observed cases, complete coverage. | Pass for finite authored cases; no engine/scene/material/listening or learner trial. |
| Can tampering with both inputs and packet expectations produce a false pass? | Every unit retains an actual substantive mutant rejection against its separate fixed oracle. | Detector checks, not failing canonical courses. Full observed values and failed assertions remain in each mutation log. |

## 2026-10-25 — Production baseline and advance verification contract

Catalogue/publication baseline: bb292f5656852e3a6e9e9f67c95ce320a4551b5f, 331/525 core sources; 194 source gaps. Actual PR201 was OPEN/draft with that head. The canonical Learn checkout was clean, branch codex/streeling-craft-transfer-20261022, origin https://github.com/spareilleux/learn.git. Plan/allocation commit f93c0356d23c3700ad1ead501eef46802dca2a31. CE checkout configuration files were absent. Galactic status/inbox returned Transport closed; no remote status, claim or acknowledgement is inferred.

Three fresh native authors own disjoint source prefixes, A18/B16/C16. They inspect actual prerequisites and prior art; they do not run the later independent domain checks. The already strengthened metadata test and review protocol are copied byte-identically from the preceding verified batch. Existing generator regression: 18 actual passes, zero failures; command, Node version, exact seven input hashes and full output are retained in test-runs/generator-initial.json/.log. That is retrospective baseline evidence, not domain or learner validation.

Expected final result: 50 distinct new EN sources plus 100 full FR/ES translations, 381/525 core sources and 144 gaps. Independent reviewers will inspect 750 localized exercise/answer pairs and 250 prepared criteria and write separate fixed-oracle model/control checks. Every course needs two actual observations, meaningful negative controls, failures retained, diagnosis/correction/replay and final-byte bindings. No engine, scene, listening, material, learner or human acceptance is inferred from model tests. User will designate a reviewer; decisions remain null.

An initial attempt to create the temporary preparation helper using nested shell quoting failed at PowerShell parsing and Python then found no generated file. No repository changes occurred. A literal apply_patch helper replaced that shell composition, executed successfully and committed the plan. This orchestration failure is not a course defect or failed domain case.

## 2026-10-25 — Prior-art and cross-unit novelty corrections during authoring

These are actual author/coordination observations, before independent validation. Unit A rejected partial-capo coverage after reading GTR008. Unit B rejected introductory EWMA after reading CYB010 and instead proposed finite initialized-weight covariance with correlated inputs. Those replacements still require independent review of their exact derivations and novelty.

Root compared the current B/C topic reports and caught two proposed Kaplan–Meier courses: PM013 time to first task use and FUT013 compatibility survival. A changed application does not by itself establish a new operation. C dropped survival and proposed a fixed-work Amdahl bound, with serial inspection as a limiting floor; B confirmed it was not teaching that operation. C must still compare the committed prior art. Future scenario numbers are authored examples, not throughput observations or promises of exponential improvement.

The workflow lesson is to compare operations across departments and concurrent author units, then inspect the actual prerequisite passages. Titles and counts alone are weak evidence. The bounded production/review waves keep unreviewed work attributable; neither a running worker nor a draft packet counts as accepted learning content. Root has not executed domain proof tests at this authoring stage.

Another temporary-helper attempt used nested PowerShell/Python quoting while preparing the future specification verifier; PowerShell rejected it before file creation. A literal apply_patch script replaced it and compiled the adapted verifier. This is a coordinator preparation failure, not a domain-test observation; no canonical course or specification was changed by that failed attempt.

## 2026-10-25 — author-assembly: before mechanical preflight

UTC 2026-10-25T16:10:51.294477+00:00. Expected: the frozen 50-course/150-source allocation and declared structural scope pass. Command `['C:\\Users\\spare\\AppData\\Local\\Programs\\Python\\Python314\\python.exe', '-X', 'utf8', '-B', 'C:/tmp/streeling-batch50-assemble-plan-20261025-next.py']`. This is a format/provenance inventory check, not a domain calculation or learner trial.

Observed: exit 0. Full output `code/streeling/evidence/batch50-2026-10-25/test-runs/author-assembly.log` and its receipt retained; investigate any nonzero result before freeze.

## 2026-10-25 — packet-scope-initial: before mechanical preflight

UTC 2026-10-25T16:10:51.390152+00:00. Expected: the frozen 50-course/150-source allocation and declared structural scope pass. Command `['C:\\Users\\spare\\AppData\\Local\\Programs\\Python\\Python314\\python.exe', '-X', 'utf8', '-B', 'C:/tmp/streeling-audit-packets-next.py']`. This is a format/provenance inventory check, not a domain calculation or learner trial.

Observed: exit 0. Full output `code/streeling/evidence/batch50-2026-10-25/test-runs/packet-scope-initial.log` and its receipt retained; investigate any nonzero result before freeze.

## 2026-10-25 — source-contract-initial: before mechanical preflight

UTC 2026-10-25T16:10:51.545620+00:00. Expected: the frozen 50-course/150-source allocation and declared structural scope pass. Command `['C:\\Users\\spare\\AppData\\Local\\Programs\\Python\\Python314\\python.exe', '-X', 'utf8', '-B', 'C:/tmp/streeling-batch50-check-20261025-next.py']`. This is a format/provenance inventory check, not a domain calculation or learner trial.

Observed: exit 1. Full output `code/streeling/evidence/batch50-2026-10-25/test-runs/source-contract-initial.log` and its receipt retained; investigate any nonzero result before freeze.

## 2026-10-25 — Raw-byte source gate rejected author A line endings

Actual source-contract-initial failed before checking content: all 54 A Markdown files contained CRLF; B/C had none. The author's structural/text self-check was not a raw-byte LF proof. Root changed only these owned new sources from CRLF to LF; words, numbers and code are unchanged. unit-a-byte-normalization.json records before/after hashes and a verified reversible reconstruction of every original source. The original author self-check and initial failed output are preserved. Independent reviewers must bind the corrected bytes, and the source contract is replayed below.

Observed replay: exit 0; full output test-runs/source-contract-after-lf.log and exact-byte receipt retained.

## 2026-10-25 — metadata-initial: before metadata regression

UTC: 2026-10-25T16:12:35.243291+00:00. Expected contract: all 150 localized sources have valid translated titles, canonical generator filenames and non-title metadata matching EN. The already strengthened checker is reused from the preceding reviewed batch. This run checks those final source contracts; it does not test the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-25/tests/test_course_metadata.mjs`.

Observed: exit 0, 150 passed, 0 failed. Complete output: `test-runs/metadata-initial.log`; source/test hashes: `test-runs/metadata-initial.json`. This attempt is preserved even if a later correction passes.

## 2026-10-25 — integrated-final: before execution

Recorded UTC: 2026-10-25T16:34:26.265792+00:00. Claim: the declared authored model and negative-control checks for the 50 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-25/tests -p test_unit_*.py -v`. Input/test hashes will be retained in `test-runs/integrated-final.json`.

### integrated-final: observed result

Exit 0; 50 tests; 100 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/integrated-final.log`; exact tested source/data/test hashes and observations: `test-runs/integrated-final.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-25 — metadata-final: before metadata regression

UTC: 2026-10-25T16:34:31.406339+00:00. Expected contract: all 150 localized sources have valid translated titles, canonical generator filenames and non-title metadata matching EN. The already strengthened checker is reused from the preceding reviewed batch. This run checks those final source contracts; it does not test the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-25/tests/test_course_metadata.mjs`.

Observed: exit 0, 150 passed, 0 failed. Complete output: `test-runs/metadata-final.log`; source/test hashes: `test-runs/metadata-final.json`. This attempt is preserved even if a later correction passes.

## 2026-10-25 — Coordinator journal-placement correction

The initial helper assumed an existing final To verify heading in each university journal. The actual baseline journals had no such closing section, so the helper rejected the missing heading before changing any journal bytes. The repeated failed invocation and exact script/log hashes are retained in test-runs/journal-placement-before-fix.json/.log. Root inspected the real headings, prepared all three results before writing, added localized closing sections where absent, and verified that removing this batch fragments recovers the exact committed old bytes. Replay exited0 (journal-placement-after-fix.json/.log); the full source/journal-history gate also passed. This is a coordinator helper defect, not a course-domain or runtime failure.

## 2026-10-25 — Narrow novelty comparison after Unit C review

Root checked MAT006 sections1–2 against VC019 after its independent reviewer explicitly identified the shared SVD geometry, stretch ratio and determinant. The strongest overlap is real: diagonal ellipse radii and area products are not new mathematics. VC019 is retained as the applied UV diagnostic task that distinguishes within-island motif distortion from the committed atlas-gutter task, with a mesh-source inspection and missing derivative evidence; it does not claim a new SVD operation or implementation. The independent review records that prior art and the finite scope. Human usefulness/learner transfer remains unestablished. A requested narrow reviewer follow-up did not launch because the four active-agent slots were occupied by the simplification wave; no additional review result is claimed. Root resolved the comparison by the actual relevant passages, without modifying source or tests.

## 2026-10-25 — integrated-after-operation-fix: before execution

Recorded UTC: 2026-10-25T16:58:29.701352+00:00. Claim: the declared authored model and negative-control checks for the 50 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-25/tests -p test_unit_*.py -v`. Input/test hashes will be retained in `test-runs/integrated-after-operation-fix.json`.

### integrated-after-operation-fix: observed result

Exit 0; 50 tests; 100 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/integrated-after-operation-fix.log`; exact tested source/data/test hashes and observations: `test-runs/integrated-after-operation-fix.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-25 — Actual code-review finding1, failed detector probe and verified fix

The completed focused ce-code-review returned Ready with fixes and one P2: MCL016 treated unknown operations as forward, and WML016 treated them as subtraction. Root reproduced both silent acceptances: the exact invalid_operation probes failed their expected-rejection tests (two failures, exit1), while the old fixed and packet expectations still passed. Full raw output and helper/input hashes remain in test-runs/operations-before-fix.json/.log. This is an actual proof-detector defect, not a new runtime or learner result.

Root added only declared vocabulary checks with one diagnostic observation before rejection, plus an explicit subtract branch. The exact same probe helper then passed both expected rejections, exit0, with original packet bytes unchanged. integrated-after-operation-fix executed50 tests/100 observations; every normal observation is identical to integrated-final. The final replay updates this detailed journal only: global entries keep their actual earlier run links and already-built bytes. final-claim-runs.json selects the new replay.

The same independent code reviewer verified only this delta and both probes, closed finding1 and bound all four final tests. This is independent fix verification, not a fresh full review. Original review.json, needs-fixes summary and manifest remain byte-identical under review-artifacts/. test-code-review-summary.json retains the passing resolution with no open findings. review-a-binding-renewal.json updates just A's supporting test SHA, preserves its original review bytes and unchanged content decisions, and records the identical100 observations.

## 2026-10-25 — Final local integration and scope

Independent AI reviewers inspected all 50 courses, 150 localized sources, 750 localized exercise/answer pairs and 250 prepared criteria. The per-unit final source, prerequisite and supporting-file SHA256 bindings are checked by validation.json. Actual human, fluent-language and learner acceptance remain null. Course/source presence is not a corpus-wide ready count.

Review corrected CYB016's cited Caltech draft from the unread 2007 edition to the actually retrieved 2009 extraction, with bounded reading scope and original source/packet bytes preserved. A's editorial location correction temporarily changed WML014's mathematical 'below target' direction too broadly; the reviewer caught and restored that intermediate error before final inspection and testing. The incorrect intermediate bytes are retained separately. These are content/coordination findings; no engine failure is fabricated. C's first successful focused run had unittest-prefix formatting before its observation lines; the original run is retained, and standalone-line formatting was corrected and replayed. Original failures, rejected topic interpretations and source-access limits stay in their unit records.

Final authoritative claims: 50 tests, 100 actual observations, complete model/control coverage and exit 0, selected by final-claim-runs.json. Metadata: 150 passes, zero failures. The actual completed test-code review and any separately verified resolutions are retained under review-artifacts/ and bound by test-code-review-summary.json; no previous batch review substitutes for this batch. All four proof-test files have final-byte bindings. No production engine, API or DSL implementation was added by these finite claim checks.

Final generator regressions: 18 passes. Actual full static build: 2,416 pages, exit 0. Built-HTML inspection: 210 changed articles, 4,794 article links, 150 canonical source banners and zero unresolved internal links. Missing-page and missing-anchor controls were detected. Repeat synchronization preserved exact bytes across 1,220 files. Full static logs remain byte-identical under test-runs/. This checks built HTML, not interactive behavior or public deployment. No lint/typecheck package script is configured; the actual generator tests and Astro build are the integration gates.

Final direct reference transport covered 42 URLs. Actual reading and fallback limitations belong to author/reviewer records and are not inferred from HTTP status. The initial author-freeze transport receipt is preserved separately. Global EN/FR/ES journals contain additive entries for the actual runs; stripping journal-additions.json recovers exact original bytes and prior checklist decisions. streeling/source.json is unchanged.

Inventory: 381/525 core English courses, 144 remaining; 382 sources per locale including extra IX Research. The curriculum specification/count document is refreshed after exact GitHub publication, using this inventory and actual final commit. Source reconciliation with Demerzel and its six-language policy remains separate work.

### Actual final observations (short previews)

Full untruncated values, independent expectations, commands, environment and input/test hashes remain in the selected claim receipt and full log. Each row below comes from actual final observations.

| Course | Model observation | Negative-control observation |
| --- | --- | --- |
| AUD016 | `{"mean":0.5,"ac_samples":[-0.5,0.5,-0.5,0.5],"total_ms":0.5,"ac_ms":0.25,"total_rms":0.7071067811865476,"ac_rms":0.5}` | `{"mean":0.0,"ac_samples":[-0.5,0.5,-0.5,0.5],"total_ms":0.25,"ac_ms":0.25,"total_rms":0.5,"ac_rms":0.5}` |
| AUD017 | `{"correlation":[0,2,0,-2],"signed_argmax":[1],"absolute_argmax":[1,3]}` | `{"correlation":[0,1,0,0],"signed_argmax":[1],"absolute_argmax":[1]}` |
| AUD018 | `{"mid":[0.7071067811865475,0.7071067811865475],"side":[0.7071067811865475,-0.7071067811865475],"left_out":[0.9999999999999999,0.0],"right_out":[0.0,0.9999999...` | `{"mid":[0.7071067811865475,0.7071067811865475],"side":[0.7071067811865475,-0.7071067811865475],"left_out":[0.49999999999999994,0.49999999999999994],"right_ou...` |
| COG015 | `{"alerts":170,"false_positives":90,"precision":0.47058823529411764,"true_positives":80}` | `{"alerts":450,"false_positives":50,"precision":0.8888888888888888,"true_positives":400}` |
| COG016 | `{"comparison_rate":0.7,"identified_strict_superiority":false,"lower":0.6,"minimum_missing_successes_for_strict_superiority":2,"upper":1}` | `{"comparison_rate":0.7,"identified_strict_superiority":false,"lower":0.6,"minimum_missing_successes_for_strict_superiority":null,"upper":0.6}` |
| COG017 | `{"assisted_change":0.3,"comparison_change":0.1,"contrast":0.2}` | `{"assisted_change":0.3,"comparison_change":0.3,"contrast":0}` |
| CS021 | `{"accepted":false,"error_count":3,"errors":["sample_rate_hz","channels","frames"]}` | `{"accepted":true,"error_count":0,"errors":[]}` |
| CS022 | `{"conflicts":["manifest"],"independent":false}` | `{"conflicts":[],"independent":true}` |
| CS023 | `{"acquired":["input","output"],"outcome":"work_error","released":["output","input"]}` | `{"acquired":["input"],"outcome":"acquire_error","released":["input"]}` |
| CYB015 | `{"bias":-1,"expected_level":3,"variance":1.75,"weights":[0.25,0.5]}` | `{"bias":-1,"expected_level":3,"variance":1.25,"weights":[0.25,0.5]}` |
| CYB016 | `{"baseline_command":5,"baseline_error":4,"baseline_output":14,"command":3.5,"error":1,"output":11}` | `{"baseline_command":5,"baseline_error":4,"baseline_output":14,"command":0,"error":-6,"output":4}` |
| CYB017 | `{"amplitude_only":[4,4,0],"commands":[1,2,1],"deltas":[1,1,-1],"final":1}` | `{"amplitude_only":[4,4,0],"commands":[4,4,0],"deltas":[4,0,-4],"final":0}` |
| DV017 | `{"C":0.9396926207859084,"R":0.9396926207859084,"S":5.551115123125783e-17,"arithmetic_mean_deg":90.0,"axial_mean_deg":0.0}` | `{"C":0.0,"R":6.123233995736766e-17,"S":6.123233995736766e-17,"arithmetic_mean_deg":45.0,"axial_mean_deg":null}` |
| DV018 | `{"a_only":20.0,"b_only":15.0,"both":10.0,"naive_sum":55.0,"neither":55.0,"union":45.0}` | `{"a_only":30.0,"b_only":25.0,"both":0.0,"naive_sum":55.0,"neither":45.0,"union":55.0}` |
| DV019 | `{"covers":[["back","side"],["front","top"]],"minimum_count":2,"uncovered":[]}` | `{"covers":[],"minimum_count":null,"uncovered":["D"]}` |
| FUT012 | `{"mean_a":3.6,"mean_b":4.0,"mean_choice":"A","tail_a":11.5,"tail_b":4.0,"tail_choice":"B","var_a":3.0}` | `{"mean_a":2.0,"mean_b":4.0,"mean_choice":"A","tail_a":3.5,"tail_b":4.0,"tail_choice":"A","var_a":3.0}` |
| FUT013 | `{"asymptotic_speedup":4.0,"ideal_minutes":12.25,"parallel_minutes":5.25,"serial_minutes":7.0,"speedup":2.2857142857142856}` | `{"asymptotic_speedup":1.6666666666666667,"ideal_minutes":19.6,"parallel_minutes":2.8,"serial_minutes":16.8,"speedup":1.4285714285714286}` |
| GAA014 | `{"overlap":[[0,4,7]],"family_disjoint":false,"distinct_item_ids":4}` | `{"overlap":[],"family_disjoint":true,"distinct_item_ids":4}` |
| GAA015 | `{"rate":0.8,"lower":0.49015684672072335,"upper":0.9433190520193067,"established":false}` | `{"rate":0.8,"lower":0.7111690380734976,"upper":0.8666340774409012,"established":true}` |
| GAA016 | `{"scores":[4,5,6,7],"mean_a":5.5,"mean_b":5.5,"contrast":0.0}` | `{"scores":[4,5,6,7],"mean_a":5.0,"mean_b":6.0,"contrast":1.0}` |
| GAS015 | `{"observed":[1.0,6.123233995736766e-17,-0.25,-3.061616997868383e-17],"zero_modes":[2,4]}` | `{"observed":[0.7071067811865476,0.5,0.1767766952966369,1.5308084989341915e-17],"zero_modes":[4]}` |
| GAS016 | `{"extension_m":0.0001999800039989008,"tension_n":10.1999800039989,"ideal_f_hz":100.0,"frequency_hz":100.9747574562156,"error_cents":16.79361678856818}` | `{"extension_m":0.0,"tension_n":10.0,"ideal_f_hz":100.0,"frequency_hz":100.0,"error_cents":0.0}` |
| GAS017 | `{"B":0.010000000000000009,"predicted_third_squared_ratio":1.0792079207920793,"held_out_residual":0.0,"valid":true}` | `{"B":-0.0033222591362126277,"valid":false}` |
| GTR015 | `{"cents":[0.0,25.0,3.061616997868383e-15,-25.0,-6.123233995736766e-15],"period_s":0.5,"peak_to_peak_cents":50}` | `{"cents":[0.0,3.061616997868383e-15,-6.123233995736766e-15,9.184850993605149e-15,-1.2246467991473532e-14],"period_s":0.25,"peak_to_peak_cents":50}` |
| GTR016 | `{"vibrating_fraction":0.6674199270850172,"base_hz":164.81377845643496,"touch_fraction_from_bridge":0.3337099635425086,"sounding_hz":329.6275569128699,"fixed_...` | `{"vibrating_fraction":1.0,"base_hz":110.0,"touch_fraction_from_bridge":0.5,"sounding_hz":220.0,"fixed_touch_local":0.5}` |
| GTR017 | `{"union_s":[[0.0,1.0]],"gaps_s":[],"overlap_s":0.1,"continuous":true}` | `{"union_s":[[0.0,0.6],[0.7,1.0]],"gaps_s":[[0.6,0.7]],"overlap_s":0.0,"continuous":false}` |
| INF016 | `{"accepted":true,"delta":3,"guarded_reconstruction":13,"naive_reconstruction":13}` | `{"accepted":false,"delta":3,"guarded_reconstruction":null,"naive_reconstruction":23}` |
| INF017 | `{"mean":5,"merged":[20,4],"naive_mean":4,"summaries":[[2,1],[18,3]]}` | `{"mean":5,"merged":[20,4],"naive_mean":5,"summaries":[[6,2],[14,2]]}` |
| INF018 | `{"actual_lengths":[2,3],"frame":"2:é3:A\|B","naive_delimited":"é\|A\|B","valid":true}` | `{"actual_lengths":[2,3],"frame":null,"naive_delimited":"é\|A\|B","valid":false}` |
| MCL015 | `{"release_times":[2,2],"scheduled_holds":[2,1]}` | `{"release_times":[0.75,1.5],"scheduled_holds":[0.75,0.5]}` |
| MCL016 | `{"note_intervals":{"a":[0,4],"b":[0,2]},"cursor_states":[0,4,0,2,4],"final_cursor":4,"valid":true}` | `{"note_intervals":{"a":[0,4],"b":[2,4]},"cursor_states":[0,4,2,4,6],"final_cursor":6,"valid":false}` |
| MCL017 | `{"slope_bpm_per_quarter":15.0,"duration_s":2.772588722239781,"endpoint_average_duration_s":2.6666666666666665}` | `{"slope_bpm_per_quarter":0.0,"duration_s":4.0,"endpoint_average_duration_s":4.0}` |
| NET014 | `{"maximum_flow":4,"minimum_cut_capacity":4,"simple_path_count":3,"sink_cut_capacity":4}` | `{"maximum_flow":3,"minimum_cut_capacity":3,"simple_path_count":3,"sink_cut_capacity":3}` |
| NET015 | `{"component_count":3,"components":[["a","b"],["c","d"],["e"]],"condensed_edge_count":2,"condensed_edges":[["ab","cd"],["cd","e"]]}` | `{"component_count":1,"components":[["a","b","c","d","e"]],"condensed_edge_count":0,"condensed_edges":[]}` |
| PHI012 | `{"compatible_with_equivalence":true,"contains_zero":true,"equivalent":true,"width":0.25}` | `{"compatible_with_equivalence":true,"contains_zero":true,"equivalent":false,"width":1.0}` |
| PHI013 | `{"core_deletion_witnesses":{"remove_A":[0,0],"remove_B":[8,0]},"full_solution_count":0,"minimal_cores":[["A","B"]]}` | `{"core_deletion_witnesses":{},"full_solution_count":3,"minimal_cores":[]}` |
| PHY019 | `{"capacity_N":12.8,"demand_N":12.0,"normal_N":16.0,"reserve_N":0.8,"static_feasible":true}` | `{"capacity_N":8.0,"demand_N":12.0,"normal_N":16.0,"reserve_N":-4.0,"static_feasible":false}` |
| PHY020 | `{"I_x_mm4":27.0,"I_y_mm4":432.0,"curvature_x_per_mm":0.0003333333333333333,"curvature_y_per_mm":2.0833333333333333e-05,"ratio":16.0}` | `{"I_x_mm4":108.0,"I_y_mm4":108.0,"curvature_x_per_mm":8.333333333333333e-05,"curvature_y_per_mm":8.333333333333333e-05,"ratio":1.0}` |
| PHY021 | `{"K_after_J":1.0,"K_before_J":4.0,"impulse_Ns":3.0,"outgoing_m_s":2.0,"retained_fraction":0.25}` | `{"K_after_J":4.0,"K_before_J":4.0,"impulse_Ns":4.0,"outgoing_m_s":4.0,"retained_fraction":1.0}` |
| PM012 | `{"baseline_cost":38,"makespan":7,"optimal_completion":{"A":5,"B":1,"C":7},"optimal_cost":30,"optimal_order":["B","A","C"]}` | `{"baseline_cost":44,"makespan":7,"optimal_completion":{"A":4,"B":5,"C":7},"optimal_cost":44,"optimal_order":["A","B","C"]}` |
| PM013 | `{"cumulative_first_use":0.625,"event_times":[1,3],"raw_event_fraction":0.5,"risk_sets":[4,2],"survival":[0.75,0.375]}` | `{"cumulative_first_use":0.5,"event_times":[1,3],"raw_event_fraction":0.5,"risk_sets":[4,3],"survival":[0.75,0.5]}` |
| SEM015 | `{"new_point":[2.0,0.5],"original":[2.0,0.5],"preserved":true,"remapped_weights":[0.25,0.25,0.5]}` | `{"new_point":[1.0,1.0],"original":[2.0,0.5],"preserved":false,"remapped_weights":[0.25,0.5,0.25]}` |
| SEM016 | `{"assignments":[[0,1,0],[1,0,1]],"consistent":true,"cycle_parity":0}` | `{"assignments":[],"consistent":false,"cycle_parity":1}` |
| SEM017 | `{"indices":[-1,0,0,1],"ownership":[true,true,true,true],"violating_coordinates":[]}` | `{"indices":[0,0,0,1],"ownership":[false,true,true,true],"violating_coordinates":[-0.1]}` |
| VC017 | `{"codes":[23,23],"encoded":[0.09090909090909091,0.08990899089908991],"separated":false}` | `{"codes":[121,119],"encoded":[0.47368421052631576,0.46847316310578424],"separated":true}` |
| VC018 | `{"double_multiplied":[0.0625,0.0,0.75],"out_alpha":1.0,"out_premultiplied":[0.25,0.0,0.75],"source_premultiplied":[0.25,0.0,0.0]}` | `{"double_multiplied":[1.0,0.0,0.0],"out_alpha":1.0,"out_premultiplied":[1.0,0.0,0.0],"source_premultiplied":[1.0,0.0,0.0]}` |
| VC019 | `{"anisotropy":4.0,"area_scale":4.0,"ellipse_axes":[0.4,0.1],"stretches":[4.0,1.0]}` | `{"anisotropy":1.0,"area_scale":4.0,"ellipse_axes":[0.2,0.2],"stretches":[2.0,2.0]}` |
| WML014 | `{"target_cents":386.3137138648348,"step":6,"represented_cents":378.94736842105266,"error_cents":-7.366345443782166}` | `{"target_cents":386.3137138648348,"step":4,"represented_cents":400.0,"error_cents":13.686286135165176}` |
| WML015 | `{"frequencies_hz":[442.0,884.0],"calibration_ratio":1.0045454545454546,"calibration_cents":7.851415040126504,"octave_ratio":2.0}` | `{"frequencies_hz":[440.0,880.0],"calibration_ratio":1.0,"calibration_cents":0.0,"octave_ratio":2.0}` |
| WML016 | `{"degrees":{"1":0,"5":6,"7":10,"9":14},"pitch_classes":[0,2,6,10],"valid":true}` | `{"valid":false,"rejected_operation_index":1,"reason":"duplicate_degree","degree":5}` |

## To verify

This snapshot completes local production, independent AI review, finite model/control checks and static integration. The next action is normal push to existing Draft PR201 followed by anonymous exact-file readback at the immutable final commit. That publication receipt stays outside this commit to avoid self-reference. Deployed HTML, human/learner acceptance and the 525-course outcome are not established here.

## Open questions

Human technical/craft/musician and fluent-language review, actual learner answers/assistance/acceptance, task-specific listening/material/native-engine/scene trials, remaining active-language coverage and Demerzel source reconciliation remain pending. The user will designate a reviewer; this journal does not repeat the request.
