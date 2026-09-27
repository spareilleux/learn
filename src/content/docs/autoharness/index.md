---
title: AutoHarness, self-writing skills for Claude Code — Mission
description: Evaluate AutoHarness, a Claude Code plugin that turns finished sessions into skills and prunes the ones that stop being used — read at a pinned commit, tested with pre-registered fixtures in an isolated lab without installing it or calling a model, and judged on evidence rather than on its README.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied, and what was run]
[AutoHarness](https://github.com/tigerless-labs/autoharness) at commit [`ca39a72`](https://github.com/tigerless-labs/autoharness/tree/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b) (2026-09-25), MIT licence, with Python 3.14.2 on Windows 11, in September 2026. The code of this course is in [`code/autoharness`](https://github.com/spareilleux/learn/tree/main/code/autoharness).

What was run is the part of AutoHarness that needs no model: the promoter, the intent queue, the skill store and the redactor, imported from a clone in isolated subprocesses. It was **never installed**: no Claude Code plugin, hook, skill folder or MCP setting was changed, and no model was called. Everything the reflector (a model) would write is out of reach of this course, and every lesson says so where it matters. The runs are Windows-only so far; Linux and macOS are *to verify*.
:::

:::caution[Verdict at `ca39a72`: do not adopt]
Two pre-registered fixtures break the project's central promise that hand-written skills are never touched, one truncated line stops promotion for good, and the redactor misses secrets written as JSON. The defects are small and local, and the evaluation lists what would change the verdict: [`evaluation.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md).
:::

## Why I'm learning this

The [agentic coding course](../agentic-coding/) taught the pieces Claude Code gives you: hooks, skills, subagents, MCP servers. You write a skill, you commit it, and it stays what you wrote. AutoHarness takes the pen away. It watches your sessions through hooks, asks a background model to distil what happened into skills, lands them in `.claude/skills/` without asking, and later archives the ones that stop being used. Its README promises that it *"stays clean on its own"*, touching *"only the skills it wrote itself"*.

A tool that writes instructions your next session is told it *"MUST consider"* deserves more scrutiny than one that only reads. And every one of its promises is testable: the part that decides what lands on disk is ordinary Python, which runs without a model. So this course does what the [SlashForge course](../slashforge/) did with an installer, one step further: it reads the pinned code, writes down what each promise would look like if it were false, and then runs the code against those predictions, in a lab where nothing can reach the real `~/.claude`.

## Who this course is for

You write C# or Java, you use Claude Code and know what a hook and a skill are — the [agentic coding course](../agentic-coding/) up to its [lesson 3](../agentic-coding/03-hooks-skills-subagents/) is enough — and you are wondering whether to let a tool rewrite your agent's instructions for you. You don't need to know Python well: the lab's code is short and every line of output is explained.

## A self-modifying skill layer, in .NET and Java terms

| | .NET / Java | AutoHarness |
|---|---|---|
| Distribution | a NuGet or Maven package | a [Claude Code plugin](https://code.claude.com/docs/en/plugins): hooks, two agents, an MCP server, Python code |
| When it runs | when you call it | on every tool call, every turn and every session start, through [hooks](https://code.claude.com/docs/en/hooks) |
| What it produces | assemblies you ship | Markdown [skills](https://code.claude.com/docs/en/skills) that later sessions load |
| Who writes the output | you, reviewed in a pull request | a background `claude -p` on Haiku, then a deterministic *promoter* that lands it — no review step |
| Ownership | a file's author in `git blame` | a `.sidecar.json` next to the skill saying `"created_by": "agent"` |
| Clean-up | you delete dead code | skills unused for long enough are archived automatically |

The fifth row is where this course spends most of its time. A plain JSON file decides what AutoHarness considers its own, and the question is what happens around that decision.

## By the end of this course, I will be able to

- say which events make AutoHarness capture, reflect, promote, inject and archive, and which of them involve a model;
- run the part of a tool that needs no model in isolated subprocesses, with a disposable home and an environment built from nothing;
- pre-register a fixture — question, hypothesis, control, falsifier, input hash — before running it, and keep what comes back even when it refutes me;
- tell apart what a README claims, what the code shows, what a fixture reproduces and what only a live model could tell;
- decide, with evidence, whether to let such a tool touch a real project.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [A fixture lab: six promises tested without installing](01-fixture-lab/) | a unit test with a fake, a test that must fail first, a clean test environment |
| 2 | *Planned:* the loop and its authority boundaries — hooks, reflector, promoter, and what a cloned repository can queue | a background job, a service account, a deployment pipeline with no approval step |
| 3 | *Planned:* why use is not quality — counters, maturity and capacity | code coverage as a metric, a feature flag nobody removes |
| 4 | *Planned:* crashes, concurrency and history — what survives an interrupted promotion | an at-least-once queue, a lost update, a backup that overwrites the previous one |
| 5 | *Planned:* the evaluation and an adoption checklist | a proof of concept, a go/no-go review |
| — | [Journal](journal/) | |

Lessons 2 to 5 are planned, not written. Their hypotheses are already listed in the evaluation (§2, *read in the source, not run*), and each will need its own pre-registered fixtures before it makes a claim.

## Resources

- [AutoHarness on GitHub](https://github.com/tigerless-labs/autoharness), and its [README at the pinned commit](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/README.md)
- Claude Code: [hooks](https://code.claude.com/docs/en/hooks), [skills](https://code.claude.com/docs/en/skills), [subagents](https://code.claude.com/docs/en/sub-agents) and [plugins](https://code.claude.com/docs/en/plugins)
- [HAL](https://arxiv.org/abs/2510.11977), the paper the README cites for its *42% → 78% on CORE-Bench* line — a result of that paper, not of AutoHarness
- This course's [pre-registration](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/preregistration.md) and [evaluation](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md)
