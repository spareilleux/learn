---
title: "Token-cost benchmark: batch, gate, and reject"
description: Measure whether Jev reduces expensive-provider work without hiding quality loss, retries, or shifted cost.
sidebar:
  order: 4
---

A lower token count is useful only when the task still succeeds. This lesson therefore measures **cost per accepted result**, not an impressive-looking raw-token percentage.

## The hypothesis

> On a fixed labeled corpus, a typed Jev decision can cut expensive-provider input by at least 50% while preserving the acceptance criteria and producing no false `supported` decision.

This is a hypothesis, not a product claim. It is rejected if quality drops, human-review load rises enough to erase the saving, or work merely moves to another provider.

## The corpus and three modes

[`benchmark-corpus.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/benchmark-corpus.json) contains 12 sanitized GA, Gaia and Demerzel cases labeled `supported`, `contradicted`, or `insufficient`. One case contains a prompt-injection attempt and must remain evidence, never instruction.

```text
python jev_benchmark.py plan
python jev_benchmark.py mock
python -W error::ResourceWarning -m unittest -v
```

- `plan` performs no network call and prints the exact call count and a request-byte cost proxy.
- `mock` validates scoring with a fixture that explicitly identifies itself as non-Jev.
- `live` is a separately authorized experiment: one batch plus 12 single-question calls over the **same 12-case state**, pinned to `jev-1.13.0`, with zero retries. Holding state constant isolates batching; a per-case-state quality experiment remains separate.

The corrected local plan measured 13 calls: 8,034 UTF-8 bytes for the batch and 38,284 for the single-question requests, 46,318 bytes total. Multiplying that byte count by the rate checked on 2026-09-22 gives a **$0.001945356 cost proxy**, below the local $0.0021 proxy limit. Bytes are not reported/billed tokens, and server-side framing is unknown: **this does not guarantee an actual dollar ceiling**. Verify account-level spending controls and obtain separate approval before any live run.

## Compare categories, not unlike tokenizers

| Metric | Why it matters |
|---|---|
| Jev input and output tokens | Direct Jev usage and cost |
| Downstream provider input, cached input and output | Work Jev may avoid or add |
| Accepted-result count | Denominator for real efficiency |
| False support and calibration | Guardrails against cheap wrong answers |
| Human reviews, retries, p50 and p95 latency | Shifted operational cost |

The primary result is dollars per accepted result under the same quality gate. A 50% token reduction with one false support is a failure for an authority-sensitive route.

## Live A/B protocol

The live path requires both `TYPESAFE_API_KEY` and `JEV_BENCHMARK_APPROVED=YES`. It reserves its evidence file before the first call and updates it after every response, so interruption cannot erase consumed work. It never retries automatically. Its local proxy guard is **not** a provider-side spending cap.

```text
python jev_benchmark.py live --out evidence/jev-live.json
```

The next experiment, if this calibration passes, is a downstream gate: compare a fixed expensive model on every case against the same model invoked only when Jev does not safely resolve the case. That is where a real 50% saving can be confirmed or refuted.

Before making any paid call, try the [offline confidence-gate stress test](../05-confidence-gate-stress/): it demonstrates why a high score alone cannot be treated as authority.

## Primary sources

- [Jev models and current pricing](https://docs.typesafe.ai/models)
- [Parallel questions](https://docs.typesafe.ai/cookbooks/parallel_questions)
- [Jev 1.13 jaggedness](https://docs.typesafe.ai/model-jaggedness/jev-1.13)
- [Software-development cascade](https://docs.typesafe.ai/cookbooks/sde_cascade)
- [OpenAI token usage categories](https://platform.openai.com/docs/api-reference/responses/object#responses/object-usage)
- [Anthropic prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
