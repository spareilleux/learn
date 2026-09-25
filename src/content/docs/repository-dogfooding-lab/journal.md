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
- [x] First candidate promoted or rejected from measured repository evidence

## Experiments

| Question | Hypothesis before measuring | Measured result | Verdict | Evidence |
|---|---|---|---|---|
| Can one registry generate several views without letting a score grant authority? | Deterministic rendering plus invariants can separate prioritization from promotion | 4 opportunities, 5 generated matrices, 6/6 tests passed in 0.002 s; scoring left status and authority unchanged | confirmed for the local tracer | [2026-09-20 entry](#2026-09-20--first-opportunity-matrix-tracer), [`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) |
| Can Jev reduce downstream token cost by 50% at equal quality? | A typed gate resolves enough cases to halve downstream input with zero false supports | Still unmeasured. The 13-call calibration ran live on 2026-09-23 and called no downstream model at all, so it cannot answer this | inconclusive | [2026-09-23 entry](#2026-09-23--the-live-benchmark-measures-something-other-than-its-question), [`evidence/jev-live.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/jev-live.json) |
| Does batching 12 questions over one shared state cut input tokens without changing any answer? | The offline plan predicted 79% fewer payload bytes; if tokens follow bytes the saving clears 50%, with quality untested | 2487 input tokens against 14939, 83.4% less, and the identical choice on all 12 cases: accuracy 0.9167 both ways, zero false supports, Brier 0.1657 against 0.1645, 453 ms against 4451 ms | confirmed for this corpus at n=12, one run | [2026-09-23 entry](#2026-09-23--the-live-benchmark-measures-something-other-than-its-question), [TypeSafe benchmark](../../typesafe-ai-system-one/04-token-cost-benchmark/) |
| Do the gates named "requires evidence" and "confirmed verdict" refuse a fabricated candidate? | They check evidence, so an entry with empty evidence fields and an artifact that does not exist is refused | Refused nothing: the entry reached `adopted`/`confirmed` with zero errors. The gates checked that keys were present, never that they said anything | refuted, then fixed | [2026-09-23 entry](#2026-09-23--an-adversarial-review-breaks-the-gates-of-the-lab), [`dogfood.py`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/dogfood.py) |
| Does a Petri net find concurrency defects in a repository that its own test suite misses? | Searching a reachability graph for dead markings finds at least one real defect from a read-only reading | Three found in GA at `a826864`, each confirmed line by line before filing, and one claim withdrawn before filing; reported as [ga#700](https://github.com/GuitarAlchemist/ga/issues/700), [#701](https://github.com/GuitarAlchemist/ga/issues/701), [#702](https://github.com/GuitarAlchemist/ga/issues/702) | promising — no maintainer has triaged them yet | [`petri-nets`](../../petri-nets/), [2026-09-23 entry](#2026-09-23--an-adversarial-review-breaks-the-gates-of-the-lab) |
| Can an offline Petri oracle expose a false Jev-advice-to-authority step? | Unsafe advice-only flow reaches an effect; a guarded flow needs independently verified evidence and an implementation grant | Synthetic 0.98 wrong support; 3/3 focused C# tests and 1/1 fixture-parity test pass; no real-repository replay | promising locally, not integrated | [dated entry](#jev-petri-2026-09-22), [lesson](../05-jev-petri-authority/), [`JevEvidenceGateTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs) |
| Is Jev a usable advisory annotator for Demerzel's six truth values? | ≥ 75% exact on blind-agreed synthetic cases, ≤ 1 false T, ≤ 1 absence read as refutation, in both option orders | Never a false T in 240 calls; but absence read as refutation 7/10, then 4–5/10 with an explicit rule that also pushed P into U 6/10 | inconclusive — `experimenting` | [entry](#2026-09-25--demerzel-and-jev-pre-registration-catches-what-the-model-hides), [`opportunities.json`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/opportunities.json) |

## 2026-09-20 — First opportunity-matrix tracer

Implemented `opportunities.json`, a validator and renderer with only the Python standard library. The registry contains Jev token gating, the Learn authoring method, a hexagonal seam audit and a RabbitMQ reliability boundary. The generated views separate coverage, ranking, promotion, evidence and method quality.

Commands:

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Measured result: `validated=4 matrices=current mirrors=current`; 6/6 tests passed in 0.002 s. Tests reject promoted candidates without artifacts and adoption without a confirmed verdict, and check EN/FR/ES file parity plus journal structure. No external network or repository mutation occurred.

<a id="jev-petri-2026-09-22"></a>

## 2026-09-22 — Synthetic Jev × Petri authority boundary

Predeclared hypothesis: if a high-confidence Jev classification is wired directly to an effect, a deliberately wrong `supported` result can authorize work; requiring separate verified-evidence and implementation-authority tokens blocks that path. Baseline: the pinned `gaia_design_authority` synthetic case returns wrong `supported` at 0.98 against expected `contradicted`.

The Python parity test binds the shared JSON fixture to the synthetic response. The C# Petri test replays `classify → authorize_from_advisory` in the unsafe net, then exhaustively checks the guarded net under all three combinations where at least one independent token is absent. A separate valid path remains fireable when both tokens exist. Local result: 3/3 focused C# tests and 1/1 fixture-parity test passed; `dogfood.py check` reported `validated=5 matrices=current mirrors=current` after regeneration. No provider call, paid token, production effect or exact-revision Gaia/IX replay. Verdict: promising as a specification experiment, not eligible for incubation yet.

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

## 2026-09-23 — The live benchmark measures something other than its question

The thirteen approved calls went out against `jev-1.13.0`. They returned a clean, large result, and that result does not answer the question the registry had written above it.

**What was measured.** The same twelve labeled cases, asked once as a single batch over one shared state, then twelve times one at a time over the byte-identical state:

| | Input tokens | Accuracy | False supports | Brier | Latency |
|---|---:|---:|---:|---:|---:|
| Batch, 1 call | 2487 | 0.9167 | 0 | 0.1657 | 453 ms |
| Singles, 12 calls | 14939 | 0.9167 | 0 | 0.1645 | 4451 ms |

Batching costs **83.4% fewer input tokens**, well past the 79% the offline plan predicted from payload bytes, and it changed **no answer at all**: the twelve choices agree case by case, not merely in aggregate. Zero retries, zero false supports either way, and the whole run stayed under the $0.0021 proxy ceiling.

**What was not measured, and the entry implied it was.** The registry's `next_gate` read "run the bounded 13-call calibration, then a fixed downstream A/B only if quality passes" — written as though passing the calibration bore on the hypothesis. It does not. The hypothesis is that a typed gate *cuts what a downstream expensive model is sent*. The benchmark never calls a downstream model; it calls Jev thirteen times and varies only how the questions are packed. Amortizing one shared state across twelve questions is a real and useful saving, and it is a different quantity from the one the success metric names.

So the Jev row stays **inconclusive** for its own question, and a second row records the claim that was actually tested. The opportunity moves to `incubating` on that evidence, not to `adopted`: its `next_gate` is now the downstream A/B, named as the thing the calibration does not stand in for.

**One error, and both arms made it.** `demerzel_immutable` claims an artifact is content-addressed where the evidence offers a path and a timestamp but no digest — the expected label is `insufficient`, and both the batch and the isolated call answered `contradicted`. Absence of a digest was read as conflict rather than as silence. Identical in both arms, so packing is not the cause; it is the one case out of twelve behind the 0.9167.

The full run, every request hash and every response, is committed at `code/typesafe-ai-system-one/evidence/jev-live.json` so the numbers above can be recomputed without trusting this entry.

## 2026-09-25 — Demerzel and Jev: pre-registration catches what the model hides

The eighth opportunity moved from a line in the TypeSafe course ("Demerzel — triage evidence without interpreting the constitution") to two measured runs in a day. The numbers are in the [TypeSafe journal](../../typesafe-ai-system-one/journal/#2026-09-25--demerzel-hexavalent-classification-with-jev); this entry records what the method did.

- **The rule was written before the data, and it held.** The model looked good in aggregate (41/58, 71%, zero false T), and without the pre-registered absence limit that reads as a pass with a caveat. With it, the run is INCONCLUSIVE, because the pre-registration named the failure it was looking for: absence read as refutation. It was there at 7/10.
- **Two annotators, not one.** The author's labels were checked by a second agent that never saw them. They disagreed on 2 of 60 cases (both D against U, the same boundary under test), which were excluded rather than adjudicated after the fact.
- **The second step answered a different question than hoped.** The fix was meant to show whether the fault lay in the model or in Demerzel's definitions. It showed both: the conflict sentence fixed C completely, and the absence sentence exposed an ambiguity in the definitions themselves, since P cases also lack a direct run.
- **A cheap test did more than the live run.** A unit test for "a sum of exactly 0.99 is accepted" failed before any call. It was the float-error trap that had already killed an IX arm.

Registry: `jev-demerzel-hexavalent-annotator`, `experimenting`, verdict `inconclusive`. Its next gate is a U definition with a companion clause for leaning evidence, pre-registered separately. No Demerzel file was changed: a sentence proposed for `logic/hexavalent-logic.md` needs a test on real belief files first.

## 2026-09-25 — Following an opportunity across repositories until each one answers

The user's instruction was to make sure the opportunity was implemented, verified and journaled everywhere it applied. Asking the owning sessions answered more than reading their code would have:

| Repository | Question | Answer, and who checked | Outcome |
|---|---|---|---|
| Demerzel | Does any definition change fix absence-as-refutation? | This session: three pre-registered steps plus 8 real beliefs, 376 calls, about $0.009 computed | No. The rule moves into Demerzel as a division of labour ([Demerzel PR](https://github.com/GuitarAlchemist/Demerzel/pull/1127), corrected in [#1128](https://github.com/GuitarAlchemist/Demerzel/pull/1128)) |
| Gaia | Does a model verdict on evidence drive a route? | The Gaia session, on main `8ed4dfc` | No; the invariant already holds, and the rule for future steps is filed as [gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159) |
| IX | Does Jev touch hexavalent values, and is the 0.99 trap live? | The IX session, by grep of `crates/` | No, and no: tolerance is 1e-3 |

The method lesson: an opportunity is not "adopted" because one repository measured it. Here the honest outcome is one rule written down (Demerzel), one guard filed for a seam that does not exist yet (Gaia), and one explicit non-use (IX). The registry entry stays `experimenting`/`inconclusive`: the rule it produced is a boundary that keeps the model out, not an adoption of the model.

## To verify

- Merge the division-of-labour rule into Demerzel ([Demerzel#1127](https://github.com/GuitarAlchemist/Demerzel/pull/1127)); revisit Jev on evidence only when a repository builds a model-on-evidence seam ([gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159)).
- Confirm the first hosted CI run for matrices, locale parity and journal structure.
- Measure authoring lead time before claiming the new method is cheaper. No baseline value exists, so the current success metric of `learn-evidence-first-course-method` cannot be refuted as written.
- Read the five `ga.*` TARS rule bodies, not only their weights, before claiming the two encodings agree or disagree.
- Have the maintainer triage ga#700, #701 and #702; the automated agent failed on all five issues, so none has been judged.
- Run the fixed downstream A/B before any claim that Jev cuts downstream cost. The live calibration called no downstream model, and n=12 on one corpus in one run supports no general figure.
- Map the guarded net to an exact-revision public Gaia or IX seam and replay the unsafe witness; compare with one simpler deterministic guard test.
- Select one exact hexagonal seam from current repository evidence or reject that opportunity.

## Open questions

- Which metrics best predict that a course discovery will survive repository integration?
- Should opportunity ownership and merge authority always be separate fields?
- When should a rejected candidate be revisited instead of retired permanently?
