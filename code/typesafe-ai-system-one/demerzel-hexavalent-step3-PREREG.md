# Pre-registration — step 3: a U definition that yields to leaning evidence

Written and committed **before any step-3 live call**. Step 2 fixed conflicts
(C 10/10) but left 4–5/10 absences read as F/D and pulled P into U (6/10),
because its U text ("a check that was not run … is Unknown") also describes the
P cases, which have no direct run but lean true.

## The only change from step 2

`--definitions leaning` keeps step 2's C text and replaces only U (tested by
`test_leaning_definitions_change_only_u_from_explicit`):

> Insufficient evidence to determine: nothing bears on the claim either way. A
> missing artefact, field or log, or a check that was not run or does not bear on
> the claim, is not evidence against. If other indirect evidence leans one way,
> choose Probable or Doubtful instead.

Same frozen corpus, same 58 scored cases, two arms, 120 calls, no retry, $0.05
stop.

## Decision rule (worse arm)

Step-2 values (canonical / reversed) in brackets.

| Verdict | Condition |
|---|---|
| `REGRESSION` | `correct` < 44 [46 / 44] or `false_true` > 1 [0 / 0] or `conflict_resolved` > 1 [0 / 0] |
| `FIXED` | not REGRESSION, `absence_as_refutation` ≤ 1 [4 / 5] and `over_unknown` ≤ 5 [7 / 8] |
| `PARTIAL` | not REGRESSION, `absence_as_refutation` ≤ 4 and `over_unknown` ≤ 8 |
| `NOT_FIXED` | anything else |

`FIXED` would justify proposing both sentences for Demerzel's
`logic/hexavalent-logic.md`, still subject to a check on real belief files.
Anything less means the U sentence stays out and U-versus-F remains a
deterministic existence check.

---

## Results — 2026-09-25 (appended after the run; the section above is unchanged since 682c713)

120/120 answered, all `jev-1.13.0`, 0 invalid, no retry. 72,726 input and 8,054
output tokens reported, **$0.0031** computed (not a bill). Mean latency 400 ms.
Receipt: `evidence/demerzel-hexavalent-step3-live.json`.

| Metric (N = 58), canonical / reversed | step 1 | step 2 | **step 3** |
|---|---|---|---|
| correct | 41 / 41 | 46 / 44 | **48 / 48** |
| false_true | 0 / 0 | 0 / 0 | 0 / 0 |
| absence_as_refutation (of 10 U) | 7 / 7 | 4 / 5 | **7 / 7** |
| conflict_resolved (of 10 C) | 4 / 4 | 0 / 0 | 0 / 0 |
| over_unknown | 5 / 4 | 7 / 8 | **2 / 2** |
| order flips | 2 | 3 | 1 (h36) |

**Verdict: `NOT_FIXED`** — no regression and the best accuracy of the three
steps (P back to 9/10, C still 10/10), but absence is read as F/D in 7/10
again, in both orders.

The three steps together answer the question step 2 was meant to answer. U and
P trade against each other: the wording that stops absence reading as
refutation also swallows P (step 2), and the wording that restores P lets
absence slide back to F/D (step 3). No definition tried makes a Jev F/D mean
"refuted". The conflict sentence, in contrast, held at 10/10 across two
different U wordings and four arms.

Consequence: U versus F/D is decided by a deterministic existence check before
any model; the model ranks only among T/P/D/F once evidence is present, and
the C sentence is the one definition change worth carrying to Demerzel.
