---
title: Journal
description: Dated notes for the AutoHarness course — the pinned commit, a static read of the plugin, six pre-registered fixtures run in isolation, the defects they reproduced, the harness's own bugs, the verdict and what remains to verify.
sidebar:
  order: 99
---

## Progress

- [x] AutoHarness pinned at `ca39a72`, read statically: lifecycle events, the use metric, ownership, robustness, authority, costs, tests; 14 hypotheses written down
- [x] Six fixtures pre-registered, then run in isolated subprocesses with no model and no install: `code/autoharness/fixtures.py`, hashed before the first run
- [x] Evaluation written, with evidence kept apart from claims: [`evaluation.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md), verdict **do not adopt** at `ca39a72`
- [x] Lesson 1: a fixture lab, six promises tested without installing
- [ ] Lesson 2: the loop and its authority boundaries (H4, H12, H14)
- [ ] Lesson 3: why use is not quality — counters, maturity, capacity (H1, H5)
- [ ] Lesson 4: crashes, concurrency and history (H8, H9, H11)
- [ ] Lesson 5: the evaluation and an adoption checklist
- [x] The fixtures on Linux and macOS: the same results, and CI now runs them on the three OSes

## QA

Every row is reproduced by [`fixtures.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/fixtures.py) or [`redact_probe.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/redact_probe.py) at commit `ca39a72` on Windows 11 with Python 3.14.2, with synthetic input, unless the status says *read*. Nothing has been reported upstream yet; that is a separate decision.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| Hand-written skills are never touched (README, lines 10, 23 and 229-230) | A `create` with the name of a hand-written skill replaces its body, keeps no copy, and stamps the skill as the agent's. An `update` of the same skill is refused | [`promoter.py#L51-L53`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L51-L53), [`#L158`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L158), [`#L129-L133`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L129-L133) | F1: `sentinel_survives: false`, `agent_created_after: true`, `archived_copy: false`; control `self_produced` | Reproduced, not reported ([2026-09-26](#2026-09-26--six-fixtures-run-in-isolation)) |
| The startup sweep removes AutoHarness's own leftovers | It deletes every `*.tmp` under the skills folder, a user's `draft.tmp` in a hand-written skill included, on an empty drain | [`skill_store.py#L82-L90`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/skill_store.py#L82-L90) | F5: `tmp_survives: false`, control `draft.txt` survives | Reproduced, not reported ([2026-09-26](#2026-09-26--six-fixtures-run-in-isolation)) |
| A bad line in the intent queue costs that line | One truncated line makes every drain raise `JSONDecodeError` before anything lands, and the queue is never cleared | [`intent_queue.py#L29-L33`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/intent_queue.py#L29-L33), [`promoter.py#L231-L240`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L231-L240) | F2: 2 drains, 2 `JSONDecodeError`, 0 of 2 valid intents landed, `queue_left: true`; control lands 2 | Reproduced, not reported ([2026-09-26](#2026-09-26--six-fixtures-run-in-isolation)) |
| Secrets are redacted before a window reaches the reflector | A key written as JSON, `{"api_key": "…"}`, and the body of a PEM private key pass through; so does `{"password": "…"}` | [`redaction_rules.toml#L10-L11`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L10-L11), [`#L25-L27`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L25-L27) | F3: the canary survives in 2 of 3 forms; control `api_key = …` redacted. Probe: the JSON `password` survives | Reproduced, not reported ([2026-09-26](#2026-09-26--six-fixtures-run-in-isolation)) |
| A redaction says which rule fired | A label can be redacted again by `api_key_assignment`, because it contains `secret:`: `[REDACTED:[REDACTED:secret:api_key_assignment]]` | [`redaction_rules.toml#L25-L27`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L25-L27) | F3's PEM header, and `Bearer …` in the probe | Reproduced, exploratory (not pre-registered) |
| Credentials in a URL are redacted | No rule targets them. In `postgres://admin:…@db.example.com/prod`, the email rule removes password and host together, by accident, and keeps the user name | [`redaction_rules.toml#L29-L31`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L29-L31) | Probe: `postgres://admin:[REDACTED:pii:email]/prod` | Reproduced, exploratory |
| A skill AutoHarness writes, it can read back | On Windows with a cp1252 locale, a non-ASCII body is written as UTF-8 and read back with the locale's codec: `UnicodeDecodeError` on byte 0x81 | [`atomic.py#L31-L32`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/atomic.py#L31-L32), [`skill_store.py#L26-L28`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/skill_store.py#L26-L28) | F4: raises with UTF-8 mode off; control `PYTHONUTF8=1` reads it back equal | Reproduced on Windows only, which the README's platform badge does not list; reproduced again on GitHub's `windows-latest` runner ([2026-09-27](#2026-09-27--the-fixtures-on-linux-windows-and-macos)) |
| Self-authored skills carry *"a `self-authored` ledger marker"* (README, lines 85-86) | Ownership is a `.sidecar.json` with `"created_by": "agent"`; the ledger is never consulted for it | [`sidecar.py#L47-L51`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/sidecar.py#L47-L51), [`#L75-L76`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/sidecar.py#L75-L76) | — | Read in the source, not run ([2026-09-26](#2026-09-26--reading-the-pinned-source)) |

## Experiments

Each hypothesis was written in [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/preregistration.md) before the first run. The file was hashed at 15:29:21 EDT (SHA-256 `b9dc7b7d…`), and edits made after the run are listed at its end. Every fixture ran in a fresh subprocess with an environment built from nothing and a disposable home; none wrote to that home, and the real `~/.claude/autoharness` was absent before and after. Run 2 equals run 1.

| Question | Hypothesis (written before the run) | Result | Verdict | Entry, code |
|---|---|---|---|---|
| F0 — Does the harness reach the promoter? | A valid `create` on a new name lands, stamped `created_by: agent` | `ok: true`, `agent_created: true` | Positive control passed | [2026-09-26](#2026-09-26--six-fixtures-run-in-isolation), [`fixtures.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/fixtures.py) |
| F1 (H2) — Does `create` take over a hand-written skill of the same name? | The ownership check covers only `update`, `patch`, `remove_file` and `delete`, so a `create` replaces the body and adopts the skill; the `update` control is refused | Control: refused, `self_produced`, body unchanged. `create`: `ok`, sentinel gone, sidecar `agent`, no archive | Confirmed | [2026-09-26](#2026-09-26--six-fixtures-run-in-isolation), [`fixtures-run.jsonl`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/fixtures-run.jsonl) |
| F2 (H10) — Does one truncated queue line block the run? | `read` parses every line before promoting and `clear` comes last, so both drains raise and the queue stays | Control: 2 landed, then 0, queue cleared. Treatment: `JSONDecodeError` twice, 0 landed, queue left | Confirmed | same |
| F3 (H13) — Does the redactor catch a JSON-quoted key and a PEM body? | No: the rule allows no quote before the colon, and the PEM rule matches the header only | Control redacted; the canary survives in `json_quoted` and in `pem` | Confirmed | same |
| F4 (new) — Does a non-ASCII skill survive a round trip on Windows? | No: written as UTF-8, read with cp1252, `UnicodeDecodeError` at 0x81; the `PYTHONUTF8=1` control reads it back equal | Exactly that | Confirmed, Windows only | same |
| F5 (H3) — Does the sweep delete a user's `*.tmp`? | Yes: every `*.tmp` under the skills folder, whoever wrote it; the `draft.txt` control survives | `draft.tmp` deleted; `draft.txt` and `SKILL.md` intact | Confirmed | same |
| F0–F5 on Linux and macOS — the same results? | Yes for F0–F3 and F5; F4's first run reads back equal, like its control, on a UTF-8 locale | WSL Ubuntu, Python 3.14.4: 0 differences, F4 equal with `utf8_mode: 1`. CI run [36364810915](https://github.com/spareilleux/learn/actions/runs/36364810915): `check.py` passes on `ubuntu-latest`, `windows-latest` and `macos-latest` | Confirmed; the reason was incomplete: the fixture's environment has no locale, and Python turns UTF-8 mode on in the C locale | [2026-09-27](#2026-09-27--the-fixtures-on-linux-windows-and-macos), [`check.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/check.py) |

## 2026-09-26 — Reading the pinned source

The brief pinned [`ca39a72`](https://github.com/tigerless-labs/autoharness/tree/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b), the head of `main` on 2026-09-25: 71 tracked files, about 7,000 lines, MIT licence. No code from it ran during this read.

What the source shows, in the order the evaluation keeps:
- **The loop runs without a person.**
  - Four hooks call one dispatcher.
  - Every 50 tool calls, and at session end, a background `claude -p --agent autoharness:reflector --dangerously-skip-permissions` on Haiku reads a redacted window and stages intents through an MCP tool.
  - The promoter lands them after each reflector exits and at every `Stop` of the main session.
- **Ownership is a plain JSON file.** `.sidecar.json` with `"created_by": "agent"` marks a skill as the agent's. The README calls it a ledger marker; the ledger plays no part in it.
- **No locks anywhere.** Comments in four modules defer them.
- **The index is not bounded by the capacity settings.** Skills on probation, and skills read but never invoked, are outside the capped pool but still get an index line.
- **The redactor has ten regular expressions.** None targets `sk-ant-` keys, JWTs or credentials in URLs.
- **The README's *42% → 78% on CORE-Bench*** is attributed to the [HAL paper](https://arxiv.org/abs/2510.11977). The repository contains no benchmark code, and its README says the project is validated *"in use, not on a benchmark"*. The `experiments/` and `docs/plans/` folders the README and comments cite are not in the tree at this commit.

Fourteen hypotheses came out of the read, H1 to H14. The ones that need no model and no hook were candidates for fixtures; the rest are listed in the evaluation's §2, for later lessons.

The upstream tests use no network and no model: `claude` is always replaced by a fake. Two need care:
- `test_layer.py` reads the real home and runs `git` in the real working directory;
- `test_spawn.py` needs a POSIX shebang.

I did not run the upstream suite.

## 2026-09-26 — Six fixtures, run in isolation

The pre-registration was hashed at 15:29:21 EDT. Two minutes later, the harness ran every fixture in its own subprocess:
- an environment built from nothing: `PATH` limited to the interpreter's folder, `PYTHONPATH` on the clone, and `HOME`, `USERPROFILE`, `TEMP` and `TMP` in a disposable folder;
- explicit skill roots for every call;
- no import of the module that starts `claude`.

The run took 14 seconds on Windows 11 with Python 3.14.2 (locale encoding cp1252).

Five hypotheses were **confirmed**, each against a control that behaved as intended, and the positive control passed. The details are in [lesson 1](../01-fixture-lab/). In short:
- a `create` takes over a hand-written skill (F1);
- one bad queue line stops promotion (F2);
- JSON keys and PEM bodies escape the redactor (F3);
- a non-ASCII skill cannot be read back on Windows (F4);
- an empty drain deletes a user's `*.tmp` (F5).

**Exploratory, not pre-registered:**
- A redaction label can be redacted again, which loses the name of the rule that fired first.
- A probe of the redactor found that `{"password": "…"}` survives, and that a URL password disappears only because the email rule happens to match `password@host`.

Both are in the QA table, marked exploratory.

The harness had the F4 bug itself. Its redirected stdout used cp1252, which garbled one string of run 1's display. That was fixed with `sys.stdout.reconfigure(encoding="utf-8")` and recorded as post-measurement edit 1. Run 2 decodes to the same eight lines.

**Verdict: do not adopt at `ca39a72`,** in real Claude Code sessions or in a real home. The reasons are measured, not read: F1 and F5 break the central promise, F2 stops the loop, and F3 leaks. The fixes look small:
- an existence check for `create`;
- a sweep limited to AutoHarness's own temporary names;
- per-line error handling;
- quoted keys in the rule.

The [evaluation](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md) lists what would change the verdict. A release that passes these fixtures again comes first, then a pilot in a disposable home with a fake or budget-capped reflector.

## 2026-09-26 — A harness that exited 0 on a run that measured nothing

At 23:20, the code README's commands were replayed from a fresh clone, as a reader would type them, with `--clone autoharness-ca39a72` as a relative path. Every child failed with `ModuleNotFoundError`: `PYTHONPATH` was relative, and the child's working directory is a temporary folder. The parent printed the failures as results and **exited 0**.

The fixes:
- the clone path is made absolute;
- a crashed child's line still names its fixture;
- the parent exits 1 if any child exits non-zero.

`redact_probe.py` got the same path fix. The rerun, with a relative and then an absolute path, is byte-identical to the recorded output. The failure path was checked on purpose: a nonexistent clone now gives `exit: 1`. This is post-measurement edit 3. The results did not change; what changed is that a broken run can no longer pass for a measurement.

## 2026-09-27 — The course pages

The mission, lesson 1 and this journal were written in English, French and Spanish from the recorded outputs, and the course was added to the sidebar and the home pages. `fixtures.py --hashes` was rerun and gave the six pre-registered hashes. `redact_probe.py` now sets `sys.dont_write_bytecode` before it imports `fixtures.py`, so it no longer leaves a `__pycache__` folder in the course directory; its rerun is byte-identical to `redact-probe.jsonl`. No fixture was rerun, and no result changed.

## 2026-09-27 — The fixtures on Linux, Windows and macOS

Codex's review of the PR asked for the course code to run in CI on the three OSes, as the repository's conventions require. [`check.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/check.py) reruns `fixtures.py` and compares every line with `fixtures-run.jsonl`. The one exception was written before any run elsewhere: off Windows, F4's first run must read back equal, as the "To verify" list predicted.

- **This machine.** On Windows 11 with Python 3.14.2: 0 differences. Under WSL, on Ubuntu with Python 3.14.4: 0 differences, and F4's first run read back equal with UTF-8 mode on (`utf8_mode: 1`).
- **The negative control.** A copy of the expected file with one value changed (`tmp_survives`) makes `check.py` print that difference and exit 1.
- **CI.** The [`autoharness-examples`](https://github.com/spareilleux/learn/blob/main/.github/workflows/autoharness-examples.yml) workflow passed on `ubuntu-latest`, `windows-latest` and `macos-latest` ([run 36364810915](https://github.com/spareilleux/learn/actions/runs/36364810915)). It fetches AutoHarness by its pinned SHA, installs nothing and calls no model. On GitHub's Windows runner F4 reproduces exactly: the same `UnicodeDecodeError` at byte 0x81.

The prediction held, but its reason was incomplete. The fixture's environment is built from nothing, so it has no locale, and in the C locale Python turns UTF-8 mode on ([PEP 540](https://peps.python.org/pep-0540/)). That was measured under WSL. The macOS runner's value is in its log, which was not read here.

## To verify

- Why F4 reads back equal on the macOS runner: UTF-8 mode, as under WSL, or the locale's codec. `check.py` prints it in the job's log.
- F4 on Windows with Python 3.15, where [PEP 686](https://peps.python.org/pep-0686/) makes UTF-8 mode the default.
- The hypotheses not yet run:
  - H1: the index is not bounded by capacity;
  - H4: a repository that ships a `.sidecar.json` makes a skill "managed";
  - H5: one malformed sidecar stops the index for a session;
  - H8, H9: an intent lost between read and clear, and overlapping reflection windows;
  - H11: a second archive deletes the first;
  - H12: the fork carrier leaves `Bash` available;
  - H14: a committed `interactive.jsonl` is drained at the first `Stop`.
- Whether `rglob("*.tmp")` descends into a symlinked skill folder, which depends on the Python version.
- The upstream test suite, run in isolation.

## Open questions

- How often would the reflector propose a `create` whose name collides with an existing skill? F1 shows nothing prevents it; only a model run with a fake or capped budget can say how likely it is.
- AutoHarness counts a skill as *used* when the model calls the `Skill` tool, before the call is allowed or runs. How far is that from *useful*, and what does it do to a rare safety skill?
- Would a hand-kept journal and skill update, checked against held-out tests, do as well as the loop, at a known cost?
- Should these findings be reported upstream, and in what form? Not decided yet.
