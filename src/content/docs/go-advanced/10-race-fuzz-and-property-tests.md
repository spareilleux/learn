---
title: "10. Race, fuzz and property tests"
description: "Turn a behavioral law into a seed-running fuzz target without overstating its coverage."
sidebar:
  order: 10
---

## Learning objective

Turn a behavioral law into a seed-running fuzz target without overstating its coverage.

## Mechanics and mental models

The [race detector](https://go.dev/doc/articles/race_detector) instruments accesses in the program actually run. A passing race run says no race was observed in those executions; it is not a static proof about all schedules. Use meaningful concurrent integration paths, including cancellation and draining, instead of relying on a single thread happy path. Run go test -race ./... on a supported environment and record its actual result. A test with a race that happens to print the expected value remains incorrect.

The [fuzzing tutorial](https://go.dev/doc/tutorial/fuzz) distinguishes seed execution from active input generation. Ordinary go test executes the seed corpus. A command with -fuzz searches additional inputs and may save minimized failures. Our FuzzReverse supplies empty, ASCII, accented and emoji seeds. It checks a law: reversing a valid UTF-8 string twice returns the original. Arbitrary byte strings are not all valid UTF-8, and converting invalid bytes to runes normalizes them, so the domain restriction is essential rather than an excuse for a failure.

The property test uses testing/quick to generate values for the same law. The framing target checks that bounded arbitrary bytes survive a write/read round trip, while the malformed frame table covers known rejection cases directly. Round trips alone can miss two mutually compatible bugs, such as encoder and decoder both using the wrong byte order. That is why the protocol also needs explicit header expectations and malformed lengths. Choose laws and concrete examples together; neither substitutes for knowing the wire contract.

C# and Java test frameworks can express the same properties, but Go fuzz targets are recognized by the standard toolchain and have a required signature. Keep the target deterministic with respect to its input and avoid external network dependencies. A fuzz failure is useful only if it can be replayed and its input retained. Seed tests, active fuzzing, race instrumentation and platform coverage are separate evidence. The journal initially marks active search and the race run pending; no number of generated cases or uncovered bugs is invented to make the course sound complete.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[collection/sequence_test.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/collection/sequence_test.go)

```go
package collection

import (
	"slices"
	"testing"
	"testing/quick"
	"unicode/utf8"
)

func TestMapStops(t *testing.T) {
	calls := 0
	for v := range Map(slices.Values([]int{1, 2, 3}), func(v int) int { calls++; return v * 2 }) {
		if v != 2 {
			t.Fatal(v)
		}
		break
	}
	if calls != 1 {
		t.Fatalf("iterator ignored stop: %d", calls)
	}
}
func TestReverseProperty(t *testing.T) {
	property := func(s string) bool { return !utf8.ValidString(s) || Reverse(Reverse(s)) == s }
	if err := quick.Check(property, nil); err != nil {
		t.Fatal(err)
	}
}
func FuzzReverse(f *testing.F) {
	for _, seed := range []string{"", "abc", "été", "🙂x"} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, s string) {
		if !utf8.ValidString(s) {
			t.Skip()
		}
		if Reverse(Reverse(s)) != s {
			t.Fatal("involution")
		}
	})
}
```

[cmd/l10/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l10/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/collection"
	"fmt"
)

func main() {
	text := "été Go"
	fmt.Println(collection.Reverse(text))
	fmt.Println(collection.Reverse(collection.Reverse(text)) == text)
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l10
```

### Expected output contract

```text
oG été
true
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Why skip invalid UTF-8 in the string involution test?

<details>
<summary>Complete solution</summary>

The implementation reverses runes, not raw bytes. Decoding invalid UTF-8 replaces invalid encodings, so the original bytes cannot always be reconstructed. Restrict that property to valid text and use the framing property for arbitrary bytes.

</details>

2. Does a successful ordinary go test prove active fuzzing ran?

<details>
<summary>Complete solution</summary>

No. It runs seed cases. Active fuzzing requires an explicit fuzz command and separate recorded duration and result. Keep race, fuzz and ordinary test evidence distinct in the journal.

</details>

## Primary sources

- [Race detector](https://go.dev/doc/articles/race_detector)
- [Fuzzing tutorial](https://go.dev/doc/tutorial/fuzz)
- [testing/quick](https://pkg.go.dev/testing/quick)

[Next lesson](../11-benchmarks-pprof-and-trace/) · [Learning journal](../journal/)
