---
title: "Go for C# and Java developers — Journal"
description: "Dated authoring and verification evidence for the standard Go course."
sidebar:
  order: 99
---

## Progress

- [x] Authored: [Toolchain and modules](../01-toolchain-and-modules/).
- [x] Authored: [Values, types and strings](../02-values-types-and-strings/).
- [x] Authored: [Control flow and functions](../03-control-flow-and-functions/).
- [x] Authored: [Arrays and slices](../04-arrays-and-slices/).
- [x] Authored: [Maps and structs](../05-maps-and-structs/).
- [x] Authored: [Pointers and methods](../06-pointers-and-methods/).
- [x] Authored: [Interfaces and composition](../07-interfaces-and-composition/).
- [x] Authored: [Errors, defer and resources](../08-errors-defer-and-resources/).
- [x] Authored: [Files, JSON and Unicode](../09-files-json-and-unicode/).
- [x] Authored: [Generics and collections](../10-generics-and-collections/).
- [x] Authored: [Goroutines and channels](../11-goroutines-and-channels/).
- [x] Authored: [HTTP and context](../12-http-and-context/).
- [x] Authored: [Testing](../13-testing/).
- [x] Authored: [CLI capstone](../14-cli-capstone/).
- [x] Integrated module tests, vet, formatting and fourteen exact stdout examples.
- [x] Source/snippet parity and localized built article links.
- [x] Bounded active fuzzing of the authored targets.
- [ ] Hosted Windows/Linux/macOS CI and Linux race detector.
- [ ] Anonymous public-page readback after Pages deployment.
- [ ] Human learner study and independent language review.

## 2026-11-07 — Complete course authoring and preliminary module verification

The standard course was authored as a general Learn course, outside Streeling. Fourteen lessons now progress from modules and value semantics to a real study-log CLI. The English, French and Spanish versions contain full explanations and two corrected exercises per lesson. Their filenames, Go snippets, commands and expected output contracts match across locales.

The running example was kept coherent: internal/study owns typed records, selection, totals, JSON loading and the cancellable stream; internal/cli composes argument parsing, acquisition and reporting; internal/webapi provides a small in-memory-tested HTTP boundary. The final command uses the same packages rather than repeating a standalone demonstration. The module has no third-party dependencies.

A source-alignment issue was avoided by extracting the exact formatted main.go files into all three languages. Lesson thirteen also quotes an exact compiled test function. Expected output was written into examples.json before execution and remains labelled as expected in the lessons until the coordinator finishes verification against the complete artifacts. No compiler diagnostic or performance measurement was invented.

A version-specific teaching correction was applied while authoring: Go 1.27 supports concrete generic methods, while interface methods still cannot declare their own type parameters. JSON behavior is tied to the actual encoding/json APIs and explicit loader tests rather than assumed from an older implementation. Another important distinction is that nil pointers inside interfaces retain a dynamic type and therefore are not nil interfaces.

The coordinator reported a successful preliminary run of the complete module on Go 1.27.1, Windows/amd64, with CGO disabled. The exact command was go test -count=1 -timeout=60s ./... from code/go-for-csharp-java. All fourteen command packages compiled and the cli, study and webapi test packages passed. This is a coordinator-supplied execution result; this course-authoring worker did not execute Go tests. Final verification must bind the result to the finished source and documentation.

The source was formatted with gofmt. Authored tests cover slice aliasing and cloning, struct mutation, typed nil interfaces, validation and wrapped causes, malformed JSON, invalid UTF-8, byte and rune counts, selection boundaries and order, mapping, cancellation, HTTP contracts and CLI input/output failures. A loader fuzz target is present; no fuzz campaign, benchmark or human learning session is claimed here.

The coordinator subsequently executed all fourteen standard-course commands and confirmed that every stdout matched examples.json exactly, including final newlines. The coordinator also reported successful go vet ./... and formatting checks on the same Go 1.27.1 Windows environment with CGO disabled. These are actual preliminary execution results, not manually invented output captures; final checks still need to bind the completed documentation and publication state.

## 2026-11-07 — Integrated technical verification

Both course modules were executed with Go 1.27.1 on Windows/amd64, CGO disabled. In this module, `go test -count=1 -timeout=60s ./...`, `go vet ./...`, formatting checks and all fourteen `go run ./cmd/lNN` examples passed. Every stdout matched `examples.json` exactly, including final newlines. The integrated check validates 96 pages, source-exact Go snippets, 84 localized output blocks, exercise solutions and journal structure. The site build succeeded; article links and fragments resolved on all 99 affected routes. The [machine-readable verification record](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) retains commands, results and source SHA-256 bindings.

The bounded fuzz runs used `-fuzztime=5s -parallel=2`: `FuzzLoad` in the standard module, and `FuzzReverse` plus `FuzzFrames` in the advanced module all passed. A one-iteration advanced benchmark smoke passed; it is not a representative performance baseline. After simplifying the JSON example to use `bytes.NewReader`, the standard tests, that example's exact output and vet were rechecked successfully. The snippets were synchronized in all three languages.

The audit exposed a real checker defect: case-insensitive detection of the marker `TODO` rejected ordinary Spanish “todo”. A regression first failed, then passed after marker detection became case-sensitive; all sixteen checker regressions and nineteen existing Node tests pass. This was a course-validation defect, not a defect in Go. No human learner session, vulnerability scan, CPU profile, trace or escape report is claimed. Hosted CI, race instrumentation and publication remain separate evidence gates.


## To verify

- Consult the hosted CI for Windows, Linux and macOS, including the Linux race detector.
- Read back the deployed EN/FR/ES pages anonymously and record the deployed revision.
- Measure a representative workload before using benchmark, profile, trace or escape-analysis conclusions.
- Observe real learner exercise attempts and obtain independent translation review; neither has happened yet.

## Open questions

- Do C# and Java readers correctly explain a typed nil before reading its solution? This requires learner observation.
- Do the explicit ownership diagrams readers draw for slices predict the capstone behavior? This also remains a learner question.
