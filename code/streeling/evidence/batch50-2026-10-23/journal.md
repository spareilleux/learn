# Batch50 production journal

## 2026-10-23 — Scope and initial regression run

The user requested lots of50 distinct courses, then explicitly requested repeated claim tests, journaled failures/corrections and replay throughout production. The production manifest contains50 courses/150 localized sources across18 departments. Three authoring units own disjoint files; source reading and authoring are in progress, not new runtime or learner evidence.

Executed existing generator regression checks:18 passed,0 failed. See `test-runs/generator-initial.json` and its complete log. Expected regression compatibility was checked; no scientific hypothesis was preregistered. No domain-claim test result is inferred from this run.

Next: independent checks and reproducible tests for each course's fixed model/counterexample, retain any actual failed attempts, correct the responsible artifact, replay, review code and content, then generate/build/read back. Those outcomes remain pending here. The historical journal text and checklist states are preserved by the exact-fragment ledger.

## 2026-10-23 — baseline-audio-01: before execution

Recorded UTC: 2026-10-23T23:47:55.322917+00:00. Claim: the declared authored model and negative-control checks for the 3 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p test_baseline_audio.py -v`. Input/test hashes will be retained in `test-runs/baseline-audio-01.json`.

### baseline-audio-01: observed result

Exit0; 6 tests; 6 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/baseline-audio-01.log`; exact tested source/data/test hashes and observations: `test-runs/baseline-audio-01.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-23 — metadata-before-fix: before metadata regression

UTC:2026-10-24T00:07:31.316556+00:00. Expected contract: every localized page title equals the course metadata used in its generated description. Source inspection found English descriptions with translated body titles in unitB; this run tests that suspected defect, not the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-23/tests/test_course_metadata.mjs`.

Observed: exit1, 118 passed, 32 failed. Complete output: `test-runs/metadata-before-fix.log`; source/test hashes: `test-runs/metadata-before-fix.json`. This attempt is preserved even if a later correction passes.

## 2026-10-23 — Real metadata regression and correction

The prospective150-case parser check returned118pass/32fail. UnitB had localized H1/title fields but English course metadata; the generator uses course metadata for descriptions. Root changed only that scalar to the existing localized title in16French+16Spanish sources. No model value or answer changed. `root-metadata-fix.json` retains every before/after scalar and byte hash; the original author self-check remains historical. Replay follows; do not infer success until its actual result is retained.

Earlier root mechanical-check failures were checker assumptions, not missing exercises: unitA uses numbered level2exercise headings, unitB uses details/summary answers, unitC uses level3headings and blockquote answers. Inspection established those three actual formats. The checker was broadened to recognize them rather than rewriting valid lessons. Temporary pre-fix checker bytes were not retained; this is a retrospective diagnosis, not a fabricated reproducible failure receipt.

## 2026-10-23 — metadata-after-fix: before metadata regression

UTC:2026-10-24T00:08:21.954088+00:00. Expected contract: every localized page title equals the course metadata used in its generated description. Source inspection found English descriptions with translated body titles in unitB; this run tests that suspected defect, not the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-23/tests/test_course_metadata.mjs`.

Observed: exit0, 150 passed, 0 failed. Complete output: `test-runs/metadata-after-fix.log`; source/test hashes: `test-runs/metadata-after-fix.json`. This attempt is preserved even if a later correction passes.

## 2026-10-23 — claims-a-01: before execution

Recorded UTC: 2026-10-24T00:08:54.021977+00:00. Claim: the declared authored model and negative-control checks for the 18 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p test_unit_a.py -v`. Input/test hashes will be retained in `test-runs/claims-a-01.json`.

### claims-a-01: observed result

Exit0; 36 tests; 36 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/claims-a-01.log`; exact tested source/data/test hashes and observations: `test-runs/claims-a-01.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-23 — claims-c-01: before execution

Recorded UTC: 2026-10-24T00:09:17.430065+00:00. Claim: the declared authored model and negative-control checks for the 16 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p test_unit_c.py -v`. Input/test hashes will be retained in `test-runs/claims-c-01.json`.

### claims-c-01: observed result

Exit0; 16 tests; 32 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/claims-c-01.log`; exact tested source/data/test hashes and observations: `test-runs/claims-c-01.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-23 — claims-b-01: before execution

Recorded UTC: 2026-10-24T00:11:42.800079+00:00. Claim: the declared authored model and negative-control checks for the 16 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p test_unit_b.py -v`. Input/test hashes will be retained in `test-runs/claims-b-01.json`.

### claims-b-01: observed result

Exit0; 17 tests; 32 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/claims-b-01.log`; exact tested source/data/test hashes and observations: `test-runs/claims-b-01.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-23 — claims-all-01: before execution

Recorded UTC: 2026-10-24T00:20:42.217095+00:00. Claim: the declared authored model and negative-control checks for the 50 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p test_unit_*.py -v`. Input/test hashes will be retained in `test-runs/claims-all-01.json`.

### claims-all-01: observed result

Exit0; 69 tests; 100 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/claims-all-01.log`; exact tested source/data/test hashes and observations: `test-runs/claims-all-01.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-23 — metadata-empty-plan-before-guard: test-detector probe

Independent code review identified dynamic test registration with no required course/locale count. A temporary copy used the deliberately incorrect empty plan; only its dependency import was redirected to the canonical helper. Canonical data/test bytes were untouched by the probe. Actual exit:0; incorrect empty input rejected:False. `test-runs/metadata-empty-plan-before-guard.json` records test/input hashes and exact command; full output is retained. A green exit on this incorrect input is a test defect, not a valid curriculum result.

## 2026-10-23 — metadata-empty-plan-after-guard: test-detector probe

Independent code review identified dynamic test registration with no required course/locale count. A temporary copy used the deliberately incorrect empty plan; only its dependency import was redirected to the canonical helper. Canonical data/test bytes were untouched by the probe. Actual exit:1; incorrect empty input rejected:True. `test-runs/metadata-empty-plan-after-guard.json` records test/input hashes and exact command; full output is retained. A green exit on this incorrect input is a test defect, not a valid curriculum result.

## 2026-10-23 — metadata-after-guard: before metadata regression

UTC:2026-10-24T00:26:23.873450+00:00. Expected contract: every localized page title equals the course metadata used in its generated description. Source inspection found English descriptions with translated body titles in unitB; this run tests that suspected defect, not the truth of domain calculations. Actual command: `node --test code/streeling/evidence/batch50-2026-10-23/tests/test_course_metadata.mjs`.

Observed: exit0, 150 passed, 0 failed. Complete output: `test-runs/metadata-after-guard.log`; source/test hashes: `test-runs/metadata-after-guard.json`. This attempt is preserved even if a later correction passes.

## 2026-10-23 — claims-all-02: before execution

Recorded UTC: 2026-10-24T00:31:39.529889+00:00. Claim: the declared authored model and negative-control checks for the 50 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p test_unit_*.py -v`. Input/test hashes will be retained in `test-runs/claims-all-02.json`.

### claims-all-02: observed result

Exit0; 69 tests; 100 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/claims-all-02.log`; exact tested source/data/test hashes and observations: `test-runs/claims-all-02.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-23 — baseline-audio-02: before execution

Recorded UTC: 2026-10-24T00:31:45.169453+00:00. Claim: the declared authored model and negative-control checks for the 3 selected courses match the frozen inputs. Expected: nonempty test execution, complete course/model/negative coverage and no failing assertions. This is a prospective test expectation, not a hypothesis about actual learners, audio, scenes or materials.

Command: `python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p test_baseline_audio.py -v`. Input/test hashes will be retained in `test-runs/baseline-audio-02.json`.

### baseline-audio-02: observed result

Exit0; 6 tests; 6 observed case records; complete model/negative course coverage: True. Verdict: pass. Full output: `test-runs/baseline-audio-02.log`; exact tested source/data/test hashes and observations: `test-runs/baseline-audio-02.json`. No failure has been removed or overwritten. A failure needs diagnosis before assigning responsibility to a course or a test.

## 2026-10-23 — Refinement from failed checks and independent test review

This is a retrospective diagnosis entry, recorded after the linked attempts. Earlier expectations, failed attempts and original author self-checks remain intact.

| Finding | Evidence and diagnosis | Correction and replay | Remaining boundary |
| --- | --- | --- | --- |
| Unit B had localized titles but English `course` metadata in 32 FR/ES sources. The generator uses `course` for descriptions. | `test-runs/metadata-before-fix.json`: 118 passes, 32 failures. `root-metadata-fix.json` retains each original scalar and before/after byte hash. | Changed only those 32 scalars to the existing localized titles. `metadata-after-fix.json` and `metadata-after-guard.json`: 150 passes, zero failures. | Metadata correctness is separate from the truth of a course claim. The generator itself was not changed. |
| An empty plan could make the dynamically registered metadata checks exit successfully. | `metadata-empty-plan-before-guard.json`: temporary empty input, exit 0. This is a real detector defect, not evidence that an empty curriculum is correct. | Require 50 unique courses, 50 module IDs, three exact locale keys and 150 unique paths before registering tests. `metadata-empty-plan-after-guard.json`: exit 1; normal `metadata-after-guard.json`: 150 passes. | Wrong inputs live in temporary copies; canonical plan/source bytes were preserved. |
| INF010 and INF009 could assert before printing their computed observation. | Independent code review identified the statement order. Its retained mutation probes distinguish an intended failure from a missing diagnostic record. | INF010 collects totals, prints the model observation, then asserts totals. INF009 computes both statistics rows, prints them with expected statistics, then asserts. Actual `claims-all-02.json` and `baseline-audio-02.json` pass. | An arithmetic exception before a result exists remains an exception; this change concerns the reviewed assertion paths. |
| AUD009 printed expected delay and prefix coverage without asserting those fixed values independently. | Independent review changed the in-memory sample rate and declared delay together; it also changed the checked prefix. The old tests could stay green with a mismatched printed expectation. | Added the independent 0.25 ms and 0.75 coverage checks, and exact reference/target/aligned/residual support-length checks. Actual `baseline-audio-02.json`: six passes and six observations. | This checks the authored comparison record, not an audio engine or a listening trial. |
| Unit A contained small transcribed decimals and a helper encoding defect. | Author-reported `unit-a-self-check.json` `fix_history` preserves exact attempts and corrections: GAS009 cents, GAS010 stiff-string partial, and a packet C-sharp character. Independent A review recomputed final cases. | Final values include 3.930158439 cents, -34.975614791 cents and 311.654797607 Hz. Explicit UTF-8 fixes helper/packet encoding; `claims-a-01.json` and `claims-all-02.json` pass on final source bytes. | These author corrections were not a failed production audio run. Temporary checker false alarms are diagnosed as checker defects, not as course failures. |

The independent test review used a local adversarial fallback after the Claude CLI worker could not start. It is not a completed Claude review. Its final receipt binds all five delivered test files. Direct primary-link transport also remains separate from content reading: 25 of 27 URLs returned HTTP 200 directly; two MathWorks HTTP 403 responses are preserved alongside actual official-page body-reading fallbacks in `primary-access-fallbacks.json`.

The Galactic status/inbox bridge returned `Transport closed` during this continuation. No remote session status, inbox acknowledgement or coordination success is inferred from that failure. Local file/test evidence is retained independently.

## 2026-10-23 — Fifty-course replay ledger

Actual run: `test-runs/claims-all-02.json`; full command, final input/test hashes, expected and computed values, and complete output are retained there and in its `.log`. It executed 69 Python tests producing 100 model/control observations. The table records coverage and the successful run verdict; it does not recast the 750 reviewed exercise/answer pairs as 750 executed tests.

| Course | Authored model observed | Negative control observed | Run verdict | Evidence |
| --- | --- | --- | --- | --- |
| AUD010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| AUD011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| AUD012 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GAS009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GAS010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GAS011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GTR009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GTR010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GTR011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GAA008 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GAA009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| GAA010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| MCL009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| MCL010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| MCL011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| WML008 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| WML009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| WML010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| CS015 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| CS016 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| CS017 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| CYB009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| CYB010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| CYB011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| COG009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| COG010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| COG011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| INF010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| INF011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| INF012 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| NET010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| NET011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| PM008 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| PM009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| PHY013 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| PHY014 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| PHY015 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| VC011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| VC012 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| VC013 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| DV011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| DV012 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| DV013 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| SEM009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| SEM010 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| SEM011 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| PHI008 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| PHI009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| FUT008 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |
| FUT009 | Yes | Yes | Pass | [Computed and expected values](test-runs/claims-all-02.json) |

Three previous courses (GAS008, AUD009, INF009) were replayed separately: `test-runs/baseline-audio-02.json`, six tests and six observations. No new native-runtime, Godot scene, physical material, listening, human technical or learner attempt was performed. Prepared learner criteria still have null decisions. A later experiment must record its own hypothesis, actual environment/input revision, result, failure diagnosis and replay rather than inheriting this fixed-model verdict.

## 2026-10-23 — Static integration and journal-history checks

Actual full `npm run build`: exit 0, 2,116 pages, 112.177 seconds including the wrapper. Complete build output and existing warnings are preserved in `test-runs/static-build.log`; no warning was converted into a fabricated clean log. Existing generator regression: 18 passes. Source synchronization: exit 0.

The built-HTML check inspected all 210 changed routes (150 courses, 54 department indexes, three overviews and three journals), 4,110 article links and all 150 new canonical source banners. No internal page/anchor link was unresolved. Deliberately missing-page and missing-anchor controls were detected. See `rendered-links.json`; this is static HTML inspection, not interactive browser or public deployment testing.

Repeat `npm run sync:streeling`: exit 0, byte-identical results across all 920 generated locale Markdown/lock/sidebar/preserved-journal files. See `sync-idempotence.json` and `test-runs/repeat-sync.log`. The additive-fragment ledger recovers the exact pre-batch bytes of all three existing journals, preserving their old checklist decisions and history. The final source inventory is 281/525 core English modules; the batch adds 50 distinct courses and 100 translations, leaving 244 core source gaps. These counts do not measure human acceptance or deployed lessons.

`test-runs/static-retention.json` retains exact origin/log hashes and byte-preserved output copies. Completed test-code review has no open findings, binds all five final test files, and retains three resolved findings plus four final wrong-input rejections with observation records under `review-artifacts/`. Actual fixed-case replays: 69 new-course tests/100 observations, six previous-course tests/six observations; metadata: 150 passes. No claim of a completed external Claude review is made.

An intermediate temporary journal-writer command failed to parse an unterminated Python f-string (exit 1) before execution; no repository file changed on that attempt. The helper string was corrected and the next execution succeeded. This is a documentation-helper defect, not a course or domain-test failure. Old failed curriculum/test attempts remain retained rather than replaced.

Source publication will be checked separately after the exact owned commit is pushed to existing Draft PR201. Its anonymous immutable GitHub readback receipt must remain outside this commit to avoid a self-reference. Public source bytes are distinct from deployed course HTML. Human, learner, listening, material and native scene/runtime decisions remain pending.

## 2026-10-23 — Final evidence assembly diagnostics

The first finalizer attempt rejected unit A's coverage object because it included additional explicit `model_cases` and `negative_controls` fields. The next attempt exposed that unit B stores a learner criterion's number in `criterion_number` and its text in `criterion`. These were temporary evidence-assembler schema assumptions, not failed reviews. The assembler now verifies all required coverage values and uses the actual criterion number field where present; it still requires the exact 50-course / 750 localized-answer / 250 prepared-criterion sets and fresh bound input hashes. The final attempt passed: 50 courses, 150 sources, 750 reviewed answer pairs, 250 prepared criteria, 68 independent calculation records, 2,116 built pages and 4,110 checked article links.

The first staging preflight rejected a retained Python test log containing native carriage returns. No bulk stage or commit occurred before that check failed. Raw logs must retain their actual bytes: the staging check was corrected to require their exact recorded SHA256 rather than normalize their output. Sources, authored Markdown and tests still require UTF-8 without BOM and LF. JSON is parsed as UTF-8 without BOM, preserving recorded raw bytes. These helper failures remain documented here; they did not change course assertions, soften a domain test or erase failed attempts.

### Raw evidence and Git normalization

Further preflights exposed native CRLF in independent review JSON, and the generator receipt's separate `retained_log` field. Those are valid recorded evidence formats; their exact bytes were preserved and their actual receipt fields checked. A temporary one-line diagnostic appender failed to parse because PowerShell interpreted literal backticks; it changed no file. This entry uses the normal patch tool instead.

The first full staging attempt then encountered the repository's `* text=auto eol=lf` rule and trailing whitespace in unedited tool output. It staged files but did not commit; raw evidence cannot be reformatted to satisfy source-code whitespace rules. The batch-local `.gitattributes` now disables text conversion for JSON and logs, allows CR-at-EOL in JSON and disables whitespace-style warnings only for raw logs. Code, course and Markdown checks remain in force.

The first index-byte comparison still detected an old normalized review blob cached from the earlier stage. Reapplying attributes with `git add --renormalize` to the explicit owned path list corrected the index. The successful preflight compared every one of the 444 staged blobs byte-for-byte with the working file in one `git cat-file --batch` read, checked all 236 reviewed input bindings, and passed `git diff --cached --check`. No outside path was staged or committed. This closes a real evidence-retention defect: a published log hash must describe the published bytes.
