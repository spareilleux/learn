---
title: "9. Files, JSON and Unicode"
description: "Separate file acquisition, byte validity, JSON decoding and domain validation."
sidebar:
  order: 9
---

## Learning objectives

Read through a filesystem abstraction, decode typed records, reject invalid UTF-8 and distinguish syntax from domain rules.

## Four boundaries, four questions

A file path, a byte sequence, a JSON value and a valid study record are different things. [fs.ReadFile](https://pkg.go.dev/io/fs#ReadFile) acquires bytes from a filesystem. [utf8.Valid](https://pkg.go.dev/unicode/utf8#Valid) checks their encoding. [json.Unmarshal](https://pkg.go.dev/encoding/json#Unmarshal) decodes those bytes into a typed destination. Our final loop enforces the domain rules. Combining those steps in your mental model makes failures difficult to explain: a readable file can contain invalid JSON, and valid JSON can describe an invalid session.

The command uses [fstest.MapFS](https://pkg.go.dev/testing/fstest#MapFS), a standard-library filesystem held in memory. It deliberately avoids depending on a working-directory fixture or operating-system path separators. The filename records.json is interpreted within that filesystem. The same fs.ReadFile operation also accepts other fs.FS implementations. The CLI later opens a real caller-specified file; it shares the parser without pretending that an in-memory fixture proves disk permissions or path handling on every platform.

## Define the decoded shape

Load decodes an array of Record values using field tags name and minutes. It rejects null because the course requires an array, while an empty array is a valid log. Missing or empty names and negative durations fail domain validation. Missing minutes becomes its zero value under this model; zero is allowed. Unknown-field handling is not a strict schema guarantee here. If a stored interchange contract required strict unknown-field rejection, that would need an explicit decoder policy and tests.

Our loader reads all input before decoding. That is simple for a small local study log, but it is not a bounded streaming parser for untrusted large uploads. Do not advertise it as one. The advanced course treats streaming and framing separately. Also note that summing arbitrarily large integer values can overflow; the small educational fixtures and CLI do not establish a money or accounting contract.

## Unicode validity is not presentation width

The explicit UTF-8 check rejects invalid byte encodings before parsing. That policy does not normalize text or define visible character boundaries. café still has five bytes and four runes. A decomposed accent can have a different rune count while displaying similarly. The lesson preserves names as entered because its domain contract does not request linguistic normalization. Validate exactly what the application promises and keep presentation concerns separate.

C# developers may recognize [System.Text.Json](https://learn.microsoft.com/dotnet/standard/serialization/system-text-json/overview); Java has several ecosystem JSON libraries rather than a directly equivalent language feature. Go's standard library supplies the encoder and decoder, but library behavior remains versioned. Go 1.27 changes JSON implementation defaults. We use the specific encoding/json APIs linked here and test the course's accepted inputs, rather than extending older decoder assumptions into a universal compatibility claim.

## Trace the complete example

The example reads Sample through a filesystem, constructs an [`io.Reader`](https://pkg.go.dev/io#Reader) over those bytes and calls the same Load used by the CLI. It then reports two decoded records and the independent Unicode measurement. JSON syntax errors remain errors, and the authored tests include malformed text, trailing content and invalid UTF-8. A successful happy-path printout alone would not demonstrate those rejection contracts.

## Worked example

Complete source: [`cmd/l09/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l09/main.go).

```go
package main

import (
	"bytes"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"io/fs"
	"testing/fstest"
	"unicode/utf8"
)

func main() {
	disk := fstest.MapFS{"records.json": {Data: []byte(study.Sample)}}
	data, err := fs.ReadFile(disk, "records.json")
	if err != nil {
		panic(err)
	}
	records, err := study.Load(bytes.NewReader(data))
	if err != nil {
		panic(err)
	}
	fmt.Printf("records=%d bytes=%d runes=%d\n", len(records), len("café"), utf8.RuneCountInString("café"))
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l09
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
records=2 bytes=5 runes=4
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. Should null and an empty JSON array mean the same thing here?

<details>
<summary>Solution 1</summary>

No. The course requires a JSON array; null decodes to a nil slice and Load rejects it with ErrInvalid. An empty array is valid and produces a zero total. This is an application policy, not a claim that null is invalid JSON. The loader test covers both inputs explicitly.

</details>

2. Where would you add validation for an empty session name?

<details>
<summary>Solution 2</summary>

Keep it after decoding into Record, in the existing domain-validation loop. A JSON decoder can establish the field’s type without establishing that its contents are meaningful. The current condition checks empty Name and negative Minutes together and wraps ErrInvalid with the record index, preserving the distinction from syntax and read failures.

</details>

## Official sources

- [fs.ReadFile](https://pkg.go.dev/io/fs#ReadFile)
- [json.Unmarshal](https://pkg.go.dev/encoding/json#Unmarshal)
- [utf8.Valid](https://pkg.go.dev/unicode/utf8#Valid)
- [Go 1.27 library changes](https://go.dev/doc/go1.27#library)

[Next lesson](../10-generics-and-collections/) · [Journal](../journal/)
