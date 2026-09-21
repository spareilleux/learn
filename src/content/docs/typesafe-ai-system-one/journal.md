---
title: Journal
description: "Dated evidence for the TypeSafe AI System One and Jev course: official facts checked, the deterministic mock experiment, live measurements still absent, and repository hypotheses still awaiting labeled corpora."
sidebar:
  order: 99
---

## Progress

- [x] Official TypeSafe introduction, primitives, model, pricing, confidence, API and pattern pages reviewed
- [x] Offline request, response-contract validator and authority-safe routing policy implemented
- [x] Mock runner and four deterministic tests run locally
- [x] Detailed one-call live protocol written with budget and stop conditions
- [x] Bounded hypotheses for Gaia, GA, Demerzel, IX and TARS
- [x] French and Spanish mirrors
- [ ] Live Jev call
- [ ] Labeled repository corpus and calibration study

## Experiments

| Question | Hypothesis before measuring | Measured result | Verdict | Evidence |
|---|---|---|---|---|
| Can the policy fail closed without a provider? | A closed mock response can exercise validation and refuse dispatch when authority is absent | 14/14 tests passed in 0.078 s; route was `human_review:no_explicit_authority` | confirmed for the local policy only | [2026-09-20 entry](#2026-09-20--offline-baseline), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |

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

## To verify

- Run exactly one live call after the operator exports `TYPESAFE_API_KEY`; record concrete model, usage, cost and latency without recording the secret.
- Confirm the response schema against the live service and decide whether the validator should adopt an official JSON Schema.
- Build a labeled corpus for one repository use case before changing any production path.
- Measure accuracy, calibration, abstention/human-review rate, cost and latency against a deterministic baseline.
- Recheck price, model IDs and limits immediately before a live run.
- Verify Python 3.10–3.13 and Linux/macOS execution in CI.

## Open questions

- Which repository has enough historical labeled decisions to support a useful first calibration study?
- Should the shared adapter expose confidence, full probabilities, or both while preventing callers from treating either as authority?
- What data-redaction contract is required before repository artifacts can be sent to an external provider?
