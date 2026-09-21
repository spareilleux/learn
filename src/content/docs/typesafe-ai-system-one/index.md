---
title: TypeSafe AI System One and Jev — Mission
description: Learn to compose typed probabilistic decisions with Jev, validate them offline, run one cost-bounded optional probe, and identify useful but authority-safe applications in Gaia, GA, Demerzel, IX, and TARS.
sidebar:
  label: Mission
  order: 0
---

:::caution[What was and was not tested]
This course was written from [TypeSafe AI's official documentation](https://docs.typesafe.ai/introduction), its [API reference](https://docs.typesafe.ai/api), [model page](https://docs.typesafe.ai/models), and the official [Jev launch post](https://typesafe.ai/blog/introducing-system-one-models-and-jev), read on 2026-09-20. The offline lab in [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) ran locally with Python 3.14.2: **14 tests passed** and the mock route refused dispatch because explicit authority was absent.

No credential was read, no console session was opened, and no TypeSafe API request was made. Every live result, latency, token count, calibration claim on our data, and repository-specific benefit remains **to verify**.
:::

## Why I am learning this

Coding agents are good at producing text, plans and patches. Our repositories also contain smaller decisions that software must consume repeatedly: classify a Gaia candidate, score a GA search result, flag a Demerzel governance record, route an IX experiment, or identify a TARS grammar ambiguity. An LLM can answer those questions in JSON, but the surrounding program still has to parse it, reject invented values, measure uncertainty and keep authority out of prose.

[Jev](https://docs.typesafe.ai/introduction) takes a narrower approach. It accepts a state plus typed questions and returns closed, structured answers. The model chooses among values we defined; our code still owns thresholds, composition and effects. That makes it interesting for high-volume judgment inside workflows, but it does **not** make a decision correct merely because its shape is valid.

## The safety thesis

This course uses one rule throughout:

> A model may estimate; deterministic code validates, gates and acts.

The distinction matters for every repository in our ecosystem:

- a valid `Choice` can still choose the wrong option;
- a high confidence is a model signal, not authority;
- a moving alias can change behavior without a code change;
- low cost can make a bad decision cheaper and more frequent;
- a provider response must never mint a Gaia grant, merge a pull request, or mutate governance by itself.

## What you will build

The course's Python lab has two paths:

1. **Mock first:** replay a saved response, validate its closed shapes and probability distributions, then apply the real routing policy with no network and no key.
2. **One optional live probe:** read `TYPESAFE_API_KEY` from the environment, estimate the input budget, make exactly one request, never retry automatically, never print the key, and record the request digest, concrete model, usage, latency and decision.

## Outline

| # | Lesson | Outcome |
|---|---|---|
| 1 | [Decisions, not strings](01-decisions-not-strings/) | Choose among Choice, Score and Noul without confusing types with truth |
| 2 | [A reproducible, cost-bounded experiment](02-bounded-experiment/) | Run the offline baseline and understand the optional one-call probe |
| 3 | [Use cases across our repositories](03-repository-use-cases/) | Select useful seams in Gaia, GA, Demerzel, IX and TARS while preserving authority |
| — | [Journal](journal/) | Measured facts, open questions and live work still to verify |

## Prerequisites

- [Python](https://docs.python.org/3/) 3.10 or later; the lab uses only the standard library.
- JSON and ordinary branching logic.
- An optional TypeSafe account and API key only for the live probe. Put the key in `TYPESAFE_API_KEY`; never paste it into a lesson, source file, terminal transcript or chat.

## Primary resources

- [Introduction](https://docs.typesafe.ai/introduction) and [quick start](https://docs.typesafe.ai/introduction/quickstart)
- [Primitives](https://docs.typesafe.ai/primitives), [confidence](https://docs.typesafe.ai/confidence), and [patterns](https://docs.typesafe.ai/patterns)
- [Models and pricing](https://docs.typesafe.ai/models) and the [HTTP API reference](https://docs.typesafe.ai/api)
- [Introducing System One Models & Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev), including the authors' own caveats about early access and evaluation bias
