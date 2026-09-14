---
title: 9. Debugging runs
description: Read a failing run from the terminal, group and annotate logs, switch on debug logging, re-run only what failed, and understand timeouts, cancellations and continue-on-error.
sidebar:
  order: 9
---

## A workflow that fails on purpose

[`.github/workflows/gha-09-debug.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-09-debug.yml) has four jobs, each one a situation you will meet:

```yaml
# GitHub Actions course, lesson 9: reading a failing run, debug logging, re-runs, timeouts
name: "GHA 09: debugging"

on:
  workflow_dispatch:
    inputs:
      fail:
        description: Make the test step fail
        type: boolean
        default: true
  push:
    branches: [main]
    paths: ['.github/workflows/gha-09-debug.yml']

permissions:
  contents: read

jobs:
  noisy:
    runs-on: ubuntu-latest
    steps:
      - name: Groups, debug and notice messages
        run: |
          echo "::group::Environment of the step"
          echo "RUNNER_OS=$RUNNER_OS RUNNER_ARCH=$RUNNER_ARCH"
          echo "RUNNER_DEBUG='${RUNNER_DEBUG:-}'"
          echo "::endgroup::"
          echo "::debug::only visible when step debug logging is on"
          echo "::notice title=Lesson 9::a notice annotation"
      - name: Trace the commands with set -x
        run: |
          set -x
          version=$(date -u +%Y.%m.%d)
          test -n "$version"
      - name: Tests (fail on demand, attempt ${{ github.run_attempt }})
        run: |
          if [ "${{ inputs.fail }}" = "true" ] && [ "${{ github.run_attempt }}" = "1" ]; then
            echo "::error title=Flaky test::failed on attempt ${{ github.run_attempt }}"
            exit 1
          fi
          echo "tests passed on attempt ${{ github.run_attempt }}"

  independent:
    runs-on: ubuntu-latest
    steps:
      - run: echo "this job doesn't depend on noisy"

  allowed-to-fail:
    runs-on: ubuntu-latest
    continue-on-error: true
    steps:
      - run: exit 3

  timeout:
    runs-on: ubuntu-latest
    timeout-minutes: 1
    steps:
      - run: sleep 90
```

The test step only fails on the first attempt: a **flaky test**, the most common reason to re-run.

## Step 1: the summary, from the terminal

```powershell
gh workflow run gha-09-debug.yml --field fail=true
gh run view 34850662582
```

The end of the output lists the annotations — every `::error`, `::warning` and `::notice`, plus the errors the runner adds:

```text
ANNOTATIONS
X The job has exceeded the maximum execution time of 1m0s
timeout: .github#1

X The operation was canceled.
timeout: .github#5

X Process completed with exit code 1.
noisy: .github#10

X failed on attempt 1
noisy: .github#9

- a notice annotation
noisy: .github#14

X Process completed with exit code 3.
allowed-to-fail: .github#5
```

Read them before any log: here they already say *which* jobs failed and *why* — a timeout, a test, an expected failure. The `title=` of an annotation appears in the web page, not in this list.

## Step 2: only the failed logs

```powershell
gh run view 34850662582 --log-failed
```

The full log of this attempt has 169 lines; `--log-failed` returned 15, only the failing steps of `noisy` and `allowed-to-fail`:

```text
noisy	Tests (fail on demand, attempt 1)	##[error]failed on attempt 1
noisy	Tests (fail on demand, attempt 1)	##[error]Process completed with exit code 1.
allowed-to-fail	Run exit 3	##[error]Process completed with exit code 3.
```

The `timeout` job isn't there: its step was **cancelled**, not failed. When a job seems to vanish from `--log-failed`, look at its conclusion.

## Workflow commands that structure a log

In the normal log of the first step:

```text
##[group]Environment of the step
RUNNER_OS=Linux RUNNER_ARCH=X64
RUNNER_DEBUG=''
##[endgroup]
##[notice]a notice annotation
```

- `::group::title` … `::endgroup::` fold lines into a collapsible section in the web log.
- `::notice`, `::warning`, `::error` create annotations (with `title=`, `file=`, `line=` — [lesson 4](../04-expressions-and-outputs/)).
- `::debug::` printed **nothing**: debug messages are hidden unless debug logging is on.

For shell scripts, `set -x` prints each command after expansion, the equivalent of stepping through:

```text
++ date -u +%Y.%m.%d
+ version=2026.09.14
+ test -n 2026.09.14
```

## Debug logging

Two switches, either as repository secrets or variables, or for one re-run with `--debug`:

| Setting | Adds |
|---|---|
| `ACTIONS_STEP_DEBUG` = `true` | `##[debug]` lines: condition evaluation, inputs, the script file executed, `::debug::` messages |
| `ACTIONS_RUNNER_DEBUG` = `true` | runner diagnostic logs in the log archive |

The third attempt of the run was started with:

```powershell
gh run rerun 34850662582 --debug
```

The same step, now:

```text
##[debug]Evaluating condition for step: 'Groups, debug and notice messages'
##[debug]Evaluating: success()
##[debug]Evaluating success:
##[debug]=> true
##[debug]Result: true
##[debug]Starting: Groups, debug and notice messages
...
##[debug]/usr/bin/bash -e /home/runner/work/_temp/e3c00f12-b91a-4ef4-830d-2340170b7bc7.sh
::group::Environment of the step
##[group]Environment of the step
RUNNER_OS=Linux RUNNER_ARCH=X64
RUNNER_DEBUG='1'
::endgroup::
##[endgroup]
##[debug]only visible when step debug logging is on
##[notice]a notice annotation
```

- Every `if:` shows how it was evaluated — the fastest way to understand a step that was skipped.
- `RUNNER_DEBUG` is `1`: a script can print more when it's set.
- The `noisy` job went from 70 to 190 log lines.

The log archive of that attempt, downloaded with `gh api repos/spareilleux/learn/actions/runs/34850662582/attempts/3/logs > attempt3.zip`, contains one folder per job with one file per step, and a `runner-diagnostic-logs` folder:

```text
runner-diagnostic-logs/103998873521-noisy.zip
    13448  Runner_20260914-134407-utc.log
    73191  Worker_20260914-134409-utc.log
```

The *Runner* log is the agent that picks up jobs; the *Worker* log is the process that executes the steps. You rarely need them, except when a job fails before its first step.

## Re-running

The documentation: "Re-runs use the privileges of the actor who initially triggered the workflow … The workflow will also use the same `GITHUB_SHA` (commit SHA) and `GITHUB_REF`". A re-run tests the **same commit**: it can reveal a flaky test, not validate a fix you just pushed.

Attempt 2 was started with `gh run rerun 34850662582 --failed`:

```text
noisy            success    attempt=2  13:42:13 → 13:42:16
timeout          cancelled  attempt=2  13:42:13 → 13:43:42
allowed-to-fail  failure    attempt=2  13:42:13 → 13:42:16
independent      success    attempt=2  13:40:15 → 13:40:18
```

- `noisy` passed: `github.run_attempt` was `2`, and even the step name changed (`Tests (fail on demand, attempt 2)`).
- The three jobs that hadn't succeeded ran again — the cancelled one included; `independent` wasn't re-run: its times are those of attempt 1, carried over.
- Each attempt keeps its own logs (`attempts/1/logs`, `attempts/2/logs`…).

## Timeouts and conclusions

`timeout-minutes` defaults to **360** minutes per job. The `timeout` job was limited to 1 minute and ran `sleep 90`:

```text
2026-09-14T13:44:10.0526092Z ##[group]Run sleep 90
2026-09-14T13:45:37.2574842Z ##[error]The operation was canceled.
2026-09-14T13:45:37.3009029Z Terminate orphan process: pid (2052) (sleep)
```

Cancelled after 87 seconds, not 60 — on every attempt, and in the exercise with `sleep 300`. Treat the limit as "cancelled some time after the limit", and set it well below the time you're ready to pay for.

The conclusions of the runs, which decide the red or grey icon:

| Run | Jobs | Run conclusion |
|---|---|---|
| push | `noisy` ✓, `independent` ✓, `allowed-to-fail` ✗ (continue-on-error), `timeout` cancelled | `cancelled` |
| dispatch, attempt 1 | `noisy` ✗, `timeout` cancelled, others as above | `failure` |
| dispatch, attempts 2 and 3 | `noisy` ✓, `timeout` cancelled | `cancelled` |

A timeout makes the run *cancelled*, not *failed* — and a notification rule or a required check that only looks for failures misses it.

## Key takeaways

- Start with `gh run view <id>` (annotations), then `gh run view <id> --log-failed`; cancelled jobs aren't in the failed logs.
- `::group::`, `::notice::` and `set -x` make logs readable; `::debug::` needs debug logging.
- `gh run rerun --debug` shows how every `if:` was evaluated, and adds runner diagnostic logs.
- `gh run rerun --failed` re-runs every job that didn't succeed, on the same commit.
- A job timeout cancels the job (here 87 s for a 1-minute limit) and makes the run *cancelled*.

## Exercises

1. Move the timeout from the job to the step: `timeout-minutes: 1` on a `sleep 300` step, followed by a step with `if: always()`. What's the step's conclusion, and does the next step run?

<details>
<summary>Solution</summary>

Checked with [`gha-09-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-09-exercises.yml):

```text
step-timeout | Run date -u +%T | 13:46:49
step-timeout | Run date -u +%T | ##[error]The action 'Run date -u +%T' has timed out after 1 minutes.
step-timeout | Run date -u +%T | 13:48:01
```

The step **failed** (not cancelled) after 72 seconds, the `always()` step ran, and the job's conclusion was `failure`. The job-level timeout of the same run cancelled its job after 87 seconds (13:46:49 → 13:48:16), with `sleep 300`: the delay doesn't depend on the script.

</details>

2. The only failing job of a run has `continue-on-error: true`, and another job `needs` it. What's the run's conclusion, and what does `needs.allowed-to-fail.result` contain?

<details>
<summary>Solution</summary>

```text
allowed-to-fail  failure
after            success
run conclusion   success
needs.allowed-to-fail.result=success
```

The job is shown as failed, but the run succeeds — "Set to `true` to allow a workflow run to pass when this job fails" — and for the dependent job, the result is `success`: `after` ran without any `if:`. A dependent job can't tell that the failure was tolerated.

</details>

3. A job ran although you expected its `if:` to skip it. Where can you see how GitHub evaluated the condition, without debug logging?

<details>
<summary>Solution</summary>

In the job's *system* log, part of the log archive (`gh api repos/<owner>/<repo>/actions/runs/<run-id>/attempts/<n>/logs`), file `<job>/system.txt`. For `noisy`, on attempt 1, without debug:

```text
Requested labels: ubuntu-latest
Job defined at: spareilleux/learn/.github/workflows/gha-09-debug.yml@refs/heads/main
Waiting for a runner to pick up this job...
Evaluating noisy.if
Evaluating: success()
Result: true
```

A job without `if:` is evaluated as `success()`. For the `if:` of **steps**, re-run with `--debug`: the `##[debug]Evaluating condition for step` lines appear in the step's log.

</details>

## Sources

- [Enable debug logging](https://docs.github.com/actions/how-tos/monitor-workflows/enable-debug-logging)
- [Re-run workflows and jobs](https://docs.github.com/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs)
- [Workflow commands](https://docs.github.com/actions/reference/workflows-and-actions/workflow-commands)
- [Workflow syntax: `timeout-minutes`, `continue-on-error`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idtimeout-minutes)
- [`gh run view`](https://cli.github.com/manual/gh_run_view) and [`gh run rerun`](https://cli.github.com/manual/gh_run_rerun)
