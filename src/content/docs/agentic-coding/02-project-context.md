---
title: "2. Project context: CLAUDE.md, AGENTS.md, memory and compaction"
description: What an agent knows about your repository before its first tool call — CLAUDE.md for Claude Code, AGENTS.md for Codex, and how one repository serves both — then auto memory, compaction, and why an instruction file guides the model but enforces nothing. With the real history of this site's AGENTS.md and GuitarAlchemist/ga's sync script.
sidebar:
  order: 2
---

Every session starts with an empty context window: the model remembers nothing from yesterday. What it knows about your project before its first tool call comes from files the agent program loads for it. In a .NET solution you already have such files for tools: `.editorconfig` for the formatter, `Directory.Build.props` for MSBuild. The difference is that those are parsed and applied; an instruction file for an agent is **text given to a model**.

## Two file names, one convention

- [Claude Code](https://code.claude.com/docs/en/memory) reads `CLAUDE.md`, from the working directory and every directory above it, plus `CLAUDE.local.md` for personal notes that you don't commit, and `~/.claude/CLAUDE.md` for all your projects. Files in subdirectories load later, when Claude reads files there.
- [Codex](https://learn.chatgpt.com/docs/agent-configuration/agents-md) reads `AGENTS.md`: first `~/.codex/AGENTS.md`, then one file per directory from the project root (typically the Git root) down to the working directory, with `AGENTS.override.md` taking precedence in its directory. It concatenates them, root first, and "stops adding files once the combined size reaches the limit defined by `project_doc_max_bytes` (32 KiB by default)".

Both concatenate rather than override: the file closest to where you started comes last, and the model is expected to give it precedence. Nothing guarantees it does.

The documentation is explicit about the mismatch: "Claude Code reads `CLAUDE.md`, not `AGENTS.md`." For a repository used with both agents, it suggests a `CLAUDE.md` that imports `AGENTS.md`:

```markdown
@AGENTS.md
```

`@path` imports are expanded when the session starts, relative to the importing file, up to four hops deep. A symbolic link also works on Linux and macOS; "on Windows, creating a symlink requires Administrator privileges or Developer Mode, so use the `@AGENTS.md` import instead".

### An experiment: does Claude Code read AGENTS.md?

Two empty directories, each with the same `AGENTS.md`:

```markdown
# Project rules

- The release codename of this project is HEDGEHOG-42.
```

The second one also has a `CLAUDE.md` containing only `@AGENTS.md`. The same question in both, with every tool removed (`--tools ""`) so that the model can't go and read the file itself, on 2026-09-14 at 22:37 UTC, Claude Code 2.1.271:

```bash
claude -p "What is the release codename of this project? Answer with the codename only, or UNKNOWN if your instructions don't say." --tools "" --output-format json
```

| Directory | `result` | `num_turns` |
|---|---|---|
| `AGENTS.md` only | `UNKNOWN` | 1 |
| `AGENTS.md` and `CLAUDE.md` = `@AGENTS.md` | `HEDGEHOG-42` | 1 |

One turn each: no tool call, the answer came from what was loaded before the first turn. With tools, the first model could have found `AGENTS.md` by listing the directory; that's a file it read, not an instruction it was given, and it would only happen if the model thought of looking. The Codex side of the experiment, the same `AGENTS.md` without `CLAUDE.md`, is *to verify*: the account hit its usage limit (see [lesson 1](../01-agents-and-permissions/)).

## A real case: this site's AGENTS.md

This repository has a 38-line `AGENTS.md` (4,696 bytes, far under Codex's 32 KiB) and an 11-byte `CLAUDE.md`: `@AGENTS.md`. Its history is the history of the mistakes agents made here. `git log --format="%h %ad %s" --date=short -- AGENTS.md`:

```text
1b108b9 2026-09-14 Render Mermaid diagrams, first one in LadybugDB lesson 8 (en, fr, es)
d32b186 2026-09-13 Java lessons 5-8 and a Spanish locale for the whole site
9849105 2026-09-13 Rust course: lessons 13-15, OS tabs, reference links, French mirror
1faa32e 2026-09-13 Add an Artifacts page listing shared Claude artifacts
6145ed7 2026-09-13 Split Software Engineering into sub-areas
95a42da 2026-09-13 Group courses under a Software Engineering area
a79c0bc 2026-09-13 Add Rust for C#/Java developers course, lessons 1-4
f43ba7e 2026-09-13 Import Streeling University modules from Demerzel
eda2608 2026-09-13 Initial learn site: Starlight, bilingual en/fr, WSL containers course
```

Read the rules as bug reports:

- [Line 8](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L8), from `f43ba7e`: the Streeling pages are generated, "never edit them by hand; change the script instead". An agent asked to fix a typo fixes the file in front of it; the next sync would silently undo it.
- [Line 13](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L13), from `1faa32e`: no bare `{`, `}` or `<` in `.mdx` prose. MDX parses them as JSX and the build fails.
- [Line 15](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L15), from `1faa32e`: "This repository is shared by several sessions: stage explicit paths only, right before committing". Several agent sessions work here in parallel; a `git add -A` in one of them commits another session's half-written lesson.
- [Line 5](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L5) changed three times in two days (`95a42da`, `6145ed7`, `d32b186`), each time the site's structure changed. An instruction file describes a codebase; when the codebase moves, the file has to move with it, or it misleads.

Two practices follow. Write rules that say **why** in a few words, so the model can apply them to a case you didn't foresee. And keep the file short: "target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence" ([memory](https://code.claude.com/docs/en/memory)). Lines 17 to 38, about the Astro dev server and documentation links, came with the initial commit and have never changed.

## Another strategy: GuitarAlchemist/ga copies

[GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) makes the opposite choice: `CLAUDE.md` is the source, 192 lines and 15,773 bytes, and `AGENTS.md` is a generated copy. [`Scripts/sync-agents-md.ps1`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Scripts/sync-agents-md.ps1#L38-L41) replaces the title and the note that says which file to edit:

```powershell
$agentsContent = $claudeContent `
    -replace '^# CLAUDE\.md', '# AGENTS.md' `
    -replace 'Edit `CLAUDE\.md`; never edit `AGENTS\.md` directly\.', 'Source of truth is `CLAUDE.md`. This file is auto-generated — do not edit directly.'
```

The Git [pre-commit hook](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.githooks/pre-commit.ps1#L196-L229) runs it before each commit, restages `AGENTS.md` if it changed, and skips the sync during a merge, a rebase or a cherry-pick, so it doesn't overwrite a conflict resolution. The script also has a `-CheckOnly` switch for CI.

| | This site: `@AGENTS.md` import | ga: generated copy |
|---|---|---|
| Source of truth | `AGENTS.md` | `CLAUDE.md` |
| Duplicated bytes | none | the whole file |
| Can drift | no | yes, if the Git hook isn't installed (`pwsh Scripts/install-git-hooks.ps1`) |
| `@path` imports | only in `CLAUDE.md`, which Codex doesn't read | would reach Claude only: the Codex documentation doesn't describe imports (*to verify*) |
| An agent edits the wrong file | a rule added to `CLAUDE.md` reaches Claude only | a rule added to `AGENTS.md` is overwritten at the next commit |

Reading ga's `CLAUDE.md` shows two more things. It names the version of the Claude Code extension its author used, [`anthropic.claude-code-2.1.126`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md?plain=1#L68), 145 patch versions before the one in this lesson: facts in instruction files age. And its [*Session-learned rules*](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md?plain=1#L134-L152) section is appended by a custom `/correct` command when the user corrects the agent, each rule with a **Why** and a **How to apply**, and corrections fenced as `untrusted-correction` blocks: the file is both instructions and a log.

## Auto memory

Claude Code has a second mechanism, [auto memory](https://code.claude.com/docs/en/memory#auto-memory): notes **Claude** writes when you correct it or when it learns something the code doesn't say, in `~/.claude/projects/<project>/memory/`, one directory per Git repository, shared by its worktrees, never shared across machines. "The first 200 lines of `MEMORY.md`, or the first 25KB, whichever comes first, are loaded at the start of every conversation"; `MEMORY.md` is an index that points to topic files Claude reads when needed. `/memory` opens these files; they're plain Markdown you can edit or delete.

| | `CLAUDE.md` / `AGENTS.md` | Auto memory |
|---|---|---|
| Written by | you, reviewed in pull requests | the agent |
| Shared | with everyone who clones the repository | no, local to your machine |
| Good for | rules the whole team must follow | your preferences, what you corrected |

Codex has an equivalent, [Memories](https://learn.chatgpt.com/docs/customization/memories), experimental and off by default in its configuration reference, with the same advice: "Keep required team guidance in `AGENTS.md` or checked-in documentation. Treat memories as a helpful recall layer, not as the only source for rules that must always apply."

## Compaction

A long session fills the context window. Both agents then **compact**: they replace the conversation with a summary written by the model, automatically near the limit or when you type `/compact` ([Claude Code](https://code.claude.com/docs/en/context-window#what-survives-compaction), [Codex](https://learn.chatgpt.com/docs/developer-commands)). `/compact focus on the failing test` tells Claude what the summary must keep.

What survives in Claude Code, according to its documentation:

| Content | After compaction |
|---|---|
| Project-root `CLAUDE.md`, unscoped rules, auto memory | re-injected from disk |
| Nested `CLAUDE.md` files and path-scoped rules | reloaded when Claude reads a matching file |
| Files Claude read or edited | up to five re-read, most recently modified first |
| Invoked skills | re-injected, up to 5,000 tokens each and 25,000 in total |
| Instructions you typed in the conversation | only what the summary kept |

The last row is the practical one: **a rule you gave in chat can disappear at compaction; a rule in `CLAUDE.md` comes back.**

This lesson was written in a session that compacted, at 22:32 UTC on 2026-09-14, on Claude Code 2.1.270 (the update to 2.1.271 applies at the next start). The session's transcript, a JSONL file under `~/.claude/projects/`, shows the summary had sections named like the documentation says: the requests, key technical concepts, files and code, errors and fixes, pending tasks, current work. It also shows something the table above doesn't lead you to expect. The instructions injected right after compaction were **the `AGENTS.md` of the session's start, at 20:56 UTC, without the Mermaid rule committed at 22:01**, while the file on disk had it. Whether the `@AGENTS.md` import is cached for the session, or something else is going on, is *to verify*; the [journal](../journal/) keeps the details. The lesson doesn't depend on the cause: after a long session, don't assume the agent has seen a change to its instruction files. Start a new session.

`/context` shows what fills the window right now, including which memory files loaded; `/clear` starts over between unrelated tasks, which is often better than compacting.

## Guidance is not enforcement

Every mechanism in this lesson is text in the context window. The Claude Code documentation says it plainly: "Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook instead", and `CLAUDE.md` "is delivered as a user message after the system prompt", with "no guarantee of strict compliance".

Line 15 of this site's `AGENTS.md` asks agents to stage explicit paths. It's a good instruction, and the agents here mostly follow it. But the machine this site is written on also has a hook that refuses dangerous `git push` commands before they run, whatever the model decided. Instructions reduce how often the agent tries something; hooks, permissions and CI decide what happens when it does. [Lesson 3](../03-hooks-skills-subagents/) writes one.

A rule of thumb for each instruction you're about to add:

| If breaking the rule… | Put it in |
|---|---|
| makes the result worse but is harmless | `CLAUDE.md` / `AGENTS.md` |
| must never happen | a permission rule, a hook or the sandbox, and the reason in `AGENTS.md` |
| can be detected after the fact | CI, and the command to run it locally in `AGENTS.md` |

## Key takeaways

- Claude Code reads `CLAUDE.md`; Codex reads `AGENTS.md`. A `CLAUDE.md` containing `@AGENTS.md` serves both from one file; a generated copy works too, if something keeps it in sync.
- Instruction files are concatenated from the root down, loaded before the first turn, and Codex stops at 32 KiB by default.
- Treat your instruction file as code: short, reviewed, with the reason for each rule, and updated when the project changes.
- Auto memory is local and written by the agent; team rules belong in the repository.
- Compaction keeps the instruction files and summarizes the conversation: put lasting instructions in files, and start a new session after changing them.
- Instructions guide; permissions, hooks, sandboxes and CI enforce.

## Exercises

1. A colleague's repository has only a `CLAUDE.md` of 300 lines, and they now want to try Codex without renaming anything. What's the smallest change, and what two problems remain?

<details>
<summary>Solution</summary>

In `~/.codex/config.toml`, add `project_doc_fallback_filenames = ["CLAUDE.md"]`: Codex then checks `AGENTS.override.md`, `AGENTS.md`, then `CLAUDE.md` in each directory, at most one file per directory ([AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). Two problems remain. If the `CLAUDE.md` uses `@path` imports, the Codex documentation says nothing about expanding them: expect Codex to see the literal text `@docs/testing.md` (*to verify*). And the setting is in each user's configuration, so every colleague has to repeat it (whether a project's `.codex/config.toml` accepts it is *to verify*). A committed `AGENTS.md`, with `CLAUDE.md` reduced to `@AGENTS.md`, avoids both, and 300 lines is a sign the file should be split anyway.

</details>

2. Sort these instructions from this site's `AGENTS.md` into "instruction file", "enforce" or "detect in CI", and say with what: (a) "use relative links in Markdown, never root-absolute `/…` links"; (b) "stage explicit paths only"; (c) "never edit `streeling/` by hand"; (d) "Link the first mention in each lesson of a tool … to its official documentation".

<details>
<summary>Solution</summary>

(a) Detect: a link checker over the built site, or a `grep` for `](/` in `src/content/docs` in CI. (b) Enforce, partly: a PreToolUse hook can refuse `git add -A`, `git add .` and `git commit -a`, but it can't know which paths belong to another session; the instruction stays. (c) Detect: CI runs `npm run sync:streeling` and fails if `git diff` isn't empty; a hook refusing `Edit` on `src/content/docs/**/streeling/**` would also work, with a deny rule `Edit(./src/content/docs/**/streeling/**)` as the simplest option. (d) Instruction file: "the first mention of a tool" is a judgment a script can't make reliably; a CI check can at least verify that the links resolve.

</details>

3. In a long session, you told the agent "from now on, run `dotnet test --filter Category!=Slow` instead of `dotnet test`". Two hours later it runs the whole suite again. Give two explanations and a fix for each.

<details>
<summary>Solution</summary>

The session compacted and the summary didn't keep your sentence: instructions given only in the conversation are summarized with everything else. Fix: put it in `CLAUDE.md` or `AGENTS.md`, which come back after compaction, or a `.claude/rules/` file. Or the model saw it and didn't follow it, for instance because the instruction file says "run `dotnet test` before committing" and the two contradict each other: fix the file so there's one rule. If running the slow tests is really harmful, neither fix is a guarantee: a PreToolUse hook that refuses `dotnet test` without `--filter` is.

</details>

## Sources

- Claude Code: [memory](https://code.claude.com/docs/en/memory), [context window](https://code.claude.com/docs/en/context-window), [how Claude Code works](https://code.claude.com/docs/en/how-claude-code-works)
- Codex: [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [advanced configuration](https://learn.chatgpt.com/docs/config-file/config-advanced), [memories](https://learn.chatgpt.com/docs/customization/memories), [slash commands](https://learn.chatgpt.com/docs/developer-commands)
- [agents.md](https://agents.md/), the site of the `AGENTS.md` convention
