# AutoHarness at `ca39a72` — evaluation

- Specimen: [tigerless-labs/autoharness](https://github.com/tigerless-labs/autoharness) at [`ca39a72e4353ebef11b7de13c1fc7fa5f4df421b`](https://github.com/tigerless-labs/autoharness/tree/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b) (2026-09-25). MIT licence.
- Question: should this course's author enable AutoHarness in real Claude Code sessions?
- Written 2026-09-26.

This file keeps evidence apart from claims:
- **§1** is what was run, with its output.
- **§2** is what was read in the source and not run.
- **§3** compares the README's claims with §1 and §2.
- **§4** lists what is missing.
- **§5** is the verdict, and it rests on §1 only.

## 1. Evidence — measured

Setup:
- Windows 11, Python 3.14.2, preferred encoding cp1252.
- Command: `python fixtures.py --clone <clone>`, run twice. Run 2 equals run 1, line for line.
- Hypotheses were pre-registered in `preregistration.md` before the first run: SHA-256 `b9dc7b7d…`, 15:29:21 EDT.
- Raw output: `fixtures-run.jsonl`.

Isolation, checked in the same run:
- each fixture ran in a fresh subprocess, in an environment built from nothing, with a disposable `HOME`/`USERPROFILE`;
- 0 files were written under that `HOME` by any fixture;
- the real `~/.claude/autoharness` was absent before and after;
- nothing imported `hook.spawn`, so no `claude` process and no LLM call.

| Fixture | Control | Measured | Verdict |
|---|---|---|---|
| F0: a valid `create` on a new name lands | — | `ok: true`, sidecar `created_by: agent` | the harness reaches the promoter |
| F1 (H2): `create` named like a hand-written skill | `update` on the same skill: rejected `self_produced`, body unchanged | `create` ok, the sentinel line is gone, the sidecar now says `agent`, no archived copy | **confirmed** |
| F2 (H10): a truncated line between two valid intents | the same queue without it: 2 landed, then 0, queue cleared | both drains raise `JSONDecodeError`, 0 landed, the queue file stays | **confirmed** |
| F3 (H13): secret written as a JSON key, and a PEM body | `api_key = <canary>`: redacted | the canary survives in `{"api_key": …}` and in the PEM body | **confirmed** |
| F4 (new): a non-ASCII skill body read back on Windows | `PYTHONUTF8=1`: equal | written as UTF-8, and reading it back raises `UnicodeDecodeError` (byte 0x81, cp1252) | **confirmed**, Windows only |
| F5 (H3): the startup sweep and a user's `draft.tmp` | `draft.txt` next to it survives | `draft.tmp` deleted, `draft.txt` and `SKILL.md` intact | **confirmed** |

Exploratory results, not pre-registered:
- **Nested labels.** A match of one rule can itself be matched by `api_key_assignment`, because its label contains `secret:`. The output is `[REDACTED:[REDACTED:secret:api_key_assignment]]`, and the name of the rule that fired first is lost. Seen in F3's PEM header and in `redact-probe.jsonl`.
- **Redaction probe** (`redact_probe.py`, output `redact-probe.jsonl`):
  - `password: hunter2hunter2` is redacted, but `{"password": "hunter2hunter2"}` is not;
  - `Bearer …` is redacted inside JSON too;
  - in `postgres://admin:hunter2hunter2@db.example.com/prod`, only `hunter2hunter2@db.example.com` is replaced, by the **email** rule. The user name stays, and the password disappears only by accident.

The harness had the F4 bug too. Its own redirected stdout used cp1252 until `sys.stdout.reconfigure(encoding="utf-8")` was added. This is recorded as a post-measurement edit; the measurements did not change.

## 2. Read in the source, not run

Each line gives its place at the pin. Lines marked **H** are hypotheses for later lessons.

- **The loop runs without a person.**
  - Every hook runs `python3 -m autoharness.hook.dispatch` (`hooks/hooks.json`).
  - The reflector is `claude -p --agent autoharness:reflector --dangerously-skip-permissions` on `haiku` (`src/autoharness/hook/spawn.py` `build_command`; `agents/reflector.md`).
  - The promoter drains the queue after each child and at every main-session Stop (`promoter.py` `drain`, called from `spawn.py` and `dispatch.py`).
- **Ownership is a plain JSON file**: `.sidecar.json` with `"created_by": "agent"` (`sidecar.py` `create`, `is_agent_created`). Any repository that ships one makes a skill "managed" — **H4**.
- **No locks anywhere.** Comments defer them (`promoter.py` docstring, `sidecar.py`, `counters.py`, `ledger.py`). A read-then-unlink queue can lose an intent appended in between — **H8**. A reflection window can overlap the next one — **H9**.
- **Capacity does not bound the index.** Probation skills, and spared skills with `use=0, view>0`, are outside the capped pool but still indexed — **H1**. A malformed sidecar would stop the whole index for a session — **H5**.
- **The fork carrier** (`AUTOHARNESS_CARRIER=fork`) passes no `--agent`, so the hook denies only `Write|Edit|MultiEdit|NotebookEdit`, and `Bash` stays available under `--dangerously-skip-permissions` — **H12**.
- **A repository that commits `.claude/autoharness/intents/interactive.jsonl`** has it drained at the first Stop. A `create` with `level: "global"` would land in `~/.claude/skills` — **H14**.
- **Archiving an existing name** removes the older archive (`skill_store.archive` `rmtree`) — **H11**.
- **The upstream tests** use no network and no LLM. `test_layer.py` reads the real `HOME` and cwd and runs `git`. `test_spawn.py` needs a POSIX shebang. I did not run the upstream suite.

## 3. Claims against evidence

| README says (at the pin) | Evidence | Status |
|---|---|---|
| *"touching only the skills it wrote itself"* (L10); *"Only its own skills … everything else, whether you wrote it or installed it, is left completely alone"* (L23); *"Yours are never touched … invisible to the promoter"* (L229-230) | F1: a `create` replaces a hand-written `SKILL.md` and stamps it as the agent's. F5: the sweep deletes a user's `*.tmp` inside a hand-written skill | **contradicted** by F1 and F5, on synthetic input |
| Self-authored skills carry *"a `self-authored` ledger marker"* (L85-86) | The marker the code checks is `.sidecar.json`, not the ledger (§2) | contradicted by reading; not run |
| *"Validated in use, not on a benchmark"* (L22) | The repository has no benchmark code, and the 42% → 78% figure (L13) is attributed to the HAL paper, not measured here | consistent |
| Platform badge: Linux, macOS (L5) | F4 fails on Windows only | F4 is **outside the stated platforms**. It matters only to someone running it on Windows |

## 4. Missing evidence

- **Everything that involves the model:** what the reflector writes, how often it proposes a `create` whose name collides with an existing skill, what a session costs. Nothing here says how *likely* F1 is in real use, only that nothing stops it.
- **Linux and macOS.** F0–F3 and F5 do not depend on the OS in the code read. That is *to verify* on those systems, and so is F4's expected pass on UTF-8 locales.
- **The hook entry point** (`dispatch`), H1, H4–H9, H11, H12, H14, and the upstream test suite.
- **Upstream reporting:** nothing was filed. Whether to report, and in what form, is a separate decision, not taken here.

## 5. Verdict

**DO NOT ADOPT** at `ca39a72` in real Claude Code sessions or in a real home directory.

Reasons, from §1 only:
- The project's central safety promise is that hand-written skills are never touched. Two fixtures break it (F1, F5), each with a passing control.
- One truncated queue line stops promotion permanently until someone deletes the file (F2).
- The redactor misses secrets in the JSON form that transcripts use (F3).

These are small, local defects:
- F1 needs an existence check for `create`;
- F5 needs the sweep to match AutoHarness's own temp-file names;
- F2 needs per-line error handling;
- F3 needs quoted keys in the rule.

The design has good parts that §2 records: atomic writes, strict name and path checks, and tests without a network.

What would change the verdict:
1. A release that fixes F1, F2, F3 and F5, and passes `fixtures.py` rerun at the new pin with the same controls.
2. Then a pilot in a disposable home with a fake or budget-capped reflector, measuring what the model proposes (the missing evidence in §4).
3. Only after that, a pilot on a real project, with its skills backed up.
