---
title: 1. First workflow
description: Workflows, events, jobs, steps and runners — and reading a run from the GitHub CLI.
sidebar:
  order: 1
---

## The vocabulary, mapped

A **workflow** is a YAML file in `.github/workflows/`. An **event** (a push, a pull request, a click on *Run workflow*) starts a **run** of it. A run contains **jobs**; each job gets a fresh virtual machine, the **runner**, and executes its **steps** in order. A step either runs a shell script (`run:`) or calls an **action** (`uses:`), a reusable piece of code published in a repository.

| GitHub Actions | Azure Pipelines | Jenkins (declarative) |
|---|---|---|
| workflow (`.github/workflows/*.yml`) | pipeline (`azure-pipelines.yml`) | `Jenkinsfile` |
| event (`on:`) | `trigger:`, `pr:`, `schedules:` | `triggers { }` |
| job | job (stages are optional) | `stage` |
| step: `run:` | `script:` / `pwsh:` | `sh` / `bat` |
| step: `uses:` (action) | task (`DotNetCoreCLI@2`) | plugin step |
| runner (`runs-on: ubuntu-latest`) | agent (`pool: vmImage: ubuntu-latest`) | `agent { label '…' }` |

Two consequences of "each job gets a fresh machine" surprise people coming from Jenkins:

- nothing is on the disk at the start of a job, **not even your code**: you check it out explicitly;
- files don't flow from one job to the next: jobs share data through outputs (lesson 4) or artifacts (lesson 5).

## The smallest useful workflow

[`.github/workflows/gha-01-hello.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-01-hello.yml):

```yaml
# GitHub Actions course, lesson 1: the smallest useful workflow
name: "GHA 01: hello"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-01-hello.yml']

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: echo "Hello from GitHub Actions"

      - name: Where am I?
        run: |
          echo "Event:   ${{ github.event_name }}"
          echo "Commit:  ${{ github.sha }}"
          echo "Runner:  $RUNNER_OS $RUNNER_ARCH"
          echo "Workdir: $(pwd)"
          ls -A

      - name: Check out the repository
        uses: actions/checkout@v7

      - name: Look again
        run: ls -A
```

| Line | Meaning |
|---|---|
| `name:` | the name shown in the *Actions* tab |
| `on: workflow_dispatch` | adds a *Run workflow* button (and `gh workflow run`) |
| `on: push` with `branches` and `paths` | runs on a push to `main` that changes this file |
| `jobs.hello.runs-on` | the runner image: GitHub-hosted Ubuntu |
| `run: \|` | a multi-line script, run by `bash` on Linux and macOS |
| `uses: actions/checkout@v7` | the [checkout action](https://github.com/actions/checkout), major version 7 |

## The run, step by step

Pushing the file started a run. With the [GitHub CLI](https://cli.github.com/):

```powershell
gh run list --workflow gha-01-hello.yml
gh run view 34845175861
gh run view 34845175861 --log
```

```text
✓ main GHA 01: hello · 34845175861
Triggered via push about 6 minutes ago

JOBS
✓ hello in 4s (ID 103979246921)
```

The log of the `Where am I?` step (timestamps removed):

```text
##[group]Run echo "Event:   push"
echo "Event:   push"
echo "Commit:  61e7e4235b7bc138f2f35cd7f61195bdaed4b019"
echo "Runner:  $RUNNER_OS $RUNNER_ARCH"
echo "Workdir: $(pwd)"
ls -A
shell: /usr/bin/bash -e {0}
Event:   push
Commit:  61e7e4235b7bc138f2f35cd7f61195bdaed4b019
Runner:  Linux X64
Workdir: /home/runner/work/learn/learn
```

Three things to read in it:

1. **`${{ github.event_name }}` was replaced before bash ran.** The script shown by the runner already contains `push`: expressions are text substitution done by GitHub. `$RUNNER_OS` is different: it's an environment variable, expanded by bash. Lesson 4 comes back to this, because it matters for security.
2. **`ls -A` printed nothing.** The working directory `/home/runner/work/learn/learn` exists but is empty. After `actions/checkout`, the same command lists the repository:

   ```text
   .git
   .gitattributes
   .github
   .gitignore
   .vscode
   AGENTS.md
   CLAUDE.md
   README.md
   ```

3. **`shell: /usr/bin/bash -e {0}`**: each `run:` is written to a temporary script and run with `bash -e`, so the step fails at the first failing command.

The `Set up job` step tells you what you got:

```text
Current runner version: '2.337.0'
Ubuntu
24.04.5
LTS
Image: ubuntu-24.04
Version: 20260907.300.1
GITHUB_TOKEN Permissions
Contents: read
Metadata: read
Packages: read
```

`ubuntu-latest` is a moving label: in September 2026 it's Ubuntu 24.04. And the job received a `GITHUB_TOKEN` that can only **read** the repository — lesson 7 explains how to widen or narrow it.

## Trap: an invalid workflow fails on every push

My first version of the lesson 3 workflow had a YAML error. The run list showed the **file path** instead of the workflow name, a failure in 0 seconds, and no job:

```text
X main .github/workflows/gha-03-triggers.yml · 34845174629
Triggered via push less than a minute ago

X This run likely failed because of a workflow file issue.
```

The web page of the run gives the reason: `You have an error in your yaml syntax on line 41`. Worse, the next push — which didn't touch that file, and the workflow has a `paths` filter — produced another failed run: GitHub can't read the filters of a file it can't parse. The culprit:

```yaml
        run: echo "cron: ${{ github.event.schedule }}"
```

In YAML, an unquoted value can't contain `: ` (colon followed by a space). A local check catches it before pushing:

```powershell
python -c "import yaml; yaml.safe_load(open('.github/workflows/gha-03-triggers.yml'))"
```

```text
yaml.scanner.ScannerError: mapping values are not allowed here
  in ".github/workflows/gha-03-triggers.yml", line 41, column 24
```

The fix: a block scalar (`run: |` and the command on the next line), or quote the whole value.

## Key takeaways

- Workflow → run → jobs (one fresh runner each) → steps (`run:` or `uses:`).
- A job starts with an empty workspace: `actions/checkout` is almost always the first step.
- `${{ }}` is replaced by GitHub before the script runs; `$VAR` is expanded by the shell.
- `gh run list`, `gh run view` and `gh run view --log` read runs without leaving the terminal.
- A workflow that doesn't parse shows up as a 0-second failure named after its file, on every push.

## Exercises

1. In `gha-01-hello.yml`, what would `ls -A` print in the `Where am I?` step if `actions/checkout` were the first step?

<details>
<summary>Solution</summary>

The repository files (`.git`, `.github`, `AGENTS.md`…), like the `Look again` step. Checkout clones into the working directory, `/home/runner/work/learn/learn`, which is where every `run:` starts.

</details>

2. Add a step that fails, run the workflow with `gh workflow run gha-01-hello.yml`, and find the failing step from the terminal.

<details>
<summary>Solution</summary>

```yaml
      - name: Fail on purpose
        run: exit 1
```

```powershell
gh workflow run gha-01-hello.yml
gh run list --workflow gha-01-hello.yml --limit 1
gh run view <run-id> --log-failed
```

`--log-failed` prints only the logs of the failed steps, ending with `##[error]Process completed with exit code 1.`. The steps after it don't run, unless they have a condition such as `if: always()` (lesson 4).

</details>

3. Why does `echo "Runner: $RUNNER_OS"` work in a `run:` step but `echo "cron: $X"` broke the YAML?

<details>
<summary>Solution</summary>

The first line is inside a block scalar (`run: |`), where YAML takes the text as is. The second was a plain (unquoted) scalar on the same line as `run:`, and a plain scalar can't contain `: `. It has nothing to do with the shell: the file is rejected before any runner starts.

</details>

## Sources

- [Understanding GitHub Actions](https://docs.github.com/actions/get-started/understand-github-actions)
- [Workflow syntax for GitHub Actions](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax)
- [`gh run view` — GitHub CLI manual](https://cli.github.com/manual/gh_run_view)
- [YAML 1.2 specification — plain scalars](https://yaml.org/spec/1.2.2/#733-plain-style)
