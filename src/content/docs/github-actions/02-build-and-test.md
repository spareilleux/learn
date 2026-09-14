---
title: 2. Build and test .NET and Java
description: A matrix over three operating systems, setup-dotnet and setup-java, the Maven cache, and the traps of xUnit v3 on the .NET 10 SDK.
sidebar:
  order: 2
---

## The project

[`code/github-actions`](https://github.com/spareilleux/learn/tree/main/code/github-actions) holds the same small function twice — turn a title into a URL slug — with four tests on each side:

| | .NET | Java |
|---|---|---|
| Code | `dotnet/Slugs/Slug.cs` | `java/src/main/java/com/example/slugs/Slug.java` |
| Tests | [xUnit v3](https://xunit.net/) `[Theory]` + `[InlineData]` | [JUnit 6](https://docs.junit.org/) `@ParameterizedTest` + `@CsvSource` |
| Command | `dotnet test` | `mvn -B verify` |
| SDK pinned by | `global.json` | `maven.compiler.release` in `pom.xml` |

```csharp
[Theory]
[InlineData("Hello, Wörld!", "hello-world")]
[InlineData("  GitHub   Actions  ", "github-actions")]
[InlineData("C# 14 & .NET 10", "c-14-net-10")]
[InlineData("", "")]
public void From_builds_a_lowercase_ascii_slug(string text, string expected) =>
    Assert.Equal(expected, Slug.From(text));
```

Before any YAML: **it must pass locally**, with the same commands CI will run. That's where the first two traps of this lesson appeared.

## Trap 1: xUnit v3 and `dotnet test` on the .NET 10 SDK

With `xunit.v3` 4.0.1, the first `dotnet test` failed before running anything:

```text
error : Testing with VSTest target is no longer supported by Microsoft.Testing.Platform on .NET 10 SDK and later. If you use dotnet test, you should opt-in to the new dotnet test experience. For more information, see https://aka.ms/dotnet-test-mtp-error
```

xUnit v3 runs on [Microsoft.Testing.Platform](https://learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-intro), and the .NET 10 SDK wants you to opt in to the new `dotnet test` explicitly, in `global.json`:

```json
{
  "sdk": {
    "version": "10.0.100",
    "rollForward": "latestFeature"
  },
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}
```

## Trap 2: no implicit `using Xunit`

Next error:

```text
CS0246: The type or namespace name 'Theory' could not be found (are you missing a using directive or an assembly reference?)
CS0246: The type or namespace name 'InlineData' could not be found (are you missing a using directive or an assembly reference?)
```

With `ImplicitUsings` enabled, this 4.0.1 package didn't add `Xunit` to the global usings: the test file needs `using Xunit;`. Then:

```text
Test run summary: Passed!
  total: 4
  failed: 0
  succeeded: 4
  skipped: 0
```

## The workflow

[`.github/workflows/gha-02-build.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-02-build.yml):

```yaml
# GitHub Actions course, lesson 2: build and test .NET and Java on three OSes
name: "GHA 02: build and test"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['code/github-actions/**', '.github/workflows/gha-02-build.yml']
  pull_request:
    paths: ['code/github-actions/**', '.github/workflows/gha-02-build.yml']

jobs:
  dotnet:
    name: dotnet (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
      - run: dotnet --version
      - run: dotnet test

  java:
    name: java (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    defaults:
      run:
        working-directory: code/github-actions/java
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: '25'
          cache: maven
      - run: java --version
      - run: mvn -B verify
```

| Element | Effect |
|---|---|
| `strategy.matrix.os` | one job per value: 3 `dotnet` jobs and 3 `java` jobs, all in parallel |
| `fail-fast: false` | a failure on Windows doesn't cancel the macOS job still running (the default, `true`, does) |
| `name: dotnet (${{ matrix.os }})` | the job name shown in the run; without `name`, GitHub uses the job id and all matrix values, e.g. `java (ubuntu-latest, 22)` |
| `defaults.run.working-directory` | every `run:` starts in that folder (`uses:` steps aren't affected) |
| [`actions/setup-dotnet`](https://github.com/actions/setup-dotnet) with `global-json-file` | installs the SDK that `global.json` asks for |
| [`actions/setup-java`](https://github.com/actions/setup-java) with `cache: maven` | installs Temurin 25 and caches `~/.m2/repository`, keyed on the hash of `pom.xml` |
| `mvn -B` | batch mode: no colors, no download progress bars in the log |

## What the run shows

All six jobs passed. Excerpts:

```text
dotnet (ubuntu-latest) | dotnet-install: Installed version is 10.0.401
dotnet (ubuntu-latest) | 10.0.401
java (ubuntu-latest)   | Resolved Java 25.0.4+1 from tool-cache
java (ubuntu-latest)   | openjdk 25.0.4.1 2026-08-18 LTS
java (ubuntu-latest)   | [INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
java (ubuntu-latest)   | [INFO] BUILD SUCCESS
```

- `global.json` says `10.0.100` with `rollForward: latestFeature`: `setup-dotnet` installed the **latest** 10.0 feature band, 10.0.401. Pin `"rollForward": "disable"` if you need exactly one SDK.
- Temurin 25 was already in the Ubuntu image (`from tool-cache`): no download.

**The shell isn't the same everywhere.** The same `run: dotnet test` step logged:

```text
dotnet (ubuntu-latest)  | shell: /usr/bin/bash -e {0}
dotnet (macos-latest)   | shell: /bin/bash -e {0}
dotnet (windows-latest) | shell: C:\Program Files\PowerShell\7\pwsh.EXE -command ". '{0}'"
```

On Windows, `run:` defaults to PowerShell 7. `dotnet test` and `mvn -B verify` behave the same in both, but a script with `$(pwd)`, `export` or `&&` chains won't. Set `defaults.run.shell: bash` for the job (Git Bash is installed on Windows runners) when a script must be identical on the three OSes.

## The cache, measured

The first run found no Maven cache and saved one; a second run (started with `gh workflow run gha-02-build.yml`) restored it:

```text
maven cache is not found
Cache saved with the key: setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb
```

```text
Cache restored from key: setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb
Cache hit occurred on the primary key setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb, not saving cache.
```

| Job | 1st run (no cache) | 2nd run (cache hit) |
|---|---|---|
| java (ubuntu-latest) | 16 s | 10 s |
| java (windows-latest) | 43 s | 28 s |
| java (macos-latest) | 20 s | 9 s |
| dotnet (ubuntu-latest) | 21 s | 22 s |
| dotnet (windows-latest) | 60 s | 57 s |
| dotnet (macos-latest) | 20 s | 22 s |

The .NET jobs didn't get faster: nothing caches the NuGet packages yet. `setup-dotnet` has a `cache: true` option based on `packages.lock.json` files, measured in [lesson 5](../05-caches-and-artifacts/). The key contains the OS (`Linux-x64`, `Windows-x64`, `macOS-arm64`): each OS has its own cache. And `macos-latest` is an **arm64** machine.

## Key takeaways

- Make it pass locally first, with exactly the commands CI runs.
- A `matrix` multiplies a job; `fail-fast: false` lets every combination finish.
- `setup-dotnet` reads `global.json`; `setup-java` installs a JDK and caches Maven or Gradle.
- `run:` is bash on Linux/macOS and PowerShell 7 on Windows unless you set `shell`.
- Measure: a Maven cache hit saved 6 to 15 seconds per job here; Windows jobs are the slowest.

## Exercises

1. Add `22` next to `25` so that the Java job also runs on Java 22, on the three OSes. How many Java jobs will run?

<details>
<summary>Solution</summary>

```yaml
    name: java ${{ matrix.java }} (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        java: ['25', '22']
    steps:
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: ${{ matrix.java }}
          cache: maven
```

6 jobs (3 × 2). But the build fails on 22: `pom.xml` sets `maven.compiler.release` to 25. Checked with [`gha-02-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-02-exercises.yml):

```text
[INFO] BUILD FAILURE
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.15.0:compile (default-compile) on project slugs: Fatal error compiling: error: release version 25 not supported -> [Help 1]
```

A matrix tests combinations; the project must support them.

</details>

2. You want the Windows job to run `dotnet test` in bash, like the others. Where do you put `shell: bash`, so that it applies to every `run:` of the job?

<details>
<summary>Solution</summary>

```yaml
    defaults:
      run:
        shell: bash
        working-directory: code/github-actions/dotnet
```

`defaults.run` at the job level (or at the workflow level for all jobs). On Windows the log then shows:

```text
shell: C:\Program Files\Git\bin\bash.EXE --noprofile --norc -e -o pipefail {0}
bash 5.3.15(2)-release, options ehB
```

Note `-o pipefail`: an explicit `shell: bash` also fails when a command in the middle of a pipe fails, which the implicit `bash -e {0}` of Linux runners doesn't do.

</details>

3. Without `using Xunit;`, which error would CI show, and on how many jobs?

<details>
<summary>Solution</summary>

`CS0246: The type or namespace name 'Theory' could not be found`, on the three `dotnet` jobs. With `fail-fast: false` all three run to the end; with the default `fail-fast: true`, the first failure cancels the other `dotnet` jobs still in progress — the `java` jobs come from another job definition, with its own matrix, and aren't affected.

</details>

## Sources

- [Building and testing .NET — GitHub Docs](https://docs.github.com/actions/tutorials/build-and-test-code/net)
- [Building and testing Java with Maven — GitHub Docs](https://docs.github.com/actions/tutorials/build-and-test-code/java-with-maven)
- [Running variations of jobs in a workflow (matrix)](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations)
- [Testing with `dotnet test` and Microsoft.Testing.Platform](https://learn.microsoft.com/dotnet/core/testing/unit-testing-with-dotnet-test)
- [`global.json` overview](https://learn.microsoft.com/dotnet/core/tools/global-json)
