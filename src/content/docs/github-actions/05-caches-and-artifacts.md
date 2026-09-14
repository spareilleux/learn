---
title: 5. Caches and artifacts
description: NuGet lock files and the setup-dotnet cache, actions/cache and its keys, uploading and downloading artifacts between jobs — with the time the cache really saved.
sidebar:
  order: 5
---

## Two ways to keep files

Every job starts on a fresh machine ([lesson 1](../01-first-workflow/)). GitHub offers two storages that outlive a job, and the documentation insists they "cannot be used interchangeably":

| | Cache | Artifact |
|---|---|---|
| Holds | files you could regenerate: downloaded packages, intermediate builds | files a job **produced**: test reports, packages, binaries |
| Shared between | runs of the repository (by key and branch) | jobs of **one** run, and people who download it |
| Missing? | the job must still work, only slower | the job that needs it fails |
| Lifetime | removed after 7 days without access, 10 GB per repository by default | 90 days by default, `retention-days` to shorten |
| Actions | [`actions/cache`](https://github.com/actions/cache), or `cache:` in `setup-*` actions | [`actions/upload-artifact`](https://github.com/actions/upload-artifact), [`actions/download-artifact`](https://github.com/actions/download-artifact) |
| Azure Pipelines | `Cache@2` | `PublishPipelineArtifact@1`, `DownloadPipelineArtifact@2` |

## A NuGet cache needs lock files

[Lesson 2](../02-build-and-test/) measured it: the Maven cache of `setup-java` saved 6 to 15 seconds per job, while the .NET jobs cached nothing. `setup-dotnet` has a `cache: true` input, but its README says the cache key is the hash of `packages.lock.json` files, and "if lock file does not exist, this action throws error". The sample project had none.

A [NuGet lock file](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies) records the exact version and content hash of every package, direct or transitive — the equivalent of `package-lock.json` for npm. One property in a [`Directory.Build.props`](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory) next to the solution turns it on for every project:

```xml
<Project>

  <PropertyGroup>
    <!-- Write packages.lock.json next to each project: setup-dotnet's cache key is its hash (lesson 5) -->
    <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
  </PropertyGroup>

</Project>
```

A local `dotnet restore` then wrote `Slugs/packages.lock.json` (5 lines, no packages) and `Slugs.Tests/packages.lock.json` (170 lines: the three test packages and their dependencies). Both are committed. In CI, `dotnet restore --locked-mode` fails instead of silently updating the file when a package no longer matches it.

## The workflow

[`.github/workflows/gha-05-artifacts.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-05-artifacts.yml) has four jobs: `test` on three OSes with the NuGet cache and a test report, `pack` builds a NuGet package, `cache-demo` uses `actions/cache` directly, and `report` downloads the artifacts of the first two.

```yaml
# GitHub Actions course, lesson 5: dependency caches, actions/cache, build artifacts between jobs
name: "GHA 05: caches and artifacts"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-05-artifacts.yml', 'code/github-actions/dotnet/**']

jobs:
  test:
    name: test (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    env:
      NUGET_PACKAGES: ${{ github.workspace }}/.nuget/packages
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
          cache: true
          cache-dependency-path: code/github-actions/dotnet/*/packages.lock.json
      - run: dotnet restore --locked-mode
      - run: dotnet test --no-restore --report-xunit-junit --report-xunit-junit-filename slugs.junit.xml --results-directory TestResults
      - name: Upload the test report
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results-${{ matrix.os }}
          path: code/github-actions/dotnet/TestResults/
          retention-days: 7

  pack:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
      - run: dotnet pack Slugs/Slugs.csproj --configuration Release --output dist -p:Version=1.0.${{ github.run_number }}
      - uses: actions/upload-artifact@v7
        with:
          name: package
          path: code/github-actions/dotnet/dist/*.nupkg
          if-no-files-found: error

  cache-demo:
    runs-on: ubuntu-latest
    steps:
      - name: Restore the cache
        id: cache
        uses: actions/cache@v6
        with:
          path: expensive
          key: gha-05-expensive-${{ runner.os }}-v1
      - name: Show the cache-hit output
        run: echo "cache-hit='${{ steps.cache.outputs.cache-hit }}'"
      - name: Produce the files only on a miss
        if: steps.cache.outputs.cache-hit != 'true'
        run: |
          mkdir -p expensive
          date -u +%FT%TZ > expensive/created-at.txt
          echo "produced"
      - run: cat expensive/created-at.txt

  report:
    needs: [test, pack]
    if: ${{ !cancelled() }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v8
        with:
          pattern: test-results-*
          path: results
      - uses: actions/download-artifact@v8
        with:
          name: package
          path: package
      - run: find results package -type f | sort
      - name: Tests per OS
        run: |
          for f in results/*/slugs.junit.xml; do
            echo "$(dirname "$f"): $(grep -o 'tests="[0-9]*" failures="[0-9]*"' "$f" | head -1)"
          done
```

| Element | Why |
|---|---|
| `NUGET_PACKAGES` | moves the NuGet global packages folder into the workspace, as the `setup-dotnet` README recommends: the cache then holds only this project's packages, not what the runner image already has |
| `cache-dependency-path` | the lock files aren't at the repository root, where `setup-dotnet` looks by default |
| `--report-xunit-junit` | an xUnit v3 option (see `dotnet test --help`) that writes a JUnit XML report; `--results-directory` chooses the folder |
| `if: always()` on the upload | the report is most useful when tests **fail** |
| `name: test-results-${{ matrix.os }}` | one artifact per matrix job, with a distinct name |
| `if-no-files-found: error` | the default is `warn`: a wrong path would upload nothing and still pass |

## Run 1 → run 2: what the cache did

The first run, on the push, found no cache and saved one per OS at the end of the job (the *Post* step):

```text
test (ubuntu-latest) | Dotnet cache is not found
test (ubuntu-latest) | Cache saved with the key: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
```

A second run, started with `gh workflow run gha-05-artifacts.yml`, restored it:

```text
test (ubuntu-latest) | Cache hit for: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
test (ubuntu-latest) | Cache Size: ~54 MB (56306437 B)
test (ubuntu-latest) | Cache restored from key: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
test (ubuntu-latest) |   Restored /home/runner/work/learn/learn/code/github-actions/dotnet/Slugs.Tests/Slugs.Tests.csproj (in 294 ms).
test (ubuntu-latest) | Cache hit occurred on the primary key dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c, not saving cache.
```

The same hash on the three OSes (the lock files are identical), prefixed with `Linux`, `Windows` or `macOS`: three caches of about 54 MB each, visible with `gh cache list`.

Now the part that matters — the step durations, from `gh api repos/spareilleux/learn/actions/runs/<run-id>/jobs`:

| Step | Ubuntu miss → hit | Windows miss → hit | macOS miss → hit |
|---|---|---|---|
| `setup-dotnet` (SDK install + cache restore) | 9 s → 11 s | 35 s → 29 s | 20 s → 12 s |
| `dotnet restore --locked-mode` | 3 s → 1 s | 5 s → 4 s | 3 s → 1 s |
| *Post* `setup-dotnet` (cache save) | 1 s → 0 s | 5 s → 1 s | 4 s → 0 s |

The restore step itself went from 3 s to 1 s. Downloading 54 MB of cache costs about as much: on this tiny project, the NuGet cache **saves almost nothing**, and the large variations of the `setup-dotnet` step come from the SDK download, not from the cache. It pays off when a restore downloads hundreds of packages, which is when you should add it — after measuring, as here. The lock files are worth keeping anyway: they make CI restore exactly what was tested locally.

## `actions/cache` directly

`setup-java` and `setup-dotnet` build the key for you. With [`actions/cache`](https://github.com/actions/cache) you choose `path` and `key` yourself. The `cache-demo` job, on the two runs:

```text
Run 1
Cache not found for input keys: gha-05-expensive-Linux-v1
cache-hit=''
produced
2026-09-14T13:12:25Z
Cache saved with key: gha-05-expensive-Linux-v1

Run 2
Cache restored from key: gha-05-expensive-Linux-v1
cache-hit='true'
2026-09-14T13:12:25Z
Cache hit occurred on the primary key gha-05-expensive-Linux-v1, not saving cache.
```

- On a miss, `cache-hit` is an **empty string**, not `'false'`: test `!= 'true'`, never `== 'false'`.
- The second run printed the date written by the first one: the files came back.
- A cache is **never updated**: on a hit, nothing is saved, even if the job changed the files. To store new content, change the key — here the `-v1` suffix, or a `hashFiles()` of the files that define the content.
- The cache is saved by a *Post* step, at the end of the job, only if the job succeeded (`post-if: success()` in the action's `action.yml`).

### Which caches a run can see

From the documentation: "Workflow runs can restore caches created in either the current branch or the default branch", plus the base branch for a pull request; not caches of child or sibling branches. A cache created by a `pull_request` run belongs to the merge ref and "can only be restored by re-runs of the pull request". In practice: let a `push` to `main` fill the caches, and every branch and pull request starts from them.

## Artifacts

Each `test` job uploaded its report, `pack` uploaded the package:

```text
test (ubuntu-latest) | Artifact test-results-ubuntu-latest has been successfully uploaded! Final size is 510 bytes. Artifact ID is 10348099499
pack                 | Successfully created package '/home/runner/work/learn/learn/code/github-actions/dotnet/dist/Slugs.1.0.1.nupkg'.
pack                 | Artifact package has been successfully uploaded! Final size is 3463 bytes. Artifact ID is 10349121193
```

`report` downloaded them. With `pattern`, each matching artifact goes into its own sub-folder (`merge-multiple: true` would put all files in one folder):

```text
Found 4 artifact(s)
Filtering artifacts by pattern 'test-results-*'
Total of 3 artifact(s) downloaded
package/Slugs.1.0.1.nupkg
results/test-results-macos-latest/slugs.junit.xml
results/test-results-ubuntu-latest/slugs.junit.xml
results/test-results-windows-latest/slugs.junit.xml
results/test-results-macos-latest: tests="4" failures="0"
results/test-results-ubuntu-latest: tests="4" failures="0"
results/test-results-windows-latest: tests="4" failures="0"
```

Expiry dates, from `gh api repos/spareilleux/learn/actions/runs/<run-id>/artifacts`: 7 days for the reports (`retention-days: 7`), 90 days for the package — the repository's default, the maximum allowed for a public repository.

The same artifacts on your machine, with the [GitHub CLI](https://cli.github.com/manual/gh_run_download):

```powershell
gh run download 34848185308 --repo spareilleux/learn --name package --dir package
gh run download 34848185308 --repo spareilleux/learn --pattern "test-results-*" --dir results
```

```text
package/Slugs.1.0.2.nupkg
results/test-results-macos-latest/slugs.junit.xml
results/test-results-ubuntu-latest/slugs.junit.xml
results/test-results-windows-latest/slugs.junit.xml
```

## Key takeaways

- Cache = regenerable files shared between runs; artifact = files produced by a run, shared between its jobs and with people.
- `setup-dotnet` `cache: true` requires `packages.lock.json` (`RestorePackagesWithLockFile`); restore with `--locked-mode`.
- Measure: here the NuGet cache turned a 3 s restore into 1 s, and cost as much to download.
- `cache-hit` is `'true'` or empty; a cache is immutable, so change the key to refresh it.
- Give every matrix job its own artifact name, set `if-no-files-found: error`, and shorten `retention-days` for reports.

## Exercises

1. Two matrix jobs (`ubuntu-latest`, `macos-latest`) upload an artifact with the **same** name, `os`, containing a file with the OS name. A later job downloads `name: os`. What happens?

<details>
<summary>Solution</summary>

The upload-artifact README says "Artifacts created by upload-artifact@v4 are immutable", and warns that in a matrix, uploading to the same artifact means "you will encounter conflict errors". That's not what happened in [`gha-05-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-05-exercises.yml), three times: both uploads succeeded and the run had **two** artifacts named `os`.

```text
same-name (macos-latest)  | Artifact os has been successfully uploaded! Final size is 141 bytes. Artifact ID is 10348738133
same-name (ubuntu-latest) | Artifact os has been successfully uploaded! Final size is 142 bytes. Artifact ID is 10348957530
same-name-download        | Downloading single artifact
same-name-download        | ubuntu-latest
```

The download picked one of them without any warning — the Ubuntu one, both in the job and with `gh run download --name os`. Which one is chosen isn't documented: *to verify* whether it's stable. Either way, a report can silently disappear. Put the matrix value in the name.

</details>

2. Remove the `cache-dependency-path` input and use `dotnet-version: 10.0.x` instead of `global-json-file`, keeping `cache: true`. What does the job do?

<details>
<summary>Solution</summary>

It fails in the `setup-dotnet` step, after installing the SDK:

```text
##[error]Dependencies lock file is not found in /home/runner/work/learn/learn. Supported file patterns: packages.lock.json
```

Without `cache-dependency-path`, the action looks for `packages.lock.json` at the repository root only. The cache isn't optional once you ask for it: no lock file, no job.

</details>

3. A step uses `key: counter-${{ github.run_id }}` and `restore-keys: counter-`, then adds one to a number stored in the cached folder. What do `cache-hit` and the counter show on the first run, and on the second?

<details>
<summary>Solution</summary>

```text
Run 1
Cache not found for input keys: gha-05-counter-34847802892, gha-05-counter-
cache-hit=''
counter is now 1
Cache saved with key: gha-05-counter-34847802892

Run 2
Cache restored from key: gha-05-counter-34847802892
cache-hit='false'
counter is now 2
Cache saved with key: gha-05-counter-34848189352
```

On run 2 the exact key didn't exist (new `run_id`), but the prefix `gha-05-counter-` matched the most recent cache: `cache-hit` is `'false'` — a partial match — the files are restored anyway, and since the exact key was missed, a new cache is saved at the end. That's how you build an incremental cache that keeps improving, at the cost of one new cache entry per run.

</details>

## Sources

- [Dependency caching reference](https://docs.github.com/actions/reference/workflows-and-actions/dependency-caching)
- [Workflow artifacts](https://docs.github.com/actions/concepts/workflows-and-actions/workflow-artifacts)
- [Store and share data with workflow artifacts](https://docs.github.com/actions/tutorials/store-and-share-data)
- [`actions/setup-dotnet`: caching NuGet packages](https://github.com/actions/setup-dotnet#caching-nuget-packages)
- [`actions/upload-artifact`](https://github.com/actions/upload-artifact) and [`actions/download-artifact`](https://github.com/actions/download-artifact)
- [Locking dependencies — NuGet](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies)
