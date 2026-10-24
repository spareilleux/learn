---
module_id: net-005-fanout-results-and-dependency-joins
department: network-science
course: "Fan-Out Results and Dependency Joins"
level: intermediate
prerequisites: ["net-004-semantic-backpressure-and-evidence-dependencies"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Fan-Out Results and Dependency Joins

> **Draft scope.** Project-source experiment with synthetic inputs. Human subject, fluent-language and learner review remain pending; no release or public course readback is claimed.

## Objectives and project question

Model branch computations and their join as a small dependency graph, distinguish retained partial work from permission to release an aggregate, and test the failure assumptions behind a parallel fan-out. **Project question:** can a GA or agentic workflow keep useful independent results when one branch fails, while still preventing a dependent all-inputs action from claiming success?

The executable source is GA's [GaAsync module at `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs). Its `zip` and `fanOutAll` compose [F# asynchronous workflows](https://learn.microsoft.com/dotnet/fsharp/language-reference/async-expressions). The [existing GA tests](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/GaClosureAndCeTests.cs) include a retained-partial-results case. The shared lab executes this module with synthetic branch values; it does not inspect current wmux sessions or implement a distributed scheduler.

## 1. Draw the join before choosing the combinator

Consider independent branches A, B and C feeding a join J. If a downstream artifact requires all three branches, J has an AND dependency: two successful inputs do not satisfy it. A separate downstream action may require only A, in which case B's failure need not block that action. These dependencies come from the consumer's contract, not from the number of green branches.

The lab assigns outputs 100 and 300 to successful branches and `DomainError "missing-branch"` to the failing branch. These integers are identifiers for demonstration, not artifact payloads or quality measurements. The actual `fanOutAll` returns an error carrying `PartialFailure` with successes `[100; 300]` and one error. Useful values are retained, but the aggregate has not become `Ok`.

### Practice exercise 1

A and C succeed while B fails. An export requires A, B and C, while a diagnostic needs only A. Under those stated dependencies, which action has all its inputs? Does `PartialFailure` itself authorize either external action?

> **Answer:** The diagnostic has its required input, while the export's AND dependency is incomplete. `PartialFailure` retains information about the branch results; it does not supply authority for any external action. Input identity, revision validity and authorization must also be checked by the consumer.

## 2. Do not infer partial collection from parallel execution

The pinned `zip` runs two workflows with `Async.Parallel`. If both return `Ok`, it returns their pair: the fixture observes `Ok (2, 3)`. If both return domain errors, the source chooses the left input's error. The fixture observes `Error (DomainError "left")` and separately records that both branch bodies started. Choosing one error is therefore not evidence that only one branch ran.

This join differs from `bind`: the latter skips its dependent callback after an error, while these zip inputs are independent workflows started together. A parallel join can discard diagnostic detail even though work occurred on both sides. Which error finishes first is not the selector used by this pinned `zip` match expression.

### Practice exercise 2

Two zip branches return domain errors named `left` and `right`. A dashboard reports only `left` and concludes that the right branch never started. Which fixture observation contradicts that conclusion, and which wider timing claim remains untested?

> **Answer:** The recorded started-branch set contains both `left` and `right`, while the result chooses the left error. This contradicts the inference that the other branch did not start. The experiment does not establish production completion order, latency, throughput or a scheduler fairness guarantee.

## 3. Interpret empty and all-failed collections

The lab observes `Ok []` for an empty fan-out and `Ok [100; 300]` for an all-successful one. For two failed inputs it observes `PartialFailure` with 0 successes and 2 errors, preserving the input order of the two domain errors. The case name “partial” does not require at least one successful branch in this implementation.

An empty successful computation is not proof that required work existed or was done. A consumer expecting three branch outputs should validate that coverage explicitly. Similarly, preserving two error values does not create branch identifiers. The source retains successful values as `obj list`; unpacking this homogeneous integer example is safe because the fixture knows its type, but mixed evidence needs an explicit typed envelope and identity contract before operational use.

### Practice exercise 3

A required three-branch export receives `Ok []`. May it mark its dependency coverage complete? What does a two-error `PartialFailure` tell you, and what does it omit?

> **Answer:** No. A successful empty collection does not establish the three expected inputs. The two-error result records that this collection's two supplied computations returned errors and retained no successes; it does not by itself identify the required branches, source revisions, retry policy or release authority.

## 4. State the exception assumption

`fanOutAll` collects returned `Result` values, but it does not surround every branch with an exception-to-result conversion. The lab's deliberate unwrapped `System.IO.IOException "unwrapped"` escapes the fan-out. It does not become a `PartialFailure`. Wrapping the deliberate exception through the module's `fromAsync` instead yields a `PartialFailure` retaining successful value 1 and an `IoError` with message `"wrapped"` and the original exception type.

This is the main falsifier for an overly broad “all branches always settle as values” claim. Converting known infrastructure failures at a named boundary can make the error channel explicit, but this experiment does not prove cancellation safety, durable retention or that every possible failure is representable. An escaped exception in a distributed system can have different consequences from this in-process F# fixture.

### Practice exercise 4

A worker writes “`fanOutAll` always preserves successful outputs, whatever another branch does.” Does the unwrapped-exception experiment support that statement? State the narrower behavior actually observed.

> **Answer:** No. The unwrapped exception escapes rather than producing the partial-results value. The retained-success observation holds for the supplied branches that return results, including the tested exception converted through `fromAsync`. It is not a guarantee about arbitrary throws, cancellation, process loss or durable storage.

## 5. Compare against a simpler workflow

A proposed agent DSL could expose separate dependent composition, all-input joins and partial-result collection. The strongest counterargument is that a short explicit function plus a consumer checklist may already express the workflow. A new DSL adds parsing, debugging, identity, recovery and policy-maintenance costs. Retain this as a candidate until a measured comparison shows a benefit.

For a finite trial, use the same synthetic success, domain-error and exception inputs in both interfaces. Compare wrong all-input admissions, lost error categories, retained useful branch values and the time an operator needs to explain the result. Reject the DSL candidate if it admits the incomplete export, hides the escaped-exception distinction, or gives the same decisions with more maintenance and no measured benefit. No DSL is implemented by this course.

### Practice exercise 5

Propose one expected result for a domain-error branch and one for an unwrapped exception. Name a guardrail for evaluating a new DSL against explicit GA function composition.

> **Answer:** With inputs `ok 100`, the returned domain error, and `ok 300`, expect a failed aggregate retaining `[100; 300]` and the error. With the deliberate unwrapped exception, expect the exception to escape rather than a `PartialFailure`. A suitable guardrail is zero admissions of the export while its declared required input is missing. Record lost diagnostics and operator explanation time as separate observations; a passing fixture does not establish agentic throughput or a release.

## Reproduce the project experiment

Use the [shared teaching lab](../../../../code/streeling/functional-composition/README.md), which loads an unchanged copy of GA's pinned module and retains its MIT license. [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) executes the lab with no NuGet package references. From the Learn repository root, the same command spelling applies on Windows, Linux/WSL and macOS:

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

The author observed SDK `10.0.113` on Windows, exit code 0, no compiler warnings, and 24 passing assertions. Other operating systems remain to verify. The [experiment record](../../../../code/streeling/evidence/functional-composition-2026-10-22/README.md) separates input provenance, execution and review. These are synthetic inputs executed by the actual pinned module, not captured GA application traffic. Read the learner packet before opening the runner, which contains the answers.

## Evidence and next check

The immutable GA module and its existing tests establish the source case study; the lab's captured observations establish only its executed inputs. Do not count an AI static review as human approval. A reviewer should check the claims against the pinned source, then a learner should attempt the separate source-assisted packet before consulting the answers. Integration, deployment and anonymous public readback remain separate steps.
