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
- [x] Lesson 6: bounded continuity, exact wake reconciliation and the Gaia-to-Demerzel receipt chain
- [ ] `factory:agent` run end to end with real Claude and Codex turns
- [x] French and Spanish mirrors
- [ ] A lesson on the hosted pump — the GitHub Actions side — which `main` has grown and this course does not cover

## QA

Findings from running Gaia's hosted pump on its own repository, observed at `main` [`8ed4dfc`](https://github.com/GuitarAlchemist/gaia/tree/8ed4dfca865696f6b54cb37ce077b0d10ece35df).

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| A labelled issue can become a Draft | Intake needs exactly one branch carrying the issue's evidence trailers, and nothing produced it; zero branches refuse like two, as `HeadIdentityAmbiguous` | [`src/hosted-draft-collector.mjs:319`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/src/hosted-draft-collector.mjs#L319) | 2 of 79 branches carried the trailers, both hand-made; scheduled intake returned `EXPECTED_NONE` for days | Fix proposed in [gaia#155](https://github.com/GuitarAlchemist/gaia/pull/155), then observed working live [2026-09-25](#2026-09-25--the-hosted-pump-end-to-end-as-far-as-a-draft) |
| An ambiguous Draft operation is reconciled | Issue 127's operation stays `EFFECT_AMBIGUOUS` and is skipped on every scheduled run; it does not block the queue, but nothing settles it | [`src/hosted-draft-pump.mjs:310`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/src/hosted-draft-pump.mjs#L310) | Present in every intake receipt from 2026-09-15 to 2026-09-24 | Reported as [gaia#161](https://github.com/GuitarAlchemist/gaia/issues/161) |
| A seeder that wrote a branch says so | A connection abort during the read-back made it exit fail-closed while the branch had landed | [`src/evidence-head-seeder.mjs:147`](https://github.com/GuitarAlchemist/gaia/blob/49d5fb3d6e4f5aa9e82cac0fb018d2c118c2958c/src/evidence-head-seeder.mjs#L147) (after the fix) | 1 occurrence, on issue 106 | Fixed in [gaia#155](https://github.com/GuitarAlchemist/gaia/pull/155) (`49d5fb3`) |
| An issue whose work shipped is closed | Issue 108 was open, although its gate was on `main`; the factory's worker made no edit | [`tests/hexagonal-direction.test.mjs`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/tests/hexagonal-direction.test.mjs) | 0 edits, 1 factory run spent | Closed as completed, [gaia#108](https://github.com/GuitarAlchemist/gaia/issues/108) |
| A factory job ends after its worker | Issue 108's job was still `STARTED` about ten hours after its worker finished, holding the single host slot | `C:/Gaia/state`, `portfolio:autonomous status` | Worker done at 00:25 local, job `STARTED` at 10:00 | Explained: `watch` stops on `RECONCILIATION_REQUIRED` ([`scripts/github-portfolio-autonomous.mjs:207`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/scripts/github-portfolio-autonomous.mjs#L207)); job retired with `retire-closed` [2026-09-26](#2026-09-26--the-factory-candidate-and-the-tests-nobody-ran) |
| A candidate marked `CANDIDATE_READY` and approved has passed its tests | No test is ever executed: the worker's tools exclude a shell, the reviewer is read-only, and the "supervisor" that the prompt says runs tests does not exist in `src/` | [`src/factory-visible-claude.mjs:354`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/src/factory-visible-claude.mjs#L354) | Issue 104's approved candidate: 16/17 of its own tests, README gate count not updated | Reported as [gaia#163](https://github.com/GuitarAlchemist/gaia/issues/163); candidate fixed by hand [2026-09-26](#2026-09-26--the-factory-candidate-and-the-tests-nobody-ran) |

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

## 2026-09-20 — Issue 76 continuity candidate

- Design Receipt v7.4 was reviewed independently before implementation. The candidate is deliberately bounded to one work identity, one successor slot and one generation-0-to-1 replacement.
- The isolated Gaia candidate ran **2,261 tests: 2,259 passed, 0 failed, 2 skipped**; its focused continuity/bus regression ran **87/87**. `npm run verify` reported **37 passed, 0 failed**, and `npm run architecture:verify` passed.
- The isolated Demerzel consumer ran **787 Python tests with 1 skipped** and **10/10 IXQL checks** while validating vendored Gaia schema/fixtures read-only.
- Review/integration found and corrected four material weak shapes: persistence imported into the controller, decisions allowed before exact wake delivery, idempotency keys replaying changed inputs, and tests omitting the bus sidecar. A simplification pass also removed avoidable scans and allocations.
- These are **candidate-worktree measurements**, not proof of publication, merge or release. The final formal review receipt, exact final commit gates and normal PR checks were still pending when this entry was written.

## 2026-09-25 — The hosted pump, end to end as far as a Draft

- **Why nothing came out.** `hosted-draft-intake.yml` had run every 6 h, successfully, and returned `EXPECTED_NONE` for days. Two causes, both on the Gaia side: no open issue carried `ready-for-agent`, and the collector requires exactly one branch whose tip carries `Gaia-Issue: N` and `Gaia-Ready-Receipt: <hash of the label event>`. **No code produced that branch.** The only two that ever existed were made by hand, and zero branches refuse the same way as two (`HeadIdentityAmbiguous`, because the test is `matching.length !== 1`). The Augment Cosmos automations were a red herring: the pump never depended on them.
- **The fix**, [gaia#155](https://github.com/GuitarAlchemist/gaia/pull/155): `npm run draft:seed-evidence -- --issue N --apply` creates `gaia/issue-N-ready-K`, one commit that reuses the default branch's tree, so no file changes. It derives the receipt with the collector's own function, extracted rather than copied, never applies the label, and lets the read-back decide the result.
- **Observed live on issue 108:** label → seed `CREATED` → intake `ADMIT` → Draft [gaia#156](https://github.com/GuitarAlchemist/gaia/pull/156) → the local factory (`portfolio:autonomous watch`, enabled once with a budget of 20 runs) took it within a minute. The same chain produced [gaia#158](https://github.com/GuitarAlchemist/gaia/pull/158) for issue 104.
- **Two refusals that were correct:** issue 148 came back `StaleRevision` because the pump had already drafted it on 2026-09-13 (#149): one Draft per work item. The factory's worker on 108 made **no edit**, because `tests/hexagonal-direction.test.mjs` was already on `main`: the issue had stayed open after its work shipped.
- **One defect found by running it:** a connection abort during the read-back after a successful write made the seeder exit fail-closed, which implied nothing was written, although the branch had landed. It now reports `AMBIGUOUS`, and a rerun reports `PRESENT`.
- **What the pump does not do, by design:** decide what is ready. `ready-for-agent` is the operator's act of authority. A feeder that picked and labelled its own work was refused by the agent's permission classifier as an unsafe agent, the same line as Gaia's "nothing self-authorizes". What shipped instead is read-only ranking ([gaia#157](https://github.com/GuitarAlchemist/gaia/pull/157)). Today it finds **one** candidate among 38 open issues, because 34 still carry `needs-triage`: grooming, not the pump, is the bottleneck.

## 2026-09-26 — The factory candidate, and the tests nobody ran

- **Why `watch` had gone quiet.** It had not hung, it had exited. After issue 108's worker made no edit, the job ended `RECONCILIATION_REQUIRED`, and `watch` stops on that status by design ([`scripts/github-portfolio-autonomous.mjs:207`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/scripts/github-portfolio-autonomous.mjs#L207)). The job then held the only slot. Since the issue and its Draft were both closed, `retire-closed` retired it as `ABANDONED` after a preview. I made the database backup the documentation asks for after the fact instead of before; nothing was lost.
- **Issue 104 produced a real candidate:** `CANDIDATE_READY`, reviewer `APPROVE`, three files (a pure lane-resume manifest, its document and 17 tests). It stayed local: the factory never publishes.
- **The approval did not mean the tests pass.** Run with the pinned Node 26.8.1, the candidate failed one of its own tests and the README gate-count test. The cause is structural. The worker prompt says "run the narrowest relevant tests", but its tools are `Read,Write,Edit,Glob,Grep` ([`src/factory-visible-claude.mjs:354`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/src/factory-visible-claude.mjs#L354)), and the prompt adds that "tests are run separately by the supervisor". No code in `src/` runs them. Reported as [gaia#163](https://github.com/GuitarAlchemist/gaia/issues/163), which proposes a deterministic, host-owned verification step before review rather than a shell for the model.
- **The failing test was wrong, not the code.** It appended `src/extra.mjs` after `src/resume-manifest.mjs`. The module requires artifacts sorted by path, so the observation was refused as malformed before any comparison. Appending `tests/extra.mjs` keeps the test's intent; with the README count updated, the candidate passes and was published to Draft [gaia#158](https://github.com/GuitarAlchemist/gaia/pull/158).

## To verify

- **`factory:agent` end to end.** It spends a real Claude turn and a real Codex turn on the installed subscriptions. Lesson 4 describes it from `src/factory-agent.mjs`, its design document and its receipt schema; no claim in that lesson comes from an observed run. What to capture when it runs: the receipt shape with and without a repair, the `(not an ETA)` progress lines, and whether the reviewer-mutation check ever fires on ignored files in practice.
- **Node 26.8.1**, the pinned version. Everything here ran on 24.12.0.
- **Linux and macOS.** The commit protocol is written and tested Windows-first, and the repository says Linux is discovery rather than a gate. The lock-directory approach should behave the same; the Windows-specific release retries would simply not be exercised.
- **A second concurrent lane against the same data directory.** All the outputs in these lessons came from sequential calls in one shell. The cross-process id-uniqueness property is what the suite asserts, not what I observed.
- **The `authority-language-detected` flag.** I saw it fire on "Please merge this." I have not looked at what it matches, and a heuristic's false-negative rate is the interesting number.
- **Issue 76 after final review.** Re-run the full Gaia and Demerzel gates on the exact reviewed commits, publish through normal PRs, and replace the candidate evidence above with immutable commit and receipt links.

## Open questions

- The bus has write serialisation and **no authentication** — trust is positional, so any process able to spawn the server can register as any actor. Lesson 5 shows that being one of two named blockers for the IX integration. What is the smallest actor-identity mechanism that would not turn the bus into a credential store?
- Replay is O(events × actors) on a log that never compacts, and `inbox` writes an event. A polling lane therefore makes every later call slower. Is there a read path that keeps `inbox.polled` as evidence without paying for it on every replay — a snapshot plus tail, as the scale document suggests?
- The four-lane number is honest about being unreplicated with real clients. Running that probe needs four simultaneous real agent lanes, which costs real model turns. What is the cheapest experiment that would genuinely discriminate — and would a mix of one real lane and three synthetic ones prove anything, or is that the Node-worker probe again with extra steps?
