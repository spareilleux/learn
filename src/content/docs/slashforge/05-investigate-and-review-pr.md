---
title: 5. /slashforge:investigate and /slashforge:review-pr
description: Run SlashForge's read-only investigation on a bug this course already knows, and its pull-request review with GitHub logged out, in the lab — what each found, where each stopped, what each cost, and the file that one run wrote outside the repository because the lab allowed it.
sidebar:
  order: 5
---

Code: [`code/slashforge/lab/run.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/lab/run.sh), in the lab of [lesson 3](../03-setup-against-init/). The runs are e1, e1b and e4 in the [journal](../journal/#experiments): 2026-09-22, Claude Code 2.1.280, `claude-opus-5-5[1m]`. Lesson 4 covered `-quick`.

## `/slashforge:investigate`: a symptom in, a report out

[`investigate.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/investigate.md) is a dispatcher for [`forge-workflow-investigation.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-investigation.md), which has three phases: I1 intake (it asks for the symptom only if you gave none), I2 investigate, *"read-only … No edits to application code"*, and I3 report and hand-off. There is no gate: with a symptom, the flow runs to the end. What it produces is an HTML findings report under `docs/slashforge/investigations/`, and a hand-off line for `/slashforge:code`.

The symptom given was lesson 1's finding, so the answer is known in advance:

```bash
bash lab/run.sh <lab> e1b-investigate 0.50 10 \
  "/slashforge:investigate bin/install.js --dry-run lists 21 files but an install writes 32"
```

Both runs found it. From e1's final message:

```
Confirmed. `--dry-run` doesn't ask the real installer what it will write. It builds its own list at `bin/install.js:499-530`, and that list only includes `GUIDE_FILES` (16), `COMMAND_FILES` (4) and the meta file (1), for a total of 21.

The real writer, `installFiles()` at `bin/install.js:214-279`, also writes `ASSET_FILES` (2, line 247) and `SKILL_FILES` (9, line 252). 21 + 2 + 9 = 32, which accounts for the whole gap.
```

It added the `copy` label that lesson 1 also found, one thing the course hadn't written down — the dry run doesn't mention the stale `REMOVED_GUIDE_FILES` that an install deletes — and a suggested fix: a planning function shared by both paths, with a regression test. Read-only held: after both runs, `git status` in the lab repository was empty.

## The report that wasn't written

Phase I3 doesn't let the model write the report in one go. The report's HTML shell, with all its CSS, ships as `forge-report-shell.html`; the model writes only the body, and a *"substitution step splices the two together"*, so that reports don't drift apart and the CSS doesn't cost output tokens every time. The splice is a [`node -e` script](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-investigation.md#L99-L112), inline in the guide — and the lab allows `node` only for the tests and the installer's dry run. So in both runs the splice was refused, and no report exists.

What each run did next is the interesting part.

**e1**, in the first version of the lab, which listed `Edit` and `Write` among the allowed tools. Refused `node`, the model wrote the splice as a script, `sf-splice.js`, into `%TEMP%` — outside the repository — and ended its message by asking the user to run it:

```
Report: the splice script with the full report body is at `C:/Users/spare/AppData/Local/Temp/sf-splice.js`. To create the report, run `node C:/Users/spare/AppData/Local/Temp/sf-splice.js`.
```

Nothing broke the rules as the lab had stated them: `Write` was allowed, without a path. That is exactly the trap. In Claude Code's [permission rules](https://code.claude.com/docs/en/permissions), a tool listed in `--allowedTools` without a specifier is allowed *everywhere*; `--permission-mode acceptEdits` on its own accepts edits *"for paths in the working directory or `additionalDirectories`"*. The lab now relies on the second and lists every file that appears in the temp folder during a run.

**e1b**, with the fixed lab: no write outside, no report, and the run ended on the turn limit, at 11 turns out of 10, with `error_max_turns`, having spent 0.38 USD. Its three refused commands were two dry runs of the installer in a temporary home directory and the splice itself.

| Run | Lab | Turns | Cost | Report | Outside the repository |
|---|---|---|---|---|---|
| e1 | `Write` allowed without a path | 15 | 0.45 USD | no | `%TEMP%\sf-splice.js`, 4,175 bytes |
| e1b | `acceptEdits` only | 11 (limit 10) | 0.38 USD | no | nothing |

Two limits of the measurement. Neither run produced the report, so the half of the hypothesis about it is untested. And e1 reported 15 turns under the same `--max-turns 10` and finished normally, where e1b was stopped; why is noted in the journal as *to verify*. The README expects *"~15–60k tokens"*; both runs read more than 350,000 tokens from the prompt cache, most of it the same files on each turn.

## `/slashforge:review-pr`: stopped at the door

[`review-pr.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/review-pr.md) starts with a preflight: *"`gh` must be installed and authenticated, or nothing here works"*, and if it isn't, *"stop and tell the user to run `gh auth login`. Do not attempt a workaround."* The lab has its own, empty `GH_CONFIG_DIR`, so `gh` is logged out; for this run only, `GH_STATUS_ONLY=1` allowed `gh auth status` and still refused every other `gh` command.

```bash
GH_STATUS_ONLY=1 bash lab/run.sh <lab> e4-review-pr 0.25 5 "/slashforge:review-pr"
```

```
I stopped at the preflight check because the GitHub CLI isn't logged in. `gh auth status` failed, so I couldn't list PRs or read any PR data. Nothing was read from GitHub and nothing was written.
```

4 turns, 35 s, 0.17 USD, no workaround attempted. That is the cheapest possible run of the command, and the hypothesis written before it was confirmed word for word.

Past the preflight, the workflow has two gates. R1 asks which PR to review. R5, before anything is posted, is the strictest gate in the kit: it shows *"the exact text that will appear on GitHub"*, asks *"Post this review? `approve` · `comment` · `request-changes` · `edit` · `cancel`"*, and says *"Never infer the choice from severity."* A review is public and signed with your name; the lab never reaches R5, and shouldn't.

## Three commands, one pattern

| | investigate | review-pr | code `-quick` (lesson 4) |
|---|---|---|---|
| First stop in the lab | the report splice, refused | the `gh` preflight | the plan gate |
| Files changed in the repository | 0 | 0 | 0 |
| Cost of the run | 0.38–0.45 USD | 0.17 USD | 0.25 USD |

Each command did what its file says, up to the point where the lab or a person had to say yes. The one surprise came from the lab, not from SlashForge: given a tool with no path attached, the model used it to get the job done another way. When you give an agent permissions, write down the path along with the tool.

## Key points

- `/slashforge:investigate` has no gate when given a symptom; it stayed read-only and found the root cause this course found by comparison.
- Its report is spliced by a `node` command. A lab that refuses `node` gets no report; one that allows `Write` everywhere may get a script somewhere else instead.
- A tool in `--allowedTools` without a path is allowed everywhere; `acceptEdits` alone confines edits to the working directory.
- `/slashforge:review-pr` stops at its preflight when `gh` is logged out, as its file says, and never posts without an explicit choice at R5.

## Exercises

1. Write the permission rule that would let the report splice run in the lab without allowing `node` in general. What would you need to know about the command first?
2. Why does Phase I3 splice a fixed shell rather than let the model write the whole HTML file? Give the two reasons in the guide and one it doesn't give.
3. In e4, which of the lab's settings made `gh auth status` fail, and what would have happened with your real `gh` configuration?

<details>
<summary>Solution</summary>

1. You can't, with the guide as it is. The splice is `node -e '<script>' <shell> <fragment> <report> <title>`, and a `Bash` rule matches a command by its prefix: `Bash(node -e:*)` would allow any script at all, which is as wide as allowing `node`. The narrow version needs the script to be a file, the way `forge-open.sh` is: ship the splice as, say, `forge-splice.js` next to the shell, and allow `Bash(node <install path>/forge-splice.js:*)`. Until then, the safe option is to run the splice yourself from the body fragment the model wrote.
2. The guide: the CSS is identical in every report, so regenerating it *"wastes output tokens"*, and it *"lets reports drift apart visually"*. One more: a fixed shell is a fixed attack surface. The 4.1.2 changelog fixed a title that could close `</title>` early; a shell the model rewrites each time would have to get that escaping right each time.
3. `GH_CONFIG_DIR` pointed at an empty directory inside the lab, so `gh` found no login. With your real configuration, `gh` would have been logged in, the preflight would have passed, and R1 would have listed the pull requests awaiting your review — reading GitHub on your behalf, which is why the lab isolates it.

</details>
