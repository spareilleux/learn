---
title: 2. Inside the files — commands, skills, guides
description: How a file under commands/ becomes /slashforge:code, what the frontmatter is for when two different programs read it, what the installer refuses and why it refuses before writing anything, how {{INSTALL_PATH}} makes a global install absolute and a project install relative, and how four short commands delegate to long guides.
sidebar:
  order: 2
---

Code: [`code/slashforge/check.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/check.sh) and [`scripts/installer-functions.mjs`](https://github.com/spareilleux/learn/blob/main/code/slashforge/scripts/installer-functions.mjs), which calls the installer's own functions. The outputs are in [`expected/`](https://github.com/spareilleux/learn/tree/main/code/slashforge/expected).

The installer [exports](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L660-L676) the functions it is built from, and loading it doesn't run it — its entry point is guarded by [`require.main === module`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L652-L658), Node's equivalent of a `Main` that only runs when the assembly is the entry assembly. So instead of describing what it does, this lesson calls it.

## A path becomes a name

```
# A file path under commands/ becomes the name you type
slashforge/setup.md            /slashforge:setup
slashforge/code.md             /slashforge:code
slashforge/investigate.md      /slashforge:investigate
slashforge/review-pr.md        /slashforge:review-pr
slashforge/brainstorm.md       /slashforge:brainstorm
slashforge/plan.md             /slashforge:plan
slashforge/debug.md            /slashforge:debug
slashforge/tdd.md              /slashforge:tdd
slashforge/verify.md           /slashforge:verify
slashforge/review-feedback.md  /slashforge:review-feedback
slashforge/request-review.md   /slashforge:request-review
slashforge/worktree.md         /slashforge:worktree
slashforge/parallel.md         /slashforge:parallel
```

The installer's [`commandName`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L186) applies the rule Claude Code documents for [how a skill gets its command name](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name): for a file in a subdirectory of `commands/`, *"subdirectory path relative to `commands/` with each `/` replaced by `:`, then the file name without extension"*. It is routing by folder, the way an ASP.NET area or a Java package turns a directory into a prefix. Nothing inside the file takes part. The prefix is also the whole collision strategy: a `/code` command of your own and `/slashforge:code` can live side by side.

## The frontmatter has two readers

Each file starts with a block of frontmatter between `---` lines. Here is [`code.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/code.md):

```markdown
---
name: /slashforge:code
description: End-to-end development workflow — gather requirements, plan, confirm, branch, implement, verify, review, push, PR. Pass `-quick` for lean mode on small changes (skips brainstorming, minimal plan, inline self-review instead of the agent review). Uses SlashForge's own skills at each phase — no plugins required.
---
```

Two programs read this block, for different reasons. The installer reads it to [refuse a broken template](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137), and requires `name` and `description`. Claude Code reads it to configure the command — and for a file in `commands/`, its documentation says the file [*"supports the same frontmatter except `name` and `paths`"*](https://code.claude.com/docs/en/skills#where-skills-live). The one field the installer insists on is one Claude Code doesn't use for this kind of file. `name: /slashforge:code` is a label for humans and for the installer's check; the command's name comes from the path, as above. Rename the file and the command changes name; edit the `name` line and nothing happens.

The two readers don't parse the same way either. Claude Code reads YAML. The installer reads [line by line](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137): every non-blank line between the fences must look like `key: value`, with a key made of letters, digits, `_` and `-`. Calling `parseFrontmatter` on a few samples:

```
# What the frontmatter check refuses
no opening fence: demo.md: missing opening '---' frontmatter fence
no closing fence: demo.md: missing closing '---' frontmatter fence
no description: demo.md: frontmatter missing required field 'description'
a key with a space: demo.md: invalid frontmatter at line 3: "long description: d"
a closing fence with a trailing space: demo.md: missing closing '---' frontmatter fence
a folded YAML description: demo.md: invalid frontmatter at line 4: "  two lines"
valid: ok {"name":"/demo","description":"d"}
```

The folded description is valid YAML, and Claude Code would read it as one line of text. The installer refuses it. Neither is wrong about its own job — the installer only has to accept the twenty-nine templates it ships, and they all use one-line values — but a check that is stricter than the runtime it guards is worth knowing about before you add a template of your own and wonder why a file Claude Code accepts won't install.

## Refused before anything is written

`check.sh` copies the package, deletes the `description:` line of one skill, and runs that copy's installer into another empty home directory:

```
Template validation failed:
  ✗ slashforge/verify.md: frontmatter missing required field 'description'
Error: Refusing to install with invalid templates.
exit 1
```

and then lists the files in that home directory: none. The [`install` function](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L477-L483) validates all four lists before it creates a single folder, and a [comment](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L142-L143) gives the reason: *"a half-installed kit is worse than none"*. It is the pattern of a batch validated in full before `SaveChanges`, rather than saved row by row until one fails.

## `{{INSTALL_PATH}}`: absolute in one mode, relative in the other

A command has to tell the model where the guides are. The templates write `{{INSTALL_PATH}}`, and the installer [replaces it](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L175-L180) — together with `{{KIT_VERSION}}` and `{{KIT_PACKAGE}}` — when it writes the file. What it replaces it with depends on the mode:

```
# The two install modes
global   guides   /home/ada/.claude/setup/slashforge
global   commands /home/ada/.claude/commands
global   {{INSTALL_PATH}} = /home/ada/.claude/setup/slashforge
project  guides   /src/app/.claude/setup/slashforge
project  commands /src/app/.claude/commands
project  {{INSTALL_PATH}} = .claude/setup/slashforge
```

In a global install the path is absolute, and always written with `/`, Windows included. In a project install it is relative to the repository. One line of `code.md`, as shipped and after each install:

```
# template
- **The argument contains `-quick`** → **LEAN MODE.** Read `{{INSTALL_PATH}}/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# global
- **The argument contains `-quick`** → **LEAN MODE.** Read `~/.claude/setup/slashforge/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# project
- **The argument contains `-quick`** → **LEAN MODE.** Read `.claude/setup/slashforge/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# placeholders left in the installed files
global  0
project 0
```

(`check.sh` writes the throwaway home as `~`; the installed file contains the full absolute path.) That relative path is what makes a project install committable: an absolute path would contain the name of whoever ran the installer. It also means the model has to resolve the path from the repository's root. Whether it still finds the guides when Claude Code is started in a subfolder is *to verify*: that depends on the model and on its working directory, not on the installer.

Comparing the two installs file by file shows exactly where the modes differ, with the number of changed lines:

```
  2  ./commands/slashforge/brainstorm.md
  3  ./commands/slashforge/code.md
  2  ./commands/slashforge/investigate.md
  2  ./commands/slashforge/plan.md
  2  ./commands/slashforge/review-pr.md
 18  ./commands/slashforge/setup.md
  3  ./setup/slashforge/forge-workflow-investigation.md
  2  ./setup/slashforge/forge-workflow-review-pr.md
  2  ./setup/slashforge/meta.json
```

Eight files name a path, and `meta.json` records the mode and the time. The other twenty-three are identical. Until 4.4.1 the guides were copied rather than rendered, so a guide could not name another file by its path; the [changelog](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/CHANGELOG.md) records that fix, and the two guides above are the ones that needed it.

This table is also the proof of what [lesson 1](../01-what-the-installer-writes/#what-the-dry-run-doesnt-announce) read in the changelog: the dry run still says `copy   forge-workflow-review-pr.md`, and a copied file could not differ between the two modes.

## Short commands, long guides

The four entry points are small. Most of what they do is in the guides they send the model to read:

```
 110  slashforge/setup.md
  70  slashforge/code.md
 165  forge-workflow.md
  46  forge-workflow-agents.md
  94  forge-workflow-quick.md
  51  slashforge/investigate.md
 154  forge-workflow-investigation.md
  67  slashforge/review-pr.md
 302  forge-workflow-review-pr.md
```

`code.md` holds the mode selection and the entry question, then says:

```markdown
## Workflow files

Read the following in full — together they are your complete workflow guide:

- {{INSTALL_PATH}}/forge-workflow.md
- {{INSTALL_PATH}}/forge-workflow-agents.md

You MUST follow every phase in order. Do not skip phases. Do not combine phases.
```

The changelog calls this shape *a dispatcher plus a workflow file*. `review-pr.md` was 301 lines until 4.4.1 moved its phases to `forge-workflow-review-pr.md`, and `investigate.md` 143 lines until 4.4.2 did the same, *"so I3 existed twice, in two levels of detail, and the two could drift"*. It is the same refactoring as moving logic out of a controller into a service: the entry point stays small enough to read at a glance, and each rule is written once.

There is a cost the table doesn't show. A command file is loaded when you type it; a guide is loaded when the model decides to read it, as a tool call, and it counts against the conversation like any file it reads. `/slashforge:code` asks for 211 lines of guides before its first question.

## Skills that are command files

The nine skills are files of the same kind, in the same folder. [`verify.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/verify.md) begins:

```markdown
---
name: /slashforge:verify
description: Evidence before claims. Use before stating that anything is done, fixed, passing, or ready — and before committing, opening a PR, or handing off. Requires running the verification command and reading its output first.
---

<!--
Adapted from the `verification-before-completion` skill in superpowers.
Copyright (c) 2025 Jesse Vincent. Licensed under the MIT License.
```

They are adapted from [superpowers](https://github.com/obra/superpowers), and each carries the MIT notice in an HTML comment, because the files are installed far from the repository that holds the licence. Claude Code has two formats for this: a [skill](https://code.claude.com/docs/en/skills) proper is a folder with a `SKILL.md` and room for supporting files, and a file in `commands/` is *"the older format"* that *"still works"*. SlashForge uses the older one for all thirteen files, which is what lets one folder give them one prefix. The workflow doesn't wait for the model to pick a skill: the guides name the one to use at each phase — `slashforge:plan` in Phase 2, `slashforge:verify` in Phase 6, and so on.

## Key points

- A file's path under `commands/` is its name; the `name` field of a command file is ignored by Claude Code and required by SlashForge's installer.
- The installer's frontmatter check is a line parser, stricter than the YAML Claude Code reads: a folded `description: >` is refused.
- Every template is validated before the first file is written, so a broken package installs nothing.
- `{{INSTALL_PATH}}` is absolute in a global install and relative in a project install; eight files use it, which is why they are the only ones that differ between the two modes.
- The four commands are dispatchers of 51 to 110 lines; the workflow itself is in guides of up to 302 lines that the model reads on demand.

## Exercises

1. You rename the installed `commands/slashforge/verify.md` to `check.md` and leave its frontmatter alone. What do you type now to run it, and what happens the next time you run the installer?
2. The installer checks four lists before writing. Suppose it validated each file just before writing it instead. What would the empty-`description` experiment above leave in the home directory?
3. In `l02_global_vs_project`, `setup.md` differs in 18 lines and `code.md` in 3. Without opening the files, what does that tell you about the two commands?

<details>
<summary>Solution</summary>

1. `/slashforge:check`: the name comes from the file's path, and Claude Code ignores `name` in a command file, so the old `name: /slashforge:verify` line changes nothing. The next install writes `verify.md` again, because the installer works from its own list, not from what is on disk — and you then have two commands with the same content, `/slashforge:check` and `/slashforge:verify`. The guides still send the model to `slashforge:verify`, so your renamed copy is the one nothing uses.
2. The files written before `verify.md` in the installer's order: the sixteen guides, the two assets and the commands and skills before it in `[...COMMAND_FILES, ...SKILL_FILES]` — `setup`, `code`, `investigate`, `review-pr`, `brainstorm`, `plan`, `debug`, `tdd` — without `meta.json`, which is written last: 26 files. A kit whose Phase 6 skill is missing, and that [`status`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L439-L457) would describe as *"unknown (legacy install — no meta.json)"*, since the guides folder exists but `meta.json` doesn't.
3. That `setup.md` names the guides by path many more times: it is the command that sends the model to most of them — rules, skills, agents, commands, hooks, memory — one line each, while `code.md` names three. The line counts are a map of which command depends on which guides, drawn by a `diff`.

</details>
