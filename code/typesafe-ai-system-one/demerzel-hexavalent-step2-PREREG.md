# Pre-registration — step 2: does an explicit absence rule fix it?

Written and committed **before any step-2 live call**. Step 1
(`demerzel-hexavalent-PREREG.md`) found 7/10 U cases answered F or D and 4/10 C
cases answered F, in both option orders.

## Question

Is the absence-as-refutation error in the definitions Demerzel ships or in the
model? If adding the absence rule to the Unknown criterion removes it, the fix
belongs in `logic/hexavalent-logic.md`; if not, a Jev answer of F/D cannot be
trusted to mean "refuted" whatever the definitions say.

## The only change

`--definitions explicit` rewrites two criteria and nothing else (tested by
`test_explicit_definitions_change_only_u_and_c`):

- **U**: "Insufficient evidence to determine. Absence of evidence (a missing
  artefact, field or log, or a check that was not run or does not bear on the
  claim) is Unknown, not evidence against."
- **C**: "Evidence supports both true and false: at least two strong, direct
  records point opposite ways. Do not resolve such a conflict by picking a side."

Same frozen corpus (sha256 in the receipt), same 58 scored cases, same two arms,
same model, 120 calls, no retry, same $0.05 stop.

## Metrics (per arm)

Step-1 values (canonical / reversed) in brackets.

- `absence_as_refutation` (U → F/D, of 10) — **primary** [7 / 7]
- `conflict_resolved` (C → T/F, of 10) [4 / 4]
- `over_unknown` (non-U label → U): the over-correction risk [5 / 4]
- `correct`, `false_true` [41, 0 / 41, 0]

## Decision rule

Applied to the worse arm:

| Verdict | Condition |
|---|---|
| `REGRESSION` | `correct` < 38 or `false_true` > 1 or `over_unknown` > 8 |
| `FIXED_BY_DEFINITION` | not REGRESSION, and `absence_as_refutation` ≤ 1 |
| `PARTIAL` | not REGRESSION, and `absence_as_refutation` in 2–4 |
| `NOT_FIXED` | not REGRESSION, and `absence_as_refutation` ≥ 5 |

`conflict_resolved` is reported, not decisive: step 1 did not predict it, so it
gets no verdict here.

The step-1 advisory verdict (`demerzel_hexavalent.verdict`) is also reported
for the new arms, for comparison only.

---

## Results — 2026-09-25 (appended after the run; the section above is unchanged since 7742f10)

120/120 answered, all `jev-1.13.0`, 0 invalid, no retry. 70,446 input and 8,030
output tokens reported, **$0.0030** computed (not a bill). Mean latency 372 ms,
max 1,352 ms. Receipt: `evidence/demerzel-hexavalent-step2-live.json`.

| Metric (N = 58) | step 1 canon / rev | **step 2 canon / rev** |
|---|---|---|
| correct | 41 / 41 | **46 / 44** |
| false_true | 0 / 0 | 0 / 0 |
| absence_as_refutation (of 10 U) | 7 / 7 | **4 / 5** |
| conflict_resolved (C → T/F, of 10) | 4 / 4 | **0 / 0** |
| over_unknown | 5 / 4 | 7 / 8 |
| order flips between arms | 2 | 3 (h17, h36, h48) |

**Verdict (worse arm = reversed): `NOT_FIXED`** — no regression (44 ≥ 38,
0 false T, over_unknown 8 ≤ 8), but 5 absences are still read as refutation.
The canonical arm alone would be `PARTIAL` (4); the rule takes the worse arm.
Step-1 advisory verdict for both new arms: `INCONCLUSIVE`.

Findings:

1. **The conflict rule works completely.** C is 10/10 in both arms (was 6/10).
   Not predicted, so not decisive — but it is the cleanest effect in either step.
2. **The absence rule helps but does not fix.** U → F/D goes from 7 to 4–5.
   Still wrong in both arms: h02 (missing file + empty run list → F), h29
   (empty digest field + injection line → F), h41 (irrelevant passing run → D).
   h36 and h48 now flip with option order — the rule moved them onto the
   boundary rather than across it.
3. **The rule creates a new error: P collapses into U.** P → U rises from 3 to
   6 of 10. P cases are, by construction, "no direct run, but indirect evidence
   leans true"; the new U text ("a check that was not run … is Unknown") matches
   them too. This is a real ambiguity in the definitions, not only in Jev:
   *absence of direct evidence* and *presence of indirect evidence* co-occur,
   and Demerzel's text does not say which wins.

Consequence for Demerzel: the C sentence is worth adopting in
`logic/hexavalent-logic.md` as-is. The U sentence is not — it needs a companion
clause ("…unless other evidence leans one way, in which case P or D") and its
own test before anyone relies on it. Neither step makes a Jev F/D safe to read
as "refuted": at 4–5/10 it must stay advisory, with U/F decided by the
deterministic check that knows whether the artefact exists.
