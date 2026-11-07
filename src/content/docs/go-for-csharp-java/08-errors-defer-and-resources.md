---
title: "8. Errors, defer and resources"
description: "Preserve error identity, add useful context and release owned resources."
sidebar:
  order: 8
---

## Learning objectives

Distinguish expected input errors from programming failures, inspect wrapped errors and place cleanup at the acquisition boundary.

## Failure is part of the function result

Go's [error interface](https://pkg.go.dev/builtin#error) describes a value with an Error method. Functions commonly return a useful value and an error, and callers check the error before using the value. Our Load returns records only after reading, decoding and validation succeed. Malformed user data is an ordinary failure of that operation. It should be reported to the caller instead of terminating the process deep inside a reusable package.

The worked command loads known fixture data, then deliberately submits an invalid empty name. The first operation should produce forty total minutes. The second should produce an error linked to ErrInvalid. The panic on an unexpected fixture error is confined to the teaching command's startup assumption; the reusable loader does not panic for invalid user input. The CLI will turn that same error into a diagnostic and nonzero status.

## Context must preserve the cause

[fmt.Errorf](https://pkg.go.dev/fmt#Errorf) with a wrapping verb adds a useful location while preserving an underlying error. Load identifies the record index and wraps ErrInvalid. [errors.Is](https://pkg.go.dev/errors#Is) can then recognize that cause through the added context. Comparing the complete message would turn harmless wording changes into compatibility breaks. Comparing only the outer error with equality would miss the wrapped sentinel.

Not every failure is ErrInvalid. A reader failure preserves its own cause; JSON syntax and type errors retain decoder information. Decide which distinctions the caller actually needs. A sentinel provides category identity; a concrete error type and [`errors.As`](https://pkg.go.dev/errors#As) can expose structured details when a real consumer needs them. Do not add a taxonomy merely to reproduce a hierarchy of exceptions. The current tests verify both invalid-record identity and preservation of a real read failure.

## Cleanup follows successful acquisition

A [defer statement](https://go.dev/ref/spec#Defer_statements) schedules a call when the surrounding function returns. Register cleanup only after acquisition succeeds. In the CLI, [`os.Open`](https://pkg.go.dev/os#Open) returns a file and an error; only the successful branch defers [File.Close](https://pkg.go.dev/os#File.Close). Defer arguments are evaluated when the statement executes, while deferred calls run in reverse registration order. A defer inside a long-running loop waits until the function returns, so move one resource lifetime into a smaller function if necessary.

Closing an input file releases a resource; it does not own the caller's standard input. The CLI therefore closes files it opens and leaves the supplied reader's lifetime to its caller. For output files, Close may carry a meaningful failure and must be considered as part of successful writing. Our capstone only opens input files and checks output writes, so it does not claim to implement durable file replacement.

## Transfer the control flow, not the syntax

[C# using](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/using) and [Java try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html) associate cleanup with a lexical construct. Go defer associates it with a function return. Ordinary errors are also explicitly returned instead of unwinding automatically through callers. This makes every decision visible but requires checking every relevant result. Silencing an error with the blank identifier is a deliberate loss of information, not equivalent to successful handling.

## Worked example

Complete source: [`cmd/l08/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l08/main.go).

```go
package main

import (
	"errors"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"strings"
)

func main() {
	records, err := study.Load(strings.NewReader(study.Sample))
	if err != nil {
		panic(err)
	}
	_, invalid := study.Load(strings.NewReader(`[{"name":"","minutes":1}]`))
	fmt.Printf("total=%d invalid=%t\n", study.Total(records), errors.Is(invalid, study.ErrInvalid))
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l08
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
total=40 invalid=true
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. Why use errors.Is rather than compare the error text?

<details>
<summary>Solution 1</summary>

Load adds context such as the failing record index, so the outer error is not the sentinel itself. errors.Is follows wrapping to identify ErrInvalid. Text comparison would depend on wording and punctuation. The authored validation test demonstrates the intended contract without promising an exact diagnostic string to users.

</details>

2. Who closes a file passed into Load, and where does defer belong?

<details>
<summary>Solution 2</summary>

The caller that successfully opens the file owns closing it. Load accepts io.Reader and cannot assume that reader is a file or that it owns its lifetime. In cli.Run, defer follows the successful os.Open branch. Returning early after a parsing failure still executes that deferred close.

</details>

## Official sources

- [errors.Is](https://pkg.go.dev/errors#Is)
- [fmt.Errorf](https://pkg.go.dev/fmt#Errorf)
- [Defer statements](https://go.dev/ref/spec#Defer_statements)
- [File.Close](https://pkg.go.dev/os#File.Close)

[Next lesson](../09-files-json-and-unicode/) · [Journal](../journal/)
