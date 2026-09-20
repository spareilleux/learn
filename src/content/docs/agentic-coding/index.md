---
title: Agentic coding with Claude Code and Codex — Mission
description: Learn how coding agents work, from what a C# or Java developer already knows — the tool loop, permissions, project instructions, hooks, skills, subagents and MCP — on this site's repository and on GuitarAlchemist/ga, with Claude Code and the Codex CLI.
sidebar:
  label: Mission
  order: 0
---

:::note[Versions studied, and what CI can and can't test]
[Claude Code](https://code.claude.com/docs/en/overview) **2.1.270**, updated to 2.1.271 while I was writing, and the [Codex CLI](https://learn.chatgpt.com/docs/codex/cli) **0.154.0**, on Windows 11, in September 2026. The code of this course is in [`code/agentic-coding`](https://github.com/spareilleux/learn/tree/main/code/agentic-coding): a hook, an MCP server in C# and the configuration files of both agents. [`.github/workflows/agentic-coding-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/agentic-coding-examples.yml) tests all of it on Linux, Windows and macOS, **without an agent and without an API key**: the hook reads tool calls as JSON, the server is driven by an MCP client, the configuration files are parsed.

What an agent answers can't be tested that way: it depends on the model, on the day and on the subscription. Every agent session quoted in these lessons is a capture, marked with its date and time in UTC, never presented as reproducible.
:::

## Why I'm learning this

Most of this site was written with a coding agent. I describe a task, the agent reads files, runs commands, edits, runs the tests, and comes back with a diff and a summary. When it works, it's faster than doing it myself; when it doesn't, the mistake can be subtle: a test it didn't run, a rule it forgot, a branch it pushed.

I want to understand what happens between my request and the diff: which files the agent reads, what it's allowed to run, what it remembers, and how to put guard rails that don't depend on the agent's goodwill. Then use it on [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), a .NET solution of 111 projects, and later on Gaia and IX.

## Who this course is for

You write C# or Java professionally. You know your IDE, Git, a build tool and a test framework. You may have used code completion (IntelliSense, GitHub Copilot's inline suggestions), but you have **never let an agent run commands in your repository**. You don't need to know anything about language models.

## Coding agents in one table

| | IDE code completion | Claude Code | Codex CLI |
|---|---|---|---|
| Runs | inside the editor, per keystroke | in a terminal, as a session | in a terminal, as a session |
| Acts on | the line you are writing | the whole repository: reads, edits, runs commands | the same |
| Asks before acting | never acts | permission modes and rules | sandbox modes and approval policies |
| Project instructions | none | `CLAUDE.md` | `AGENTS.md` |
| Deterministic guard rails | none | hooks | hooks, sandbox |
| Extra tools | editor extensions | MCP servers, skills, subagents | MCP servers, skills, subagents |
| Non-interactive | no | `claude -p` | `codex exec` |

Sources: [how Claude Code works](https://code.claude.com/docs/en/how-claude-code-works), [Codex CLI](https://learn.chatgpt.com/docs/codex/cli), [Codex approvals and security](https://learn.chatgpt.com/docs/agent-approvals-security).

## The repositories

- **This site**, [spareilleux/learn](https://github.com/spareilleux/learn): an Astro site with courses in three languages, a CI that runs the code of each course, and an [`AGENTS.md`](https://github.com/spareilleux/learn/blob/main/AGENTS.md) that has grown with every mistake an agent made here. Several agent sessions work in it at the same time.
- **[GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga)**, pinned at commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) (2026-09-14): a music theory application in C# and F#, with a `CLAUDE.md`, an `AGENTS.md`, project skills and subagents, and [`GaMcpServer`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer), an MCP server that exposes its music theory to agents. This course reads ga; it never writes to it.

## By the end of this course, I will be able to

- explain the loop between the model and the tools, and what an agent can do without asking;
- install Claude Code and the Codex CLI on Windows, Linux and macOS, and run them interactively and from a script;
- write project instructions that both agents read, and know what they can't enforce;
- block a dangerous command with a hook, package a procedure as a skill, and delegate to a subagent;
- write an MCP server in C#, test it without an agent, and connect it to both agents;
- use these tools on a real .NET solution, and review what the agent did.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [Agents, tools and permissions](01-agents-and-permissions/) | IDE refactorings, running a build from the terminal |
| 2 | [Project context: `CLAUDE.md`, `AGENTS.md`, memory and compaction](02-project-context/) | `README.md`, `.editorconfig`, a wiki page nobody reads |
| 3 | [Hooks, skills and subagents](03-hooks-skills-subagents/) | Git hooks, analyzers, scripts in `tools/` |
| 4 | [MCP: a C# server for both agents](04-mcp/) | a JSON-RPC or gRPC service, dependency injection |
| 5 | [Matt Pocock skills: executable engineering methods](05-matt-pocock-skills/) | runbooks, TDD, issue decomposition |
| 6 | [Sandcastle: one isolated agent run](06-sandcastle/) | containers, branches, process isolation |
| 7 | [Compound Engineering: close the learning loop](07-compound-engineering/) | delivery pipelines, postmortems, reusable documentation |
| 8 | Working on GuitarAlchemist/ga: plan, build, test, review (coming next) | a pull request review |
| 9 | Agents in CI, and several agents on one repository | GitHub Actions, branch protection |
| 10 | Gaia and IX: agents that run other agents | orchestration, queues |
| — | [Journal](journal/) | |

## Resources

- [Claude Code documentation](https://code.claude.com/docs/en/overview), also available as Markdown ([index](https://code.claude.com/docs/llms.txt))
- [Codex documentation](https://learn.chatgpt.com/docs/codex/cli), and the [Codex source code](https://github.com/openai/codex)
- [Model Context Protocol](https://modelcontextprotocol.io/), its [specification](https://modelcontextprotocol.io/specification/2026-07-28/architecture) and the [C# SDK](https://github.com/modelcontextprotocol/csharp-sdk)
- [Agent Skills](https://agentskills.io/), the open format of `SKILL.md` files that both agents read
