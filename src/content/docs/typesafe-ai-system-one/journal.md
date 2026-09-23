---
title: Journal
description: "Dated TypeSafe AI and Jev evidence: offline controls, small live synthetic pilots, and remaining repository-calibration gaps."
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
- [x] Small live Jev calls on synthetic corpora; not repository calibration
- [x] Labeled repository corpus and offline scoring harness
- [x] Shared-state batching plan corrected; offline confidence-gate stress fixture and 23 tests run
- [ ] Live calibration study
- [x] Offline deterministic negative control for structured Gaia evidence

## Experiments

| Question | Hypothesis before measuring | Measured result | Verdict | Evidence |
|---|---|---|---|---|
| Can the policy fail closed without a provider? | A closed mock response can exercise validation and refuse dispatch when authority is absent | 14/14 tests passed in 0.078 s; route was `human_review:no_explicit_authority` | confirmed for the local policy only | [2026-09-20 entry](#2026-09-20--offline-baseline), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| Can a bounded harness test the 50% token-saving hypothesis before spending? | A fixed corpus and exact call plan can expose cost, quality and retry guardrails without contacting Jev | Historical plan: 12 cases, 13 calls, 17,663 UTF-8 bytes, 19/19 tests; it mislabeled bytes as tokens and changed state between arms | invalidated as a token/cost bound; [corrected below](#2026-09-22--batching-protocol-correction-and-gate-stress-test) | [2026-09-20 entry](#2026-09-20--token-cost-benchmark-harness), [lesson 4](../04-token-cost-benchmark/) |
| Can a confidence threshold alone prevent false support? | A deliberately wrong high-confidence support should still pass a threshold while lower thresholds trade review load for coverage | Synthetic fixture: at 0.95, 1/12 passes and it is false; corrected 13-call plan totals 46,318 request bytes; 23/23 tests in 0.086 s | refuted for confidence-only gating; no Jev quality or billed cost measured | [2026-09-22 entry](#2026-09-22--batching-protocol-correction-and-gate-stress-test), [lesson 5](../05-confidence-gate-stress/) |
| Does identical-state batching reduce Jev input on the fixed 12-case synthetic corpus? | A shared state should be cheaper than repeating it for each question without changing labels | Batch and 12 singleton calls each got 11/12 labels; 2,487 vs 14,939 input tokens, a measured 83.4% reduction in provider input for this comparison only | promising for this synthetic workload; not a whole-workflow saving | [live pilot below](#2026-09-22--live-batching-pilot) |
| Does an explicit absence-versus-conflict rule improve Jev's labels? | Explicitly treating missing evidence as insufficient will correct at least one baseline mistake | Exploratory nine-case corpus: generic 8/9, explicit 9/9 and exact repeat 9/9; explicit prompt added 702 input tokens (36.5%) per batch | preliminary; corpus prepared after the earlier error, not held out | [challenge below](#2026-09-22--live-absence-versus-conflict-challenge) |
| Does structured Gaia publication evidence need Jev for equality checks? | A deterministic rule should classify all nine source-derived fixture scenarios without a model call | 9/9 fixture labels; three offline tests passed; zero provider calls | confirmed only for deliberately simple, synthetic structured comparisons | [negative control below](#2026-09-23--structured-gaia-evidence-negative-control) |

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

The preceding Python entry describes the state at that moment; the live calls below happened later and supersede its pending-call statement.

## 2026-09-22 — Live batching pilot

On the fixed 12-case synthetic corpus, the same state was sent once with 12 questions and then repeated in 12 single-question calls. Jev returned 11/12 correct labels in each arm, with no false `supported` labels. Provider usage reported 2,487 input tokens for the batch versus 14,939 for the singleton arm (83.4% less batch input); multiclass Brier scores were 0.1505 and 0.1452, respectively. The persistent mistake was to call missing digest/revision evidence `contradicted` rather than `insufficient`. Two batch repeats and reversed choice order preserved the labels. Across the 17 captured calls, reported input was 25,236 tokens, or an estimated $0.001059912 at the [published input rate](https://docs.typesafe.ai/models); posted billing was not checked. No repository decision, authority transfer, or full workflow cost saving was measured.

## 2026-09-22 — Live absence-versus-conflict challenge

After seeing the above error, we prepared a **new but not untouched held-out** [nine-case synthetic corpus](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/absence-vs-conflict-corpus.json): three missing-evidence, three contradicting-evidence and three supported cases. Before the calls, we hypothesized that an explicit rule would fix at least one label without losing other correct labels. With `jev-latest` resolving to `jev-1.13.0`, the generic prompt scored 8/9, zero false supports, Brier 0.103067, and 1,921 reported input tokens. The explicit rule scored 9/9, zero false supports, Brier 0.005356, and 2,623 input tokens; an exact repeat scored 9/9, Brier 0.006067, and 2,623 input tokens. The repaired case was `missing_receipt_sha` (`contradicted` → `insufficient`). The three captured calls used 7,167 input tokens, estimated $0.000301014 at the published rate. This is exploratory prompt development, not calibration or proof of generalization; the extra 702 tokens per batch may erase savings elsewhere. The model remains advisory and cannot authorize effects.

## 2026-09-23 — Structured Gaia evidence negative control

Before running, we specified the rule: a known mismatch is `contradicted`; otherwise a missing required observation is `insufficient`; otherwise all matching checks are `supported`. Nine sanitized scenarios were derived from Gaia's pinned `validateObservation`, `validateAuthorization`, and `validatePullRequest` seams at `c94df3f5a53cd9f472e8a97b656dc23d7c940389`. The [corpus](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/gaia-structured-evidence-corpus.json) contains three scenarios per class and no production receipt. The [offline baseline](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/test_gaia_structured_evidence.py) classified 9/9 labels; its three tests passed. A mixed missing-and-mismatched case confirms that a known conflict takes precedence. No Jev request or external effect occurred. This is a designed fixture, so 9/9 does not estimate field accuracy or model superiority. **Decision:** keep these structured comparisons in deterministic validation; reserve Jev experiments for genuinely semantic, ambiguous evidence, with no authority over effects.

## To verify

- Check posted provider billing against the token-based estimates; do not equate published rates with an observed invoice.
- Confirm the response schema against the live service and decide whether the validator should adopt an official JSON Schema.
- Run a preregistered, untouched labeled repository corpus with redaction, baseline, latency and end-to-end cost measurements.
- Recheck price, model IDs and limits immediately before a live run.

## Open questions

- Which repository has enough historical labeled decisions to support a useful first calibration study?
- Should the shared adapter expose confidence, full probabilities, or both while preventing callers from treating either as authority?
- What data-redaction contract is required before repository artifacts can be sent to an external provider?
