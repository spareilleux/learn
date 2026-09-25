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
