---
title: "12. Reflection, encoding and boundaries"
description: "Make encoding choices part of the boundary contract and keep reflection narrowly typed."
sidebar:
  order: 12
---

## Learning objective

Make encoding choices part of the boundary contract and keep reflection narrowly typed.

## Mechanics and mental models

[encoding/json/v2](https://pkg.go.dev/encoding/json/v2) and [encoding/json/jsontext](https://pkg.go.dev/encoding/json/jsontext) are stable additions in Go 1.27. The v2 package maps Go values to JSON; jsontext handles the syntactic JSON layer. Existing encoding/json is backed by the newer implementation while preserving its established v1 behavior. Sharing implementation does not make all default semantics interchangeable. Select an API and its options as an explicit wire contract, then test the fields and edge cases that clients actually depend on.

Record has named JSON fields and Decode requests rejection of unknown members. Encode and Decode operate on bytes with a concrete destination type. This avoids a generic map of arbitrary runtime values where number interpretation and missing fields become implicit decisions. Rejection of unknown members is one policy; a version tolerant public protocol may intentionally permit new fields instead. The course chooses strict input to teach the decision, not to declare strictness universally compatible with every evolution strategy.

The [reflect](https://pkg.go.dev/reflect) helper asks for type information only after checking nil and kind. NumField is meaningful for a struct, not every value. Fields returns zero for nil and non-struct values, and returns two for Record. Counting fields neither serializes them nor proves they are exported or writable. Runtime reflection can panic when used with the wrong kind, and setting through reflection requires an addressable settable value. A small type switch or an explicit interface is often simpler when the alternatives are known.

C# attributes and Java annotations may resemble Go struct tags, but tags are strings interpreted by a library rather than a general executable annotation framework. Likewise, reflection is not a replacement for static generic constraints. Keep a typed boundary for normal operations and isolate dynamic inspection where the input is genuinely open ended. unsafe and cgo are outside this executable course: they cross memory or foreign-runtime boundaries, introduce additional ownership rules and complicate portability. Their existence is not a reason to replace safe reflection with layout assumptions. Verify encoding behavior against the selected Go 1.27 compiler instead of extrapolating earlier experimental JSON notes.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[encodingx/record.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/encodingx/record.go)

```go
package encodingx

import (
	"encoding/json/v2"
	"reflect"
)

type Record struct {
	Name   string `json:"name"`
	Values []int  `json:"values"`
}

func Encode(value Record) ([]byte, error) { return json.Marshal(value) }
func Decode(data []byte) (Record, error) {
	var value Record
	err := json.Unmarshal(data, &value, json.RejectUnknownMembers(true))
	return value, err
}
func Fields(value any) int {
	t := reflect.TypeOf(value)
	if t == nil || t.Kind() != reflect.Struct {
		return 0
	}
	return t.NumField()
}
```

[cmd/l12/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l12/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/encodingx"
	"fmt"
)

func main() {
	value := encodingx.Record{Name: "sum", Values: []int{2, 3}}
	data, err := encodingx.Encode(value)
	if err != nil {
		panic(err)
	}
	decoded, err := encodingx.Decode(data)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(data))
	fmt.Println(decoded.Name, encodingx.Fields(decoded))
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l12
```

### Expected output contract

```text
{"name":"sum","values":[2,3]}
sum 2
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Does a successful round trip prove public JSON compatibility?

<details>
<summary>Complete solution</summary>

No. Encoder and decoder may share the same unexpected behavior. Add exact wire expectations and representative old client inputs; explicitly choose unknown-field, null, number and naming policies before changing an existing protocol.

</details>

2. Why inspect Kind before NumField?

<details>
<summary>Complete solution</summary>

NumField requires a struct type. Checking nil and kind establishes that precondition and gives this helper a predictable zero result outside its supported domain, without relying on panic recovery for normal control flow.

</details>

## Primary sources

- [encoding/json/v2](https://pkg.go.dev/encoding/json/v2)
- [encoding/json/jsontext](https://pkg.go.dev/encoding/json/jsontext)
- [reflect](https://pkg.go.dev/reflect)
- [Go 1.27](https://go.dev/doc/go1.27)

[Next lesson](../13-dependencies-builds-and-security/) · [Learning journal](../journal/)
