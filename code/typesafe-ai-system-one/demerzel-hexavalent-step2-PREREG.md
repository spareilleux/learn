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
