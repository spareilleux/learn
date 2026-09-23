---
title: Repository Dogfooding Lab — Mission
description: Turn courses and repository observations into falsifiable experiments, evidence-bearing incubation, and measured adoption across GA, Gaia, Demerzel, IX, TARS and Learn.
sidebar:
  label: Mission
  order: 0
---

:::caution[Current evidence]
The tracer bullets are local and offline: a JSON registry with five opportunities, five generated matrices, and a synthetic Jev × Petri authority-boundary test. No production repository integration, live Jev saving, architecture improvement or RabbitMQ benefit is claimed yet. Those candidates remain `discovered` or `experimenting` until their own gates pass.
:::

## Mission

This course turns learning into a research loop:

```text
observation → falsifiable hypothesis → baseline → bounded experiment
            → adversarial review → incubation → integration or rejection
```

It advances two disciplines together:

- **classical software engineering:** architecture, reliability, tests, observability, performance and maintainability;
- **agentic AI engineering:** cost per accepted result, calibration, escalation, retries, provider-specific tokens and safe autonomy.

A finished course is not success. Success is a retained result: adoption with evidence, or a useful rejection that prevents waste.

## What you will build

[`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) contains a machine-readable opportunity registry. A Python standard-library tool validates promotion rules and generates five views:

1. course × repository coverage;
2. opportunity score;
3. promotion state;
4. results and evidence;
5. the quality of the course method itself.

## Outline

| # | Lesson | Outcome |
|---|---|---|
| 1 | [Opportunity matrices](01-opportunity-matrices/) | Prioritize discovery without turning a score into authority |
| 2 | [Experiment and artifact chain](02-experiment-artifact-chain/) | Produce replayable evidence from hypothesis to verdict |
| 3 | [Dogfood the course method](03-course-method-dogfood/) | Improve examples, journals, locale parity and adoption feedback |
| 4 | [Incubate, integrate, reject](04-incubate-integrate-reject/) | Promote only measured, reversible candidates |
| 5 | [Jev × Petri authority boundary](05-jev-petri-authority/) | Show why high-confidence advice cannot grant an effect |
| — | [Journal](journal/) | Detailed experiments, rejected ideas and next gates |

## Run the lab

```text
cd code/repository-dogfooding-lab
python dogfood.py write
python dogfood.py check
python -m unittest -v
```
