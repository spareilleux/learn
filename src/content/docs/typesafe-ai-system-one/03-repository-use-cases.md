---
title: "3. Use cases across our repositories"
description: Practical, bounded hypotheses for Gaia, GA, Demerzel, IX and TARS, with the deterministic seam, the model's advisory role, evaluation data and explicit rejection criteria for each.
sidebar:
  order: 3
---

The useful question is not “Where can we add AI?” It is:

> Where do we already need a fast, repeated, fuzzy judgment whose answer space is closed and whose effect can stay behind a deterministic gate?

The table below proposes experiments, not features. None has been run with Jev.

| Repository | Candidate judgment | Primitive | Deterministic owner | First evaluation |
|---|---|---|---|---|
| [Gaia](https://github.com/GuitarAlchemist/gaia) | classify evidence into review, bounded implementation, rejection, or unknown | Choice + Noul | authority verifier and state machine | historical receipts with blinded labels |
| [GA](https://github.com/GuitarAlchemist/ga) | route a music query or rank ambiguous search intent | Choice + Score | query parser, capability registry and read-only search | labeled chatbot/query corpus |
| [Demerzel](https://github.com/GuitarAlchemist/Demerzel) | flag a governance record for which tribunal or human review queue | Choice | constitution, schemas and tribunal code | past verdicts with authority fields removed from model input |
| [IX](https://github.com/GuitarAlchemist/ix) | score experiment observations for anomaly or follow-up priority | Score + Noul | Rust pipeline and statistical tests | held-out experiment reports |
| [TARS](https://github.com/GuitarAlchemist/tars) | classify a DSL utterance when deterministic parsing yields several candidates | Choice | F# parser and typed AST validation | ambiguity corpus with parser candidates |

## Gaia — advice beside the gate, never inside authority

Jev could inspect a compact evidence summary and estimate the next lifecycle step, risk and whether authority language appears. It must not read a probability as proof that authority exists. Gaia's exact receipts, digests, generations and grants remain the source of truth.

Useful measurement: compare Jev's route with independently labeled historical cases, especially stale evidence, missing authority, conflicting reviews and retry ambiguity. Reject the integration if any model answer can create a successor, send a wake, mint a grant or bypass exact replay without the deterministic controller independently proving every precondition.

## GA — route fuzzy intent, preserve musical truth

GA has useful fuzzy seams: “Is this question about voicing search, harmony analysis, playback, or account support?” is a Choice. “How strongly does the query ask for an exact fingering versus conceptual explanation?” is a Score.

The model must not invent notes, chords, tunings or OPTIC-K dimensions. Those belong to GA's domain types and algorithms. A promising tracer would route to existing read-only capabilities and compare against a labeled query set; reject it if it worsens deterministic parser coverage, hides `unknown`, or changes an effectful endpoint.

## Demerzel — triage evidence, do not interpret the constitution

Demerzel can use a closed Choice to prioritize which independent tribunal or queue should examine a record. The constitution, schemas and authority remain deterministic and read-only from the classifier's perspective.

The key negative case is an attractive but unauthorized proposal. The expected result is a review route, never a governance mutation. Evaluate false negatives separately because a missed high-risk record is more costly than an extra human review.

## IX — turn reports into features, not conclusions

IX produces numerical experiments and model artifacts. Jev may help convert text observations into structured features such as reproducibility risk, missing-baseline likelihood or follow-up priority. Classical statistics and Rust invariants still decide whether an experiment passes.

Compare the structured features with human labels and simpler baselines: regexes, a small classifier, or explicit metadata. Reject Jev when a deterministic field gives the same result more cheaply, or when its scores are treated as measurements rather than model estimates.

## TARS — choose among parser candidates

The strongest TARS use case begins *after* deterministic parsing has produced several valid typed candidates. Jev receives the utterance and a closed list of candidate meanings, then Choice ranks them. TARS still validates the selected AST and can ask the user when probability is split.

Do not send free-form source generation directly into an evaluator. The model's answer space should be candidate IDs already created by the parser. The falsifier is straightforward: if adding Jev reduces exact parse success, removes useful ambiguity, or performs worse than the parser's existing ranking on a held-out corpus, keep the deterministic path.

## A shared cross-repository adapter

If two experiments succeed, the maintainable shape is a small provider-neutral port, not five SDK integrations:

```text
evaluate(state, questions, budget) -> typed answers + provider evidence
```

Each repository owns its questions, thresholds, labeled corpus and effect policy. The adapter owns HTTP, model pinning, timeout, cost accounting, response validation and redaction. Gaia may record the evidence, but it must not become the universal decision service or inherit domain logic from its siblings.

## Cost and provider guardrails

- default to mock and replay in CI;
- require an explicit live-test flag and environment credential;
- pin a model and a maximum input size;
- cap calls, retries, elapsed time and estimated dollars independently;
- log exact provider/model/usage without logging secrets;
- fall back to deterministic behavior or human review, never another paid provider silently;
- compare against the simplest non-model baseline before adoption.

## Exercises

1. Which proposed use case has the cleanest first tracer, and why?

<details>
<summary>Solution</summary>

TARS candidate ranking is especially clean because the deterministic parser supplies a closed list and validates the selected AST. The model cannot invent a new command shape, and success can be measured against a labeled ambiguity corpus. Gaia triage is also useful, but its proximity to authority demands stricter separation.

</details>

2. A GA integration sends every user query to Jev, then falls back to an LLM when confidence is low. What two guardrails are missing?

<details>
<summary>Solution</summary>

There is no explicit total provider/cost ceiling, and fallback silently broadens both provider authority and spend. The code should choose a bounded route before calling anything: deterministic path, one explicitly authorized provider call, or human clarification.

</details>

## Sources

- TypeSafe AI: [speculative fan-out](https://docs.typesafe.ai/patterns/fan-out), [confidence-gated routing](https://docs.typesafe.ai/patterns/confidence-routing), [composite scoring](https://docs.typesafe.ai/patterns/composite-scoring)
- Repositories: [Gaia](https://github.com/GuitarAlchemist/gaia), [GA](https://github.com/GuitarAlchemist/ga), [Demerzel](https://github.com/GuitarAlchemist/Demerzel), [IX](https://github.com/GuitarAlchemist/ix), [TARS](https://github.com/GuitarAlchemist/tars)
