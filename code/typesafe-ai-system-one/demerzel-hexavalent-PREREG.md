# Pre-registration — Demerzel hexavalent classification with Jev

Written and committed **before any live call**. Results go in a separate section
appended after the run; this section is not edited afterwards.

## Question

Can Jev (`jev-1.13.0`, pinned), given only Demerzel's own one-line definitions of
the six hexavalent values (`logic/hexavalent-logic.md`), classify synthetic
governance evidence into T/P/U/D/F/C well enough to serve as an **advisory**
annotator, and does it keep *absence of evidence* (U) apart from *refutation*
(F/D)?

The second half is the live weakness already observed in this lab: on
2026-09-22 both arms of the batching benchmark answered `contradicted` for
`demerzel_immutable`, whose evidence was merely missing.

## Corpus

`demerzel-hexavalent-corpus.json`: 60 synthetic cases, 10 per value, in the
Demerzel governance domain. Written by one agent under an explicit labeling
standard (sufficient = direct primary evidence; leans = indirect; absence is U;
C needs two strong opposing records), including hard boundary pairs (U vs F/D,
P vs T, C vs F, D vs U) and 3 prompt-injection strings. No label word
(true/false/probable/unknown/doubtful/contradict/verified/refuted) appears in any
proposition or evidence. A second agent labeled all 60 blind from the same
standard, without seeing the author's labels. Both labels are frozen in the file.

**Scored set:** only cases where the two annotators agree. Disagreements are
reported, not adjudicated.

Jev does **not** receive the labeling standard — only Demerzel's six
definitions, as a deployment would. Whether adding the standard helps is a
separate, later experiment.

## Arms

- `canonical`: options in order T, P, U, D, F, C.
- `reversed`: options in order C, F, D, U, P, T.

One call per case per arm (120 calls), one proposition per state, no retries.

## Metrics (per arm, on the scored set of size N)

- `correct`: exact-match count.
- `false_true`: predicted T when the label is not T (T is the value Demerzel's
  confidence ladder lets an agent act on).
- `absence_as_refutation`: predicted F or D when the label is U.
- `invalid`: timeouts, HTTP errors, contract failures (any case, scored or not).
- Reported, not decisive: confusion matrix, order flips between arms, the
  keyword baseline (`python demerzel_hexavalent.py baseline`), chance = N/6.

## Decision rule (per arm)

| Verdict | Condition |
|---|---|
| `INVALID_ARM` | `invalid` > 3 |
| `KILL` | `correct` < 0.60·N, or `false_true` > 3 |
| `ADVISORY_USEFUL` | `correct` ≥ 0.75·N and `false_true` ≤ 1 and `absence_as_refutation` ≤ 1 |
| `INCONCLUSIVE` | anything else |

The overall verdict is the **worse** of the two arms (order: INVALID_ARM, KILL,
INCONCLUSIVE, ADVISORY_USEFUL).

Lessons applied from the IX runs: probability-sum tolerance is 0.01 (Jev rounds
to two decimals); a timeout is recorded as invalid and never retried; the rule is
in counts, with no gaps between bands (`demerzel_hexavalent.verdict`, tested).

## Budget and stop conditions

- Local proxy before calls: see `python demerzel_hexavalent.py plan`.
- Stop immediately once reported input tokens × $0.042/M exceeds **$0.05**.
- Operator cap for the whole course: $1 (≈ $0.021 used before this run).
- Requires `JEV_DEMERZEL_APPROVED=YES` and `TYPESAFE_API_KEY` from the
  environment; the key is never printed or written.

## What this cannot show

Synthetic, English-only, agent-authored evidence; the author and blind annotator
share a labeling standard and a model family, so agreement measures consistency,
not truth. No real Demerzel belief files are sent. Even `ADVISORY_USEFUL` grants
nothing: a Jev value would be one input to Demerzel's deterministic confidence
ladder, never a verdict, and a `C` would still escalate to a human.
