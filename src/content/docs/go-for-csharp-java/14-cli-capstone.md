---
title: "14. CLI capstone"
description: "Compose modules, typed data, JSON input, filtering and tested reporting into a usable command."
sidebar:
  order: 14
---

## Learning objectives

Trace the complete command, distinguish diagnostics from report output, and verify real input and output boundaries.

## The smallest complete application

The capstone is a study-log report. With no arguments it uses the course sample. The min flag selects sessions by an inclusive duration threshold. The file flag accepts a JSON filename, while a single dash selects standard input. The report preserves input order, prints each selected name and duration, then the total. This is a functioning local command rather than fourteen unrelated demonstrations joined only by prose.

The tiny main delegates to cli.Run and passes process arguments and standard streams. [os.Exit](https://pkg.go.dev/os#Exit) belongs at this process boundary. It ends the process without running deferred calls in main, so cleanup stays inside Run, whose normal return runs its defers first. This separation also lets tests exercise the application without terminating the test process. There is no test-only production hook: Run is the real entry point used by main.

## Walk the pipeline in dependency order

The [flag package](https://pkg.go.dev/flag) parses min and file through a dedicated [`FlagSet`](https://pkg.go.dev/flag#FlagSet). Invalid syntax, a negative minimum or unexpected positional arguments return the usage-error result. Help returns success. Acquisition then chooses the sample, the supplied [io.Reader](https://pkg.go.dev/io#Reader) or a file opened through [os.Open](https://pkg.go.dev/os#Open). The function closes only files it opened; it does not own standard input.

study.Load establishes encoding, JSON shape and record validity. study.Select materializes the matching values, and study.Total adds those selected durations. Formatting writes reports to out and diagnostics to errOut. Each output write is checked, so a broken downstream writer does not become a false success. Input and output failures return one; argument errors return two; success returns zero from Run. When launching through go run, distinguish the Go launcher’s own status behavior from the application's returned code.

## The tested seam spans the application

CLI tests supply genuine JSON text and capture both streams. They cover the sample, filtering, standard input, empty data, malformed JSON, invalid records, invalid flags and unexpected arguments. A temporary file checks acquisition through a real path. A failing writer checks that output failure changes the result. The command manifest additionally exercises the executable's default path and exact visible output. Together these checks cross parsing, domain operations and formatting without relying on an external service.

C# and Java developers may expect a dependency-injection container, command framework or service class. This application needs none of those to have a clear seam. The dependencies are streams and typed functions, and the effects are concentrated in one package. Introduce a framework only if a concrete application requirement justifies it. Small does not mean untested; the composition is the behavior that the integration tests observe.

## Scope the claim honestly

The command reads a small log completely into memory. It does not update files, merge duplicate names or promise Unicode normalization. It also does not establish a durable accounting format or enforce an overflow policy for arbitrary integer totals. Those are deliberate limits of this educational application, not hidden future features. The HTTP lesson offers another adapter around the same core; adding an HTTP hop to this CLI would not improve its current contract.

Review the journey: module imports supply the core, value types model durations, slices retain order, errors preserve causes, defer handles opened files, JSON validates input, and tests verify composition. Goroutines are available where a lifetime requires them, but ordinary local summation remains sequential. The advanced course can now build on a concrete understanding of these choices rather than a memorized list of syntax.

## Worked example

Complete source: [`cmd/l14/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l14/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/cli"
	"os"
)

func main() { os.Exit(cli.Run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr)) }
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l14
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
types: 15 min
go: 25 min
total: 40 min
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. How do you report only the sample session lasting at least twenty minutes?

<details>
<summary>Solution 1</summary>

Run go run ./cmd/l14 -min 20 from the module directory. Select retains only go, whose duration is twenty-five, so the report contains that session and a twenty-five-minute total. The existing filter integration case checks this behavior. No parsing or filtering rule needs to be duplicated in main.

</details>

2. A user supplies a JSON file with a negative duration. Trace the outcome.

<details>
<summary>Solution 2</summary>

Run opens the file and registers its close, then Load rejects the record and wraps ErrInvalid. Run writes an input diagnostic to errOut, returns one and closes the file as its defer runs. It writes no report to out. The invalid-record test checks the same parser and boundary without depending on the exact diagnostic wording.

</details>

## Official sources

- [flag package](https://pkg.go.dev/flag)
- [io.Reader](https://pkg.go.dev/io#Reader)
- [os.Open](https://pkg.go.dev/os#Open)
- [os.Exit](https://pkg.go.dev/os#Exit)

[Continue with advanced Go](../../go-advanced/) · [Journal](../journal/)
