---
title: Opportunity matrices
description: Use several small matrices to expose coverage, value, evidence and promotion without hiding uncertainty in one score.
sidebar:
  order: 1
---

One giant ranking conceals too much. This lab keeps five views because they answer different questions. The current values are published in the generated [`matrices.md`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/matrices.md); `python dogfood.py check` fails if that artifact drifts from the JSON registry.

## 1. Course × repository coverage

This view finds both transfer opportunities and blind spots. A technique may fit several repositories, but that does not mean every repository should adopt it.

## 2. Opportunity score

The score adds pain, fit, expected value, evidence and reversibility, then subtracts cost and risk. Every dimension is 0–5. It orders investigation only.

Two safeguards are essential:

- the score cannot change `status` or `authority`;
- a high score with weak evidence remains discovery, not incubation.

## 3. Promotion state

The state machine is deliberately explicit:

```text
discovered → experimenting → incubating → integrating → adopted
       └──────────────→ rejected                         → retired
```

Promoted states require evidence artifacts. `adopted` additionally requires a confirmed verdict. Rejected candidates remain in the registry so another agent does not repeat the same failed idea.

## 4. Results and evidence

This view answers: what was actually measured, where is the artifact, and when should the conclusion be revisited? A running agent, comment, label or plausible narrative is not evidence.

## 5. Course-method quality

The method itself is dogfood. The matrix tracks executable examples, journal evidence, locale parity, adoption feedback and agentic efficiency.

<details>
<summary>Exercise: add a candidate without overstating it</summary>

Add an opportunity with a real observed pain, a simpler alternative and a falsifier. Keep it `discovered` until a baseline exists. Run `python dogfood.py write` and `python -m unittest -v`.

</details>
