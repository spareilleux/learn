---
title: "1. Decisions, not strings"
description: The System One mental model, the three typed primitives, why confidence is not authority, and where Jev's closed outputs help without proving semantic correctness.
sidebar:
  order: 1
---

[TypeSafe AI](https://docs.typesafe.ai/introduction) describes Jev as a model for fast, focused judgments inside software. A request contains a `state` and one or more questions. Each question is evaluated independently against the same state, and the answer comes back under the ID chosen by the caller.

That is deliberately less general than generated text. The gain is not magic correctness; it is a smaller interface that ordinary code can validate and compose.

## Three primitives

| Primitive | Ask it when | Returned value |
|---|---|---|
| [`Choice`](https://docs.typesafe.ai/primitives/choice) | exactly one member of a closed set should win | chosen option, every option's probability, confidence |
| [`Score`](https://docs.typesafe.ai/primitives/score) | the answer lies on an ordered rubric | probability-weighted score, legend, probabilities, confidence |
| [`Noul`](https://docs.typesafe.ai/primitives/noul) | the useful answer is a degree of yes versus no | one number from 0 to 1 |

`Noul` is not a misspelling in this course. It is TypeSafe's name for its binary probability primitive. Unlike Choice and Score, it does not carry a separate `confidence` field.

The request in the lab asks all three at once:

```json
{
  "next_step": {
    "type": "choice",
    "instructions": "Which next lifecycle step is supported by the supplied evidence?",
    "criteria": {
      "design_review": "Review the design; implementation authority is absent or evidence is incomplete.",
      "bounded_implementation": "Implement one bounded tracer only when design and authority evidence are explicit.",
      "reject": "The proposal contradicts a hard constraint or cannot fail closed."
    }
  },
  "delivery_risk": {
    "type": "score",
    "instructions": "How difficult would the proposed effect be to reverse?",
    "criteria": ["Low and reversible", "Moderate or compensatable", "High or hard to reverse"]
  },
  "authority_present": {
    "type": "noul",
    "instructions": "Does the state contain explicit, bounded implementation authority?"
  }
}
```

## Atomic questions, composition in code

The official guidance says to ask one snap judgment per question and decompose broad analysis into independent dimensions. That is why the example does not ask, “Should Gaia implement this safely?” It asks separately what the next step appears to be, how reversible the effect is, and whether explicit authority appears in the state.

The final decision remains code:

```python
if not authority_artifact_verified:
    return "human_review:no_explicit_authority"
if authority_present < 0.9:
    return "human_review:model_did_not_observe_authority"
if next_step_confidence < 0.75:
    return "human_review:uncertain_next_step"
if delivery_risk > 1.0:
    return "human_review:risk_above_bound"
```

`authority_artifact_verified` is supplied by trusted local code, not by Jev. The Noul answer can make the route more conservative, but it can never turn a missing authority artifact into permission.

The thresholds are hypotheses, not universal constants. TypeSafe's [confidence guidance](https://docs.typesafe.ai/confidence) says to start conservatively and tune on domain data. A destructive action needs a different policy from a read-only recommendation.

## Type safety is not semantic truth

The API can constrain `next_step.choice` to one of the options in the request. Our validator can reject a response containing `"merge_now"`. That is valuable: a valid response cannot smuggle in a new command by inventing a string.

But two different claims are easy to conflate:

1. **Shape:** the response matches the defined answer space.
2. **Meaning:** the selected answer is correct for this state.

The first can be checked mechanically on every call. The second needs labeled examples, error analysis, calibration and a consequence-aware policy. The launch post's “can't hallucinate” claim concerns the closed output interface; this course does not use it as evidence that Jev cannot make a wrong judgment.

## Version and probability discipline

The current model page lists `jev-1.13.0` and aliases `jev-latest` and `jev-preview`. Aliases can move. When thresholds have been evaluated against one model, pin its version and log the concrete `model` in every response. Upgrade deliberately and rerun the corpus.

Use the full probabilities when the distribution matters. `confidence` compresses a distribution into one convenient statistic; it cannot tell your code which secondary option deserves escalation or whether a domain-specific margin is sufficient.

## Key takeaways

- Choice, Score and Noul are closed judgment primitives, not free-form generation.
- Ask atomic questions and compose the result in code.
- Schema validity prevents invented answer shapes; it does not prove correctness.
- Confidence guides a policy; it is neither authority nor acceptance.
- Pin a concrete model when thresholds matter, and measure upgrades on your corpus.

## Exercises

1. You need to decide which repository owns a bug: Gaia, GA, IX, TARS, or Demerzel. Which primitive fits, and what option must be added if the list may be incomplete?

<details>
<summary>Solution</summary>

Use Choice because the answer is one member of a closed, unordered set. Add `unknown` or `none_of_the_above`; without it, the model must assign probability to an option even when none fits.

</details>

2. A response chooses `bounded_implementation` with confidence 0.98, but the state contains no authorization record. May the caller dispatch work?

<details>
<summary>Solution</summary>

No. Confidence describes the model's distribution, not authority. Deterministic code must verify the actual authority artifact. In the lab, the Noul answer is advisory too; its value cannot replace cryptographic or repository evidence.

</details>

## Sources

- TypeSafe AI: [introduction](https://docs.typesafe.ai/introduction), [primitives](https://docs.typesafe.ai/primitives), [confidence](https://docs.typesafe.ai/confidence), [models](https://docs.typesafe.ai/models)
- TypeSafe AI: [Introducing System One Models & Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev)
