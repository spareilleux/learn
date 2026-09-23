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

## To verify

- Run exactly one live call after the operator exports `TYPESAFE_API_KEY`; record concrete model, usage, cost and latency without recording the secret.
- Confirm the response schema against the live service and decide whether the validator should adopt an official JSON Schema.
- Run the 13-call live calibration only after explicit approval of the $0.0021 ceiling.
- Measure accuracy, calibration, abstention/human-review rate, cost and latency against a deterministic baseline.
- Recheck price, model IDs and limits immediately before a live run.
- Verify Python 3.10–3.13 and Linux/macOS execution in CI.

## Open questions

- Which repository has enough historical labeled decisions to support a useful first calibration study?
- Should the shared adapter expose confidence, full probabilities, or both while preventing callers from treating either as authority?
- What data-redaction contract is required before repository artifacts can be sent to an external provider?
