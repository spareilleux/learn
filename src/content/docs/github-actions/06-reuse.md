---
title: 6. Reusable workflows and composite actions
description: Stop copying YAML — a composite action for repeated steps, a reusable workflow for whole jobs, with inputs, outputs, a matrix, and what the called workflow can and can't see.
sidebar:
  order: 6
---

## The copy problem

After five lessons, the same four lines appear in several workflows: `setup-dotnet` with `global-json-file`, the NuGet cache, `dotnet restore --locked-mode`. GitHub Actions has two ways to share them, which C# developers can map to familiar ideas:

| | Composite action | Reusable workflow |
|---|---|---|
| Shares | a sequence of **steps** | whole **jobs** |
| File | `action.yml` in its own folder | a workflow in `.github/workflows/` with `on: workflow_call` |
| Called from | a step: `uses: ./.github/actions/<name>` | a job: `uses: ./.github/workflows/<file>.yml` |
| Chooses the runner | no, runs in the caller's job | yes, each job has its own `runs-on` |
| Secrets | "Cannot use secrets" directly — pass them as inputs | receives `secrets:` or `secrets: inherit` |
| In the log | "Logged as one step even if it contains multiple steps" | each job and step logged normally |
| C# analogy | a helper method called in the middle of your code | a whole build template |
| Azure Pipelines | step template | job or stage template |

The quotes come from the documentation's comparison table. Both can live in the same repository or be called from another one (`owner/repo/path@ref`).

## A composite action

[`.github/actions/dotnet-restore/action.yml`](https://github.com/spareilleux/learn/blob/main/.github/actions/dotnet-restore/action.yml):

```yaml
# GitHub Actions course, lesson 6: a composite action that installs the SDK and restores with the NuGet cache
name: Set up and restore a .NET solution
description: Installs the SDK pinned by global.json, then restores with the NuGet cache and the lock files.

inputs:
  directory:
    description: Folder that contains global.json, the solution and the packages.lock.json files
    required: true

outputs:
  sdk-version:
    description: The SDK version reported by dotnet --version
    value: ${{ steps.sdk.outputs.version }}

runs:
  using: composite
  steps:
    - name: Keep NuGet packages in the workspace
      shell: bash
      run: echo "NUGET_PACKAGES=$GITHUB_WORKSPACE/.nuget/packages" >> "$GITHUB_ENV"
    - uses: actions/setup-dotnet@v6
      with:
        global-json-file: ${{ inputs.directory }}/global.json
        cache: true
        cache-dependency-path: ${{ inputs.directory }}/*/packages.lock.json
    - id: sdk
      shell: bash
      working-directory: ${{ inputs.directory }}
      run: echo "version=$(dotnet --version)" >> "$GITHUB_OUTPUT"
    - shell: bash
      working-directory: ${{ inputs.directory }}
      run: dotnet restore --locked-mode
```

- `inputs` are read with `${{ inputs.directory }}`; an output must be mapped explicitly from an inner step (`value: ${{ steps.sdk.outputs.version }}`).
- Every `run:` step in a composite action needs a `shell:` — exercise 1 shows what happens without it.
- The first step writes to `$GITHUB_ENV`: the variable exists for the following steps of the action **and** for the rest of the caller's job. A composite action shares the job's machine, workspace and environment.

## A reusable workflow

[`.github/workflows/gha-06-dotnet-test.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-dotnet-test.yml) uses the action and runs the tests:

```yaml
# GitHub Actions course, lesson 6: a reusable workflow that tests the .NET sample on one OS
name: "GHA 06: reusable .NET test"

on:
  workflow_call:
    inputs:
      os:
        description: Runner label
        type: string
        default: ubuntu-latest
    outputs:
      sdk-version:
        description: SDK used by the tests
        value: ${{ jobs.test.outputs.sdk-version }}
      tested-on:
        description: Operating system of the runner
        value: ${{ jobs.test.outputs.tested-on }}

jobs:
  test:
    runs-on: ${{ inputs.os }}
    outputs:
      sdk-version: ${{ steps.setup.outputs.sdk-version }}
      tested-on: ${{ runner.os }}
    steps:
      - uses: actions/checkout@v7
      - id: setup
        uses: ./.github/actions/dotnet-restore
        with:
          directory: code/github-actions/dotnet
      - run: dotnet test --no-restore
        working-directory: code/github-actions/dotnet
      - name: What the called workflow sees
        shell: bash
        run: |
          echo "event_name:         ${{ github.event_name }}"
          echo "github.workflow:    ${{ github.workflow }}"
          echo "github.workflow_ref: ${{ github.workflow_ref }}"
          echo "job.workflow_ref:   ${{ job.workflow_ref }}"
          echo "COURSE from caller: '$COURSE'"
          echo "NUGET_PACKAGES:     $NUGET_PACKAGES"
```

Outputs climb two levels: step → job (`jobs.test.outputs`) → workflow (`on.workflow_call.outputs`).

And the caller, [`.github/workflows/gha-06-reuse.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-reuse.yml):

```yaml
# GitHub Actions course, lesson 6: calling a reusable workflow with a matrix, and reading its outputs
name: "GHA 06: reuse"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-06-reuse.yml', '.github/workflows/gha-06-dotnet-test.yml', '.github/actions/dotnet-restore/**']

env:
  COURSE: github-actions

jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
    uses: ./.github/workflows/gha-06-dotnet-test.yml
    with:
      os: ${{ matrix.os }}

  summary:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "COURSE in the caller: '$COURSE'"
          echo "sdk-version: ${{ needs.test.outputs.sdk-version }}"
          echo "tested-on:   ${{ needs.test.outputs.tested-on }}"
```

A job that calls a reusable workflow has **no** `runs-on` and no `steps`: only `name`, `uses`, `with`, `secrets`, `strategy`, `needs`, `if`, `concurrency`, `permissions` and `cache-mode`.

## What the run shows

```text
test (ubuntu-latest) / test   success
test (windows-latest) / test  success
summary                       success
```

Job names are `<caller job> / <called job>`. In the API, the Ubuntu job has these steps:

```text
1 Set up job
2 Run actions/checkout@v7
3 Run ./.github/actions/dotnet-restore
4 Run dotnet test --no-restore
5 What the called workflow sees
9 Post Run ./.github/actions/dotnet-restore
10 Post Run actions/checkout@v7
11 Complete job
```

The four steps of the composite action are **one** step (3), and their logs are nested groups inside it; numbers 6 to 8 don't appear in the list. The *Post* step 9 is the post step of `setup-dotnet` inside the action — the NuGet cache save, skipped here because the cache was hit.

### What the called workflow sees

```text
event_name:         push
github.workflow:    GHA 06: reuse
github.workflow_ref: spareilleux/learn/.github/workflows/gha-06-reuse.yml@refs/heads/main
job.workflow_ref:   spareilleux/learn/.github/workflows/gha-06-dotnet-test.yml@refs/heads/main
COURSE from caller: ''
NUGET_PACKAGES:     /home/runner/work/learn/learn/.nuget/packages
```

- The `github` context belongs to the **caller**: same event, same workflow name. To know which file defines the running job, read `job.workflow_ref`.
- `COURSE` is empty. The documentation is explicit: "environment variables set in an `env` context defined at the workflow level in the caller workflow are not propagated to the called workflow". Pass values as `inputs`, or use `vars` (repository variables).
- `NUGET_PACKAGES` came from the composite action's `$GITHUB_ENV` and reached the next steps of the job.

And the caches? The action restored `dotnet-cache-Linux-557e0cce…`, the cache saved by [lesson 5](../05-caches-and-artifacts/)'s workflow: same key, same path, same branch — caches belong to the repository, not to a workflow.

### Outputs of a matrix

```text
COURSE in the caller: 'github-actions'
sdk-version: 10.0.401
tested-on:   Windows
```

Two matrix jobs set `tested-on`, the caller got one value: Windows, the job that finished last (13:25:06, against 13:24:29 for Ubuntu). That's the documented rule: "the output will be the output set by the last successful completing reusable workflow of the matrix which actually sets a value". Don't use a matrix output for anything that differs between the combinations; upload an artifact per combination instead.

## Limits worth knowing

From the reference:

- "You can connect up to ten levels of workflows" (the caller plus nine nested levels);
- "You can call a maximum of 50 unique reusable workflows from a single workflow file";
- a reusable workflow referenced by branch or tag can change under your feet; a commit SHA can't. Lesson 7 comes back to pinning.

## Key takeaways

- Repeated **steps** → composite action, called by a step, running in the caller's job. Repeated **jobs** → reusable workflow, called by a job, with its own runners.
- Composite `run:` steps need `shell:`; local actions and workflows need `actions/checkout` first (for actions) and a path starting with `./`.
- The called workflow sees the caller's `github` context but not its `env`; use `inputs`, `outputs` and `job.workflow_ref`.
- With a matrix, a reusable workflow's output is the one of the last job to finish.

## Exercises

1. Remove `shell: bash` from a `run:` step of a composite action. When is the error detected, and what does it say?

<details>
<summary>Solution</summary>

Only when a job runs the action — the push that commits it doesn't complain. Checked with [`gha-06-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-exercises.yml) and a deliberately broken [`exercise-no-shell`](https://github.com/spareilleux/learn/blob/main/.github/actions/exercise-no-shell/action.yml) action:

```text
##[error]/home/runner/work/learn/learn/./.github/actions/exercise-no-shell/action.yml (Line: 8, Col: 7): Required property is missing: shell
##[error]Failed to load /home/runner/work/learn/learn/./.github/actions/exercise-no-shell/action.yml
```

In a workflow, `run:` has a default shell; in a composite action, it has none.

</details>

2. A job starts directly with `uses: ./.github/actions/dotnet-restore`, without `actions/checkout`. What happens?

<details>
<summary>Solution</summary>

```text
##[error]Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/learn/learn/.github/actions/dotnet-restore'. Did you forget to run actions/checkout before running your local action?
```

A local action is read from the workspace, which is empty until the checkout. A reusable workflow referenced with `./` doesn't have this problem: GitHub reads it from the repository before the job starts.

</details>

3. The caller passes `configuration: Release` in `with:`, but `gha-06-dotnet-test.yml` declares only the `os` input. When does it fail?

<details>
<summary>Solution</summary>

Before any job starts. The run ends with the conclusion `startup_failure` and no jobs; `gh run view` only says "This run likely failed because of a workflow file issue", and the run page shows:

```text
The workflow is not valid. .github/workflows/gha-06-invalid-input.yml (Line: 13, Col: 22): Invalid input, configuration is not defined in the referenced workflow.
```

Checked on a temporary branch, so that an invalid workflow wouldn't fail every push on `main` (see [lesson 1](../01-first-workflow/)). Inputs are a contract checked when the run is created, like the parameters of a method at compile time.

</details>

## Sources

- [Reuse workflows](https://docs.github.com/actions/how-tos/reuse-automations/reuse-workflows)
- [Reusable workflows reference](https://docs.github.com/actions/reference/workflows-and-actions/reusable-workflows)
- [Reusing workflow configurations: reusable workflows versus composite actions](https://docs.github.com/actions/concepts/workflows-and-actions/reusing-workflow-configurations)
- [Metadata syntax for GitHub Actions (`action.yml`)](https://docs.github.com/actions/reference/workflows-and-actions/metadata-syntax)
- [Contexts reference: `job.workflow_ref`](https://docs.github.com/actions/reference/workflows-and-actions/contexts)
