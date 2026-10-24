# GA functional composition teaching lab

This experiment executes an unchanged public `GaAsync.fs` from GA commit `dc2e74cbd992a298f67efb928b5b3754615e1924`. `source.json` binds its bytes and the retained MIT license. It does not build or change the GA application.

## Run

Install the [.NET SDK](https://learn.microsoft.com/dotnet/core/install/) with [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/). From the Learn repository root, the same command spelling applies on Windows, Linux/WSL and macOS:

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

The author ran this with SDK `10.0.113` on Windows. Linux/WSL and macOS execution remains to verify. There are no NuGet references, package installs, host services or network calls in the runner. Each asynchronous computation has a 5-second timeout, which is a lab bound rather than a performance target.

## Predict before running

The runner contains answers. Use the separate learner packet in `../evidence/functional-composition-2026-10-22/` before opening it. The synthetic values represent computation outputs, not measured audio quality or approved agent evidence.

The runner checks success and stopped bind chains, pure reassociation examples, error mapping, optional-value promotion, an exception boundary, empty/successful/partially failed fan-outs, all-failed fan-outs, parallel zip selection, and wrapped versus unwrapped exceptions. A mismatch raises an error and exits nonzero. JSON observations use F# display strings so no union serializer dependency is required.

## Evidence limits

This is native execution of one pinned module with synthetic inputs. It is not the complete GA NUnit suite, an agent scheduler, durable handoff transport, IXQL execution, a Godot/WASM render, a human review or a publication gate. Successful partial values do not authorize downstream effects. Heterogeneous evidence should retain producer, artifact and revision identifiers; this homogeneous integer fixture does not supply them.
