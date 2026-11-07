---
title: "2. Values, types and strings"
description: "Separate byte strings, Unicode code points and named numeric types."
sidebar:
  order: 2
---

## Learning objectives

Predict zero values and conversions, explain byte and rune counts, and give minutes a distinct named type.

## Values with an explicit representation

Go's [type system](https://go.dev/ref/spec#Types) separates a value's representation from the operations its type permits. A variable declaration without an initializer supplies the type's zero value: zero for numbers, false for booleans and an empty string for strings. These are actual initialized values. A useful zero value reduces setup code, but it does not replace a domain rule. An empty study name is still invalid for our log even though it is a perfectly valid Go string.

An int is a signed integer whose size depends on the target architecture. Use it for ordinary indexing and counts; choose an explicitly sized integer when a binary format requires one. Numeric types do not generally mix through automatic widening. An explicit conversion records the intended boundary, but does not itself prove that a value fits. Untyped constants have special representability rules, so a literal can initialize Minutes without implying that every int variable can be assigned there unchanged.

## Names can carry a domain distinction

Our declaration of Minutes creates a named type with int as its underlying type. It is not an alias. This lets us attach Double and prevents casually mixing a minutes variable with an unrelated named numeric type. Arithmetic on a Minutes value remains numeric arithmetic; naming the type does not automatically prohibit negative values or overflow. Load will enforce the nonnegative input rule later. Keep those responsibilities separate: static distinction catches one family of mistakes, validation catches another.

The short declaration syntax infers a variable's type from its initializer. It does not create a dynamically typed value. Reassignment still follows the type rules. Within an inner scope, a short declaration can also shadow an outer variable, which is especially easy to miss when checking an error. Read the declaration site, not just the identifier spelling. Formatting output with a decimal verb does not change the underlying numeric type or add validation.

## A string counts bytes

A [string](https://go.dev/ref/spec#String_types) is an immutable sequence of bytes, not an array of characters. Our café literal occupies five UTF-8 bytes and four Unicode code points. [`len`](https://pkg.go.dev/builtin#len) counts bytes; [utf8.RuneCountInString](https://pkg.go.dev/unicode/utf8#RuneCountInString) counts code points. A rune is an alias for int32 used to represent a Unicode code point. Neither count necessarily measures the number of visible user-perceived characters: combining marks and joined emoji need a richer model.

String indexing retrieves a byte. A range loop decodes UTF-8 and yields byte offsets plus rune values. Slicing at an arbitrary byte offset can split an encoded character. Go strings can contain invalid UTF-8, so validity is an input contract rather than a universal guarantee. Our JSON loader checks that contract explicitly. Do not normalize or trim names silently unless your application actually requires that policy; bytes, code points and application identities answer different questions.

## Moving from C# or Java

[C# string](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/reference-types#the-string-type) and [Java String](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html) expose UTF-16-oriented APIs. Carrying a character-count assumption directly into Go therefore changes its meaning. Go string equality compares byte sequences, so visually identical composed and decomposed spellings can remain unequal. The worked command demonstrates a modest, stable claim: five bytes, four runes, and a Minutes method doubling twenty. Read all three results as separate properties, then inspect the named type declaration in the shared package.

## Worked example

Complete source: [`cmd/l02/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l02/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"unicode/utf8"
)

func main() {
	name := "café"
	minutes := study.Minutes(20)
	fmt.Printf("bytes=%d runes=%d double=%d\n", len(name), utf8.RuneCountInString(name), minutes.Double())
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l02
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
bytes=5 runes=4 double=40
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. What changes if the name is the ASCII string go?

<details>
<summary>Solution 1</summary>

The byte length and rune count are both two because each ASCII code point occupies one UTF-8 byte. The numeric result remains forty because the string does not participate in the calculation. Replacing the text does not change the type of minutes or the receiver of Double.

</details>

2. Does converting a negative int to Minutes validate the duration?

<details>
<summary>Solution 2</summary>

No. The conversion expresses a numeric type conversion; it does not impose the study-log rule. The current Load function rejects negative record durations after decoding. Double multiplies the numeric receiver by two. A separate constructor could enforce a stronger type invariant, but this course deliberately teaches the existing boundary validation.

</details>

## Official sources

- [Language types](https://go.dev/ref/spec#Types)
- [String length](https://go.dev/ref/spec#Length_and_capacity)
- [UTF-8 rune counting](https://pkg.go.dev/unicode/utf8#RuneCountInString)

[Next lesson](../03-control-flow-and-functions/) · [Journal](../journal/)
