---
title: Journal
description: Dated progress notes for the agentic coding course — the versions of Claude Code, Codex and the MCP SDK, the captures and what they cost, the surprises in both agents and in GuitarAlchemist/ga's MCP server, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Claude Code and the Codex CLI installed on Windows; versions noted below
- [x] CI: the hook, the MCP server (SDK client and raw sessions in both protocol eras) and the configuration files, on Linux, Windows and macOS, without an agent or an API key
- [x] Lesson 1: agents, tools and permissions
- [x] Lesson 2: project context, `CLAUDE.md`, `AGENTS.md`, memory and compaction
- [x] Lesson 3: hooks, skills and subagents
- [x] Lesson 4: MCP, a C# server for both agents
- [ ] Codex sessions: every capture that needs the model (usage limit until 2026-09-19)
- [ ] Lesson 5: working on GuitarAlchemist/ga

## 2026-09-14 — Versions and installation

- **Claude Code**: native installer, `~/.local/bin/claude`. The session started on **2.1.270**; `claude doctor` then reported "Last update attempt: success → 2.1.271 (2026-09-14)", and new sessions from about 22:14 UTC ran **2.1.271**. The running session stays on its version until it restarts, so the captures before and after that time differ in version. Each capture in the lessons names its own.
- **Codex CLI**: **0.154.0**, installed with `npm install -g @openai/codex` (Node.js 24.12.0). The PowerShell installer from the documentation wasn't tried.
- **.NET**: `code/agentic-coding/global.json` pins SDK 10.0.100 with `rollForward: latestFeature`; locally that selects 10.0.112, while the root of the repository, without `global.json`, gets an 11.0 preview. CI uses `actions/setup-dotnet` with the same `global.json`.
- **ModelContextProtocol** 2.2.0 and Microsoft.Extensions.Hosting 10.0.12 for the server; GuitarAlchemist/ga uses ModelContextProtocol 1.3.0.
- **Documentation moves**: `docs.anthropic.com/en/docs/claude-code/…` redirects (301) to `code.claude.com/docs/en/…`; the Codex documentation is at `learn.chatgpt.com/docs/…`. Both sites serve every page as Markdown with a `.md` suffix, which is how the claims of the lessons were checked, page by page.
- No `ANTHROPIC_API_KEY` on the machine nor in CI: every capture used the subscription.

## 2026-09-14 — Captures and their cost

Every agent output in the lessons is a capture, with its UTC time. What `claude -p` reported:

| Capture | Lesson | Turns | Cost reported |
|---|---|---|---|
| Unchecked items in the journals, 22:10 | 1 | 3 | $0.34 |
| MCP server, `D dorian`, `Gb major`, `ladybugdb`, 22:11 | 4 | 5 | $0.36 |
| `${CLAUDE_PROJECT_DIR}` in `.mcp.json`, first try, 22:15 | 4 | 4 | $0.39 |
| Hook blocking `git push --prune`, 22:18 | 3 | 2 | |
| Write refused in `default` mode, 22:22 | 1 | 2 | |
| Skill, 22:24 and 22:25 | 3 | 6 and 2 | |
| `CLAUDE.md` / `AGENTS.md` experiment, 22:37 | 2 | 1 each | |
| Subagent `lesson-checker`, 22:48 | 3 | 4 | $0.49, of which $0.04 for the Haiku subagent |
| Three `.mcp.json` variants, 22:54 | 4 | 4 | $0.34 |

The "cost" is what the JSON output reports; on a subscription, it counts against usage limits rather than being billed.

`codex exec` on the same question as the first capture stopped with the error quoted in [lesson 1](../01-agents-and-permissions/): the usage limit, until "Sep 19th, 2026 9:42 AM". The Codex commands that don't call a model worked: `codex --help`, `codex exec --help`, `codex mcp add`, `codex mcp list`, `codex mcp get`, with a temporary `CODEX_HOME`.

## 2026-09-14 — Surprises in Claude Code

- **`claude -p` follows `defaultMode` from the user settings.** This machine's `~/.claude/settings.json` sets `"defaultMode": "auto"`, so a `claude -p` asked to create a file created it without a prompt. The documentation's table says `claude -p` starts in `default`, but settings come first in the order it gives. Lesson 1 passes `--permission-mode default` for the capture of a refusal.
- **`--allowedTools` doesn't restrict the tool list**, it pre-approves; `--tools` restricts. Easy to confuse in scripts.
- **Git Bash rewrites a prompt that starts with `/`.** `claude -p "/journal-status …"` arrived as `C:/Program Files/Git/journal-status …`. `MSYS_NO_PATHCONV=1` fixes it. The model then worked around the missing command by reading `SKILL.md` itself.
- **A Haiku subagent's `Read` with the path `/C:/Users/…`** was refused as "a suspicious Windows path pattern that requires manual approval", in `default` mode, twice, before it retried with relative paths. The refusals appear in the parent's `permission_denials`.
- **The parent agent misattributed a rule**: it told the user that "Key takeaways" came from nowhere, when it was in the subagent's own definition, which the parent never reads.
- **Hooks of an untrusted folder run in `-p` mode**, while its allow rules are ignored with a warning. Documented under [workspace trust](https://code.claude.com/docs/en/hooks#workspace-trust), and worth a line in any "clone and run" script.
- **`${CLAUDE_PROJECT_DIR}` in `.mcp.json` args fails without a default** (`CONNECTION_CLOSED`), documented: the variable is set for the server, not for Claude Code. `${CLAUDE_PROJECT_DIR:-.}` works. `claude mcp list` displays that entry as `${CLAUDE_PROJECT_DIR}/server/LearnMcp.dll`, without the `:-.`: a display quirk, the server connected.
- **The AGENTS.md injected after compaction was the one from the start of the session.** This course's session started at 20:56 UTC; the Mermaid rule was committed to `AGENTS.md` at 22:01; the session compacted at 22:32. The session transcript shows the instruction files injected after compaction without the Mermaid rule, although the file on disk had it and the documentation says the project-root `CLAUDE.md` is "re-injected from disk". `CLAUDE.md` here is only `@AGENTS.md`: maybe the import is what's cached. Observed once, on 2.1.270, cause unknown.
- **The machine's own git hook blocked my commands twice**: regular expressions like `push .*--delete` matched text inside here-documents and JSON test data. Writing the files with an editor tool instead of a shell here-document avoided it. The same hook lets `git push --prune` through. This is the motivation of lesson 3's hook, which parses the command.
- **Tool search is on**: MCP tools aren't in the model's context at startup; the first call of every MCP capture is `ToolSearch`.

## 2026-09-14 — Surprises in Codex

- `codex mcp-server` is gone; the documentation page that described it is now a removal notice pointing to the experimental app server.
- `--full-auto` is rejected by `codex exec` 0.154.0 (`unexpected argument '--full-auto'`), the `untrusted` approval policy is retired, and `--approve-for-me` is new. Many tutorials still use the old flags.
- On Windows, hook commands run with `%COMSPEC%` or `cmd.exe /C` ([source](https://github.com/openai/codex/blob/60e35765c3e43e152bf5b382a38a0628efd70842/codex-rs/hooks/src/engine/command_runner.rs#L435-L441)): the documented `$(git rev-parse --show-toplevel)` form needs a `command_windows` override.
- This machine has hooks in both `~/.codex/hooks.json` and `~/.codex/config.toml`; every `codex exec` warns "prefer a single representation for this layer".
- `codex mcp add` with a `CODEX_HOME` under the temporary folder warns that it refuses to create PATH aliases there, and proceeds.
- `codex mcp list` shows "enabled", with no connection check; `claude mcp list` checks servers it can start.

## 2026-09-14 — The MCP server and its tests

- The first raw test piped five JSON lines at once: the replies came back out of order (id 4 before id 3). The raw mode now waits for each reply before sending the next request.
- `server/discover` without `_meta` answers `-32602`, "requires per-request metadata declaring a supported protocol version".
- The SDK returns a `string[]` as JSON text with `"` escaped as `\u0022`, and non-ASCII characters escaped too: `course_outline` returns one string instead, so an em dash in a title stays readable.
- The Windows console printed that em dash as `-` until the check client set `Console.OutputEncoding` to UTF-8; the expected files are identical on the three OSes.
- A `Console.WriteLine` inside a tool breaks the raw sessions but **not** the SDK client's output, which skipped the non-JSON line: the SDK client is a tolerant test.
- First `dotnet run guard-git-push.cs`: about 13 s to compile; later runs, 0.24 s from the build cache. The hook registrations use a 120 s timeout.
- CI run [34904115148](https://github.com/spareilleux/learn/actions/runs/34904115148) passed on the first push on Linux, Windows and macOS.

## 2026-09-14 — GuitarAlchemist/ga, at commit `a826864`

Findings for the author of ga; this course doesn't write to ga, and nothing was reported upstream.

- **`GaMcpServer/Tools/ScaleTool.cs`, `GetScaleNotes`** ([lines 50-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ScaleTool.cs#L50-L80)):
  - spells with sharps only: `F major` gives `A#` instead of `Bb`;
  - the parameter description gives `'Bb major'` as an example, and the tool rejects `Bb` ("Unknown root note 'Bb'. Use sharps…");
  - errors are returned as ordinary text results, not `isError: true` or an exception;
  - any mode not starting with "minor" is treated as major: `D dorian` returns D major;
  - `get_key_notes("Key of F")` spells `Bb`, so two tools of the same server disagree.
  Observed through a local build of ga on 2026-09-14 around 22:57 UTC; the source at `a826864` has the same logic.
- **`.mcp.json` at the root of ga** contains absolute, machine-specific paths: it only works on its author's machine. Relative paths, or `${VAR:-default}`, would make it shareable.
- **ModelContextProtocol 1.3.0** in `GaMcpServer.csproj`, raised from 1.1.0 because the governance companion package depends on `>= 1.3.0`; the current stable is 2.2.0, which speaks the 2026-07-28 revision.
- **`Scripts/sync-agents-md.ps1`**: its help says a "do not edit" warning is "appended at the top", while the code replaces the note line; harmless, but the comment is out of date. `CLAUDE.md` also names the Claude Code extension version `2.1.126`, 145 patch versions behind.

## To verify

- The install commands of lesson 1 on Linux, WSL and macOS, for both agents, and Codex's PowerShell installer.
- A Codex session that answers the first question of lesson 1, and the same `AGENTS.md` experiment as lesson 2.
- Codex hooks: whether the `config.toml` example of lesson 3 runs on Windows with `command_windows`, and whether its relative path works when Codex starts in a subdirectory; the trust flow in `/hooks`.
- Codex skills: whether `$ARGUMENTS`, `argument-hint` and `allowed-tools` mean anything to Codex, and invoking `$journal-status`.
- Codex custom agent `lesson_checker`: loading, and `sandbox_mode = "read-only"` in practice.
- Codex MCP: a session calling `scale_notes` and `course_outline`; the working directory relative `args` resolve against without `cwd`; `default_tools_approval_mode = "approve"`.
- Whether `project_doc_fallback_filenames` is accepted in a project's `.codex/config.toml`.
- Whether Codex expands `@path` imports in `AGENTS.md` (its documentation doesn't mention them).
- Whether Claude Code and Codex tolerate a non-JSON line on a server's stdout, like the SDK client does.
- The cause of the stale `AGENTS.md` after compaction: repeat with a plain `CLAUDE.md`, without import, on 2.1.271.
- `codex exec -o`: whether the file is written by the CLI outside the sandbox in `read-only` mode.
