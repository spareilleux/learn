---
title: 4. /slashforge:code — ten phases and four gates
description: Read the ten phases of SlashForge's development workflow and the four places where it waits for a person, then run its lean mode headless on a real fix in the lab and watch where it stops — a captured run, with its cost, and the one rule it bent.
sidebar:
  order: 4
---

Code: [`code/slashforge/lab/run.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/lab/run.sh), in the lab that [lesson 3](../03-setup-against-init/) builds. The run is e3 in the [journal](../journal/#experiments): one run on 2026-09-22, Claude Code 2.1.280, `claude-opus-5-5[1m]`.

## Ten phases, four gates

[`forge-workflow.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow.md) is the guide `/slashforge:code` sends the model to read. It has ten phases; four of them are marked *(Gate)*, which means the model asks and waits:

| Phase | What happens | Gate |
|---|---|---|
| 1 Freeform intake | the request; `slashforge:brainstorm` writes a design spec unless the change is trivial | |
| 2 Propose plan | `slashforge:plan` writes the plan | |
| 3 Confirm plan | | **yes** |
| 4 Branch decision | | **yes** |
| 5 Implement | TDD, debugging, parallel subagents as needed | |
| 6 Verify (lint, test, build) | `slashforge:verify`: *"no success claims without evidence"* | |
| 7 Code review | a `code-reviewer` agent | |
| 8 Push & PR | | **yes** |
| 9 PR review feedback | `slashforge:review-feedback` | |
| 10 Post-merge cleanup | | **yes** |

In .NET or Java terms, gates 3 and 4 are what a team settles in a ticket and a branch naming policy, and gate 8 is the pull request itself. The difference that matters is the one the [mission page](../) points out: a branch policy is enforced by the server, and a gate is a sentence the model is asked to obey. [`code.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/code.md) is emphatic about it — *"You MUST follow every phase in order. Do not skip phases. Do not combine phases."* — and an instruction, however emphatic, is still only an instruction.

## Lean mode

`-quick` loads [`forge-workflow-quick.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-quick.md) on top, which overrides phases in a table: Phase 1 is skipped, the plan keeps only *Changes* and *Test strategy*, Phase 5 uses one skill at most, and the agent review of Phase 7 becomes an inline checklist. The four gates are all marked **KEEP**, and so is Phase 6. The README gives lean mode *"~40–70k tokens per change"*, against 100–250k for the full workflow.

## The run: a real fix, up to the first gate

The change asked for is the one this course found in lesson 1 and that `/slashforge:investigate` diagnosed in [lesson 5](../05-investigate-and-review-pr/): make the dry run list everything the install writes.

```bash
bash lab/run.sh <lab> e3-code-quick 0.75 20 \
  "/slashforge:code -quick make bin/install.js --dry-run list every file that installFiles writes, including the skills and the two assets"
```

```
exit:      0
wall:      57 s
turns:     6
tokens:    in 10, cache write 23433, cache read 158847, out 1710
cost:      0.2534734 USD (as computed by Claude Code)
denials:   0
changed:   0 path(s) in the lab repository
```

It read the installer and its tests, wrote a lean plan and stopped:

```
Plan (lean)

Changes — `bin/install.js` only:
- Add an exported `plannedWrites(target, { guideFiles, assetFiles, commandFiles, skillFiles })` that returns `{ kind, src, dest }` entries in the same order `installFiles` writes them: guides (rendered), the 2 assets (copied), commands + skills (rendered), then `meta.json`.
- Replace the inline list in the `--dry-run` branch (`bin/install.js:499-527`) with a call to `plannedWrites`. …

Test strategy (TDD, `test/install.test.js`):
- Install into a temp dir and check that the `dest` list from `plannedWrites` equals the list `installFiles` returns. This keeps the two from drifting apart again.
- …

Two things I need from you before I start:
1. Plan: OK as written?
2. Branch: you're on `lab`. Should I work here, or create a new branch (for example `fix/dry-run-lists-all-writes` off `lab`)?
```

The plan is the right one. It is the fix lesson 1 suggested by comparison with PowerShell's `ShouldProcess`: one list, used by the preview and by the action, and a test that compares them so they cannot drift again. And no file changed: the gate held.

It held in a slightly different shape from the guide's, though. The run asked the Phase 3 question and the Phase 4 question in one message, where `code.md` says *"Do not combine phases"*. Here that costs nothing — both answers are needed before any edit, and a headless run would have stopped at the first one anyway. But it shows that the order of the phases is something the model interprets, not something that is enforced. If the order matters to you, it has to live somewhere that is enforced, such as a hook or a server-side rule; the [agentic coding course](../../agentic-coding/03-hooks-skills-subagents/) draws that line.

## What the run cost, and what it didn't measure

The run stopped after Phase 2, so it measures the fixed cost of getting to the first decision: 0.25 USD, 57 s. Against the README's *"~40–70k tokens"*, the answer depends on what you count: 1,720 tokens of fresh input and output, 23,433 written to the prompt cache, 158,847 read from it. Most of what the model reads is the same guides and files again on each turn, which the cache makes cheap but not free.

Past the gates, the lab can't go. Phase 5 would edit and run the tests, which the lab allows. Phase 8 would push and open a pull request, which the lab refuses, since the clone has no remote and `gh` is blocked, and should refuse: that is a decision with your name on it. Answering the gates one at a time, with `claude -p --resume` and a ceiling for each answer, is how you would measure the rest; the journal lists it as a decision for the author, with its budget.

## Key points

- `/slashforge:code` has ten phases; 3 (plan), 4 (branch), 8 (push and PR) and 10 (cleanup) wait for a person, and `-quick` keeps all four.
- A gate is an instruction to the model. The run respected the gate and bent the phase order, asking two gates in one message.
- Headless, the workflow stops at its first gate with no file changed. Here that took 6 turns, 57 s and 0.25 USD.
- The README's token ranges don't say how they count cached input, which is most of the input here.

## Exercises

1. The plan proposes an exported `plannedWrites` rather than a flag on `installFiles` that skips the writes. Give one argument for each design.
2. Answer the two questions of the run with `claude -p --resume`, one at a time, each with its own ceiling. Which phase stops the run next, and does the lab let it through?
3. The README says lean mode does not escalate by itself: *"if the plan reveals more than 2 files or a new abstraction, it stops and tells you to restart with `/slashforge:code`"*. Does this plan qualify?

<details>
<summary>Solution</summary>

1. A separate `plannedWrites` is a pure function of the target and the four lists: easy to test, and the dry run and the install both call it, so they share one list by construction. A `dryRun` flag inside `installFiles` shares even more — the same loop decides and acts — but mixes printing and writing in one function, and each new kind of file needs both branches. The plan's test, comparing the planned list with what `installFiles` returns, protects the first design against drift.
2. After *"OK"* and *"work here on `lab`"*, Phase 5 edits `bin/install.js` and `test/install.test.js` and runs `npm test`, which the lab allows (a `git commit` is not in its allowed list, so any commit is refused); Phase 6 verifies; the inline review of Phase 7 follows; Phase 8 is the next gate, and pushing is refused by the lab. Record the cost of each resumed run.
3. The plan touches two files, `bin/install.js` and `test/install.test.js`, which is not *more than 2*, and adds one exported function. Whether a function that replaces an inline list counts as a *new abstraction* is the model's judgement; in this run it judged that it didn't and stayed in lean mode.

</details>
