---
title: GitHub Actions — Mission
description: Learn GitHub Actions from real runs — build, test and deploy .NET and Java projects, with every log in the lessons captured from this site's own repository.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every workflow in this course lives in this site's repository ([`.github/workflows/gha-*.yml`](https://github.com/spareilleux/learn/tree/main/.github/workflows)) and really runs on GitHub. The logs, errors and timings quoted in the lessons come from those runs, in September 2026 (runner `2.337.0`, image `ubuntu-24.04`). The sample code is in [`code/github-actions`](https://github.com/spareilleux/learn/tree/main/code/github-actions).
:::

## Why I'm learning this

This site is built, tested and deployed by [GitHub Actions](https://docs.github.com/actions): a Pages deployment on every push, and CI that compiles the Rust, Java and C# examples of the courses on Linux, Windows and macOS. I wrote those workflows by copying and adjusting. I want to understand what each line does, why a run fails, and how to make it fast and safe.

## Who this course is for

You know how to build and test a .NET or Java project from the command line (`dotnet test`, `mvn verify`), and you know Git. You may have used another CI system — [Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/), [Jenkins](https://www.jenkins.io/), [GitLab CI](https://docs.gitlab.com/ci/) — but that isn't required.

## By the end of this course, I will be able to

- read any workflow file and say when it runs, where, and in what order;
- build and test .NET and Java on three operating systems with a matrix and caches;
- choose the right triggers and filters, and avoid runs that pile up or never start;
- pass data between steps and jobs, and control what happens after a failure;
- reuse workflows and actions instead of copying them;
- secure a workflow: token permissions, secrets, pinned actions, OIDC;
- deploy a static site to GitHub Pages;
- diagnose a failing run from its logs.

## Outline

| # | Lesson | If you know Azure Pipelines |
|---|---|---|
| 1 | [First workflow](01-first-workflow/) | pipeline, stage, job, step, agent |
| 2 | [Build and test .NET and Java](02-build-and-test/) | `strategy: matrix`, `UseDotNet@2`, `Cache@2` |
| 3 | [Triggers, filters and concurrency](03-triggers/) | `trigger`, `pr`, `schedules`, parameters |
| 4 | [Expressions, contexts and outputs](04-expressions-and-outputs/) | `$[ ]`, variables, output variables, `condition` |
| 5 | [Caches and artifacts](05-caches-and-artifacts/) | `Cache@2`, `PublishPipelineArtifact@1` |
| 6 | [Reusable workflows and composite actions](06-reuse/) | step, job and stage templates |
| 7 | [Security: permissions, secrets, pinning, OIDC](07-security/) | service connections, workload identity federation |
| 8 | [Deploying to GitHub Pages](08-pages/) | environments, approvals |
| 9 | [Debugging runs](09-debugging/) | `system.debug`, diagnostic logs, retry failed jobs |
| 10 | [Writing your own action](10-custom-action/) | custom tasks, container jobs |
| — | [Journal](journal/) | |

## Resources

- [GitHub Actions documentation](https://docs.github.com/actions)
- [Workflow syntax reference](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax)
- [Events that trigger workflows](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [GitHub CLI manual: `gh run`](https://cli.github.com/manual/gh_run)
- [Runner images](https://github.com/actions/runner-images): what is installed on `ubuntu-latest`, `windows-latest`, `macos-latest`
