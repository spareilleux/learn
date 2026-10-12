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
- [x] Lesson 5: Matt Pocock skills and tracer-bullet workflow
- [x] Lesson 6: Sandcastle bounded isolation lab
- [x] Lesson 7: Compound Engineering lifecycle and durable learning
- [ ] Codex sessions: every capture that needs the model (usage limit until 2026-09-19)
- [ ] Lesson 8: working on GuitarAlchemist/ga
- [x] An observation format for model, skill and subagent runs, and its first observation (2026-09-26)
- [x] Three retrospective observations recorded: the hook timeouts (2026-09-26), a wmux crash recovery and GA #740's early merge (2026-09-27)

## QA

The software this course teaches is Claude Code, the Codex CLI and, through the MCP lesson, GuitarAlchemist/ga's MCP server — all three produced findings. Four of them are documentation that does not match behaviour, which matters more here than elsewhere, because a tutorial on agents is mostly a tutorial on trusting what a tool says about itself. Nothing has been reported upstream.

There is no Experiments table: this journal records surprises and expected-against-actual findings, but no entry set a hypothesis before a measurement, and writing one backwards from a result is exactly what that section exists to prevent.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| `claude -p` starts in `default` mode, as the documentation's table says | It follows `defaultMode` from the user's settings. This machine sets `"defaultMode": "auto"`, so a `claude -p` asked to create a file created it without a prompt | `~/.claude/settings.json` | A file written with no approval asked | Reproduced; documentation and behaviour disagree [2026-09-14](#2026-09-14--surprises-in-claude-code) |
| `--allowedTools` restricts the tools available | It pre-approves them. `--tools` is what restricts | Claude Code CLI | Two flags, one of which does the opposite of what its name suggests in a script | Reproduced, easy to confuse [2026-09-14](#2026-09-14--surprises-in-claude-code) |
| `${CLAUDE_PROJECT_DIR}` in `.mcp.json` args resolves for Claude Code too | It is set for the server, not for Claude Code, so the server fails to start | `.mcp.json` | `CONNECTION_CLOSED`; `${CLAUDE_PROJECT_DIR:-.}` works | Documented; the failure mode is not [2026-09-14](#2026-09-14--surprises-in-claude-code) |
| `AGENTS.md` is re-read from disk right after a compaction, as the documentation says | The copy injected after compaction was the one from the start of the session | Claude Code 2.1.270 | The session started at 20:56 UTC, the rule was committed at 22:01, the session compacted at 22:32, and the correct copy arrived at 23:06:49 — 34 minutes stale | Reproduced once, cause unknown, not reported [2026-09-14](#2026-09-14--surprises-in-claude-code) |
| A prompt that begins with `/` reaches the model as typed | Git Bash rewrites it: `claude -p "/journal-status …"` arrived as `C:/Program Files/Git/journal-status …` | Git Bash on Windows | `MSYS_NO_PATHCONV=1` fixes it. The model then worked around the mangled prompt instead of reporting it | Reproduced; the shell's doing, not Claude Code's [2026-09-14](#2026-09-14--surprises-in-claude-code) |
| A subagent reading an absolute Windows path is allowed in `default` mode | A Haiku subagent's `Read` of `/C:/Users/…` was refused as "a suspicious Windows path pattern that requires manual approval", twice, before it retried with relative paths | Claude Code, `default` mode | Two refusals, then a workaround the subagent found alone | Reproduced [2026-09-14](#2026-09-14--surprises-in-claude-code) |
| An agent can tell where one of its own rules came from | The parent told the user that "Key takeaways" came from nowhere, when it was in the subagent's own definition — which the parent never reads | Claude Code subagents | A confident wrong attribution | Reproduced; a limit worth teaching [2026-09-14](#2026-09-14--surprises-in-claude-code) |
| JSON-RPC replies come back in the order they were requested | Five lines piped at once came back out of order: id 4 before id 3 | The course's raw MCP session | Fixed by waiting for each reply rather than piping | Reproduced; the protocol allows it, the course's first code did not [2026-09-14](#2026-09-14--the-mcp-server-and-its-tests) |
| `codex exec` still accepts `--full-auto`, as most tutorials show | 0.154.0 rejects it (`unexpected argument '--full-auto'`); the `untrusted` approval policy is retired and `--approve-for-me` is new | Codex CLI 0.154.0 | One removed flag, one removed policy, one new flag | Reproduced; `codex mcp-server` is gone too, its doc page now a removal notice [2026-09-14](#2026-09-14--surprises-in-codex) |
| `codex mcp list` tells you whether a server works | It prints "enabled" with no connection check, unlike `claude mcp list`, which starts the servers it can | Codex CLI 0.154.0 | A status that cannot fail | Reproduced [2026-09-14](#2026-09-14--surprises-in-codex) |
| `GetScaleNotes` spells notes according to the key asked for | It spells with sharps only, whatever the key | `GaMcpServer/Tools/ScaleTool.cs` 50-80 | "F major" gives A♯ where A♭ … B♭ is right | Fixed upstream by [#681](https://github.com/GuitarAlchemist/ga/pull/681), merged 2026-09-23, with tests [2026-09-14](#2026-09-14--guitaralchemistga-at-commit-a826864), [2026-09-24](#2026-09-24--upstream-fixes) |
| The tool accepts the flat spellings its own documentation uses as examples | It rejects them: `Unknown root note 'Bb'` | `GaMcpServer/Tools/ScaleTool.cs` | The doc example is the failing input | Fixed upstream by [#681](https://github.com/GuitarAlchemist/ga/pull/681), merged 2026-09-23, with tests [2026-09-14](#2026-09-14--guitaralchemistga-at-commit-a826864), [2026-09-24](#2026-09-24--upstream-fixes) |
| A mode that is not major or minor returns that mode | Anything not starting with "minor" is treated as major, so `D dorian` returns D major | `GaMcpServer/Tools/ScaleTool.cs` | Captured live during the lesson | Fixed upstream by [#681](https://github.com/GuitarAlchemist/ga/pull/681), merged 2026-09-23, with tests [2026-09-14](#2026-09-14--guitaralchemistga-at-commit-a826864), [2026-09-24](#2026-09-24--upstream-fixes) |
| Two tools of the same server spell a note the same way | `get_key_notes("Key of F")` spells B♭ while `GetScaleNotes` spells sharps only | GA's MCP server | Two answers to one question, from one server | Fixed upstream by [#681](https://github.com/GuitarAlchemist/ga/pull/681), merged 2026-09-23, with tests [2026-09-14](#2026-09-14--guitaralchemistga-at-commit-a826864), [2026-09-24](#2026-09-24--upstream-fixes) |
| An MCP error is returned as an error | It is returned as ordinary text | `GaMcpServer/Tools/ScaleTool.cs` | No `isError`, no exception: a client cannot tell success from failure | Reproduced, not reported [2026-09-14](#2026-09-14--guitaralchemistga-at-commit-a826864) |
| `.mcp.json` at a repository's root is shareable | GA's holds absolute, machine-specific paths | GA's repository root | Paths that work on one machine | Reproduced, not reported [2026-09-14](#2026-09-14--guitaralchemistga-at-commit-a826864) |

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
- **The AGENTS.md injected after compaction was the one from the start of the session.** This course's session started at 20:56 UTC; the Mermaid rule was committed to `AGENTS.md` at 22:01; the session compacted at 22:32. The session transcript shows the instruction files injected after compaction without the Mermaid rule, although the file on disk had it and the documentation says the project-root `CLAUDE.md` is "re-injected from disk". The current copy arrived at 23:06:49 UTC, attached to the next incoming message, as "Instruction files were re-read after the conversation was compacted; these differ from their earlier copies": for 34 minutes, while lessons 1 to 4 were written, the instructions in context lacked the rule (the lessons used Mermaid anyway, from the conversation summary). `CLAUDE.md` here is only `@AGENTS.md`: maybe the import plays a part. Observed once, on 2.1.270, cause unknown.
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

## 2026-09-20 — Agent workflow tutorials

- Pinned Matt Pocock skills at `c55ee460`, Sandcastle at `e99f832f` (package 0.12.0), and Compound Engineering at `6be0932b` (plugin 3.27.0).
- Added lessons 5–7 in English, French and Spanish from primary upstream sources.
- No plugin, credential or paid provider was used. Sandcastle and model-backed plugin runs remain manual experiments.
- Recorded the upstream Sandcastle conflict between the old `config.json` documentation and the current TypeScript templates instead of choosing silently.

## 2026-09-24 — Upstream fixes

- The four `ScaleTool` rows were fixed upstream by [#681](https://github.com/GuitarAlchemist/ga/pull/681), merged 2026-09-23. `GetScaleNotes` spells one letter per degree: `F major` gives `F G A Bb C D E`, and `Bb major`, the documentation's own example, is accepted and gives `Bb C D Eb F G A`. `D dorian` gives `D E F G A B C`. Each case is a test in GA's `ScaleToolTests.cs`, which I read at GA's main without running it.
- The two tools now agree. A session fixing other course findings called `KeyTool.GetKeyNotes` and `ScaleTool.GetScaleNotes` for all 30 keys of `Key.Items`, and they spelled the same notes for every key.

## 2026-09-26 — An observation format for models, skills and subagents

Notes on agent runs drift into anecdotes: "Opus did it faster", "the subagent got lost". An anecdote mixes up three things: what the model reasoned, what the harness let it do, and who owned the work. The format below keeps them apart, so that two observations can be compared, or declared not comparable.

**The record.** One row per run. A field you don't have is written *unknown*, never guessed.

| Field | What goes in it |
|---|---|
| Date, run ID | Local date and time with its offset; the correlation or session ID |
| Repository | The exact commit SHA each repository was read or changed at |
| Harness | CLI or app and its version (`claude --version`), and the operating system |
| Model, requested and observed | What was asked for, and what a receipt shows. A model name shown by a UI or by the agent itself is *self-reported*, not a receipt |
| Skill or subagent | Name and version, or a digest of the file; the role: parent, subagent or peer agent |
| Task and context | The task in one sentence; what context was supplied (files, briefs, memory) |
| Permissions | The permission mode, and what was allowed or denied |
| Hypothesis | Written before the run, or marked *retrospective observation* |
| Evidence | The command, artifact, log or exit code a reader can re-open |
| Result and state | One of: submitted, visible, accepted, completed, independently verified |
| Failure category | Model reasoning; launcher, tool, auth, permission or environment; orchestration or ownership |
| Tokens and cost | The figure and its provenance: provider bill, harness estimate, or *unknown* |
| Confidence and limits | Sample size, and what the run cannot show |
| Reproducibility | What a second run needs: same inputs, seed, versions |
| Follow-up | The next check, with its owner |

**States are not interchangeable.**
- *Submitted*: the request left.
- *Visible*: the recipient shows it.
- *Accepted*: the recipient took ownership.
- *Completed*: it says it is done.
- *Independently verified*: someone else re-checked the evidence.

A wrapper still running, a busy CPU or a "done" message proves none of the last two.

**Failure categories are not interchangeable either.**
- A timeout caused by a slow host is an environment failure, not a model failure.
- A wrong claim made with every tool working is a reasoning failure.
- Two agents writing the same file is an ownership failure, whichever model they ran.

**No leaderboard from anecdotes.** Different tasks, budgets and contexts cannot be ranked against each other. A fair model comparison needs:
- matched tasks with fixed inputs;
- repeated runs or seeds where results vary;
- criteria fixed and blinded before the runs;
- an independent check of each result;
- cost reported next to quality.

That comparison is *proposed, not performed*.

**First observation: this delegation, 2026-09-26.** A coordinator (Codex) handed a Claude Code session four course briefs and one diagnostic, correlation `test-quality-courses-20260926` and its siblings. Only evidence available to this session is recorded.

| Field | Observation |
|---|---|
| Harness | Claude Code 2.1.282 (`claude --version`, 13:39 EDT). The coordinator's preflight also saw 2.1.282 installed, while the npm registry offered 2.1.283. No upgrade or restart was made |
| Model | Self-reported only: the session's surface showed "Opus 5.5 (1M context)", medium thinking, and its system prompt names the same model. No provider receipt was checked |
| Roles | Codex as coordinator; this session as the single writer in the learn worktree; one read-only subagent reading a pinned AutoHarness clone; a peer agent (Augment) doing a read-only static audit of Abide, written to the shared handoff folder |
| Shared bus | The coordinator reported that the status and inbox calls of the shared message bus returned "Transport closed". Nothing shows that the bus accepted a claim; coordination went through files in a shared folder |
| Hypotheses | Written before measuring for the test-quality lab only ([repository-dogfooding lesson 6](../../repository-dogfooding-lab/06-mutation-property-testing/)); everything else here is *retrospective observation* |
| Results, by state | Lab measured and journal written: completed, not independently verified. The coordinator's supervision note says it re-parsed the mutation reports and found the same counts; that is a re-check of recorded evidence, not a rerun. Hook diagnosis: completed; the coordinator marked its root cause a hypothesis |
| Failures seen, by category | Reasoning, caught before measuring: a malformed-input generator that could build valid input. Tool use, caught by a hash check: a script edit silently converted a pre-registered file to CRLF, and it was reverted. Launcher and environment: a shell here-document failed to parse, and nothing was written; on the host, starting a bare `bash` took about 2.8 s during the hook diagnosis. Orchestration: none observed; one writer per repository held |
| Tokens and cost | *Unknown*. No provider bill or usage receipt was read. No paid API was called |
| Limits | One session, one day, one coordinator; not a sample of anything |

## 2026-09-26 — Three hooks that timed out, and a slow host

*Retrospective observation: no hypothesis was written before these measurements.* The evidence is local: a harness and its logs kept in the coordinator's handoff folder, not in this repository.

**The symptom.** Every prompt reported three `UserPromptSubmit` hooks timing out, and their output was discarded. All three belong to one third-party plugin, [claude-octopus](https://github.com/nyldn/claude-octopus) 9.56.1, installed at commit [`cb2677b`](https://github.com/nyldn/claude-octopus/tree/cb2677b2bd442bcc501489cc6110ab54fb14e701). Its [`hooks.json`](https://github.com/nyldn/claude-octopus/blob/cb2677b2bd442bcc501489cc6110ab54fb14e701/hooks/hooks.json#L300-L325) gives two of them 5 s and the third 8 s. The scripts were read before anything ran:
- they are advisory context injectors, not safety checks;
- each one starts by reading stdin with `timeout 3 cat` ([`done-criteria.sh`, line 26](https://github.com/nyldn/claude-octopus/blob/cb2677b2bd442bcc501489cc6110ab54fb14e701/hooks/done-criteria.sh#L26));
- the GitHub one acts only inside the plugin's own repository.

**The measurement.** A harness ran each hook outside Claude Code:
- `env -i`, an empty temporary `HOME`, a synthetic prompt, the original thresholds;
- one run each, on 2026-09-26 around 13:00 EDT, in Git Bash on Windows 11;
- no network call and no provider launched, and the temporary `HOME` was still empty afterwards.

| Command | Exit | Wall time |
|---|---|---|
| `bash -c true` | 0 | 2,829 ms |
| `bash -lc true` | 0 | 25,457 ms |
| `timeout 3 cat </dev/null` | 0 | 7,031 ms |
| `python3 -c pass` | 0 | 10,357 ms |
| `python -c pass` | 0 | 1,539 ms |
| `done-criteria.sh` (5 s) | 124, timeout | 9,546 ms, 0 bytes out |
| `user-prompt-submit.sh` (5 s) | 124, timeout | 11,690 ms, 0 bytes out |
| `github-work-queue-watch.sh` (8 s) | 124, timeout | 15,298 ms, 0 bytes out |

**What this shows.**
- The symptom reproduces outside Claude Code.
- The hooks' logic is not what spends the budget. The cheapest path through `done-criteria.sh` is a fresh `bash` and then `timeout 3 cat` on an input already at its end. Those two steps alone cost 2.8 s + 7.0 s, more than the whole 5 s.
- On that host, at that moment, *starting any process* took seconds.

**What it does not show.** The cause is *most likely* host-wide process-creation latency, and that is not isolated. The candidates are:
- load: about 40 `bash`, 65 `node` and 13 `claude` processes were running;
- antivirus scanning of each launch;
- a costly login profile, if hooks are started through one. I have not checked which shell mode Claude Code uses.

The limits: single samples, no quiet-moment comparison, and the three hooks run one after another where Claude Code runs them together. The `python3` against `python` gap is one sample each, under varying load. In the terms of the [observation format above](#2026-09-26--an-observation-format-for-models-skills-and-subagents), this is an **environment** failure, not a model failure.

**Nothing was changed.** The plugin has kill switches (`OCTO_DONE_CRITERIA=off`, `OCTOPUS_GITHUB_WORK_QUEUE=off`); setting them is a configuration change that needs the user's approval. Raising the timeouts would hide the latency and add seconds to every prompt.

An upstream patch idea stays a draft, untested and not sent:
- read stdin with a bash builtin;
- make one `jq` call instead of several `python3` calls;
- exit before spawning `git` outside the plugin's repository.

## 2026-09-27 — After a wmux crash: resumed is not delivered

*Retrospective observation.* The evidence is the coordinator's recovery note, kept locally, plus what this session saw of itself. Session and surface identifiers are left out.

- **What happened.** The terminal multiplexer that hosts the agent panes (wmux) crashed. With the user's authorization, the coordinator:
  - relaunched version 1.1.1, which quit during its own update and created no agent;
  - then saw 2.13.1, which the user installed, answer and restore its workspaces;
  - resumed six lanes (IX, Learn, TARS, Demerzel, Gaia, Music) by their exact historical conversations.
  There was no reboot, data reset, permission bypass, repository edit, server restart or paid call.
- **"Resumed" is a UI state, not a delivery.** The recovery note records, for each lane, what was observed: a resumed recap, a prior diff, a prompt. Its own rule is that *"agent labels/running alone are not delivery evidence"*. In the [observation format's](#2026-09-26--an-observation-format-for-models-skills-and-subagents) states, a resumed pane is *visible*. It becomes *accepted* when the lane acknowledges a task, and *completed* only with a receipt.
- **What made recovery cheap.** Each lane had written its state into files before the crash, not only into its conversation. Those files named the exact checkout, head and uncommitted paths, and gave the next action.
  - This Learn session resumed from such a file. It then waited for publication authority, as the file said, instead of acting on its recap.
  - The IX lane found, the same way, one uncommitted workflow edit whose commit and push the crash had cut off. It asked the user before pushing it.
  - A conversation summary is not enough for this. It says what was intended, not which command actually ran.
- **Identifiers changed.** Workspace and surface IDs were new after the restart, so any monitor had to re-read the mapping before sending keys to a pane. That is an orchestration failure waiting to happen, and here it was caught.

## 2026-09-27 — GA #740 merged before its independent review

*Retrospective observation*, recorded with the observation format. The public facts were read with `gh`. The rest comes from local receipts — the IX lane's, the coordinator's and the post-merge review's — which this course has read but not re-run.

| Field | Observation |
|---|---|
| Repository | [GuitarAlchemist/ga#740](https://github.com/GuitarAlchemist/ga/pull/740), *pipeline editor: OS theme, argument type checks, GA example pipeline*. Merged 2026-09-27T02:50:43Z as [`d67d04b`](https://github.com/GuitarAlchemist/ga/commit/d67d04bdb04742ba338518e28197e6035cb80e90). The merged head, [`984192e`](https://github.com/GuitarAlchemist/ga/commit/984192e970746dbed9e56255616360f56d9eed62), was pinned with `--match-head-commit` |
| Roles | The IX agent session was the author, and it merged with the repository owner's credentials. Codex was meant to be the integrator, after an independent review of that exact head |
| What went wrong | The user's turn "pousse tout ce qui est green" ("push everything that is green") reached the author first, and it read that as merge authority for green PRs. It checked the Codex bot comments (no open P0/P1 at that head) and green CI, then merged. The instruction that Codex must review the head before any merge arrived after the merge |
| Failure category | **Orchestration or ownership**: two instructions with different authority reached one agent in the wrong order. No tool failed and no reasoning step was wrong given what the agent had seen, but the gate did not run |
| Evidence at the merge | Public: every GitHub check on the PR passes. Reported by Codex after the merge: generated-theme synchronization checked, and three targeted test suites, 35 of 35 passed. That is not full HTTP, browser, build or backend coverage |
| Post-merge review | Read-only, by a separate session, with its receipt kept locally; this course did not re-run it. It confirmed, each with a reproduced failing case: the proposal routes the PR adds admit more than their cap when bodies arrive late (29 pending against 20, while serial posts respect it); concurrent clicks pass the advisor's spend cap (8 calls admitted where one fitted, API mocked, no money spent; serial calls respect it); a malformed body gets a misleading "invalid JSON body"; a corrupt ledger line throws outside any `try`. From the source: a proposal with no base revision is treated as current. The PR body mentions neither the paid advisor API nor the proposal routes agents can write to. The manual Accept and Run gates hold, and the review indicates no revert |
| State | The merge is *completed*, and so is the review. A fix for the five code findings is *submitted* to Codex: a local branch, not committed, with a failing test first for each (5 failed before the fix, and 42 of 42 pass after it, over 4 files). Codex re-ran those 4 files: 42 of 42. The fix is not integrated, and its full review, a browser check and a full build remain. So no defect is closed on `main` yet |
| Response | No revert. Integration stays with Codex. Residuals the fix names itself stay open: two dev servers sharing a ledger can still race, the spend check uses an estimate rather than a guaranteed upper bound, and request bodies past the size limit are still buffered, as before the PR |
| Follow-up | Codex's decision on the fix, then its PR and CI, then this entry's status |

## To verify

- Apply the observation format to a second, independent delegation, and have someone other than its author check one record against its evidence.
- The install commands of lesson 1 on Linux, WSL and macOS, for both agents, and Codex's PowerShell installer.
- A Codex session that answers the first question of lesson 1, and the same `AGENTS.md` experiment as lesson 2.
- Codex hooks: whether the `config.toml` example of lesson 3 runs on Windows with `command_windows`, and whether its relative path works when Codex starts in a subdirectory; the trust flow in `/hooks`.
- Codex skills: whether `$ARGUMENTS`, `argument-hint` and `allowed-tools` mean anything to Codex, and invoking `$journal-status`.
- Codex custom agent `lesson_checker`: loading, and `sandbox_mode = "read-only"` in practice.
- Codex MCP: a session calling `scale_notes` and `course_outline`; the working directory relative `args` resolve against without `cwd`; `default_tools_approval_mode = "approve"`.
- Whether `project_doc_fallback_filenames` is accepted in a project's `.codex/config.toml`.
- Whether Codex expands `@path` imports in `AGENTS.md` (its documentation doesn't mention them).
- Whether Claude Code and Codex tolerate a non-JSON line on a server's stdout, like the SDK client does.
- Why the re-read `AGENTS.md` reached the session only with the next incoming message after compaction: repeat with a plain `CLAUDE.md`, without import, on 2.1.271.
- `codex exec -o`: whether the file is written by the CLI outside the sandbox in `read-only` mode.
- A disposable installation capture for each workflow, without installing overlapping suites in the same fixture.
- A Sandcastle Docker run on an explicit branch with one iteration, no merge, and host-owned test evidence.
- The hook timeouts: three runs of each hook at a quiet moment and three under load, the three hooks run together as Claude Code runs them, and whether Claude Code starts hooks through a login shell.
- GA #740: whether the fix for the review's five code findings reaches `main` with its regression tests, and a browser check of the editor, which neither the review nor the fix ran.
