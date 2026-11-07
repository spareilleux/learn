---
title: "7. Interfaces and composition"
description: "Use implicit interface satisfaction and recognize a typed nil inside an interface."
sidebar:
  order: 7
---

## Learning objectives

Separate a nil pointer from a nil interface, reason about method sets, and choose small interfaces at their consumer.

## State the behavior a caller needs

An [interface](https://go.dev/ref/spec#Interface_types) describes behavior. Named requires a Label method returning string; Record satisfies that contract without declaring an implements relationship. Its pointer type also has access to the value-receiver method. The consumer can describe a small requirement without making the producer inherit a shared base class. This works across packages, so a local interface can accept an existing type you did not design.

Our later loader consumes [io.Reader](https://pkg.go.dev/io#Reader), which abstracts reading bytes rather than naming files, terminals and strings separately. That is a useful interface because the loader needs the read operation and tests can supply real in-memory readers. Avoid defining an interface mirroring every method of one concrete type just to resemble a C# service registration pattern. Start from what the consumer actually calls.

## An interface contains more than a pointer

An interface value has a dynamic type and a dynamic value. It is nil only when both are absent. In the worked program, pointer is a nil *Record. Assigning it to Named installs that pointer type as the dynamic type, even though the dynamic pointer value is nil. Therefore pointer equals nil, while named does not. This is a language-level distinction with practical consequences for error returns and optional dependencies.

The example deliberately does not call named.Label. Label uses a value receiver and accessing a value through this nil pointer would require a dereference. The nonnil interface does not guarantee that a call is safe. To return an absent interface, return a plain nil at the boundary instead of converting a typed nil pointer into the interface. Tests make that distinction observable without inventing a compiler error or relying on an unstable runtime diagnostic.

## Compose behavior rather than inherit state

Struct embedding can promote methods from an embedded field, and interface embedding can combine method requirements. Neither creates the same subtype relationship as class inheritance. The containing struct still has its own identity and fields. Use embedding when promotion expresses the public behavior you want; use an ordinary named field when callers should go through that field explicitly. Composition is also possible with no embedding at all.

C# and Java interfaces are familiar contracts, but implementations usually declare that relationship. Go satisfaction is implicit and depends on [method sets](https://go.dev/ref/spec#Method_sets). A method with a pointer receiver can make *T satisfy an interface without making T satisfy it. The convenient address-taking used for a direct call on a local variable does not rewrite interface satisfaction rules. This is why receiver choice belongs to the API design.

## Version-aware limits

Keep ordinary behavior interfaces distinct from constraints used with type parameters. The any alias is the empty interface; it permits storing values but does not grant operations specific to their hidden types. Recovering concrete behavior needs a type assertion or switch, not wishful duck typing. In Go 1.27 concrete methods can declare type parameters, but interface methods still cannot declare their own type parameters or be implemented by generic methods. That limit does not mean Go lacks generic methods; it describes the particular interface boundary.

## Worked example

Complete source: [`cmd/l07/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l07/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

type Named interface{ Label() string }

func main() {
	var pointer *study.Record
	var named Named = pointer
	value := study.Fixture()[0]
	fmt.Printf("pointer-nil=%t interface-nil=%t label=%s\n", pointer == nil, named == nil, value.Label())
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l07
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
pointer-nil=true interface-nil=false label=types
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. Why are pointer-nil and interface-nil different in the output?

<details>
<summary>Solution 1</summary>

pointer is a nil *Record, but assigning it to Named retains *Record as a dynamic type. The interface is therefore not the empty nil interface. The example compares both without invoking a method on the nil target. To represent no Named value at all, initialize or return the interface itself as nil.

</details>

2. What should Load accept if callers have either files or strings?

<details>
<summary>Solution 2</summary>

Accept io.Reader, as the checked-in Load already does. Both a file and strings.NewReader provide the read operation. Parsing stays in Load while acquisition stays with the caller. There is no need for a second loader or a wide application interface; the small byte-reading contract expresses the actual dependency.

</details>

## Official sources

- [Interface types](https://go.dev/ref/spec#Interface_types)
- [Method sets](https://go.dev/ref/spec#Method_sets)
- [io.Reader](https://pkg.go.dev/io#Reader)
- [Go 1.27 language changes](https://go.dev/doc/go1.27#language)

[Next lesson](../08-errors-defer-and-resources/) · [Journal](../journal/)
