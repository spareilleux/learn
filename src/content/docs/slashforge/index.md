---
title: SlashForge, workflow commands for Claude Code — Mission
description: Read, install and take apart SlashForge, an npm package that gives Claude Code a gated ten-phase development workflow written entirely in Markdown — what its installer writes, how a file becomes a slash command, and where the kit and Claude Code disagree about the same file.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied, and what CI can and can't test]
[SlashForge](https://github.com/rajdeepratan/SlashForge) **4.4.3**, tag [`v4.4.3`](https://github.com/rajdeepratan/SlashForge/tree/bd75a4f770bb2e323551c05fab0d3f326c72ae98) (the installer is identical on `main` on 2026-09-22), with [Node.js](https://nodejs.org/) 24 and [Claude Code](https://code.claude.com/docs/en/overview), on Windows 11, in September 2026. The code of this course is in [`code/slashforge`](https://github.com/spareilleux/learn/tree/main/code/slashforge), and [`.github/workflows/slashforge-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/slashforge-examples.yml) runs it on Linux, Windows and macOS.

What CI tests is **the installer**: it runs it into a throwaway home directory and compares everything it prints and writes. What the commands do once Claude Code runs them depends on the model and costs tokens — tens of thousands per run, by SlashForge's own estimate — so those lessons are captures, dated, never presented as reproducible.
:::

## Why I'm learning this

The [agentic coding course](../agentic-coding/) taught the pieces Claude Code gives you: project instructions, commands, skills, subagents, hooks. It did not show what a complete workflow built from those pieces looks like. SlashForge is one: four commands and nine skills that take a request through intake, plan, confirmation, branch, implementation, verification, review, pull request, feedback and cleanup, and stop at four *gates* where nothing continues until you answer.

It is a good specimen for two reasons. It is small enough to read — one 676-line installer and twenty-nine Markdown templates — and it is honest about its cost: its README says it is *"deliberately heavy"* and gives token budgets for each command. And every behaviour it has lives in plain text you can open, which means you can check each claim it makes against the file that is supposed to implement it.

That is what this course does. It installs SlashForge where it can do no harm, reads what it wrote, and compares the documentation, the installer and Claude Code's own rules with each other. They don't always agree: the [QA table](journal/#qa) of the journal lists where.

## Who this course is for

You write C# or Java, you have used Claude Code — the [agentic coding course](../agentic-coding/) up to its [lesson 3](../agentic-coding/03-hooks-skills-subagents/) is enough — and you want to know what an opinionated workflow kit adds, what it costs and what it installs on your machine before you run it. You don't need to know JavaScript: the installer is read, not written.

## A workflow kit, in .NET and Java terms

| | .NET / Java | SlashForge |
|---|---|---|
| Distribution | a NuGet or Maven package | an [npm](https://docs.npmjs.com/) package, run once with `npx` |
| What it installs | assemblies, templates (`dotnet new install`) | Markdown files under `~/.claude/` or `./.claude/` |
| The executable part | compiled code | a 676-line installer; the rest is text that Claude Code reads |
| How you invoke it | a CLI verb, an IDE command | a slash command: `/slashforge:code` |
| Guard rails | branch policies, required reviews | four gates written into the instructions — the model is told to stop |
| Configuration | `appsettings.json`, `pom.xml` | your repository's `CLAUDE.md` and `.claude/rules/` |

The last two rows are the ones to keep in mind. A branch policy is enforced by the server; a SlashForge gate is a sentence the model is asked to obey. The [agentic coding course](../agentic-coding/03-hooks-skills-subagents/) draws the same line between instructions and hooks.

## By the end of this course, I will be able to

- install SlashForge globally or into one repository without touching the rest of `~/.claude/`, and remove it cleanly;
- say, for each file it writes, what Claude Code does with it and why its path matters;
- read a command file and follow it into the guides it delegates to;
- run `/slashforge:setup`, `/slashforge:code` and its `-quick` mode, `/slashforge:investigate` and `/slashforge:review-pr` on a real repository, and measure what they cost;
- decide, for a given change, whether the ceremony is worth it.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [What the installer writes](01-what-the-installer-writes/) | `dotnet tool install`, `dotnet new install`, a package that drops files |
| 2 | [Inside the files: commands, skills, guides](02-inside-the-files/) | template parameters, routing by folder, a validator that is stricter than the runtime |
| 3 | `/slashforge:setup` against `/init`, on a real repository (coming next) | a project template, an onboarding checklist |
| 4 | `/slashforge:code`: ten phases and four gates | branch policies, a pull request template |
| 5 | `-quick`, `/slashforge:investigate` and `/slashforge:review-pr` | a hotfix process, a bug report, a code review |
| 6 | Making it yours: rules, verification commands, a team install | `.editorconfig`, a shared build configuration |
| — | [Journal](journal/) | |

## Resources

- [SlashForge on GitHub](https://github.com/rajdeepratan/SlashForge), its [documentation site](https://www.rajdeepratan.com/slashforge/) and its [changelog](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/CHANGELOG.md)
- [The `slashforge` package on npm](https://www.npmjs.com/package/slashforge)
- Claude Code: [skills and custom commands](https://code.claude.com/docs/en/skills), and [the `.claude` directory](https://code.claude.com/docs/en/claude-directory)
- [superpowers](https://github.com/obra/superpowers), the skills library SlashForge's nine skills are adapted from, under the MIT licence
- [Agent Skills](https://agentskills.io/), the open format of skill files
