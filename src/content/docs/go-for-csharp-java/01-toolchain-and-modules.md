---
title: "1. Toolchain and modules"
description: "Build a reproducible module and understand packages, imports and executable entry points."
sidebar:
  order: 1
---

## Learning objectives

Locate a module root, distinguish a package from a module, and run a checked-in command without changing its dependency graph.

## A small executable before a framework

[Go](https://go.dev/doc/) ships a compiler, formatter, test runner and module-aware command in one toolchain. Start with the official installation instructions for your operating system, then use the same commands on Windows, Linux/WSL and macOS. The course targets Go 1.27; the coordinator identified Go 1.27.1 on Windows. That version report is environment information, not proof that these newly authored examples passed. Our first deliverable is a program that imports local business data and prints one stable line.

A module is a versioned collection of packages. Its root contains [`go.mod`](https://go.dev/ref/mod#go-mod-file), whose module directive supplies the prefix used by imports. Here that prefix is example.com/learn/go-for-csharp-java. It is an educational identifier: no request to example.com is needed to import packages inside the same module. A package is usually the Go source files in one directory. The package clause names their compilation unit; the import path identifies its location. Several executable directories can share the same module and internal packages.

## Read the project from the outside inward

The first command lives at cmd/l01/main.go. Package main and a function named main define an executable. The import of internal/study joins the module prefix with a directory. An uppercase initial letter exports an identifier, so main can call Fixture and read Course. Lowercase declarations remain accessible to their own package. The internal directory additionally constrains who may import the package; it is a tool-enforced visibility boundary rather than a naming suggestion.

Run commands from code/go-for-csharp-java, not from the repository root. The checked-in go.mod already exists, so do not run go mod init over it. The go run command compiles and launches the requested package; its compilation artifacts are not the same thing as a published binary. go build creates build artifacts, while go test builds and executes tests. Formatting with [`gofmt`](https://pkg.go.dev/cmd/gofmt) is a separate deterministic operation. These distinctions will matter when we test the CLI without pretending that a successful compilation validates its input behavior.

## Transfer your existing build knowledge

A C# project file and a Java build descriptor combine several responsibilities that Go distributes among directory conventions, go.mod and the go command. Do not look for a class named Program or an application object. Startup is a function in package main. You also do not declare a namespace around every declaration. The import spelling is not an alias for downloading a package every time the executable starts; it participates in compilation and module resolution.

The course uses only the standard library, so there are no third-party requirements to install. The go directive declares the module's language baseline and minimum toolchain requirement; it does not claim that the running compiler has that exact patch version. Toolchain selection can obtain a newer toolchain when configured to do so. Confirm your environment before interpreting version-dependent behavior. Go 1.27 changes some language and library rules, so an old tutorial can disagree with a current compiler.

## Follow the dependency rather than copying files

The worked program calls Fixture, which returns two records, and prints their count. Follow the import to internal/study/study.go and find both the constant and function. This gives an early end-to-end path: executable, local package, typed data and visible output. Later lessons replace counting with selection, JSON parsing and reporting. Keep that package relationship intact when experimenting. Copying a helper into every command may appear convenient, but it hides whether the capstone actually uses the behavior taught earlier.

A common trap is running one source filename when the example requires several package files. Prefer the package path shown below. Another is renaming the module directive without updating imports. Treat those two spellings as one contract. Finally, a relative import such as a parent-directory filesystem path is not the way this module refers to its own packages. Use the module prefix and preserve the directory structure.

## Worked example

Complete source: [`cmd/l01/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l01/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	fmt.Printf("module=%s records=%d\n", study.Course, len(study.Fixture()))
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l01
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
module=study-log records=2
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. Why can this example run without contacting example.com?

<details>
<summary>Solution 1</summary>

The import resolves inside the current module because its prefix matches go.mod. The domain-shaped name identifies the module; it is not an instruction to contact a website at run time. The dependency is the checked-in internal/study package. The manifest expects two records because Fixture constructs exactly two values.

</details>

2. Add a second command without duplicating the fixture. What must its file contain?

<details>
<summary>Solution 2</summary>

Create another cmd subdirectory, declare package main, import example.com/learn/go-for-csharp-java/internal/study and call study.Fixture from main. The existing l01 program is a complete solution pattern. Preserve go.mod and the shared package. Only the executable directory changes; no new module or dependency is needed.

</details>

## Official sources

- [Go modules tutorial](https://go.dev/doc/tutorial/create-module)
- [go command](https://pkg.go.dev/cmd/go)
- [Module reference](https://go.dev/ref/mod)

[Next lesson](../02-values-types-and-strings/) · [Journal](../journal/)
