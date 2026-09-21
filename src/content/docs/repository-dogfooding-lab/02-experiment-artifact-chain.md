---
title: Experiment and artifact chain
description: Build a replayable chain from repository observation to bounded experiment, independent review and durable verdict.
sidebar:
  order: 2
---

An experiment is useful when another person or agent can determine exactly what happened without trusting the author.

## Minimum chain

| Artifact | Required content |
|---|---|
| Observation | Concrete repository pain, pinned source or measured symptom |
| Hypothesis | Directional, falsifiable claim written before measurement |
| Baseline | Current quality, cost, latency or change surface |
| Protocol | Fixed corpus/workload, exact commands, limits and stop conditions |
| Raw evidence | Outputs, usage, hashes and environment; secrets excluded |
| Verdict | Confirmed, refuted or inconclusive against predeclared criteria |
| Promotion receipt | Accountable authority, exact evidence and next reversible step |

## Classical and agentic metrics

For classical software engineering, prefer defect rate, changed-file surface, deterministic test setup, p50/p95 latency, recovery time and operational burden.

For agentic systems, add accepted-result quality, false positives, calibration, escalation, retries, provider-specific input/cached/output tokens and dollars. Do not sum token counts from unlike tokenizers and call the total a saving.

## Independent refutation

The reviewer tries to invalidate the conclusion: leakage in the corpus, a cheaper deterministic alternative, shifted human cost, missing failure cases, or an artifact that does not match the tested revision.

<details>
<summary>Exercise: define a 50% token-saving experiment</summary>

Fix one corpus and downstream model. Compare calling it on every case with calling it only after a Jev gate. Keep the quality gate identical. Reject the hypothesis on any false authority-sensitive support, or when retries and human review erase the dollar saving.

</details>
