---
title: "1. Package and module boundaries"
description: "Design a small domain package whose ownership and errors remain understandable without its HTTP adapter."
sidebar:
  order: 1
---

## Learning objective

Design a small domain package whose ownership and errors remain understandable without its HTTP adapter.

## Mechanics and mental models

A [module](https://go.dev/ref/mod) is a versioned collection of packages, while a package is the unit of compilation, visibility and dependency. A directory of ordinary Go files generally supplies one package. The module path is the prefix of its import paths; it does not create an assembly containing every exported symbol. Begin with a responsibility that a caller can name: domain values, framing, or job admission. A package called helpers usually hides the dependency decision instead of resolving it.

The worked domain package constructs a job by checking its name and copying the input slice. Exporting Job permits adapters to exchange a useful value; NewJob provides a convenient validated construction path. Because exported fields still allow direct construction, the service validates again at its actual admission boundary. This is deliberate: a constructor convention alone cannot guarantee invariants for an exported struct. A stricter library could hide fields and provide accessors, but this course keeps the transport boundary visible.

A C# namespace and a Java package offer useful naming analogies, but neither maps exactly to a Go module. Uppercase identifiers are exported from a Go package; there is no public keyword on each declaration. The internal directory convention restricts importers to the parent tree, and import cycles are rejected. Prefer a small interface at its consumer when replacement is actually needed. Making every concrete type an interface merely translates a dependency injection habit without reducing a dependency.

Trace the future service inward: HTTP imports jobs, jobs imports domain, and domain imports only the standard library. The domain package must not import HTTP to format a status code. Otherwise a business error would carry a transport decision into every caller. Versioning belongs at the module boundary: a breaking public API after version one normally requires a new major import path. This example module is teaching code, not a promise to publish a package registry entry.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[domain/job.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/domain/job.go)

```go
package domain

import (
	"errors"
	"fmt"
	"strings"
)

var ErrInvalid = errors.New("invalid job")

type Job struct {
	Name   string
	Values []int
}

func NewJob(name string, values []int) (Job, error) {
	if strings.TrimSpace(name) == "" {
		return Job{}, fmt.Errorf("name: %w", ErrInvalid)
	}
	return Job{Name: name, Values: append([]int(nil), values...)}, nil
}

func (j Job) Total() int {
	var total int
	for _, v := range j.Values {
		total += v
	}
	return total
}

func Clone(data []byte) []byte { return append([]byte(nil), data...) }

type ValidationError struct{ Field string }

func (e *ValidationError) Error() string {
	if e == nil {
		return "nil validation"
	}
	return "invalid " + e.Field
}
func Validate(name string) error {
	if name == "" {
		return &ValidationError{Field: "name"}
	}
	return nil
}
func TypedNil() error { var e *ValidationError; return e }
```

[cmd/l01/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l01/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	job, err := domain.NewJob("sum", []int{2, 3})
	if err != nil {
		panic(err)
	}
	fmt.Println(job.Name, job.Total())
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l01
```

### Expected output contract

```text
sum 5
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. The caller changes the original slice after NewJob. What must remain true, and why?

<details>
<summary>Complete solution</summary>

The job total remains five because its backing array was copied. TestOwnership mutates the input and checks the observable total; assigning a slice descriptor alone would retain the alias.

</details>

2. Where should a rule mapping invalid jobs to HTTP 400 live?

<details>
<summary>Complete solution</summary>

In the HTTP adapter. Domain construction returns an error identity; the adapter chooses a response status, while another consumer could choose a command exit code. Keep the import direction toward the domain.

</details>

## Primary sources

- [Go modules reference](https://go.dev/ref/mod)
- [Package names](https://go.dev/blog/package-names)

[Next lesson](../02-memory-escape-and-gc/) · [Learning journal](../journal/)
