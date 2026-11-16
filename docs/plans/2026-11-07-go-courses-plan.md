# Go standard and advanced courses

## Goal and scope

Create two complete general Learn courses modeled on `java-for-csharp`, outside Streeling. Teach Go to C#/Java developers with detailed explanations, runnable examples, corrected exercises, primary sources and honest learning journals. Provide matching English, French and Spanish pages. The local installed compiler is Go 1.27.1 on Windows/amd64; the language baseline is Go 1.27. Use the official Go 1.27 release notes, not outdated assumptions about generic methods or JSON v2.

## Course units

### Standard course

Own `src/content/docs/{,fr/,es/}go-for-csharp-java/` and `code/go-for-csharp-java/` only. Fourteen numbered lessons: toolchain/modules; values/types/strings; control flow/functions; arrays/slices; maps/structs; pointers/methods; interfaces/composition; errors/defer/resources; files/JSON/Unicode; generics/collections; goroutines/channels; HTTP/context; testing; a tested command-line capstone. The capstone should actually compose concepts from the earlier lessons.

### Advanced course

Own `src/content/docs/{,fr/,es/}go-advanced/` and `code/go-advanced/` only. Fourteen numbered lessons: package/module boundaries; memory/escape/GC; generics/iterators; error contracts/typed nil; memory model/synchronization/atomics; bounded pipelines; cancellation/deadlines/shutdown; production HTTP; streaming/framing; race/fuzz/property testing; benchmarks/pprof/trace; reflection/encoding/boundaries; dependency/build/security tooling; an integration-tested service capstone. Own code is independent of the standard module, although readers should study the standard course first.

### Site integration and verification

Root owns `astro.config.mjs`, the three home pages, `.github/workflows/go-examples.yml`, `scripts/check-go-courses.py`, any checker regression tests, verification receipts and publishing. Add collapsed groups under Software Engineering / Languages & frameworks and cards on all three home pages. Preserve all unrelated changes, dependencies, sidebar behavior and Streeling content.

## Shared authoring contract

- Every locale has `index.md`, fourteen identically named English-slug lessons and `journal.md`. Frontmatter includes a title, description and sidebar order. Lessons are substantial teaching material, not outlines: roughly 650 or more words of explanatory prose, a worked runnable example, C#/Java comparisons, pitfalls and at least two exercises with collapsible solutions. A compact lesson may be shorter only when it still fully teaches its topic.
- Each runnable example lives in the course's own dependency-free Go module (`module example.com/learn/<course>`, `go 1.27.0`). Put executable examples under `cmd/l01` through `cmd/l14`; add meaningful package or command tests and runnable capstone integration tests. All networking stays on loopback or `httptest`/`net.Pipe`; tests do not depend on external services or sleeps to establish ordering.
- Each module supplies `examples.json`, an array of `{ "lesson": "01-slug.md", "command": "./cmd/l01", "stdout": "exact expected output with newline" }`. Go examples quoted in lessons must be exact complete files or exact excerpts of checked-in Go sources. Keep quoted output in `text` fences; it must match a manifest stdout or an executable Go example test. Avoid pretending compiler, benchmark or platform-dependent output has been observed before root runs it.
- Prose is translated fully; code, commands, paths and output remain identical across locales. Avoid English prose comments in Go snippets so code can remain byte-identical. Link first tool/API mentions to official documentation. Explain cross-platform differences; use MDX Starlight OS tabs if a lesson requires distinct shell commands.
- Journals follow the repository's Progress, QA/Experiments when applicable, dated entries, To verify and Open questions pattern. Initially mark execution/publication as pending. Root updates them from actual results. Do not claim the author, a human learner, another OS or a live ecosystem service was tested when it was not.

## Execution and ownership

Use native CE execution. The standard and advanced units are an independent shared-workspace wave from a clean committed baseline. Their modules, documents and generated files are disjoint; no shared code APIs are added. Workers do not stage, commit, install packages, start servers, run builds or mutate shared caches. Root alone owns authoritative tests and Git operations. Abort shared waves on unowned writes. Integration is serial after both course units finish.

## Verification and delivery

1. Inspect the Java reference, current Go primary documentation and existing navigation/testing conventions.
2. Author both course units and inspect every actual changed path.
3. Run Go formatting checks, `go test ./...`, `go vet ./...`, all 28 executable examples with exact stdout checks, snippet/source alignment, localized page parity, exercises, journal structure and links. Include meaningful negative compiler examples if a lesson quotes a rejection; capture actual diagnostics before quoting them.
4. Add GitHub Actions on Windows, Linux and macOS, plus a Linux race-detector job and bounded fuzz/benchmark smoke where authored. Record actual outputs and failures honestly. Validate the site build and existing Node tests. Browser layout inspection is attempted only if an available browser capability supports it; otherwise record that limit.
5. Complete the CE simplification/review/shipping tail, publish through GitHub, and verify the actual anonymous public pages in all three locales after Pages deployment. Source presence or a successful merge alone does not prove publication.

This work does not modify Streeling, add Go frameworks, migrate ecosystem services, install global tooling, or publish unrelated pre-existing branch work. Ready/learner acceptance is separate from compiled examples and deployed content.
