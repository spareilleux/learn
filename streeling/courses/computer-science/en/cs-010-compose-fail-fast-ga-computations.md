---
module_id: cs-010-compose-fail-fast-ga-computations
department: computer-science
course: "Compose Fail-Fast GA Computations"
level: intermediate
prerequisites: ["cs-004-composable-agentic-audio-loop"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Compose Fail-Fast GA Computations

> **Draft scope.** Project-source experiment with synthetic inputs. Human subject, fluent-language and learner review remain pending; no release or public course readback is claimed.

## Objectives and project question

Compose a dependent calculation with the actual GA `GaAsync` operations, predict which callbacks run after an error, and distinguish algebraic reassociation from permission to reorder effects. **Project question:** how can a guitar or agentic pipeline retain the reason a prerequisite failed while preventing dependent work from starting?

The primary source is GA's [GaAsync module at `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs). Its `GaAsync<'T>` is `Async<Result<'T, GaError>>`. Here `Result` is the [F# result type](https://learn.microsoft.com/dotnet/fsharp/language-reference/results), not GA's separate C# `Result<TValue,TError>`. GA's [existing closure tests](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/GaClosureAndCeTests.cs) already exercise early-error propagation and error mapping. This lesson executes the F# module directly; it does not claim that the complete NUnit suite ran.

## 1. Separate a value transformation from a dependent computation

At the pinned revision, `ok x` makes a successful asynchronous result and `fail e` makes a failed one. `map f` transforms a successful value with an ordinary function. `bind f` accepts a function that returns another `GaAsync` computation and propagates its result. On an `Error`, both operations preserve that error and skip the supplied callback. This is a local control-flow property of a composition; it is not a global agent scheduling policy.

The lab starts with 5. Its first bound function doubles the value, its second adds 1, and its final map formats a label. The result observed by the runner is `Ok "ready:11"`; its trace is `["double"; "increment"]`. These arithmetic values model prerequisite outputs. They are not guitar frequencies, quality scores or accepted review receipts.

### Practice exercise 1

Predict the result for the same functions starting at 8. Which step needs `bind`, and which can use `map`? Explain why formatting the label must not be mistaken for approving the result.

> **Answer:** Doubling and incrementing give 17, so formatting gives `Ok "ready:17"`. The lab functions returning `GaAsync` are composed with `bind`; the ordinary formatting function can use `map`. A formatted label is only a value. Neither its text nor a successful computation supplies review or release authority.

## 2. Retain the first failure

The stopped case starts with `Error (DomainError "invalid-pitch")` and then composes the same bound functions. The observed result retains that exact domain error, and the callback trace is `[]`. No successful placeholder is inserted. That makes the corrective action visible instead of converting a failed prerequisite into a plausible number.

A source-reading subtlety matters: constructing a computation and running it are different operations. `GaAsync` uses [F# asynchronous workflows](https://learn.microsoft.com/dotnet/fsharp/language-reference/async-expressions). A callback skipped by `bind` is not invoked by that bind, but effects performed before the pipeline was constructed have already happened. The trace measures these fixture callbacks; it does not prove that an arbitrary pipeline has no external effects.

### Practice exercise 2

The first prerequisite returns `DomainError "missing-artifact"`. The next callback uploads a derived artifact. Under this `bind` chain, is that callback invoked? Would an upload performed before building the chain be undone?

> **Answer:** The callback is skipped and the error remains `DomainError "missing-artifact"`. An earlier upload is not undone. Fail-fast composition supplies neither a transaction nor compensation for effects outside the skipped callback.

## 3. Check a law with a bounded experiment

For pure functions with the stated types, bind associativity compares `(m |> bind f) |> bind g` with `m |> bind (fun x -> f x |> bind g)`. Both expressions keep the order `f` then `g`; reassociation does not swap them. The lab uses `validate`, which rejects nonpositive integers, and `format`, which returns a successful label. For inputs 5 and -1, the two forms respectively agree on `Ok "note:5"` and `Error (DomainError "nonpositive-note")`.

Two examples are evidence for those cases, not a proof for all values or all side effects. They also cannot establish equivalent timing, cancellation, retries or resource lifetimes. A useful dogfooding change is to write a counterexample prediction before altering the chain, then retain a failed prediction as evidence.

### Practice exercise 3

A colleague rewrites `validate` then `format` into `format` then `validate` and cites associativity. Is that the same transformation? What concrete input exposes the issue?

> **Answer:** No. Associativity changes grouping while preserving order; this proposal swaps operations and even changes their input types. The original -1 case returns the domain error before formatting. A reordered expression must first be type-checked and given its own semantics; the two fixture agreements do not justify it.

## 4. Add context without turning failure into success

The lab's `mapError` transforms `DomainError "invalid-pitch"` into `DomainError "wrapped: DomainError: invalid-pitch"`. The successful `Ok 42` case remains unchanged and does not call the error mapper. This is explicit transformation of the error channel. It should retain enough structure for the next corrective action; repeatedly turning structured errors into prose can destroy useful fields.

The lesson's string wrapper is deliberately small. A real agent handoff should retain artifact identity, producer, revision and error category when those matter. That is a project design requirement to assess at the boundary, not a feature supplied by this string fixture.

### Practice exercise 4

Would `mapError` be the right operation to return a successful default pitch after a missing input? State the observed success-path behavior and the information a recovery decision would need.

> **Answer:** No. `mapError` changes the error value while keeping the result failed. In the lab, its success-path example stays `Ok 42` and the mapper is not invoked. Recovery needs an explicit policy, a justified replacement input and a record of the original failure; it is a different operation from adding error context.

### Practice exercise 5

Write a result and trace expectation for a chain whose first result is `Error (DomainError "stale-source")` and whose only bound callback records `"publish"`. What wider claim would still be unjustified if this check passed?

> **Answer:** Expect the same error and an empty callback trace. Passing that case would establish only that this bind skips that callback for that input. It would not prove race-free publication, human review, durable delivery, cancellation safety or absence of effects elsewhere.

## Reproduce the project experiment

Use the [shared teaching lab](../../../../code/streeling/functional-composition/README.md), which loads an unchanged copy of GA's pinned module and retains its MIT license. [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) executes the lab with no NuGet package references. From the Learn repository root, the same command spelling applies on Windows, Linux/WSL and macOS:

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

The author observed SDK `10.0.113` on Windows, exit code 0, no compiler warnings, and 24 passing assertions. Other operating systems remain to verify. The [experiment record](../../../../code/streeling/evidence/functional-composition-2026-10-22/README.md) separates input provenance, execution and review. These are synthetic inputs executed by the actual pinned module, not captured GA application traffic. Read the learner packet before opening the runner, which contains the answers.

## Evidence and next check

The immutable GA module and its existing tests establish the source case study; the lab's captured observations establish only its executed inputs. Do not count an AI static review as human approval. A reviewer should check the claims against the pinned source, then a learner should attempt the separate source-assisted packet before consulting the answers. Integration, deployment and anonymous public readback remain separate steps.
