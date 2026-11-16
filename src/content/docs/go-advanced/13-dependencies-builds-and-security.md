---
title: "13. Dependencies, builds and security"
description: "Distinguish a reproducible source selection from a vulnerability assessment and a deployable artifact."
sidebar:
  order: 13
---

## Learning objective

Distinguish a reproducible source selection from a vulnerability assessment and a deployable artifact.

## Mechanics and mental models

The [modules reference](https://go.dev/ref/mod) describes go.mod as part of dependency selection and language configuration. This module declares go 1.27.0 and imports only standard library packages. No external dependency does not mean no security maintenance: the toolchain and standard library still need supported updates. A checksum verifies consistency of downloaded content against an expected digest; it does not certify that the code is safe, reviewed or free of vulnerabilities.

The [go command](https://pkg.go.dev/cmd/go) provides module graph inspection, tests, vet and builds with different purposes. go list -m all shows selected modules; go mod verify checks downloaded module content; go vet inspects suspicious constructs; go test exercises authored contracts. Each result answers a different question. A green unit test cannot establish that an artifact was built with the expected compiler or that deployment uses that artifact. Capture the version and provenance alongside the output that matters.

[runtime/debug.ReadBuildInfo](https://pkg.go.dev/runtime/debug#ReadBuildInfo) exposes build information available in the running binary. Our command prints the main module path, a deterministic field for this example. It deliberately avoids quoting a compiler version or revision that changes between machines. Real release metadata should include the source revision, compiler, flags, target architecture and artifact digest. Paths in an artifact may reveal build machine information; consider trimpath as a deliberate release setting and verify the effect rather than assuming it proves bit-for-bit reproducibility.

C# NuGet and Java Maven users already know that selecting dependencies, restoring bytes and publishing binaries are separate steps. Go's module rules differ from nearest-wins or ad hoc override assumptions. Review replacements and workspace configuration because local overrides may alter what a command builds. [Go vulnerability management](https://go.dev/security/vuln) explains govulncheck's use of the vulnerability database and reachable symbols. That tool is not installed or executed by this unit. Record a real run before claiming assessment, and recognize that even a clean result covers known advisories and tool scope, not every possible defect. Keep secrets outside command examples and inspect release artifacts rather than only source files.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[provenance/build.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/provenance/build.go)

```go
package provenance

import "runtime/debug"

func MainModule() (string, bool) {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "", false
	}
	return info.Main.Path, true
}
```

[cmd/l13/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l13/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/provenance"
	"fmt"
)

func main() {
	path, ok := provenance.MainModule()
	if !ok {
		panic("build info unavailable")
	}
	fmt.Println(path)
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l13
```

### Expected output contract

```text
example.com/learn/go-advanced
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Does a verified module checksum establish that it is secure?

<details>
<summary>Complete solution</summary>

No. It establishes agreement with expected content. Review source and advisories separately, run the appropriate vulnerability tooling when authorized, and record the tool’s coverage and actual result.

</details>

2. Why print the module path rather than a fixed compiler version in this example?

<details>
<summary>Complete solution</summary>

The path is stable for the checked-in example and can be replayed exactly. Real compiler and revision fields must come from the artifact or command executed, not from an author’s assumed machine configuration.

</details>

## Primary sources

- [Modules reference](https://go.dev/ref/mod)
- [Go command](https://pkg.go.dev/cmd/go)
- [Go vulnerability management](https://go.dev/security/vuln)
- [runtime/debug.ReadBuildInfo](https://pkg.go.dev/runtime/debug#ReadBuildInfo)

[Next lesson](../14-service-capstone/) · [Learning journal](../journal/)
