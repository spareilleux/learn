---
title: Journal
description: Dated progress notes for the Gaia course — the pinned revision and how it was run, what the suite and the verifier actually reported, the surprises (a refusal that is itself an event, a verify that used to print red and exit 0), and the list of things still to verify, starting with the factory run that spends real model turns.
sidebar:
  order: 99
---

## Progress

- [x] Pinned revision chosen and checked out clean; every command re-run against it
- [x] Lesson 1: the problem, the four axes, the doctrine
- [x] Lesson 2: the six verbs, with a real three-actor exchange
- [x] Lesson 3: the event log, the commit protocol, `verify`
- [x] Lesson 4: the coordination tracer, the agent factory, receipts and the tree digest
- [x] Lesson 5: the lane ladder and the ecosystem verdicts
- [ ] `factory:agent` run end to end with real Claude and Codex turns
- [x] French and Spanish mirrors
- [ ] A lesson on the hosted pump — the GitHub Actions side — which `main` has grown and this course does not cover

## 2026-09-15 — Setup and versions

- **Gaia** at [`d68e900`](https://github.com/GuitarAlchemist/gaia/tree/d68e90099ae2a6fbbec9d428617bfcd02095aac0), the head of `main` on 2026-09-13. Checked out as a detached linked worktree so the tree was clean and nothing local leaked into an output.
- **Node.js** v24.12.0 on Windows 11. Gaia pins one exact release — `.node-version` and `engines.node` both read **26.8.1** — and nothing enforces it when you invoke `node` yourself, so everything in these lessons ran on 24.12.0 without a warning or a failure. Running it on the pinned release is *to verify*; the CI path is Windows with that release, and Ubuntu is described as portability discovery rather than a gate.
- **Zero dependencies**, so no `npm install` before any of this, and no `node_modules` in a clean checkout. The claim is not marketing: `package.json` has no `dependencies` and no `devDependencies` key at all, and the test runner is `node --test`.
- Every bus command ran against a throwaway data directory via `GAIA_INTERAGENT_DATA_DIR`, so nothing touched a real workspace. Outputs are pasted unedited except for shortening absolute paths to `…`.

## 2026-09-15 — What the commands actually reported

| Command | Result |
|---|---|
| `doctor`, empty directory | `ok: true`, exit 0, `supportedMaxLiveLanes: 4`, and a note saying to run `initialize --apply` |
| `initialize` | dry run by default; `--apply` appended exactly one `actor.registered` |
| `bus-cli tools` | exactly 6: `register`, `send`, `inbox`, `ack`, `heartbeat`, `handoff` |
| `verify` | **37 checks passed, 0 failed**, in 8 sections, `evidenceGatesResult: false` |
| `node --test` | **2075 tests, 2074 pass, 0 fail, 1 skipped**, 38.9 s |
| `factory:smoke` | `completed`, evidence log fixed point `sha256:256a51d2…` over 15 events / 6,315 bytes, `evidenceGatesResult: true` |
| `inventory-digest` | 323 files, 5,937,493 bytes, `ordinal-path-bytes-sha256/1 dccabe8f…` |

The full three-actor exchange in lesson 2 came to **10 events and 3,617 bytes** on disk. That number is worth keeping in mind next to lesson 5's cost model: replay is O(events × actors), and a genuine multi-party coordination session is tiny.

## 2026-09-15 — Surprises

**A refusal is an event.** Addressing an ambiguous actor name returns `ok: false`, exits 1, and appends `command.rejected` to the log. I expected the refusal to be a return value and nothing more. It is the detail that makes the log answer "what did this session attempt?" rather than only "what did it achieve", and once seen it is hard to accept a system that logs only successes.

**`verify` used to print a red check and exit 0.** The README records the fix: both `doctor` and `verify` previously exited 0 on a log whose handoff had transferred authority, *while `verify` displayed its own red check saying otherwise*. A reader keying on the exit code, or on `ok`, read that as a pass. A tool that reports a failure and returns success is the exact failure mode lesson 1 is about, found inside the verifier — which is a good argument for the negative controls that now always gate.

**The evidence checks split into two regimes, and that is deliberate.** Five of them — three actors, more than one actor kind, a correlated thread, an acknowledgement, a handoff — are legitimately false on a correct empty workspace, so they report without gating unless the caller claims the log *is* evidence. I had assumed a verifier either checks something or does not. The hinge being the caller's claim rather than the tool's opinion is a better design than either alternative.

**`resolveLaneLimit` takes an options object.** Called positionally it silently returns the default, which is how I first mis-measured it. `resolveLaneLimit({ requested: 6 })` throws with the full evidence statement; `resolveLaneLimit(6)` returns `{ limit: 4 }`. Worth noting given that the module's whole argument is that silent clamping is the mistake — the refusal is real, but only on the documented call shape.

**The residuals are published, not buried.** The factory design document states that a host-user worker cannot be proven to have avoided network, secrets or writes elsewhere, and that a receipt claiming containment would need a separate OS boundary. Most projects would have written "runs agents in an isolated workspace". This one names the gap and the capability that would close it.

**`main` has grown well past what this course covers.** The hosted Draft pump on GitHub Actions, the drain Petri net, the control room, hybrid search, the runner capability probe, managed PR delivery rounds, test observation intake — `docs/` holds 50-odd design records at the pinned revision. The five lessons cover the bus, the log, the factory and the limits. That is a deliberate tracer-bullet slice, not a complete map.

## 2026-09-15 — Corrections made while writing

- I first quoted the repository's `AGENTS.md` for the "privilege is prevented by absence" rule. **That file does not exist at `d68e900`** — it was an untracked file in a local checkout of an older branch. The quote was replaced with the `README.md` statement and the operator module's own header, both verified present at the pinned revision. Every other quotation was re-checked against the pinned tree for the same reason.
- The local working copy I started from sat on a branch from 2026-08-29 whose `README.md` differed from `main`'s, and which had no `ARCHITECTURE.md` or `CONTEXT.md`. Starting from a clean pinned worktree instead of the checkout that happened to be open is the habit that caught it.

## To verify

- **`factory:agent` end to end.** It spends a real Claude turn and a real Codex turn on the installed subscriptions. Lesson 4 describes it from `src/factory-agent.mjs`, its design document and its receipt schema; no claim in that lesson comes from an observed run. What to capture when it runs: the receipt shape with and without a repair, the `(not an ETA)` progress lines, and whether the reviewer-mutation check ever fires on ignored files in practice.
- **Node 26.8.1**, the pinned version. Everything here ran on 24.12.0.
- **Linux and macOS.** The commit protocol is written and tested Windows-first, and the repository says Linux is discovery rather than a gate. The lock-directory approach should behave the same; the Windows-specific release retries would simply not be exercised.
- **A second concurrent lane against the same data directory.** All the outputs in these lessons came from sequential calls in one shell. The cross-process id-uniqueness property is what the suite asserts, not what I observed.
- **The `authority-language-detected` flag.** I saw it fire on "Please merge this." I have not looked at what it matches, and a heuristic's false-negative rate is the interesting number.

## Open questions

- The bus has write serialisation and **no authentication** — trust is positional, so any process able to spawn the server can register as any actor. Lesson 5 shows that being one of two named blockers for the IX integration. What is the smallest actor-identity mechanism that would not turn the bus into a credential store?
- Replay is O(events × actors) on a log that never compacts, and `inbox` writes an event. A polling lane therefore makes every later call slower. Is there a read path that keeps `inbox.polled` as evidence without paying for it on every replay — a snapshot plus tail, as the scale document suggests?
- The four-lane number is honest about being unreplicated with real clients. Running that probe needs four simultaneous real agent lanes, which costs real model turns. What is the cheapest experiment that would genuinely discriminate — and would a mix of one real lane and three synthetic ones prove anything, or is that the Node-worker probe again with extra steps?
