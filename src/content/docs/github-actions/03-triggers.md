---
title: 3. Triggers, filters and concurrency
description: push and pull_request with branch and path filters, manual runs with inputs, schedules, and concurrency groups that cancel or queue runs.
sidebar:
  order: 3
---

## Choosing the events

The `on:` key lists the events that start a run. The ones you use every day:

| Event | Starts a run when | Azure Pipelines equivalent |
|---|---|---|
| `push` | commits are pushed to a branch or a tag | `trigger:` |
| `pull_request` | a pull request is opened, updated (`synchronize`) or reopened | `pr:` |
| `workflow_dispatch` | someone clicks *Run workflow*, or runs `gh workflow run` | manual run with `parameters:` |
| `schedule` | a cron expression matches | `schedules:` |
| `workflow_call` | another workflow calls this one ([lesson 6](../06-reuse/)) | templates |

[`.github/workflows/gha-03-triggers.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-03-triggers.yml) combines four of them:

```yaml
# GitHub Actions course, lesson 3: events, filters, manual inputs, schedules, concurrency
name: "GHA 03: triggers"

on:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-03-triggers.yml']
  workflow_dispatch:
    inputs:
      greeting:
        description: Who to greet
        type: string
        default: world
      loud:
        description: Shout the greeting
        type: boolean
        default: false
  schedule:
    - cron: '17 6 * * 1'   # Mondays 06:17 UTC

concurrency:
  group: gha-03-${{ github.ref }}
  cancel-in-progress: true

jobs:
  show:
    runs-on: ubuntu-latest
    steps:
      - name: Which event?
        run: |
          echo "event_name: ${{ github.event_name }}"
          echo "ref:        ${{ github.ref }}"
          echo "actor:      ${{ github.actor }}"
      - name: Manual inputs
        if: github.event_name == 'workflow_dispatch'
        run: |
          echo "greeting: ${{ inputs.greeting }}"
          echo "loud:     ${{ inputs.loud }}"
      - name: Scheduled run
        if: github.event_name == 'schedule'
        run: |
          echo "cron: ${{ github.event.schedule }}"
      - name: Slow step (to see concurrency cancel a run)
        run: sleep 60
```

## Filters: `branches` and `paths`

`branches: [main]` ignores pushes to other branches; `paths` ignores pushes that don't change a matching file. Every workflow of this site uses `paths` so that a typo fix in a lesson doesn't rebuild the Rust course on three OSes.

Two warnings from the documentation:

- **Required checks.** "If a workflow is skipped due to path filtering, branch filtering, or a commit message, then checks associated with that workflow will remain in a 'Pending' state." If a `paths`-filtered workflow is a *required* status check in a branch protection rule, a pull request that doesn't touch those paths can never be merged.
- **Big diffs.** "If the generated diff contains more than 3,000 files and the files the workflow filter matches are not in the first 3,000 returned by the filter, the workflow will **not** run."

And the trap seen in [lesson 1](../01-first-workflow/): if the file doesn't parse, its filters don't exist either, and every push produces a failed run.

## Manual runs with inputs

`workflow_dispatch.inputs` declares typed parameters (`string`, `boolean`, `choice`, `number`, `environment`). From the terminal:

```powershell
gh workflow run gha-03-triggers.yml --field greeting=Grace
```

```text
##[group]Run echo "greeting: Grace"
echo "greeting: Grace"
echo "loud:     false"
greeting: Grace
loud:     false
```

`loud` wasn't passed: it took its `default`. Two limits: the workflow file must exist **on the default branch** for the button and `gh workflow run` to work, and an `inputs` block can have at most 25 top-level properties.

**Inputs are empty on other events.** The lesson 4 workflow also has an input, `fail`. On a `push`, the step `if [ "${{ inputs.fail }}" = "true" ]` became:

```text
if [ "" = "true" ]; then
```

No error, no default: an empty string. Test `github.event_name` or give the script a fallback when a workflow has several events.

## Schedules

`cron: '17 6 * * 1'` means "minute 17, hour 6, any day of the month, any month, Monday". From the documentation:

- scheduled runs use "the latest commit on the default branch";
- "the shortest interval you can run scheduled workflows is once every 5 minutes";
- runs "can be delayed during periods of high loads… High load times include the start of every hour" — hence minute 17 rather than 0;
- "in a public repository, scheduled workflows are automatically disabled when no repository activity has occurred in 60 days".

The expression is in UTC unless you specify an IANA time zone, which the documentation now allows. *To verify: the first Monday run of `gha-03`, to be recorded in the [journal](../journal/).*

## Concurrency: cancel or queue

A **concurrency group** is a name; "there can be at most one running job or workflow in a concurrency group at any time". What happens to the others depends on `cancel-in-progress`:

| `cancel-in-progress` | A new run arrives while one is running |
|---|---|
| `false` (default) | it waits as *pending*; a pending run already waiting is **cancelled** and replaced |
| `true` | the running one is cancelled, the new one starts |

`gha-03` uses `group: gha-03-${{ github.ref }}` (one group per branch) and `cancel-in-progress: true`. I pushed a change to the file, then started two manual runs ten seconds apart while the first was in its `sleep 60`:

```powershell
gh workflow run gha-03-triggers.yml --field greeting=Ada --field loud=true
gh workflow run gha-03-triggers.yml --field greeting=Grace
gh run list --workflow gha-03-triggers.yml --limit 3
```

| Started (UTC) | Event | Result | Duration |
|---|---|---|---|
| 12:46:38 | push | cancelled | 1m10s |
| 12:47:19 | workflow_dispatch (Ada) | cancelled | 12s |
| 12:47:29 | workflow_dispatch (Grace) | success | 1m25s |

The push run's log ends with:

```text
##[group]Run sleep 60
sleep 60
shell: /usr/bin/bash -e {0}
##[error]The operation was canceled.
```

The *Ada* run was cancelled before its job even started: its job list is empty. Only the latest run of the group finished. That's what you want for a CI build of a branch: nobody needs the result of a commit that has already been replaced.

### When cancelling is wrong: deployments

This site's deployment workflow had no concurrency group. Two pushes 14 seconds apart started two deployments, and the second failed:

```text
##[error]HttpError: Deployment request failed for cb69dca950b667b876d8d32cfe778a24b6320c59 due to in progress deployment. Please cancel 61e7e4235b7bc138f2f35cd7f61195bdaed4b019 first or wait for it to complete.
```

Cancelling a deployment halfway is worse than waiting, so the fix [queues them](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/deploy.yml#L15-L17):

```yaml
concurrency:
  group: pages
  cancel-in-progress: false
```

With a fixed group name (`pages`, not per branch) and no cancellation, a deployment runs to the end; if several pushes arrive meanwhile, only the most recent one waits — the intermediate ones are cancelled while pending, which is fine, since the latest commit contains them.

## Key takeaways

- `branches` and `paths` filters save runs, but a skipped required check stays *Pending*.
- `workflow_dispatch` inputs are typed, need the file on the default branch, and are empty on other events.
- `schedule` is best-effort: default branch, 5-minute minimum, delays at the top of the hour, disabled after 60 days without activity in a public repository.
- `concurrency` with `cancel-in-progress: true` keeps only the latest CI run; for deployments, use a fixed group without cancellation.

## Exercises

1. A pull request only changes `README.md`. `gha-02-build.yml` is a required check on `main`. What does the pull request page show, and what are two ways out?

<details>
<summary>Solution</summary>

The check `dotnet (ubuntu-latest)` (and the others) stays *Expected — Waiting for status to be reported*, and the merge button stays blocked. Ways out: remove `paths` from the `pull_request` trigger and skip the expensive work inside the job instead; or add a small always-running job that depends on the others and make *that* job the required check. *To verify: the exact wording of the pending check in the pull request page.*

</details>

2. Write a concurrency group for a CI workflow that cancels superseded runs on pull requests but never cancels runs on `main`.

<details>
<summary>Solution</summary>

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

`cancel-in-progress` accepts an expression. On a pull request, `github.ref` is `refs/pull/<number>/merge`, so each pull request has its own group and new pushes cancel the previous run; on `main` runs queue.

</details>

3. You want a nightly build at 02:00 in Paris. Why is `cron: '0 2 * * *'` a double mistake?

<details>
<summary>Solution</summary>

Without a time zone it's 02:00 **UTC** (03:00 or 04:00 in Paris depending on daylight saving time), and minute 0 is the busiest moment, when scheduled runs are the most likely to be delayed. Pick an off-round minute (`'23 0 * * *'` is 01:23 or 02:23 in Paris) or specify the time zone.

</details>

## Sources

- [Events that trigger workflows](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [Workflow syntax: `on.<push|pull_request>.paths`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore)
- [Control the concurrency of workflows and jobs](https://docs.github.com/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
- [`gh workflow run` — GitHub CLI manual](https://cli.github.com/manual/gh_workflow_run)
