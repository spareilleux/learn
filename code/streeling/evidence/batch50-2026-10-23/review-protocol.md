# Independent review contract

The author self-checks are inputs, not independent acceptance. Each independent reviewer owns one `review-<unit>.json` file and reads that unit's actual frozen sources and fixed-data packet. Review every answer in every language and every prepared criterion. Recompute the authored quantities rather than echoing expected values. Check novelty against actual prerequisites and distinguish source inspection, authored models, historical execution and actual human/learner evidence.

The receipt contains:

- `verdict`: pass only with no open corrections; `unit`: a, b or c.
- `coverage`: course count, localized source count, exercise-answer pairs and learner criteria.
- `course_checks`: one row per course, `code`, novelty/source/model/boundary findings and `decision`.
- `exercise_answer_checks`: one row per localized exercise, `code`, `locale`, `exercise`, `decision` and concrete checked result or reasoning.
- `learner_criterion_checks`: one row per prepared criterion, `code`, `criterion`, `decision`, `learner_decision: null` and acceptance reasoning.
- `calculation_checks`: independently recomputed model quantities and negative controls, with `code`, `pass_` and concrete observed/expected values or logical witnesses. Every course must have a checked model and negative control; logical decision cases need an explicit witness rather than an invented numerical metric. Do not invent a check count or runtime execution.
- `findings`: each finding has an ID, text and status `resolved` or `observed-preserved`; unresolved findings prevent pass. Keep any fix history and affected hashes.
- `source_bindings`, `supporting_bindings`, `prerequisite_bindings`: lists of actual-read paths and exact SHA256 hashes. Prefer repository-relative paths for files inside the checkout and absolute paths for external copies. Bind all owned localized sources, the unit packet, relevant plan/protocol and actual supporting/prerequisite inputs read. Never claim a read solely because an author listed it.
- Human technical, artisan/musician, fluent-language, actual learner, new runtime/material/listening and deployed HTML decisions remain null.

Required unit coverage is54sources/270pairs/90criteria for A and48sources/240pairs/80criteria each for B and C. Root verifies the union is exactly150sources/750pairs/250criteria across50 distinct English courses. Review is not a sample. If a course/source changes after review, the affected review and hash bindings must be renewed before publication.

## Executable claim tests requested later

The reviewer also owns only `tests/test_unit_<unit>.py` for its unit. Use Python's standard-library `unittest`; no dependencies, network, engine/browser/GPU calls, Git writes or shared state. Read the actual unit fixed-data inputs and independently compute the declared quantities. Do not use an expected output to generate the result being checked. Verify a concrete model case and a relevant negative control for every course, including logical witnesses for nonnumeric policy examples. These are tests of authored cases, not production integration evidence. A test asserting a constant against itself or merely checking file hashes is not domain validation.

Emit one-line `OBSERVATION ` followed by JSON for each checked case, before its assertions, with `code`, `case` (`model` or `negative`), concrete `observed`, independent `expected` and `scope`. This retains actual computed values on success and failure. Give tests readable names containing their course code. Root executes the authoritative suite with `python -B -m unittest discover -s code/streeling/evidence/batch50-2026-10-23/tests -v`, retains every attempt and journals failures/corrections/replay. Reviewers may run their own focused pure test module to characterize it, retaining the actual output; no invented red failure is required. Root performs a separate code review of the three test modules. Do not bind mutable root journals/logs as frozen review inputs before root finalizes them; bind the test module and fixed inputs actually read.
