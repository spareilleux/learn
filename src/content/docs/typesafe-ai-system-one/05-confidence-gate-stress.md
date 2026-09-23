---
title: "Confidence-gate stress test: when to abstain"
description: Replay a deliberately wrong synthetic response to measure false support, review load and the limits of a confidence-only gate.
sidebar:
  order: 5
---

This experiment is **offline and synthetic**. It tests our gate, not Jev's accuracy. Two labels are deliberately changed to wrong `supported` answers, one at confidence 0.98. No repository action is authorized.

## Question and pre-registered hypothesis

> Can a confidence threshold alone prevent a false `supported` result while preserving useful coverage?

We expect **no**: raising the threshold should reduce coverage, but a confidently wrong answer can still pass. [TypeSafe's confidence documentation](https://docs.typesafe.ai/confidence) describes confidence as model output, not proof. [Jev 1.13 jaggedness](https://docs.typesafe.ai/model-jaggedness/jev-1.13) lists indirection, irrelevant state and prompt injection among the cases that deserve separate tests.

## Run the stress fixture

From `code/typesafe-ai-system-one/`:

```text
python jev_gate_audit.py synthetic
python -W error::ResourceWarning -m unittest -v
```

The measured local fixture yielded:

| Threshold | Would pass a confidence-only `supported` gate | False supports | Sent to review |
|---:|---:|---:|---:|
| 0.50 | 6 | 2 | 6 |
| 0.90 | 5 | 1 | 7 |
| 0.95 | 1 | 1 | 11 |
| 0.99 | 0 | 0 | 12 |

At 0.95, the **only** passing item is wrong. A threshold can trade review load for coverage; it cannot establish truth or grant merge, deployment or implementation authority. The script always reports `authority_granted: false` and `provider_called: false`.

## Reuse a completed live receipt, without another call

Only after a separately authorized benchmark has produced a complete local receipt:

```text
python jev_gate_audit.py record --input evidence/jev-live.json
```

The audit rejects incomplete receipts and request digests that do not match the current pinned corpus. It prints aggregate metrics only. No live receipt or key belongs in Git. A real model's threshold must be chosen on a held-out set; tuning it against these 12 labels would overfit.

## Exercise

For a deployment-sensitive route, is a 0.99 threshold enough to turn a Jev `supported` answer into permission to deploy? Explain the evidence and authority boundaries.

<details>
<summary>Solution</summary>

No. This fixture merely sends all 12 items to review at 0.99; it proves nothing about unseen model answers. A model score is evidence to consider, while a separate deterministic authorization check controls the effect. A false support above any fixed threshold remains possible.

</details>

## Next falsifier

A separately approved quality pilot should compare the same question over per-case state and shared 12-case state, with exact model, actual usage, false-support count, latency and multilingual slices. The pure batching cost comparison must hold state identical in both arms, as the [official parallel-questions example](https://docs.typesafe.ai/cookbooks/parallel_questions) does. The [research note](https://github.com/spareilleux/learn/blob/main/docs/research/2026-09-22-jev-experiment-design-primary-sources.md) records the full protocol. None of those provider results has been measured here.
