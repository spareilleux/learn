---
module_id: "inf-021-distinguish-stream-entropy-rate-from-label-entropy"
department: "information-theory"
course: "Distinguish Stream Entropy Rate from Label Entropy"
title: "Distinguish Stream Entropy Rate from Label Entropy"
level: "intermediate"
prerequisites: ["inf-012-retain-event-order-in-a-handoff-summary", "inf-010-keep-joint-outcomes-when-composing-verdicts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguish Stream Entropy Rate from Label Entropy

> This is an authored mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A Demerzel status stream spends equal time in two labels. An agent concludes that every arriving label carries the maximum fresh uncertainty. That conclusion ignores repetition across time. A stream can have balanced marginal labels and still be predictable from its previous state. Before measuring useful novelty in evidence, distinguish the distribution of labels from the process generating their order.

Stipulate a stationary binary Markov source with a symmetric chance of changing labels. Stationarity makes the current label balanced. Conditional on the current label, the next one has the declared change probability and its complement. The weighted conditional entropy therefore reduces to the binary entropy of that probability. This is the entropy rate under the stated source, not the marginal entropy of one isolated label.

For a finite block, retain the first label’s uncertainty and add the conditional uncertainty of each later transition. Multiplying the rate by the whole block length would forget that initial state. The control sets the transition to independent balanced labels. The marginal distribution stays unchanged while the rate and finite-block entropy increase. Keep that comparison visible when an assistant proposes a frequency-only novelty score.

Shannon’s source definition weights conditional entropies by state frequencies. Our source parameters are invented and known, not inferred from a short log. Real monitoring may have changing conventions, hidden states and incomplete receipts. The event-order prerequisite already shows semantic consequences of ordering; this lesson adds a quantitative process distinction. A low modeled rate is not low importance, stale authorization or permission to omit repeated warnings.

## Sources and project boundary

The retained Learn helper separates metadata, title and body, and indexes English module identities. Inspect that representation when naming the artifact and its revision. It does not implement this lesson’s model or supply its invented inputs.

[Prerequisite: inf-012-retain-event-order-in-a-handoff-summary](../../information-theory/en/inf-012-retain-event-order-in-a-handoff-summary.md)

[Prerequisite: inf-010-keep-joint-outcomes-when-composing-verdicts](../../information-theory/en/inf-010-keep-joint-outcomes-when-composing-verdicts.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf)

## Fixed model and negative control

```json
{
  "values": {
    "flip_probability": 0.25,
    "stationary": [
      0.5,
      0.5
    ],
    "block_length": 4
  },
  "formula": "Binary symmetric stationary Markov source: P(next != current)=p. h(p)=-p*log2(p)-(1-p)*log2(1-p), using 0*log2(0)=0. Marginal entropy=1; entropy rate=h(p); block entropy=1+(L-1)*h(p).",
  "expected": {
    "marginal_entropy_bits": 1,
    "entropy_rate_bits_per_symbol": 0.8112781244591328,
    "block_entropy_bits": 3.4338343733773984
  },
  "negative_control": {
    "values": {
      "flip_probability": 0.5,
      "stationary": [
        0.5,
        0.5
      ],
      "block_length": 4
    },
    "expected": {
      "marginal_entropy_bits": 1,
      "entropy_rate_bits_per_symbol": 1,
      "block_entropy_bits": 4
    },
    "why": "Removing temporal dependence leaves the same label proportions but independent next labels."
  },
  "input_types": {
    "flip_probability": "probability rational in [0,1]",
    "stationary": "length-2 probability vector fixed to [0.5,0.5]",
    "block_length": "positive integer"
  },
  "assumptions": [
    "Known binary symmetric first-order Markov source initialized in the declared stationary distribution.",
    "Base-2 logarithms; quantities refer to random symbols, not semantic value."
  ],
  "limits": "No telemetry was fitted and no achievable compressor, novelty detector or governance-complexity measurement is claimed."
}
```

### Exercise 1

What is the marginal entropy?

<details><summary>Answer 1</summary>

It is `1` bit because each isolated label has probability `0.5`. This does not assert independence of consecutive labels.

</details>

### Exercise 2

Compute the source rate.

<details><summary>Answer 2</summary>

The binary conditional entropy is `0.8112781244591328` bits per symbol. Knowledge of the previous label reduces the modeled next-label uncertainty.

</details>

### Exercise 3

Compute finite-block entropy.

<details><summary>Answer 3</summary>

For length `4`, retain the initial bit and the later conditional contributions, giving `3.4338343733773984` bits. Rate times the full length omits that initial-state distinction.

</details>

### Exercise 4

Apply the independent-label control.

<details><summary>Answer 4</summary>

Its rate is `1` and block entropy is `4`, while marginal entropy remains `1`. Identical label proportions do not establish identical process uncertainty.

</details>

### Exercise 5

May repeated warnings be discarded as low information?

<details><summary>Answer 5</summary>

No. Mathematical unpredictability and operational importance differ. A repeated warning can remain necessary; an actual omission policy needs its own meaning, evidence and authority contract.

</details>

## Source-assisted learner task

Critique a marginal-frequency novelty claim for a fictional agent status stream.

**Direct manual baseline:** Write the transition rows and conditional entropies, keeping the first block label separate.

**Falsifier:** A marginal-only summary assigns the same process rate to the dependent and independent controls.

Save a first answer before opening the solutions. Identify the input types, the comparison boundary and the quantity that the task asks you to preserve. Draw the smallest table or diagram that permits every intermediate result to be checked. Keep an unexpected result; editing the premises until a preferred conclusion appears would destroy the counterexample.

Read the linked prerequisite and the bounded primary passage. Record the source revision, the definition actually used and the assumptions you imported. The project artifact supplies a real representation to inspect, while the fixed model supplies invented inputs. Neither a document name nor an accessible URL establishes a production result. Explain what would need to be observed before using the calculation in an operational decision.

State the direct manual baseline and its falsifier before proposing a composable DSL or an agent abstraction. Ask an assistant to challenge your manual answer only after saving it. Retain the prompt, the reply, the source passage it cites and the correction you accept or reject. A shorter expression is useful only if it preserves the operation, the control and the refusal boundary. Compare it with a plain table first.

Submit the original answer, intermediate quantities, corrected answer and control together. Label source consultation and calculator use as assistance. A future dogfood comparison should use the same task version and retain failures as well as successes; otherwise changing the question can masquerade as improvement. The prepared criteria below remain undecided until a learner actually attempts the task. An answer key and an author check establish neither learning nor adoption.

## Prepared learner criteria

- Exercise 1: What is the marginal entropy? — Decision undecided.
- Exercise 2: Compute the source rate. — Decision undecided.
- Exercise 3: Compute finite-block entropy. — Decision undecided.
- Exercise 4: Apply the independent-label control. — Decision undecided.
- Exercise 5: May repeated warnings be discarded as low information? — Decision undecided.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
