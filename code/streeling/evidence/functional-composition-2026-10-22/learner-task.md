# Functional composition source-assisted learner task

**Status:** prepared, no learner attempt or outcome recorded. This packet is not an approval or a mastery test. It checks overlapping source-assisted reasoning for three draft courses; transfer and causal learning are not measured. Work before opening the course answers, runner or reviewer rubric.

## Inputs

Inspect the unchanged [GA module](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs). Its local copy is `code/streeling/functional-composition/vendor/GaAsync.fs`. You may consult [F# results](https://learn.microsoft.com/dotnet/fsharp/language-reference/results), [options](https://learn.microsoft.com/dotnet/fsharp/language-reference/options) and [async workflows](https://learn.microsoft.com/dotnet/fsharp/language-reference/async-expressions). These are primary-source lookups, not supplied answer observations.

All values and branch names below are synthetic. Assume no effect before the explicitly named callback. The numeric validation rule is a fixture choice, not a music-theory rule.

## Task CS-010: dependent composition

Input A starts with `ok 5`. A bound function records `double` then returns `ok (x * 2)`. The next records `increment` then returns `ok (x + 1)`. A final map formats `ready:{x}`. Input B starts with `fail (GaError.DomainError "invalid-pitch")` and uses the same callbacks.

1. Predict both results and both callback traces, then identify which source branch determines the difference.
2. For pure functions, explain the difference between reassociating binds and swapping the functions. Does a match on two example inputs prove a universal law?
3. Explain what `mapError` may change, and whether it supplies a successful fallback.
4. State one effect that cannot be undone by skipping a callback.
5. State what this computation cannot establish about publication or human approval.

## Task CS-011: representation boundaries

Inputs are `None`, `Some 0` and `Some 5`. Promote an option with supplied `DomainError "missing-note"`, then bind a validator that requires a positive integer and otherwise returns `DomainError "nonpositive-note"`. Separately, project `Error "missing-note"` and `Error "invalid-pitch"` through standard F# `Result.toOption`. A third scenario deliberately raises `System.IO.IOException "fixture-io"` inside the module's `fromAsync` boundary.

1. Predict the promoted-and-validated results for the three inputs and distinguish presence from domain validity.
2. Identify information introduced by `ofOption` and information erased by `Result.toOption`.
3. Decide whether a repair worker can infer transport retryability from the projected values alone.
4. From the source, describe the returned exception information and decide whether the name `IoError` proves an I/O cause.
5. State the evidence still needed to claim cancellation safety.

## Task NET-005: branch-to-join dependencies

Branches A and C return `ok 100` and `ok 300`. B returns `fail (GaError.DomainError "missing-branch")`. Export E requires all three named branches; diagnostic D requires only A. A separate two-input zip has left and right returned domain errors. Also consider an empty fan-out, two returned domain errors, and a branch deliberately raising `System.IO.IOException "unwrapped"`; contrast it with an exception wrapped through `fromAsync` using message `"wrapped"` and another successful branch `ok 1`.

1. Predict the returned aggregate for A/B/C and separate retained values from eligibility of E and D. Keep authority separate from input coverage.
2. Determine which error zip selects when both fail, and whether that selection proves only one branch started.
3. Explain what empty success and all-failed collection mean for the required branch coverage.
4. Contrast the wrapped and unwrapped exception outcomes using the actual source. Identify what the boxed success list does not encode.
5. State one falsifier for a proposed DSL claiming to improve these joins compared with explicit functions and a checklist.

## Record

A learner supplies predictions, source locations, uncertainty and elapsed time. A reviewer scores each criterion against the separate rubric and records actual observations, without treating assisted performance as independent transfer. Subject and language reviewers must review their own claims separately. All current learner identity, elapsed-time, score and verdict fields remain unset.
