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
| Can Jev reduce downstream token cost by 50% at equal quality? | A typed gate resolves enough cases to halve downstream input with zero false supports | Offline plan only: 12 cases, 13 calls, zero retries, $0.0021 hard ceiling; no live result | inconclusive | [TypeSafe benchmark](../typesafe-ai-system-one/04-token-cost-benchmark/) |

## 2026-09-20 — First opportunity-matrix tracer

Implemented `opportunities.json`, a validator and renderer with only the Python standard library. The registry contains Jev token gating, the Learn authoring method, a hexagonal seam audit and a RabbitMQ reliability boundary. The generated views separate coverage, ranking, promotion, evidence and method quality.

Commands:

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Measured result: `validated=4 matrices=current mirrors=current`; 6/6 tests passed in 0.002 s. Tests reject promoted candidates without artifacts and adoption without a confirmed verdict, and check EN/FR/ES file parity plus journal structure. No external network or repository mutation occurred.

## To verify

- Confirm the first hosted CI run for matrices, locale parity and journal structure.
- Measure authoring lead time before claiming the new method is cheaper.
- Run an independent adversarial review of the opportunity schema and scores.
- Complete the bounded Jev calibration only with explicit spend approval.
- Select one exact hexagonal seam from current repository evidence or reject that opportunity.

## Open questions

- Which metrics best predict that a course discovery will survive repository integration?
- Should opportunity ownership and merge authority always be separate fields?
- When should a rejected candidate be revisited instead of retired permanently?
