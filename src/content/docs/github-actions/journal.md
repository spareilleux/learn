---
title: Journal
description: Dated progress notes — runs, errors and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Sample code: the same slug function in .NET (xUnit v3) and Java (JUnit 6)
- [x] Lesson 1: first workflow, reading runs with `gh`
- [x] Lesson 2: matrix build on three OSes, setup-dotnet, setup-java, Maven cache
- [x] Lesson 3: triggers, filters, inputs, concurrency
- [x] Lesson 4: expressions, contexts, outputs, conditions
- [ ] Lesson 5: artifacts and caching (NuGet cache with `packages.lock.json`)
- [ ] Lesson 6: reusable workflows and composite actions
- [ ] Lesson 7: security — permissions, secrets, pinning, OIDC
- [ ] Lesson 8: deploying to GitHub Pages
- [ ] Lesson 9: debugging runs
- [ ] Lesson 10: writing your own action

## 2026-09-14 — Local first: two xUnit v3 traps

Before writing any workflow, `dotnet test` on the sample project (SDK 10.0.112 locally, `xunit.v3` 4.0.1) failed twice:

1. `Testing with VSTest target is no longer supported by Microsoft.Testing.Platform on .NET 10 SDK and later.` Fix: `"test": { "runner": "Microsoft.Testing.Platform" }` in `global.json`.
2. `CS0246: The type or namespace name 'Theory' could not be found`. With `ImplicitUsings` enabled, this package version didn't add `using Xunit`. Fix: the `using` in the test file.

The Java side (`mvn -B verify`, JUnit 6.1.3, Maven 3.9.16) passed first time.

## 2026-09-14 — First push: four workflows, one invalid

Pushing the four lesson workflows (commit `61e7e42`) started them all. `GHA 01`, `GHA 02` (6 jobs) and `GHA 04` passed. `GHA 03` appeared under its file name, failed in 0 s, with no job: `You have an error in your yaml syntax on line 41`, a `run: echo "cron: …"` line (an unquoted value containing `: `). The next push, unrelated to that file, failed it again, despite its `paths` filter.

A second commit the same afternoon repeated the mistake in `gha-04-exercises.yml` (`run: echo "next: $BUILD_LABEL"`); this time `python -c "import yaml; yaml.safe_load(...)"` caught it before the push. Lesson: validate YAML locally, every time.

## 2026-09-14 — Two deployments of this site collided

Pushes `61e7e42` and `cb69dca`, 14 s apart, each started `Deploy to GitHub Pages`. The second deploy job failed:

```text
##[error]HttpError: Deployment request failed for cb69dca950b667b876d8d32cfe778a24b6320c59 due to in progress deployment. Please cancel 61e7e4235b7bc138f2f35cd7f61195bdaed4b019 first or wait for it to complete.
```

The site stayed on the previous version until the next push. Fix in `deploy.yml` (commit `5c9896f`): `concurrency: { group: pages, cancel-in-progress: false }`. Several sessions push to this repository, so collisions were bound to happen again.

## 2026-09-14 — Measurements

- Maven cache, `gha-02` first run → second run: Ubuntu 16 s → 10 s, Windows 43 s → 28 s, macOS 20 s → 9 s. .NET jobs unchanged (21/60/20 s → 22/57/22 s): no NuGet cache yet.
- `global.json` `10.0.100` + `latestFeature` → `setup-dotnet` installed SDK 10.0.401.
- Temurin 25.0.4 was preinstalled on `ubuntu-latest` (`Resolved Java 25.0.4+1 from tool-cache`).
- `macos-latest` is arm64 (`setup-java-macOS-arm64-maven-…` cache key).
- Default `run:` shell: `/usr/bin/bash -e {0}` (Ubuntu), `/bin/bash -e {0}` (macOS), `pwsh -command ". '{0}'"` (Windows). Explicit `shell: bash` on Windows: `bash.EXE --noprofile --norc -e -o pipefail {0}`, bash 5.3.15.
- `GITHUB_TOKEN` default permissions on this repository: `Contents: read`, `Metadata: read`, `Packages: read`. The token was 377 characters long.
- Concurrency with `cancel-in-progress: true`: push run cancelled by a manual run 41 s later, itself cancelled 10 s later by another one before its job started.

## Open questions

- Does the `schedule` trigger of `gha-03` (Mondays 06:17 UTC) run on time? *To verify on 2026-09-21.*
- `setup-dotnet` `cache: true`: does it require `packages.lock.json`, and what does it save on Windows? *To verify in lesson 5.*
- What exactly does a pull request page show for a required check skipped by `paths`? *To verify.*
