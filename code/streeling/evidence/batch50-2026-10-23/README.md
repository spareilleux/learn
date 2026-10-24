# Fifty-course batch: project models and composition

This batch contains50 distinct English courses and their full French/Spanish translations. The150 localized sources are not150 courses. `batch-plan.json` declares exact paths, department allocation and the immutable Learn baseline. Canonical sources live in `streeling/courses/`; the existing generator alone writes site pages.

## Production and review evidence

- Unit A covers18 audio/music/practice courses. Unit B covers16 agentic/systems courses. Unit C covers16 craft/scene/interpretation courses.
- Each unit's fixed-data JSON records actual source reading, a distinct authored example per course, assumptions, expected calculations, a negative control, five exercise checks, five prepared learner criteria and a source-assisted task.
- Author self-checks retain final source hashes and translation parity. They are distinct from the independent review receipts.
- Independent review receipts inspect all localized answers, prepared criteria, novelty/prerequisites, fixed calculations and source/version/claim boundaries. AI review is not human technical, artisan/musician, fluent-language or learner acceptance.
- `learner-task.md` describes the actual answer/assistance record needed later. Prepared criteria remain undecided; no participant success is inferred from authored expected answers.
- The later user request adds reproducible claim tests and iterative journal entries. `journal-validation-plan.md` governs this extension; `journal.md` retains meaningful runs, failures, corrections and replay. Existing history/checklist states are preserved by `journal-additions.json`.
- Root validation retains the exact inventory delta, claim tests, generator tests, full static build, changed article/source-banner/link checks, repeat-sync equality and protected provenance/history checks. Direct URL transport is separate from actual primary reading.

## Repeat the claim checks

From the repository root, with Python 3 and Node installed:

```sh
python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p "test_unit_*.py" -v
python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -p "test_baseline_audio.py" -v
node --test code/streeling/evidence/batch50-2026-10-23/tests/test_course_metadata.mjs
```

The final recorded runs have 69 new-course tests with 100 model/control observations, six previous-course tests with six observations, and 150 localized metadata checks. Keep a new attempt's complete output and environment/input/test hashes; append its question, expectation, result and diagnosis to the journal. Preserve failed attempts. A changed course or test needs a new execution record and renewed review of the affected inputs. `final-claim-runs.json` selects the authoritative retained attempts; older attempts remain historical evidence.

Independent test review and its final deliberately wrong-input probes are retained in `test-code-review-summary.json` and the byte-preserved JSON copies under `review-artifacts/`. No external Claude review ran; the completed adversarial review used a separate local context.

The batch-local `.gitattributes` preserves raw JSON/log bytes across Git checkouts. Their receipt hashes bind those bytes, including original line endings and tool-output whitespace. Course Markdown and test code keep the repository's normal text rules.

## Claim boundaries

These lessons use explicit small records, direct calculations and manual baselines before proposing agentic or DSL abstractions. Reused historical project results keep their original revision, test scope and failed or inconclusive verdicts. Source inspection is not new runtime execution. Authored rates, timings, workloads, learners and scene counts are illustrative models, not new machine, listener, material or user-study observations.

No new runnable lab, audio engine, craft solver, scene renderer, production API or DSL is delivered. Human and actual learner decisions remain pending. The source inventory tracks progress toward525 courses across the original21 departments; publication of source files in DraftPR201 does not establish deployed HTML or completion of that objective. The anonymous immutable GitHub readback receipt is retained outside the repository after push to avoid a self-referential commit dependency.
