# Journal-driven claim verification

This supplement records the user's later instruction: test claims, retain failures, refine courses/tests/journals and replay throughout production. It extends the fifty-course production plan. The50-course/150-source scope stays fixed.

## Owned changes

Root owns the batch journal, execution logs/receipts and append-only additions to the existing English/French/Spanish Streeling journals. The old entries, checklist states and historical failures remain unchanged. This explicit request supersedes the earlier rule to byte-preserve the three journals; `streeling/source.json` remains protected.

Narrow, reproducible Python standard-library claim tests are now part of the requested deliverable. This is the specific code sub-step returned to the code workflow from the knowledge-work carve-out. It adds no production API, engine, DSL or full lab. The existing generator tests remain the regression baseline; they do not verify domain claims. There were no existing claim test files found under `code/streeling/` by the focused test-file search.

## Loop

1. State the claim and its assumptions, source/course revision and expected observation before a new experiment. Existing unpreregistered work is labeled retrospective, never rewritten as a prospective hypothesis.
2. Independently derive a check for each course's actual authored model and its counterexample. Keep fixed expectations independent of the calculation being tested. Do not implement a checker that merely compares an expected field with itself.
3. Execute the checks and retain the complete command, interpreter, input/test hashes, exit status, stdout/stderr and concrete observed values. Test incorrect cases or mutated copies to demonstrate that the check can reject an error; do not mutate canonical data to manufacture a failure.
4. Keep real failures. Determine whether the defect is in the course, test, source interpretation or environment. Correct the relevant artifact and add a precise regression check. Retain the before/after evidence and affected hashes.
5. Replay affected checks and renew independent reviews after any changed source. Record the new result without deleting the failed attempt.
6. Root runs all final claim tests and generator tests, builds/links/checks synchronization, then records final source and test hashes in the journals before publication.

Independent reviewers own `tests/test_unit_a.py`, `tests/test_unit_b.py` or `tests/test_unit_c.py` and their corresponding review receipt after each author's source freeze. Tests read actual fixed unit data and check relevant course statements. Root owns authoritative execution and separate code review of those tests. A mathematical test proves the declared calculation or logical witness, not a real guitar, learner, material, live agent, browser renderer or production effect. Claims of such behavior require their own actual integration trial or remain explicitly unverified.

## Journal record

Each meaningful record has a question/claim, prospective hypothesis or retrospective status, actual command, pinned inputs, observed result, verdict, corrections, replay and limitations. Record authoring/source inspection as such, not as runtime tests. Never mark a course studied or a human review complete from production verification.
