---
title: "4. Error contracts and typed nil"
description: "Preserve error identity across layers and return a genuinely nil interface on success."
sidebar:
  order: 4
---

## Learning objective

Preserve error identity across layers and return a genuinely nil interface on success.

## Mechanics and mental models

The [errors](https://pkg.go.dev/errors) package separates recognizing an error from displaying its message. NewJob wraps ErrInvalid using the wrapping format directive. A caller can add context without losing the identity that errors.Is checks. errors.As finds a compatible typed error in the error tree and fills a target pointer. Compare identities and types for program decisions; reserve human readable strings for explanation. Changing punctuation should not silently alter the caller's control flow.

An interface value contains dynamic type information as well as a dynamic value. TypedNil returns an error interface containing a nil pointer of type ValidationError. That interface is not nil. Validate instead returns literal nil on success. The command prints the difference without dereferencing a nil pointer. ValidationError.Error accepts a nil receiver, which makes displaying that particular value safe; other types may panic on such a call. The lesson is the interface representation, not a rule that nil receivers always work.

C# nullable reference annotations describe a static contract, while Java null is a reference value; neither directly predicts Go interface nil equality. Think about both parts of the interface. A function returning a concrete pointer can return its zero value successfully, but converting that pointer to error creates a different contract. Prefer error as the declared result type for functions whose callers should use the ordinary error convention, and write an explicit nil success return.

Wrapping an implementation error also exposes something to callers. If users begin matching a particular driver error, replacing that driver can become a public compatibility change. Decide which errors are meaningful at the package boundary. This course exposes invalid, full and closed identities because callers can choose validation, overload and shutdown responses. It does not promise every underlying representation. A panic remains suitable for a violated programmer assumption at a process boundary, not routine invalid user input. Multiple errors may be joined when both matter, but callers should not depend on a formatted tree's layout.

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

[cmd/l04/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l04/main.go)

```go
package main

import (
	"errors"
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	fmt.Println(domain.TypedNil() == nil, domain.Validate("ok") == nil)
	var detail *domain.ValidationError
	fmt.Println(errors.As(domain.Validate(""), &detail), detail.Field)
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l04
```

### Expected output contract

```text
false true
true name
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Why is TypedNil() == nil false?

<details>
<summary>Complete solution</summary>

The interface retains the dynamic pointer type even though the pointer value is nil. Return literal nil from the success path as Validate does; do not repair callers with string comparisons.

</details>

2. How can an HTTP adapter recognize a wrapped invalid job?

<details>
<summary>Complete solution</summary>

Use errors.Is(err, domain.ErrInvalid). For ValidationError details, use errors.As with a pointer target. Both traverse wrapped errors; direct equality recognizes only the unwrapped sentinel itself.

</details>

## Primary sources

- [errors](https://pkg.go.dev/errors)
- [FAQ: nil error](https://go.dev/doc/faq#nil_error)

[Next lesson](../05-memory-model-sync-and-atomics/) · [Learning journal](../journal/)
