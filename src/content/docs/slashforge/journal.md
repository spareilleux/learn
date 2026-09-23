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
- [ ] Lesson 3: `/slashforge:setup` against `/init`, on a public repository
- [ ] Lesson 4: `/slashforge:code`, ten phases and four gates
- [ ] Lesson 5: `-quick`, `/slashforge:investigate` and `/slashforge:review-pr`
- [ ] Lesson 6: making it yours

## QA

Every row below is reproduced by `check.sh` or read in the installer at tag `v4.4.3`. None has been reported upstream: the repository had no issue open or closed on 2026-09-22, and its tests don't cover the dry run.

There is no Experiments table yet: nothing here was measured against a hypothesis written beforehand. Lessons 3 to 5, which run the commands through the model, are where that will change.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| `--dry-run` lists what the install writes | It lists 21 files; the install writes 32. The nine skills, `forge-open.sh` and `forge-report-shell.html` are missing | [`bin/install.js#L499-L528`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L499-L528) builds its own list from two of the four arrays | `l01_dry_run_vs_install`: 11 written, not announced; 0 announced, not written | Reproduced, not reported [2026-09-22](#2026-09-22--the-installer-read-and-run) |
| The dry run labels each file with what the install does to it | It says `copy` for every guide. Guides are rendered since 4.4.1 | same lines | `l02_global_vs_project`: two guides differ between the global and the project install, which a copy could not do | Reproduced, not reported [2026-09-22](#2026-09-22--the-installer-read-and-run) |
| The README's *What gets installed* describes 4.4.3 | It describes three commands in `commands/forge/`; 4.4.3 writes four commands and nine skills in `commands/slashforge/` | [`README.md#L103-L112`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/README.md#L103-L112) | `l01_files` | Reproduced, not reported [2026-09-22](#2026-09-22--the-installer-read-and-run) |
| The installer's comments describe its code | Three are older than it: *"the three entry points"* above a list of four; `'forge/setup.md' -> '/slashforge:setup'` above `commandName`; *"a namespace subdirectory (forge/)"* where it writes `slashforge/` | [`#L45-L50`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L45-L50), [`#L182-L183`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L183), [`#L259-L260`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L259-L260) | `l02_installer_functions`: `commandName('slashforge/setup.md')` gives `/slashforge:setup` | Read; comments only, no behaviour affected |
| `--yes`, which the help ties to *"the update prompt"*, doesn't answer other questions | With stdin not a terminal it is on, and `uninstall` removes everything without asking | [`#L628-L633`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L628-L633) | `l01_uninstall`: 15 removals, exit 0, no prompt | Reproduced; documented in part |
| A template Claude Code accepts, the installer accepts | The installer reads frontmatter line by line: a folded YAML `description: >` is refused, and a closing `---` followed by a space is not found, although the opening fence is trimmed | [`#L113-L137`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) | `l02_installer_functions`: 6 refusals out of 7 samples | Reproduced; affects only templates you add |
| The `name` field the installer requires names the command | Claude Code ignores `name` in a file under `commands/`; the path names the command | [Claude Code, skills](https://code.claude.com/docs/en/skills#where-skills-live) | — | Documented on both sides; a trap when renaming (lesson 2, exercise 1) |

## 2026-09-22 — The installer, read and run

SlashForge 4.4.3 (tag `v4.4.3`, commit `bd75a4f`), Node.js 24.21.0, Windows 11. The installer on `main` was the same file that day.

The course doesn't let the installer near the real `~/.claude`. `check.sh` points `HOME`, and `USERPROFILE` on Windows, at `out/home`, sets `SLASHFORGE_NO_UPDATE_CHECK=1` so that the version check doesn't reach npm, and runs every command with stdin from `/dev/null`, as CI does. That last choice shows a behaviour of its own: with no terminal, the installer answers yes to everything, uninstall included.

The dry run was the first surprise. I counted its lines by hand and got 23, which was wrong: `scripts/dry-run-vs-install.mjs` now does the counting, and says 21 against 32. The cause is in the code rather than in a missed update: the preview is a second path through the installer, and the real one gained assets in 4.1.0 and skills in 4.2.0 without it. I first wrote that the nine skills were *not installed*; they are, only not announced — the script's second list, *in the dry-run but not written*, is empty.

Lesson 2 calls the installer's exported functions instead of describing them, which is possible because loading `install.js` doesn't run it. Two measurements came from that lesson: which files differ between a global and a project install (nine: eight name a path, and `meta.json`), and the line counts that show the four commands are dispatchers for longer guides.

The broken-template check copies the package, deletes one `description:` line, and runs the copy into its own home directory: exit 1, and no file written.

## To verify

- Whether the model finds `.claude/setup/slashforge/…` when Claude Code is started in a subfolder of a repository with a project install (lesson 2).
- The token cost of each command, which the README estimates, on a public repository (lessons 3 to 5).
- Whether a skill written as a file in `commands/` is ever picked by the model on its own, or only when a guide names it.

## Open questions

- Would upstream take a dry run built from `installFiles` itself, the way PowerShell's `-WhatIf` goes through the same `ShouldProcess` as the action? Not proposed: nothing leaves this repository without the author's approval.
