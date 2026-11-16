# AutoHarness fixtures — pre-registration

Written 2026-09-26, before any fixture was run. Nothing below this heading's "Post-measurement edits" section is changed after the run; results go to `evaluation.md`.

- Source: `https://github.com/tigerless-labs/autoharness`, commit `ca39a72e4353ebef11b7de13c1fc7fa5f4df421b`. `fixtures.py` refuses to run on any other commit.
- Harness: `code/autoharness/fixtures.py`. Input hashes come from `python fixtures.py --hashes` (the SHA-256 of each fixture's inputs as canonical JSON). They are computed without importing AutoHarness.
- Environment: Windows 11, Python 3.14.2, preferred encoding cp1252, UTF-8 mode off unless stated.
- Isolation, for every fixture:
  - a fresh subprocess with an environment built from nothing: `PATH` (the interpreter's folder only), `PYTHONPATH=<clone>/src`, and `HOME`, `USERPROFILE`, `TEMP` and `TMP` pointing into a disposable directory, plus `SYSTEMROOT` on Windows;
  - no inherited variable, so no credentials and no `AUTOHARNESS_*` settings;
  - the working directory is inside the disposable directory;
  - every call gets explicit `roots`;
  - only `hook.promoter` and `lib.{intent_queue, layer, redact, sidecar, skill_store}` are imported. `hook.spawn` is not imported, so nothing starts `claude` and nothing calls an LLM.
- Command: `python fixtures.py --clone <clone>`, run once under the lane's heavy lock.
- Stop conditions, for all fixtures:
  - a fixture writes anything under the disposable `HOME`: this counts as a leak and is reported;
  - the real `~/.claude/autoharness` appears when it did not exist before: stop, and report it;
  - a subprocess runs longer than 60 s;
  - an import pulls in `spawn` or tries the network. Neither is expected: the modules above are standard library only.

The upstream tests I read before running anything:
- `tests/test_promoter.py`:
  - `test_update_requires_agent_created` covers F1's negative control;
  - `test_drain_sweeps_orphan_tmp` covers F5, with a `*.tmp` that is AutoHarness's own;
  - no test creates over an existing hand-written skill;
  - no test feeds `drain` a malformed queue line.
- `tests/test_redact.py`: it tests `api_key=` without quotes and a PEM header on one line, never a JSON key or a PEM body.
- `tests/test_e2e_live.py`: a skipped placeholder. I do not run it.

## F0 — positive control

- Question: does the harness reach the promoter at all?
- Input hash: `83539d1aa8d00fc436994ec02255b94eef38f8e246556a023e68e130823585c0`.
- Expected: a valid `create` on a new name returns `ok: true`, and the sidecar says `created_by: agent`.
- Falsifier: `ok: false`, or an exception. In that case, every other result is void.

## F1 — does `create` take over a hand-written skill? (H2)

- Question: does `create` overwrite a hand-written skill that has the same name?
- Hypothesis, from reading `promoter.py`:
  - `_resolve_level` returns the intent's level for `create` without looking at what exists;
  - the ownership check (`target_is_agent_created`) only runs for `update`, `patch`, `remove_file` and `delete`;
  - `_land` then writes the body and stamps a new sidecar.
  So a `create` named like a hand-written skill replaces the author's text and marks the skill as the agent's.
- Input hash: `6b2a45a43418ce1421db9fa41d2f150ab6f76d8441f1fc0fce4c81a2740fce03`.
- Negative control, run first: an `update` on the same hand-written skill. It must be rejected with `self_produced`, leaving the body unchanged. If it were accepted, the protection would be missing altogether and F1 would show nothing specific to `create`.
- Expected if H2 holds:
  - `create.ok` is true;
  - `sentinel_survives` is false;
  - `agent_created_after` is true;
  - no archived copy exists.
- Falsifier:
  - `create` is rejected (any finding family); or
  - the sentinel survives; or
  - the old body is archived before being replaced.

## F2 — does one bad queue line block the whole run? (H10)

- Question: what happens when the intent queue holds one truncated line between two valid intents?
- Hypothesis: `intent_queue.read` parses every line with `json.loads` before any promotion. `drain` runs sweep → read → promote → account → clear. A truncated line therefore raises before anything lands, and before `clear`. The file stays, so the next `drain` of that run fails the same way: a poison pill.
- Input hash: `3c80d64fa379c4ccd426a66cebe88845cc29ca9b4be78596606695b1157dd419`.
- Control: the same two valid intents with no bad line. Expected: both drains succeed, the first lands 2 and the second lands 0, and the queue file is gone.
- Expected if H10 holds, for the treatment:
  - both attempts raise `JSONDecodeError`;
  - no valid intent lands (`landed_names` is empty);
  - the queue file is still there (`queue_left` is true).
- Falsifier: the bad line is skipped and the two valid intents land, or the second attempt succeeds.

## F3 — does the redactor miss secrets? (H13)

- Question: does the redactor catch a secret written as a quoted JSON key, and the body of a PEM key?
- Hypothesis:
  - the `api_key_assignment` rule, `(api[_-]?key|…)\s*[:=]\s*['"]?…`, allows no closing quote between the key and the `:`, so `"api_key": "…"` escapes it;
  - `private_key_block` matches only the `-----BEGIN … PRIVATE KEY-----` line, so the key material on the following lines stays.
- Input hash: `fcb3d2e95a180ff89626b5a254e4a7f3d4c6239e09689b72359239314c3d6c9a`. The canary is synthetic: `CANARYabcdefghij0123456789`.
- Control: `api_key = <canary>`, the form the rule was written for. Expected: the canary is redacted.
- Expected if H13 holds: the canary survives in `json_quoted` and in `pem`.
- Falsifier: the control keeps its canary (the harness is wrong), or either treatment loses it.

## F4 — does a non-ASCII skill survive a round trip on Windows? (new)

This hypothesis was not in the static report. It came from re-reading the code for this pre-registration.

- Question: does a skill whose body contains non-ASCII characters come back intact when the skill store reads it on Windows?
- Hypothesis: `atomic.write_text` always encodes UTF-8, but `skill_store.read_body` (and `intent_queue.read`, `sidecar.read`, `ledger.read`) calls `read_text()` with no encoding. That means the locale encoding, cp1252 here. The body `# Café Á` is written as UTF-8. `Á` is `C3 81`, and 0x81 is undefined in cp1252, so reading it back should raise `UnicodeDecodeError`.
- Input hash: `b60a8e5ecd1e33355b3fa90b76f8f45052fa391261ebbcf7448e928fb825bae3`.
- Control: the same fixture with `PYTHONUTF8=1`. Expected: `equal: true`.
- Expected if the hypothesis holds:
  - `ok` is true and `bytes_are_utf8` is true;
  - `read_back.raised` is `UnicodeDecodeError`, and only when UTF-8 mode is off.
- Falsifier: the read succeeds with UTF-8 mode off. That could happen if Python 3.14 already defaults `read_text` to UTF-8; the result would then say that, not that AutoHarness is safe.
- Scope: this is only about Windows with a non-UTF-8 locale. Linux and macOS usually use UTF-8 locales; that is *to verify*, not assumed.

## F5 — does the sweep delete a user's `*.tmp`? (H3)

- Question: does the startup sweep delete a user's `*.tmp` file?
- Hypothesis: `skill_store.sweep_orphans` deletes every `*.tmp` under the skills folder, recursively, whether or not AutoHarness wrote it. An empty `drain` would therefore delete a user's `draft.tmp` inside a hand-written skill.
- Input hash: `6b895ca2e28a6f8a0de9c1eeb179e1d2dae0449076781b831d9d0bdad4d0cb47`.
- Control: a `draft.txt` next to it, with the same content. Expected: it survives.
- Expected if H3 holds:
  - `tmp_survives` is false;
  - `control_survives` is true;
  - `skill_survives` is true.
- Falsifier: `draft.tmp` survives.

## Deliberately not run in this slice

- H1 and H4–H9, H11, H12 and H14 stay as hypotheses from the static read.
- The reflector and curator agents, which need `claude -p`, and any hook dispatch.
- Anything that installs the plugin.

## Post-measurement edits

Everything above this section is byte-identical to the file hashed at 15:29:21 EDT, before the first run: SHA-256 `b9dc7b7dfa726898f6c8f097f495ab7206f6e5aa8a2bde2c966b732785414a72`, taken with this section reading "(none yet)".

1. 15:31: run 1 (`fixtures-run-1-cp1252-stdout.jsonl`) was written by the parent process through a redirected stdout. That stdout used cp1252, which is the F4 failure class, in the harness itself. Only the display of F4's control `title_line` was affected. The child computed `equal: true` before printing.
   - I added `sys.stdout.reconfigure(encoding="utf-8")` to `fixtures.py`. The harness's SHA-256 moved from `e6866af9…` to `868eb1e1…`. The fixture inputs and their hashes are unchanged.
   - I ran it once more (run 2, `fixtures-run.jsonl`, 15:32).
   - Once each run is decoded with its own encoding, all 8 lines of run 1 and run 2 are equal.
2. One observation was not pre-registered, so it is exploratory. In F3's `pem` case, the header is redacted twice: `private_key_block` first writes `[REDACTED:secret:private_key_block]`, and then `api_key_assignment` matches `secret:private_key_block` inside that label. The output is `[REDACTED:[REDACTED:secret:api_key_assignment]]`, which loses the name of the rule that fired.
3. 23:20: I replayed the code README's commands from a fresh local clone, with `--clone autoharness-ca39a72` as a relative path. This exposed two harness defects:
   - every child failed with `ModuleNotFoundError`, because the relative `PYTHONPATH` does not resolve from the child's temporary cwd;
   - the parent still exited 0.
   Fixes in `fixtures.py` (the SHA-256 moved from `868eb1e1…` to `89a891bd…`):
   - the clone path is made absolute;
   - a crashed child's line still names its fixture;
   - the parent exits 1 if any child exits non-zero.
   `redact_probe.py` got the same path fix. The fixture inputs and child logic are unchanged, and `--hashes` gives the same output.
   Rerun with the fixed harness, relative and absolute paths: both outputs are **byte-identical** to `fixtures-run.jsonl`.
   Failure path checked: `run_fixture("C:/nonexistent-clone", "F0")` returns `fixture: F0`, `exit: 1`.
