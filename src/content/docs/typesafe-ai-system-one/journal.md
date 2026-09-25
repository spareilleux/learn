---
title: Journal
description: "Dated evidence for the TypeSafe AI System One and Jev course: official facts checked, the deterministic mock experiment, live measurements still absent, and repository hypotheses still awaiting labeled corpora."
sidebar:
  order: 99
---

## Progress

- [x] Official TypeSafe introduction, primitives, model, pricing, confidence, API and pattern pages reviewed
- [x] Offline request, response-contract validator and authority-safe routing policy implemented
- [x] Mock runner, 12-case benchmark corpus and 19 deterministic tests run locally
- [x] Detailed one-call live protocol written with budget and stop conditions
- [x] Bounded hypotheses for Gaia, GA, Demerzel, IX and TARS
- [x] French and Spanish mirrors
- [ ] Live Jev call
- [x] Labeled repository corpus and offline scoring harness
- [x] Shared-state batching plan corrected; offline confidence-gate stress fixture and 23 tests run
- [ ] Live calibration study

## Experiments

| Question | Hypothesis before measuring | Measured result | Verdict | Evidence |
|---|---|---|---|---|
| Can the policy fail closed without a provider? | A closed mock response can exercise validation and refuse dispatch when authority is absent | 14/14 tests passed in 0.078 s; route was `human_review:no_explicit_authority` | confirmed for the local policy only | [2026-09-20 entry](#2026-09-20--offline-baseline), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| Can a bounded harness test the 50% token-saving hypothesis before spending? | A fixed corpus and exact call plan can expose cost, quality and retry guardrails without contacting Jev | Historical plan: 12 cases, 13 calls, 17,663 UTF-8 bytes, 19/19 tests; it mislabeled bytes as tokens and changed state between arms | invalidated as a token/cost bound; [corrected below](#2026-09-22--batching-protocol-correction-and-gate-stress-test) | [2026-09-20 entry](#2026-09-20--token-cost-benchmark-harness), [lesson 4](../04-token-cost-benchmark/) |
| Can a confidence threshold alone prevent false support? | A deliberately wrong high-confidence support should still pass a threshold while lower thresholds trade review load for coverage | Synthetic fixture: at 0.95, 1/12 passes and it is false; corrected 13-call plan totals 46,318 request bytes; 23/23 tests in 0.086 s | refuted for confidence-only gating; no Jev quality or billed cost measured | [2026-09-22 entry](#2026-09-22--batching-protocol-correction-and-gate-stress-test), [lesson 5](../05-confidence-gate-stress/) |
| Can Jev classify Demerzel evidence into T/P/U/D/F/C and keep absence apart from refutation? | Pre-registered: ADVISORY_USEFUL needs ≥ 75% exact, ≤ 1 false T, ≤ 1 absence read as F/D | Step 1: 41/58, 0 false T, 7/10 absences read as F/D. Step 2 (explicit U and C text): 46/58 and 44/58, conflicts 10/10, absences 4–5/10, but P fell into U 6/10 | INCONCLUSIVE, then NOT_FIXED | [entry](#2026-09-25--demerzel-hexavalent-classification-with-jev), [pre-registration](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-hexavalent-PREREG.md) |

## 2026-09-20 — Official-source review

- Jev 1.13 is listed as `jev-1.13.0`; `jev-latest` is a moving stable alias.
- Published price: $0.042 per million input tokens; output tokens free. This is a point-in-time fact, not a promise.
- Published limits: 64k total context, 32k for state plus the longest question, text-only input, 250,000 tokens/s and 1,200 requests/minute. TypeSafe says rate limits may change without notice.
- Choice and Score return probabilities and confidence; Noul returns a 0–1 value without a separate confidence field.
- No claim from the launch post was treated as a measurement on our repositories.

## 2026-09-20 — Offline baseline

Environment: Windows 11, Python 3.14.2. Commands:

```text
python typesafe_lab.py mock
python -W error::ResourceWarning -m unittest -v
```

Measured: request digest `67c1ee4bcd36b497f60872c0715d435b364c3b7743ad06f9be543071af044a1b`; decision `human_review:no_explicit_authority`; 14 tests passed in 0.078 s. No external network request occurred; one hermetic loopback test proved redirects stop before the bearer token reaches a second origin. The fixture identifies itself as `mock-jev-course/1`, not as Jev.

## 2026-09-20 — Token-cost benchmark harness

Added 12 sanitized GA, Gaia and Demerzel cases, including a prompt-injection counterexample. The historical `plan` reported 13 calls, zero retries, 17,663 UTF-8 request bytes incorrectly labeled a token upper bound, a $0.000741846 byte-based cost proxy incorrectly labeled a cost upper bound, and a $0.0021 local proxy ceiling incorrectly labeled hard. The combined suite passed 19/19 tests in 0.078 s. These labels and the batching design were corrected on 2026-09-22.

The mock scorer produced perfect fixture accuracy, Brier 0.015 and a 2.4 single-to-batch input ratio. Those numbers validate the scorer only: the fixture is `mock-jev-benchmark/1`, no provider was called, and none of them is a Jev result.

## 2026-09-22 — Batching protocol correction and gate stress test

Primary-source review found that the old batch and singleton requests had different state sizes, so their ratio could not isolate batching. The corrected plan holds the same 12-case state in every request: 8,034 UTF-8 bytes for the batch, 38,284 for 12 single-question requests, 46,318 total. At the reviewed rate this is a $0.001945356 **byte-based proxy**, not a guaranteed provider bill. The old mock 2.4 ratio was arbitrary fixture data and has been removed from the current output.

Pre-registered hypothesis: a high confidence threshold alone will not prevent a false `supported`. The deliberately wrong synthetic fixture confirms this gate limitation: at 0.95, 1/12 passes and it is false; at 0.99, none pass and all 12 require review. Commands `python jev_benchmark.py plan`, `python jev_gate_audit.py synthetic`, and `python -W error::ResourceWarning -m unittest -v` completed locally; 23/23 tests passed in 0.086 s. No API key was read, no Jev request was sent and no actual token saving was measured. See the [primary-source addendum](https://github.com/spareilleux/learn/blob/main/docs/research/2026-09-22-jev-experiment-design-primary-sources.md).

## 2026-09-22 — Python 3.10 to 3.14, offline

Hypothesis before running: the offline suite uses only the standard library, so it passes unchanged from Python 3.10 to 3.14. Command, on a fresh export of `code/typesafe-ai-system-one` at `b3a9c16`, one interpreter at a time through uv 0.10.4: `uv run --no-project --python <v> python -W error::ResourceWarning -m unittest`. Result on Windows 11: 23/23 tests pass on 3.10.19, 3.11.14, 3.12.12, 3.13.12 and 3.14.3, in 0.104 to 0.132 s. The hosted CI for the same commit ([run 35804194871](https://github.com/spareilleux/learn/actions/runs/35804194871)) passes on Ubuntu, Windows and macOS with Python 3.14. Verdict: confirmed for the offline suite; CI still tests 3.14 only. No API key was read and no provider was called: the live call and the 13-call calibration still wait for the operator's `TYPESAFE_API_KEY` and an explicit approval of the ceiling, which are human decisions.

## 2026-09-25 — Demerzel hexavalent classification with Jev

Question, pre-registered in [`demerzel-hexavalent-PREREG.md`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-hexavalent-PREREG.md) and committed before the first call: given only Demerzel's own one-line definitions from `logic/hexavalent-logic.md`, does `jev-1.13.0` classify governance evidence into True, Probable, Unknown, Doubtful, False or Contradictory, and does it keep *absence of evidence* (U) apart from *refutation* (F/D)? That second half is the `demerzel_immutable` error of 2026-09-22.

Corpus: 60 synthetic cases, 10 per value, written by one agent under an explicit standard and labeled blind by a second. They agree on 58; h39 and h57 (D against U) are excluded from scoring. No label word appears in any evidence, and three cases carry a prompt injection. Two arms per step: canonical option order and reversed. One call per case, no retries, a stop at $0.05 of reported input.

| N = 58 | Keyword baseline | Step 1: Demerzel text | Step 2: explicit U and C |
|---|---:|---:|---:|
| Exact (canonical / reversed) | 12 | 41 / 41 | 46 / 44 |
| False T | 5 | 0 / 0 | 0 / 0 |
| Absence read as F/D (of 10 U) | 0 | **7 / 7** | 4 / 5 |
| Conflict resolved to one side (of 10 C) | — | 4 / 4 | **0 / 0** |
| Non-U read as U | — | 5 / 4 | 7 / 8 |
| Computed cost (not billed) | — | $0.0027 | $0.0030 |

240/240 answers were valid, all `jev-1.13.0`; mean latency 372–392 ms. Verdicts, by the pre-registered rules: step 1 **INCONCLUSIVE** (above the kill line, zero false T, but under 75% and far over the absence limit); step 2 **NOT_FIXED** (worse arm still 5/10).

What it shows:

- **The errors run down the lattice, never up.** No false T in 240 calls, and none of the injections produced a T.
- **Absence becomes refutation, systematically.** In step 1 the seven U errors are identical in both option orders. Spelling out "absence is Unknown, not evidence against" halves them and no more: h02, h29 and h41 stay wrong in both orders, and h36 and h48 now flip with option order.
- **The conflict sentence works completely.** "At least two strong, direct records point opposite ways; do not resolve such a conflict by picking a side" took C from 6/10 to 10/10 in both orders.
- **The absence sentence creates a new error.** P falls into U 6/10 (from 3): the P cases are "no direct run, but indirect evidence leans true", which the new U text also describes. The ambiguity is in the definitions, not only in the model.

A test caught a bug before any call: with a tolerance of 0.01, a two-decimal sum of exactly 0.99 was still rejected, because float error puts the gap just above 0.01. That is the trap that failed the French arm of [ix#355](https://github.com/GuitarAlchemist/ix/pull/355); the harness now adds an epsilon. Receipts: [step 1](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/demerzel-hexavalent-live.json), [step 2](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/demerzel-hexavalent-step2-live.json); `python demerzel_hexavalent.py score --out <receipt>` recomputes each verdict. Running total against the $1 operator cap: about $0.027 computed.

## To verify

- Re-run Demerzel hexavalent with a U definition that yields to leaning evidence (P or D), pre-registered, and test the conflict sentence on real Demerzel belief files before proposing it upstream.
- Run exactly one live call after the operator exports `TYPESAFE_API_KEY`; record concrete model, usage, cost and latency without recording the secret.
- Confirm the response schema against the live service and decide whether the validator should adopt an official JSON Schema.
- Run the 13-call live calibration only after explicit approval of the $0.0021 ceiling.
- Measure accuracy, calibration, abstention/human-review rate, cost and latency against a deterministic baseline.
- Recheck price, model IDs and limits immediately before a live run.

## Open questions

- Which repository has enough historical labeled decisions to support a useful first calibration study?
- Should the shared adapter expose confidence, full probabilities, or both while preventing callers from treating either as authority?
- What data-redaction contract is required before repository artifacts can be sent to an external provider?
