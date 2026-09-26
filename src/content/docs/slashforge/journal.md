---
title: Journal
description: Dated progress notes for the SlashForge course — the version studied, what the installer writes and where its dry run, README and comments disagree with it, where its frontmatter check disagrees with Claude Code, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] SlashForge 4.4.3 pinned in `code/slashforge/package.json`; `check.sh` runs the installer into a throwaway home directory and a throwaway repository
- [x] CI: `check.sh` on Linux, Windows and macOS, with no Claude Code and no API key
- [x] Lesson 1: what the installer writes
- [x] Lesson 2: inside the files — commands, skills, guides
- [x] Lessons 1 and 2 re-run from a fresh export of the course code: 19 of 19 outputs match
- [x] A throwaway lab for lessons 3 to 5: `code/slashforge/lab/prepare.sh` and `lab/run.sh`, with a ceiling on every run
- [x] Lessons 3 to 5 tested in the lab, headless, each up to its first gate: six runs, 1.83 USD in all (see Experiments)
- [x] Lesson 3 page: `/slashforge:setup` against `/init`
- [x] Lesson 4 page: `/slashforge:code`, ten phases and four gates, with `-quick`
- [x] Lesson 5 page: `/slashforge:investigate` and `/slashforge:review-pr`
- [x] Lesson 6: making it yours — rules, verification, a team install; `check.sh` now compares 20 outputs
- [x] Lesson 7: contributing back, and a retest of 4.5.0 on Windows

## QA

Every row below is reproduced by `check.sh` or read in the installer at tag `v4.4.3`. None has been reported upstream: the repository had no issue open or closed on 2026-09-22, and its tests don't cover the dry run. On 2026-09-26 the author acknowledged these findings and announced fixes([entry](#2026-09-26--the-authors-response-and-how-to-check-a-release)), and release 4.5.0 fixes the eight installer and guide rows, retested on Windows ([retest](#2026-09-26--retest-on-slashforge-450)).

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| `--dry-run` lists what the install writes | It lists 21 files; the install writes 32. The nine skills, `forge-open.sh` and `forge-report-shell.html` are missing | [`bin/install.js#L499-L528`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L499-L528) builds its own list from two of the four arrays | `l01_dry_run_vs_install`: 11 written, not announced; 0 announced, not written | Reproduced, not reported [2026-09-22](#2026-09-22--the-installer-read-and-run) · Fixed in v4.5.0, retested on Windows ([2026-09-26](#2026-09-26--retest-on-slashforge-450)) |
| The dry run labels each file with what the install does to it | It says `copy` for every guide. Guides are rendered since 4.4.1 | same lines | `l02_global_vs_project`: two guides differ between the global and the project install, which a copy could not do | Reproduced, not reported [2026-09-22](#2026-09-22--the-installer-read-and-run) · Fixed in v4.5.0, retested on Windows ([2026-09-26](#2026-09-26--retest-on-slashforge-450)) |
| The README's *What gets installed* describes 4.4.3 | It describes three commands in `commands/forge/`; 4.4.3 writes four commands and nine skills in `commands/slashforge/` | [`README.md#L103-L112`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/README.md#L103-L112) | `l01_files` | Reproduced, not reported [2026-09-22](#2026-09-22--the-installer-read-and-run) · Fixed in v4.5.0, retested on Windows ([2026-09-26](#2026-09-26--retest-on-slashforge-450)) |
| The installer's comments describe its code | Three are older than it: *"the three entry points"* above a list of four; `'forge/setup.md' -> '/slashforge:setup'` above `commandName`; *"a namespace subdirectory (forge/)"* where it writes `slashforge/` | [`#L45-L50`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L45-L50), [`#L182-L183`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L183), [`#L259-L260`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L259-L260) | `l02_installer_functions`: `commandName('slashforge/setup.md')` gives `/slashforge:setup` | Read; comments only, no behaviour affected · Fixed in v4.5.0, retested on Windows ([2026-09-26](#2026-09-26--retest-on-slashforge-450)) |
| `--yes`, which the help ties to *"the update prompt"*, doesn't answer other questions | With stdin not a terminal it is on, and `uninstall` removes everything without asking | [`#L628-L633`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L628-L633) | `l01_uninstall`: 15 removals, exit 0, no prompt | Reproduced; documented in part · Fixed in v4.5.0, retested on Windows ([2026-09-26](#2026-09-26--retest-on-slashforge-450)) |
| A template Claude Code accepts, the installer accepts | The installer reads frontmatter line by line: a folded YAML `description: >` is refused, and a closing `---` followed by a space is not found, although the opening fence is trimmed | [`#L113-L137`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) | `l02_installer_functions`: 6 refusals out of 7 samples | Reproduced; affects only templates you add · Fixed in v4.5.0, retested on Windows ([2026-09-26](#2026-09-26--retest-on-slashforge-450)) |
| The `name` field the installer requires names the command | Claude Code ignores `name` in a file under `commands/`; the path names the command | [Claude Code, skills](https://code.claude.com/docs/en/skills#where-skills-live) | — | Documented on both sides; a trap when renaming (lesson 2, exercise 1) |
| The kit's guides agree on where a skill goes and how long it may be | `forge-instructions.md` says `.claude/skills/*.md` and *"Every `.md` file … under 200 lines"*; `forge-skills.md` says a folder with `SKILL.md`, under 500 lines. Claude Code's documentation only lists the folder form | [`forge-instructions.md#L14-L34`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-instructions.md#L14-L34), [`forge-skills.md#L27-L51`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-skills.md#L27-L51) | Two contradictions in guides the model reads in the same run | Read, not reported [2026-09-22](#2026-09-22--lesson-6-two-rulebooks-and-which-copy-runs) · Fixed in v4.5.0, retested on Windows ([2026-09-26](#2026-09-26--retest-on-slashforge-450)) |
| Setup's verify step catches a file over 200 lines | `wc -l CLAUDE.md .claude/**/*.md` in bash without `globstar` stops one folder deep, so a skill's `SKILL.md` is never counted | [`forge-instructions.md` Step 9](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-instructions.md#L126-L139) | `l06_verify_glob`: a 300-line `SKILL.md` missing from the count, on Linux, Windows and macOS | Reproduced, not reported [2026-09-22](#2026-09-22--lesson-6-two-rulebooks-and-which-copy-runs) · Fixed in v4.5.0, retested on Windows ([2026-09-26](#2026-09-26--retest-on-slashforge-450)) |

## Experiments

Lessons 3 to 5 run the commands through the model, so each run has a hypothesis written before it and a ceiling (`lab/run.sh` has no default budget). The hypotheses for L3 to L5 were written while the lab was still logged out; the runs came after the author logged the lab in. Every run is headless and ends at the first question the workflow asks. Costs are the ones Claude Code computes for the model it used, `claude-opus-5-5[1m]`, the account's default: they would be lower with a smaller model. They are one run each, not averages.

| Question | Hypothesis (written before the run) | Result | Verdict | Entry, code |
|---|---|---|---|---|
| e0 — Can the lab run a command without touching the real `~/.claude`? | A Claude Code whose configuration directory is empty is not logged in, and stops before any model call, spending nothing | `Not logged in · Please run /login`, exit 1, 1 turn, 114 ms, 0 tokens in and out, 0 USD, 0 files changed. Ceiling: 0.25 USD, 3 turns | Confirmed: the lab is isolated, and it cannot go further without a login | [2026-09-22](#2026-09-22--the-lab-for-lessons-3-to-5-and-where-it-stops), `lab/run.sh` |
| L3 — What does `/slashforge:setup` write on a repository with no `.claude/`, compared with `/init`? | It writes `CLAUDE.md` and `.claude/rules/`, and stops at the Graphify offer (a yes/no) before provisioning anything | e2: nothing written. Graphify skipped without asking (under its 70% threshold); stopped on six clarifying questions. 6 turns, 56 s, 0.27 USD. e2b, `/init` on the same clone: a 50-line `CLAUDE.md` written at once, no question, 9 turns, 92 s, 0.32 USD | Refuted: setup asks before it writes, and the Graphify gate never fired | [2026-09-22](#2026-09-22--lessons-3-to-5-run-in-the-lab), `lab/run.sh` |
| L4 — How far does `/slashforge:code -quick` get headless on a small change? | It stops at the Phase 3 gate (confirm plan) with no edit to the repository, under 70,000 tokens, the high end of the README's range for `-quick` | e3: a lean plan (one exported `plannedWrites`, a test comparing it with `installFiles`), then a stop, no file changed. It asked Phase 3 and Phase 4 (branch) in one message. 6 turns, 57 s, 0.25 USD; 1,720 tokens in and out, 23,433 written to the cache, 158,847 read from it | Confirmed for the gate and for "no edit"; the token part depends on what is counted: cache reads alone exceed 70,000 | [2026-09-22](#2026-09-22--lessons-3-to-5-run-in-the-lab) |
| L5a — Does `/slashforge:investigate` stay read-only? | It edits no tracked file and writes one HTML report under `docs/slashforge/` | e1 and e1b: no file changed in the repository, the right root cause, and no report, because building it needs `node` code the lab refuses. In e1, where the lab pre-approved `Write`, the model wrote its report builder to `%TEMP%` instead. e1: 15 turns, 0.45 USD; e1b: stopped by the turn limit at 11, 0.38 USD | Confirmed for the repository; the report half is untested; and a pre-approved `Write` is not confined to the repository | [2026-09-22](#2026-09-22--lessons-3-to-5-run-in-the-lab) |
| L5b — What does `/slashforge:review-pr` do with no GitHub login? | It stops at its Step 0 preflight and asks for `gh auth login`, as its file says, with no other command run | e4: `gh auth status` failed, the command stopped and told the user to run `gh auth login`; nothing read from or written to GitHub. 4 turns, 35 s, 0.17 USD | Confirmed | [2026-09-22](#2026-09-22--lessons-3-to-5-run-in-the-lab) |
| e5 — When a command exists both in `~/.claude` and in the project, which runs? | The personal one, as Claude Code's documentation says (*"personal over project"*) | e5b: `GLOBAL`, 1 turn, 0.09 USD. e5, with a 0.10 USD ceiling, stopped with `error_max_budget_usd` at 0.103 USD before its answer was returned | Confirmed; and the ceiling works under a subscription login, checked after each call | [2026-09-22](#2026-09-22--lesson-6-two-rulebooks-and-which-copy-runs) |

## 2026-09-22 — The installer, read and run

SlashForge 4.4.3 (tag `v4.4.3`, commit `bd75a4f`), Node.js 24.12.0 locally and 24.21.0 in CI, Windows 11. The installer on `main` was the same file that day.

The course doesn't let the installer near the real `~/.claude`. `check.sh` points `HOME`, and `USERPROFILE` on Windows, at `out/home`, sets `SLASHFORGE_NO_UPDATE_CHECK=1` so that the version check doesn't reach npm, and runs every command with stdin from `/dev/null`, as CI does. That last choice shows a behaviour of its own: with no terminal, the installer answers yes to everything, uninstall included.

The dry run was the first surprise. I counted its lines by hand and got 23, which was wrong: `scripts/dry-run-vs-install.mjs` now does the counting, and says 21 against 32. The cause is in the code rather than in a missed update: the preview is a second path through the installer, and the real one gained assets in 4.1.0 and skills in 4.2.0 without it. I first wrote that the nine skills were *not installed*; they are, only not announced — the script's second list, *in the dry-run but not written*, is empty.

Lesson 2 calls the installer's exported functions instead of describing them, which is possible because loading `install.js` doesn't run it. Two measurements came from that lesson: which files differ between a global and a project install (nine: eight name a path, and `meta.json`), and the line counts that show the four commands are dispatchers for longer guides.

The broken-template check copies the package, deletes one `description:` line, and runs the copy into its own home directory: exit 1, and no file written.

## 2026-09-22 — The lab for lessons 3 to 5, and where it stops

Versions: Claude Code 2.1.280, Node.js 24.12.0 locally, SlashForge 4.4.3, Windows 11 with Git Bash.

**Lessons 1 and 2, re-run.** I exported `code/slashforge` from the published commit (`cfa14ef`) into a new folder, ran `npm ci` and `bash check.sh`: 19 of 19 outputs match, in 135 s including the install. CI passed on Linux, Windows and macOS for the same commit. Afterwards the real `~/.claude` held no `commands/` and no `setup/` folder: nothing of SlashForge.

**The lab.** `lab/prepare.sh <dir>` creates a home directory, a Claude Code configuration directory (`CLAUDE_CONFIG_DIR`), a GitHub CLI directory (`GH_CONFIG_DIR`) and a git configuration, all inside `<dir>`. It clones SlashForge itself at `v4.4.3` (public, MIT, no dependencies) onto a branch `lab`, removes the remote, and adds a pre-push hook that refuses. Then it installs the kit globally into the lab's home. I checked the guard with a push to a local bare repository: `lab: push refused`, exit 1.

`lab/run.sh <dir> <name> <max-usd> <max-turns> <prompt>` runs `claude -p` in the lab repository with `--max-budget-usd`, `--max-turns` and a 900 s timeout. It accepts edits, allows only read-only git, `ls` and the tests, and refuses `git push`, `gh`, `curl`, the web and MCP servers. It records exit code, wall time, turns, tokens, the cost that Claude Code computes, permission denials, and how many paths changed. A headless run ends at the first question the workflow asks, so a SlashForge gate ends the run. It is never answered.

**The smallest experiment, e0**: `/slashforge:investigate` on the dry-run finding of lesson 1, with a ceiling of 0.25 USD and 3 turns. Claude Code answered `Not logged in · Please run /login` in 114 ms, with 0 tokens and 0 USD, and the lab repository was unchanged. Its JSON result reports `"subtype": "success"` with `"is_error": true` and `"terminal_reason": "api_error"`, so a script has to read `is_error` and not `subtype`.

**Where it stops.** Logging the lab in needs a person. The login is a browser flow for the author's account, and copying the real credentials into the lab would be reading `~/.claude`, which this lab exists not to do. So lessons 3 to 5 stop here, at step zero. The gates the commands would have reached are listed below, from their files, not from a run:

| Command | Where it waits for a person |
|---|---|
| `/slashforge:setup` | the Graphify offer (yes/no), clarifying questions, and before overwriting a file it generated in an older version |
| `/slashforge:code` and `-quick` | Phase 3 confirm plan, Phase 4 branch decision, Phase 8 push and PR, Phase 10 cleanup; `-quick` keeps all four |
| `/slashforge:investigate` | only when called without a symptom |
| `/slashforge:review-pr` | Step 0 (`gh` must be logged in, or it stops), R1 choosing the PR, R5 before posting anything |

Two of these need an authority this lab doesn't have and must not be given: Phase 8 pushes and opens a pull request, and `review-pr` posts to GitHub.

**SlashForge's own tests, in the lab.** `node --test` on the clone exited 0 but took 523 s. I didn't capture the pass count, because my filter expected TAP lines and the default reporter prints something else. I suspected the test of `forge-open.sh`, which runs `start` under Git Bash. Run alone, it passes in 20 s, and I first concluded that it wasn't the cause. That conclusion was wrong: a passing test proves nothing here. [`test/install.test.js:527`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/test/install.test.js#L527) calls the helper with `/tmp/definitely-does-not-exist-slashforge.html`, and on Windows [`forge-open.sh`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-open.sh#L37-L40) runs `start`, swallows the error and exits 0. So the test is green whatever `start` does, a false positive, and a screen capture taken by the author shows that it displays a Windows error dialog on the desktop. The 20 s run doesn't rule the helper out as a cause of the 523 s either. I did not run the test again, because it opens a window. The cause of the 523 s is still to verify.

## 2026-09-22 — Lessons 3 to 5, run in the lab

The author logged the lab's own configuration directory in with `claude auth login` (subscription, not API billing), in their own terminal: the login page gives a code to paste, which a background job can't do. `claude auth status` in the lab then said `"loggedIn": true, "authMethod": "claude.ai"`, and the real `~/.claude` was not involved.

Versions: Claude Code 2.1.280, model `claude-opus-5-5[1m]` (the default; no `--model` was passed), SlashForge 4.4.3 on its own repository at `v4.4.3`. Six runs, each with its ceiling, one at a time:

| Run | Prompt | Ceiling | Turns | Wall | Cost | Stopped at |
|---|---|---|---|---|---|---|
| e1 | `/slashforge:investigate` on the dry-run finding | 0.50 USD, 10 turns | 15 | 76 s | 0.45 USD | the report step, refused (see below) |
| e2 | `/slashforge:setup` | 0.75 USD, 20 turns | 6 | 56 s | 0.27 USD | six clarifying questions |
| e2b | `/init` | 0.50 USD, 20 turns | 9 | 92 s | 0.32 USD | done: `CLAUDE.md` written |
| e3 | `/slashforge:code -quick` + the dry-run fix | 0.75 USD, 20 turns | 6 | 57 s | 0.25 USD | Phase 3 and Phase 4 together |
| e4 | `/slashforge:review-pr` | 0.25 USD, 5 turns | 4 | 35 s | 0.17 USD | Step 0: `gh` not logged in |
| e1b | e1 again, with the fixed lab | 0.50 USD, 10 turns | 11 | 58 s | 0.38 USD | the turn limit |

Total: 1.83 USD. No run reached its dollar ceiling. After e2b, the lab repository was restored (its `CLAUDE.md` is kept with the run's files); every other run left it unchanged.

**What the investigation found.** Both runs gave the root cause lesson 1 gives: the dry run builds its own list from `GUIDE_FILES` and `COMMAND_FILES`, and `installFiles` also writes `ASSET_FILES` and `SKILL_FILES`, 21 + 2 + 9 = 32. e1 added two things the course hadn't written: that guides are labelled `copy` though rendered (lesson 1 has it), and that the dry run doesn't mention the stale `REMOVED_GUIDE_FILES` it deletes. It proposed the fix lesson 1 suggests, one planning function shared by both paths, with a test that compares them.

**A write that left the repository.** In e1, `lab/run.sh` listed `Edit` and `Write` among the allowed tools. That pre-approves them everywhere, not only in the working directory, and the model used it: refused `node` for the report, it wrote a 4,175-byte script to `%TEMP%\sf-splice.js` and told the user to run it. The file is kept with the run, and the lab is fixed. `Edit` and `Write` are no longer listed, so `acceptEdits` accepts edits inside the repository only, and `run.sh` lists any file that appears in the temp folder during a run. e1b, e2 to e4 wrote nothing outside; the one file listed after e2b was an image written by another program.

**`/init` against `/slashforge:setup`.** `/init` wrote a 50-line `CLAUDE.md` straight away, and found on its own the README drift that this course's QA table lists ("Known drift: the README's *What gets installed* table still shows `commands/forge/`"). Setup read more and wrote nothing: it proposed four agents, asked about hooks, commands, release rules and layout, and said it would write `CLAUDE.md` last. The Graphify offer, which the hypothesis expected as the first gate, didn't appear: most of the repository is Markdown and `.astro`, under Graphify's 70% language threshold, and setup skips it silently in that case, as its file says.

**The gates.** Each command stopped where its file says a person decides, and none went past one. One deviation: `/slashforge:code -quick` asked for the plan (Phase 3) and the branch (Phase 4) in the same message, while `code.md` says *"Do not combine phases"*.

**Limits.** One run per command, one repository, one model. Costs are computed by Claude Code for the subscription session, not billed amounts. The `-quick` token comparison with the README is loose, because the README doesn't say whether its range counts cached input. The turn limit behaved differently in two runs: e1 reported 15 turns with `--max-turns 10` and finished normally, and e1b stopped at 11 with `error_max_turns`. The cause is to verify.

## 2026-09-22 — Lesson 6: two rulebooks, and which copy runs

Most of lesson 6 is reading, and two findings came out of it. The two guides the model reads during setup disagree: `forge-instructions.md` lists skills as `.claude/skills/*.md` under a 200-line golden rule, and `forge-skills.md` asks for a folder with a `SKILL.md` under 500 lines. And the verify step at the end of setup, `wc -l CLAUDE.md .claude/**/*.md`, doesn't look inside skill folders in bash's default mode. `check.sh` now builds a small repository with a 300-line `SKILL.md` and compares the two file lists (`l06_verify_glob`), so CI shows it on the three systems; in zsh, where `**` is recursive by default, the same line would see the file.

One model run, to settle what a team install means. The hypothesis, written from Claude Code's documentation before the run: with `/lab:which` both in the lab's personal `commands/` and in the repository's `.claude/commands/`, the personal one runs. e5, with a ceiling of 0.10 USD, was stopped with `error_max_budget_usd` at 0.103 USD: the ceiling works under a subscription login, and it is checked after the call, not before. e5b, with 0.30 USD, answered `GLOBAL` for 0.09 USD. Both probe files are kept with the run, and the lab was restored. So a teammate with a global install runs their own version of `/slashforge:code`, not the one the team committed.

Limit: the re-run behaviour of setup — refresh, ask, or leave alone according to the `generated_by` marker — is described from the guide, not tested; testing it means running setup past its questions twice.

## 2026-09-26 — The author's response, and how to check a release

A reply attributed to SlashForge's author, [Rajdeep Singh Ratan](https://www.linkedin.com/in/rajdeepratan/), was posted on LinkedIn and pasted into this course's working notes on 2026-09-26. The post's permalink and publication date have not been checked; the link above is the author's profile, not the post. In short, the author went through the findings of this journal, agreed with them, and said they will inform upcoming releases, including one manifest shared by the dry run and the install, and guides and checks that agree with each other.

Status when this entry was written: **author acknowledgement, fixes announced, not fixed and not retested.** Later the same day, this course found that release 4.5.0 already shipped the fixes, and retested it: see the [next entry](#2026-09-26--retest-on-slashforge-450). Nothing below changes a measured result. Every row still describes `v4.4.3` at `bd75a4f`, and becomes *fixed* only after the checklist that follows has been run on a named release.

| What the author acknowledged | Where this journal measured it |
|---|---|
| The dry run lists 21 files, the install writes 32 | QA, first row (`l01_dry_run_vs_install`) |
| The preview says guides are copied when they are rendered | QA, second row (`l02_global_vs_project`) |
| The README is stale after the rename | QA, third row |
| Installer comments are stale | QA, fourth row (read, comments only) |
| Non-interactive auto-yes also covers `uninstall` | QA, fifth row (`l01_uninstall`) |
| Template validation is stricter than Claude Code's own rules | QA, sixth row (`l02_installer_functions`) |
| Two guides disagree on a skill's location and length | QA, row on the two guides ([lesson 6 entry](#2026-09-22--lesson-6-two-rulebooks-and-which-copy-runs)) |
| The bash 200-line check misses nested skills | QA, row on the verify step (`l06_verify_glob`) |
| A Windows test passes whatever happens and opens an error dialog | [Lab entry](#2026-09-22--the-lab-for-lessons-3-to-5-and-where-it-stops) and *To verify* |
| Building the report with inline `node` is awkward to authorize safely | Experiment L5a, and "A write that left the repository" in the [lessons 3 to 5 entry](#2026-09-22--lessons-3-to-5-run-in-the-lab) |
| Each command costs money before its first checkpoint | Experiments L3 to L5b: 0.17 to 0.45 USD per run, computed by Claude Code, not billed |
| Whether cached input counts in the token figures is ambiguous | Experiment L4: cache reads alone exceed the README's 70,000 |
| A stale global copy silently wins over the kit committed in the project | Experiment e5: `GLOBAL` |

**Release-verification checklist.** To run on the first release that claims these fixes, before any row changes status:

1. Name the release: its tag and the exact commit SHA it points to, read from the repository, not from a changelog.
2. Rerun the same reproductions (`check.sh`, the `l01`, `l02` and `l06` checks) at that commit, on every operating system the release claims: Linux, Windows and macOS.
3. Compare the dry run's list with the files the install actually writes, file by file, and record both exit codes.
4. Keep the negative controls. A check that finds nothing on the old commit proves nothing on the new one, so run each check on `bd75a4f` too and confirm that it still fails there.
5. With stdin not a terminal, check that `uninstall` no longer removes files without an explicit confirmation or flag, and that `--yes` is documented as covering it if it still does.
6. Read how the README now defines per-command cost and whether cached input counts. Rerun one command with a dollar ceiling to compare.
7. Rerun e5 with a personal and a project copy, and record which one runs, and whether the kit now warns about it.
8. Update each QA row: *fixed in `<tag>`, retested on `<OS list>`*, or *still open in `<tag>`*. Keep the original measurement and its date in the row.

No outreach from this course: nothing was posted, filed or sent upstream.

## 2026-09-26 — Retest on SlashForge 4.5.0

Checking upstream before calling anything open showed a release the course had not seen: tag `v4.5.0` at `10d3d916b30323598515aa27aef43a8527e7e967`, dated 2026-09-25. Its [CHANGELOG](https://github.com/rajdeepratan/SlashForge/blob/10d3d916b30323598515aa27aef43a8527e7e967/CHANGELOG.md) lists a fix for every installer and guide row of the QA table, and for the Windows helper test and the inline `node` reports, and adds a warning when a global install shadows a project one. It credits this course.

`code/slashforge/retest/retest.sh` installs a given release into a throwaway folder and reruns `check.sh` against the 4.4.3 expectations. It ran on Windows 11 with Git Bash and Node 24.12.0:

| | 4.4.3 (negative control) | 4.5.0 |
|---|---|---|
| `check.sh` against the 4.4.3 expectations | exit 0, 20/20 | exit 1, 16 differ: the expectations are 4.4.3's |
| Dry run against install | 21 listed, 32 written, 11 missing | 34 and 34, none missing |
| Dry-run labels | 16 `copy`, 4 `render` | 29 `render`, 4 `copy` |
| `uninstall` with no terminal | 15 removals, exit 0 | refused, exit 1 |
| Folded YAML, trailing-space fence | both refused | both accepted; 4 real errors still refused |
| Shadowing warning on `--project` | none | printed |
| Templates with inline `node -e '` | 4 | 0 |
| Step 9 on three throwaway repositories (`verify-step9.sh`) | the glob sees no skill file | a 600-line `SKILL.md` and a nested 250-line file flagged; a 300-line `SKILL.md` passes |

Read, not run:
- the README and the guides now agree;
- the three stale comments are gone;
- the npm package 4.5.0 equals the tag's `bin/` and `templates/`, ignoring line endings;
- the new helper test stubs the openers on Linux and macOS and returns early on Windows. So Windows no longer gets a dialog, and gets no assertion either.

The README now says its token ranges don't separate cache reads from fresh input: a clarification, not a split.

Verdict: the eight installer and guide rows are **fixed in 4.5.0, retested on Windows**. Each row keeps its 4.4.3 measurement. Not retested:
- Linux, macOS and WSL;
- any model-backed run on 4.5.0.

The lessons still describe 4.4.3, and CI still pins it. [Lesson 7](../07-contributing-back/) tells the story and lists what is still open.

## To verify

- Rerun `retest/retest.sh 4.5.0` on Linux and macOS, and in WSL; only Windows 11 was retested.
- Rerun one model-backed command on 4.5.0 (cost figures, gates, which copy runs) before saying anything about run-time behaviour after the fixes.
- Run the release-verification checklist of the 2026-09-26 entry on the first release that claims the announced fixes, before changing any QA status.
- Why SlashForge's `node --test` takes 523 s on Windows with Git Bash, including how much of it is the `forge-open.sh` test. Don't re-run that test on a desktop session: it opens an error dialog (see the lab entry).
- Why e1 reported 15 turns under `--max-turns 10` and finished normally, when e1b stopped at 11.
- Whether the model finds `.claude/setup/slashforge/…` when Claude Code is started in a subfolder of a repository with a project install (lesson 2).
- The cost of a full workflow past its gates. The lab stops at the first gate by design; going further means answering the gates, which is the author's decision.
- Whether a skill written as a file in `commands/` is ever picked by the model on its own, or only when a guide names it.

## Open questions

- Does setup's re-run respect the `generated_by` markers as its guide says: refresh the current version's files, ask about older ones, leave edited ones alone?
- Would upstream take a dry run built from `installFiles` itself, the way PowerShell's `-WhatIf` goes through the same `ShouldProcess` as the action? Not proposed: nothing leaves this repository without the author's approval.
