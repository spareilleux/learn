---
title: "Learning journal"
description: "Authored progress, actual verification evidence and remaining experiments for advanced Go."
sidebar:
  order: 99
---

## Progress

- [x] Authored lesson 1 — [Package and module boundaries](../01-package-and-module-boundaries/)
- [x] Authored lesson 2 — [Memory, escape analysis and GC](../02-memory-escape-and-gc/)
- [x] Authored lesson 3 — [Generics and iterators](../03-generics-and-iterators/)
- [x] Authored lesson 4 — [Error contracts and typed nil](../04-error-contracts-and-typed-nil/)
- [x] Authored lesson 5 — [Memory model, synchronization and atomics](../05-memory-model-sync-and-atomics/)
- [x] Authored lesson 6 — [Bounded pipelines](../06-bounded-pipelines/)
- [x] Authored lesson 7 — [Cancellation, deadlines and shutdown](../07-cancellation-deadlines-and-shutdown/)
- [x] Authored lesson 8 — [Production HTTP boundaries](../08-production-http/)
- [x] Authored lesson 9 — [Streaming and framing](../09-streaming-and-framing/)
- [x] Authored lesson 10 — [Race, fuzz and property tests](../10-race-fuzz-and-property-tests/)
- [x] Authored lesson 11 — [Benchmarks, pprof and trace](../11-benchmarks-pprof-and-trace/)
- [x] Authored lesson 12 — [Reflection, encoding and boundaries](../12-reflection-and-encoding/)
- [x] Authored lesson 13 — [Dependencies, builds and security](../13-dependencies-builds-and-security/)
- [x] Authored lesson 14 — [An integrated HTTP job service](../14-service-capstone/)
- [x] Integrated module tests, vet, formatting and fourteen exact stdout examples.
- [x] Source/snippet parity and localized built article links.
- [x] Bounded active fuzzing of the authored targets.
- [x] Hosted Windows/Linux/macOS CI and Linux race detector.
- [x] Anonymous public-page readback after Pages deployment.
- [ ] Human learner study and independent language review.

## QA

| Expected / observed | Location and measurement | Status |
| --- | --- | --- |
| A complete nonzero header without a body should be a truncated frame. | [framing/frame.go:50](https://github.com/spareilleux/learn/blob/7afa6d69bf354ead998b05303ac940075f7d548b/code/go-advanced/framing/frame.go#L50); Initially EOF; regression failed. Payload EOF normalization makes the new and existing framing tests pass. Initial implementation refuted. | Corrected before publication |

## Experiments

| Question / hypothesis before the check | Result / verdict |
| --- | --- |
| A complete nonzero header without a body should be a truncated frame. | Initially EOF; regression failed. Payload EOF normalization makes the new and existing framing tests pass. Initial implementation refuted. [Go](https://github.com/spareilleux/learn/tree/main/code/go-advanced) · [Dated entry](#2026-11-07--review-counterexamples-and-corrections) · [JSON](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) |


## 2026-11-07 — Course authored and preliminary module verification

The fourteen lessons, mission and corrected exercises were authored in English, French and Spanish. The code is an independent standard-library-only module with fourteen executable callers and reusable domain, iterator, pipeline, framing, encoding, provenance, HTTP and job-service packages. The lesson sources are copied from formatted checked-in Go files; no natural-language code comments require divergent translations.

The implementation makes several teaching choices explicit. Jobs copy caller-owned slices at admission rather than trusting a constructor convention on an exported struct. The pipeline owns channel closure at its producer and coordinator. The service serializes admission and queue closure, buffers one reply per accepted task and permanently stops admission during drain. Framing validates an advertised length before allocation and handles short writes. These are authored design decisions, not reports of failed experiments.

The coordinator reported an actual preliminary run of `go test -count=1 -timeout=60s ./...` under Go 1.27.1 on Windows/amd64 with CGO disabled: the fourteen command packages compiled and the eight test packages passed. The course author did not independently execute that command. This is preliminary technical evidence; the final receipt must bind tests, source snippets, exact stdout, translated pages and the revision actually published. The checked items above refer to authored lessons, not publication or human acceptance.

Go 1.27 documentation was consulted to avoid obsolete restrictions on generic methods and experimental-only descriptions of JSON v2. Typed nil, partial stream reads and cooperative cancellation are documented behavior that can surprise C#/Java developers. They are not presented as upstream bugs. No upstream issue was filed. There is no QA table of software defects or Experiments table of measured hypotheses at this stage: none was established by this unit's author.

## 2026-11-07 — Integrated technical verification

Both course modules were executed with Go 1.27.1 on Windows/amd64, CGO disabled. In this module, `go test -count=1 -timeout=60s ./...`, `go vet ./...`, formatting checks and all fourteen `go run ./cmd/lNN` examples passed. Every stdout matched `examples.json` exactly, including final newlines. The integrated check validates 96 pages, source-exact Go snippets, 84 localized output blocks, exercise solutions and journal structure. The site build succeeded; article links and fragments resolved on all 99 affected routes. The [machine-readable verification record](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) retains commands, results and source SHA-256 bindings.

The bounded fuzz runs used `-fuzztime=5s -parallel=2`: `FuzzLoad` in the standard module, and `FuzzReverse` plus `FuzzFrames` in the advanced module all passed. A one-iteration advanced benchmark smoke passed; it is not a representative performance baseline. After simplifying the JSON example to use `bytes.NewReader`, the standard tests, that example's exact output and vet were rechecked successfully. The snippets were synchronized in all three languages.

The audit exposed a real checker defect: case-insensitive detection of the marker `TODO` rejected ordinary Spanish “todo”. A regression first failed, then passed after marker detection became case-sensitive; all sixteen checker regressions and nineteen existing Node tests pass. This was a course-validation defect, not a defect in Go. No human learner session, vulnerability scan, CPU profile, trace or escape report is claimed. Hosted CI, race instrumentation and publication remain separate evidence gates.


## 2026-11-07 — Review, counterexamples and corrections

The completed six-lens review retained three confirmed findings: payload EOF classification, missing cancellation-after-startup coverage and missing official iterator API links. All three were corrected. A complete nonzero frame header with no payload first failed the new regression (`EOF`, expected `unexpected EOF`); after normalization, the existing framing tests and the new regression pass. Clean stream EOF, empty frames, partial payloads and other reader errors keep their existing tests. The complete source listing was synchronized in all three translations.

A channel-gated test now cancels Squares after startup, beyond its initial Err check; it requires context.Canceled and bounded completion. A second test concurrently releases sixteen Submit calls and two Drain calls, checks every accepted reply and leaves the first accepted reply unread until both drains finish. Both packages passed twenty consecutive runs. These checks exercise the stated lifetimes; they do not enumerate every scheduler interleaving or establish an observed production hang.

The permanent content checker now compares every localized text output block with examples.json. A deliberately invented Spanish output first escaped detection (one failing regression), then was rejected after the fix; all seventeen checker regressions pass. A native Windows command-line probe also showed that unquoted -run=^$ reaches a child as -run=$. Quoting -run="^$" preserves the intended argument; the benchmark instructions were corrected in EN/FR/ES. The [verification record](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) preserves the failing counterexamples, passing checks and final source digests. Hosted CI and anonymous public readback are still pending at this entry.

## 2026-11-07 — Hosted tests and public delivery

The [Go workflow](https://github.com/spareilleux/learn/actions/runs/42404338250) passed all nine jobs: both modules on Windows, Linux and macOS, two Linux race-detector jobs and the course checker. The [Pages deployment](https://github.com/spareilleux/learn/actions/runs/42405574875) successfully published revision `cd8ca24400c1591d56dc0878ba52974fd6e54b4d`. Anonymous HTTP requests then verified all 99 expected routes: 96 course documents, including six journals, and three homepages in EN/FR/ES. Titles, language, canonical URLs, fourteen-lesson indexes, corrected exercises and homepage course links matched expectations. The [public verification record](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-public.json) preserves every URL, observation time and HTML SHA-256, with the deployment and CI identities. This confirms publication and the exercised technical checks; learner acceptance, independent language review and representative profiling remain unmeasured.

## To verify

- Measure a representative workload before using benchmark, profile, trace or escape-analysis conclusions.
- Observe real learner exercise attempts and obtain independent translation review; neither has happened yet.

## Open questions

- Can a C#/Java developer explain why cancelling a request does not imply transactional rollback?
- Can a learner locate the owner of each channel closure without reading a solution?
- Does the shared reading protocol help learners distinguish semantic guarantees from compiler measurements?
- What additional persistence and operation-identity contract would be needed before this in-memory service could safely retry external effects?
