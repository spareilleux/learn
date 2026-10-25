# Fifty more project-useful courses

This batch adds 50 distinct English lessons and 100 full French/Spanish translations. It advances the original 21-department source inventory from 281 to 331 of 525; translations and the extra IX Research department do not inflate that denominator. This README describes the requested batch; actual completion is decided by the final receipts, not by this introduction.

`allocation.json` fixes the identifiers, `production-plan.md` defines the work and `batch-plan.json` binds the exact source paths after author freeze. Each lesson has five corrected exercises, a distinct authored case and control, actual source reading and a source-assisted learner task. Prepared learner criteria have null acceptance decisions until actual responses and assistance records exist.

## Test and refine

The [production journal](journal.md) retains prospective expectations or clearly labeled retrospective checks, exact commands and input/test revisions, computed observations, failures, diagnoses, corrections and replay. `test-runs/` retains complete actual output. `journal-additions.json` makes the prior EN/FR/ES global journal history byte-recoverable; learner checklist states are preserved.

Independent source/model review covers each localized answer and prepared criterion. Independent Python tests calculate each fixed model and its negative control with separate expectations. The metadata checker started as a byte-identical copy of the preceding reviewed checker; observed defects led to additional generator-filename and shared-metadata checks. A controlled before/after probe retains the same 50 deliberately incorrect cases: accepted before the change, rejected afterward. The nonempty/exact-cardinality guard remains. New test code is reviewed independently before source publication. The batch-local attributes preserve the exact raw JSON/log bytes bound by receipts.

From the repository root, after the source/test files are complete:

```sh
python -X utf8 -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-24/tests -p "test_unit_*.py" -v
node --test code/streeling/evidence/batch50-2026-10-24/tests/test_course_metadata.mjs
```

Use the installed Python 3 launcher (`python3` where required). A new attempt must retain its own output, environment, input/test hashes, expected/observed values and diagnosis. Keep failed attempts; changing a course or a test requires affected checks and review bindings to be renewed. `final-claim-runs.json` identifies the authoritative actual attempts after verification; earlier logs remain historical evidence.

## Evidence boundaries

Authored rates, timings, signals, meshes, views and trials are finite examples. A calculation is not an observed audio-engine, renderer, material, live-agent, musician or learner outcome. Source reading is pinned to its stated revision and passage. HTTP success is transport evidence only; failed primary access and official-body fallbacks remain explicit.

Root alone synchronizes generated pages, builds and checks the changed HTML and source banners, verifies repeat-sync equality, commits owned files and pushes to existing Draft PR201 without rewriting its title/body. An anonymous readback of all changed files at the resulting immutable GitHub commit is separate from deployed course HTML. That final receipt stays outside the commit to avoid self-reference. Human technical, craft/musician, fluent-language and learner decisions remain pending.

## Verified local result — 2026-10-25

`validation.json` records 50 tests / 100 model-control observations, 150 metadata passes, 18 generator regressions, 2,266 built pages, 210 changed articles with 4,485 resolved links and repeat-sync equality across 1,070 files. All 750 answers and 250 prepared criteria were independently inspected; human and learner decisions remain null. `test-code-review-summary.json` retains the original completed review plus independently verified resolution of its one alignment defect, with exact final test hashes. The production journal preserves the false midpoint premise, corrected labels, source/metadata detector improvements and original failed attempts. Publication verification is a separate immutable-commit readback receipt outside this snapshot.
