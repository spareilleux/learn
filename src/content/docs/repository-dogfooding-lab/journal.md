---
title: Journal
description: Detailed evidence for the repository dogfooding lab, including its own method, opportunity matrices and promotion decisions.
sidebar:
  order: 99
---

## Progress

- [x] Machine-readable registry and deterministic renderer
- [x] Five generated matrices
- [x] Promotion invariants and stale-output test
- [x] First classical and agentic opportunities recorded
- [x] Course method included as its own dogfooding candidate
- [x] CI locale-parity and journal-structure checks
- [ ] First independent opportunity review
- [ ] First candidate promoted or rejected from measured repository evidence

## Experiments

| Question | Hypothesis before measuring | Measured result | Verdict | Evidence |
|---|---|---|---|---|
| Can one registry generate several views without letting a score grant authority? | Deterministic rendering plus invariants can separate prioritization from promotion | 4 opportunities, 5 generated matrices, 6/6 tests passed in 0.002 s; scoring left status and authority unchanged | confirmed for the local tracer | [2026-09-20 entry](#2026-09-20--first-opportunity-matrix-tracer), [`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) |
| Can Jev reduce downstream token cost by 50% at equal quality? | A typed gate resolves enough cases to halve downstream input with zero false supports | Offline plan only: 12 cases, 13 calls, zero retries, $0.0021 hard ceiling; no live result | inconclusive | [TypeSafe benchmark](../../typesafe-ai-system-one/04-token-cost-benchmark/) |
| Do the gates named "requires evidence" and "confirmed verdict" refuse a fabricated candidate? | They check evidence, so an entry with empty evidence fields and an artifact that does not exist is refused | Refused nothing: the entry reached `adopted`/`confirmed` with zero errors. The gates checked that keys were present, never that they said anything | refuted, then fixed | [2026-09-23 entry](#2026-09-23--an-adversarial-review-breaks-the-gates-of-the-lab), [`dogfood.py`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/dogfood.py) |
| Does a Petri net find concurrency defects in a repository that its own test suite misses? | Searching a reachability graph for dead markings finds at least one real defect from a read-only reading | Three found in GA at `a826864`, each confirmed line by line before filing, and one claim withdrawn before filing; reported as [ga#700](https://github.com/GuitarAlchemist/ga/issues/700), [#701](https://github.com/GuitarAlchemist/ga/issues/701), [#702](https://github.com/GuitarAlchemist/ga/issues/702) | promising — no maintainer has triaged them yet | [`petri-nets`](../../petri-nets/), [2026-09-23 entry](#2026-09-23--an-adversarial-review-breaks-the-gates-of-the-lab) |

## 2026-09-20 — First opportunity-matrix tracer

Implemented `opportunities.json`, a validator and renderer with only the Python standard library. The registry contains Jev token gating, the Learn authoring method, a hexagonal seam audit and a RabbitMQ reliability boundary. The generated views separate coverage, ranking, promotion, evidence and method quality.

Commands:

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Measured result: `validated=4 matrices=current mirrors=current`; 6/6 tests passed in 0.002 s. Tests reject promoted candidates without artifacts and adoption without a confirmed verdict, and check EN/FR/ES file parity plus journal structure. No external network or repository mutation occurred.

## 2026-09-23 — An adversarial review breaks the gates of the lab

A different model reviewed the schema and the scores, with one instruction: break them. It did, twice, and both exploits are now regression fixtures in `test_dogfood.py`.

**The gates checked presence, not evidence.** This entry validated with zero errors before today:

```json
{ "id": "malicious-fabricated-adoption", "status": "adopted", "verdict": "confirmed",
  "artifacts": ["does-not-exist.txt"],
  "baseline": "", "success_metric": "", "falsifier": "", "result": "", "authority": "" }
```

A candidate with no evidence, no result and an artifact that is not on disk reached `adopted`. `artifacts` only had to be a non-empty list; `verdict` only had to be the string `confirmed`; no other field was checked for content at all. The names of those gates promised a semantic check that the code never performed — against lesson 2, which asks that a reader judge an experiment *without trusting the author*.

**A rejection could prove nothing.** `rejected` was left out of the artifact requirement, so a candidate could be dismissed with no evidence and no result — against lesson 1, which keeps rejections precisely so nobody repeats the idea.

**What changed.** Every string field must now be non-blank; every artifact path must exist on disk, links being taken on trust; `rejected` joins the states that require evidence, and needs a refuted or inconclusive verdict; a promoted candidate needs at least one artifact in this repository, not links alone. The promotion and result tables are now ordered by promotion state rather than by score: the reviewer found no path from score to status in the data, but a table that always shows the best-scored row first exercises the same authority on the reader's attention.

The earlier test named "score does not mutate authority" asserted that a pure sum did not mutate its argument — true by construction, and so evidence of nothing. It now checks the rendered promotion table instead.

Measured result: `validated=6 matrices=current mirrors=current`, 9/9 tests in 0.004 s. Two candidates were added: the Petri-net technique that produced [ga#700–#702](https://github.com/GuitarAlchemist/ga/issues/700), at `incubating`/`promising`, and a cross-check between GA's Petri nets and the five `ga.*` rules of the TARS grammar ecosystem, at `discovered`.

**One thing the review found that is not fixed here.** The opportunity describing this course is the least falsifiable of the registry: its success metric is "authoring lead time no worse than baseline", and no baseline lead time is recorded anywhere. A criterion whose reference was never measured cannot be refuted. It stays in *To verify* rather than being quietly reworded.

**And the candidate added today passed the old gates.** Its `incubating` status was granted by a check that would equally have stamped the fabricated entry above. What it rests on is the line-by-line verification against GA's source, not the approval of this registry — which is the argument for hardening the gates before trusting any of them, including our own.

## To verify

- Confirm the first hosted CI run for matrices, locale parity and journal structure.
- Measure authoring lead time before claiming the new method is cheaper. No baseline value exists, so the current success metric of `learn-evidence-first-course-method` cannot be refuted as written.
- Read the five `ga.*` TARS rule bodies, not only their weights, before claiming the two encodings agree or disagree.
- Have the maintainer triage ga#700, #701 and #702; the automated agent failed on all five issues, so none has been judged.
- Complete the bounded Jev calibration only with explicit spend approval.
- Select one exact hexagonal seam from current repository evidence or reject that opportunity.

## Open questions

- Which metrics best predict that a course discovery will survive repository integration?
- Should opportunity ownership and merge authority always be separate fields?
- When should a rejected candidate be revisited instead of retired permanently?
