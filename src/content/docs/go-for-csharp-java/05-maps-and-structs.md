---
title: "5. Maps and structs"
description: "Model records as values and aggregate names without confusing absence with zero."
sidebar:
  order: 5
---

## Learning objectives

Use keyed struct literals, aggregate into a map, and distinguish a missing key from a stored zero.

## Name the data before choosing the collection

A [struct](https://go.dev/ref/spec#Struct_types) groups named fields. Record has Name and Minutes, so its literal describes a study session rather than an anonymous pair. Keyed literals [`make`](https://pkg.go.dev/builtin#make) the field relationship visible and tolerate field reordering better than positional literals. The capitalized fields are exported; their JSON tags specify external names. A tag is metadata, not a rule enforcing valid durations. Load will apply the domain rules after decoding.

Assigning a struct copies its fields. This is closer to a C# value type than to assuming every Java data object has reference identity. The copy may still contain shared references if its fields include maps, pointers or slices. Our current fields avoid that mutable nested-storage issue. Choosing a struct does not create inheritance, constructors or automatically generated property accessors. Functions and methods provide the behavior we actually need.

## Aggregate with an explicit missing-value rule

A [map](https://go.dev/ref/spec#Map_types) associates keys and values. The command allocates a map from string to Minutes and adds each record's duration to its name's total. Reading an absent key yields the value type's zero value. That makes the addition concise: the first occurrence starts at zero, while a repeated name adds to the existing total. A lookup with two assignment targets also returns a presence boolean, which distinguishes a stored zero from a missing name.

The worked command reads one known key and one missing key. It does not print the whole map, because map iteration order is unspecified. A report requiring stable ordering should preserve an input order or sort keys explicitly. The capstone preserves the slice's order. Deterministic formatting is a behavior decision; a map alone does not promise it.

## Mutation and ownership

A nil map can be read and its length queried, but it cannot accept new entries. Allocate with make before writing. Assignment of a map value shares its underlying mapping; it does not clone entries. [`delete`](https://pkg.go.dev/builtin#delete) removes a key and is harmless when that key is absent. Concurrent unsynchronized mutation is a separate problem; placing values in a map does not make the mapping safe for multiple goroutines.

An entry containing a struct is retrieved as a value. The familiar read-modify-write pattern is to retrieve it, change the local copy and assign it back. Alternatively, a map of pointers intentionally shares mutable records, with a different ownership contract. Do not select pointer values merely to make method syntax convenient. First decide whether two readers should observe the same mutation.

## Compare the lookup contract

[C# Dictionary.TryGetValue](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.trygetvalue) makes the presence result explicit, much like Go's two-result lookup. [Java Map.get](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#get(java.lang.Object)) commonly uses null to indicate absence, with additional distinctions for maps permitting null values. In Go, the zero Minutes value is legitimate, so checking only the retrieved number loses information. The boolean is the answer to whether the key exists, independent of the numeric domain.

## Worked example

Complete source: [`cmd/l05/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l05/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	totals := make(map[string]study.Minutes)
	for _, record := range study.Fixture() {
		totals[record.Name] += record.Minutes
	}
	minutes, present := totals["missing"]
	fmt.Printf("go=%d missing=%d present=%t\n", totals["go"], minutes, present)
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l05
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
go=25 missing=0 present=false
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. If go is stored with zero minutes, how do you distinguish it from missing?

<details>
<summary>Solution 1</summary>

Read both results of the lookup. The go key returns zero and true; a missing key returns zero and false. Testing only the number cannot distinguish them. This is why the example prints the presence boolean alongside the missing value instead of treating zero as an error.

</details>

2. Two go records contain ten and fifteen minutes. What must aggregation produce?

<details>
<summary>Solution 2</summary>

The map must hold twenty-five for go. The first addition starts from the absent key’s zero value, and the second adds fifteen to ten. Keep the allocated map and the += operation shown in main. To print several aggregated names reproducibly, sort their keys or retain a separate ordered list.

</details>

## Official sources

- [Map types](https://go.dev/ref/spec#Map_types)
- [Struct types](https://go.dev/ref/spec#Struct_types)
- [Map indexing](https://go.dev/ref/spec#Index_expressions)

[Next lesson](../06-pointers-and-methods/) · [Journal](../journal/)
