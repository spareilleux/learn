---
title: Gaia — Mission
description: Gaia is a durable local coordination bus and an evidence-bearing software factory for Claude Code and Codex sessions — six non-privileged verbs, an append-only event log, and receipts nobody has to take on trust. This course explains what it is trying to accomplish, why privilege is prevented by absence rather than by a check, and what has actually been measured, with every output run on the pinned revision.
sidebar:
  label: Mission
  order: 0
---

:::note[Revision studied, and what is measured here]
Gaia at commit [`d68e900`](https://github.com/GuitarAlchemist/gaia/tree/d68e90099ae2a6fbbec9d428617bfcd02095aac0) (2026-09-13), the head of `main`, on Windows 11 with [Node.js](https://nodejs.org/en) v24.12.0, on 2026-09-15. Gaia has **zero runtime dependencies**, so every command in this course runs from a clean checkout with no `npm install`.

Every output quoted in these lessons was produced by running the command on that revision, in a throwaway data directory, and pasted unedited apart from shortening long absolute paths. **No lesson in this course launches a billed model.** The one command that does — `factory:agent`, which spends a real Claude and a real Codex turn — is described from its code, its design document and its receipt schema, and is marked *to verify* where I have not run it.
:::

## Why I am learning this

I write most of my code with a coding agent now. The [agentic coding course](../agentic-coding/) covers one agent in one repository: the tool loop, permissions, `CLAUDE.md`, hooks, MCP. This course is about the problem that appears immediately afterwards, and that no amount of prompt engineering fixes.

Two agent sessions, then four, work on the same set of repositories. They cannot see each other. Each one finishes and reports success. And I have no way to tell these three sentences apart:

- "I implemented the change and the tests pass."
- "I implemented the change, ran nothing, and the sentence above is what a model produces when a task ends."
- "Another session changed that file under me, and my diff is against a tree that no longer exists."

All three arrive as the same confident paragraph. An agent's completion message is **prose**, and prose is not evidence. Gaia is my attempt to build the layer that makes the difference checkable: coordination that is durable, and results that carry receipts somebody else can replay or refuse.

## What Gaia is trying to accomplish

Gaia's architecture map states the goal in one sentence: *Gaia coordinates evidence-bearing software delivery while keeping observation, acceptance, and authority distinct.*

That sentence is doing a lot of work, so here it is unpacked into the four claims this course is built around.

**1. Coordination and authority are different things, and must not travel together.** A message that says "please merge this" must be able to reach another agent without ever being able to *cause* a merge. In Gaia that is not a permission check which could be bypassed — the verbs that could approve, merge, push or deploy **do not exist**. Lesson 2 prints the whole tool surface, then shows a message asking for merge authority being delivered and denied in the same breath.

**2. Freshness, quality, acceptance and authority are four independent axes.** A fresh artifact may be wrong. A high-quality artifact may be stale. An accepted artifact may grant no authority. Most agent tooling collapses these into one number or one green check; Gaia keeps them apart on purpose, and refuses to report a single "confidence" scalar at all.

**3. Evidence is what another actor can replay, not what the producer asserts.** Every state change writes a receipt binding exact inputs, content digests, preconditions and the authority actually spent. Lesson 4 runs the factory tracer and reads the receipt it produces — including the parts that say what the receipt does **not** prove.

**4. A limit with no measurement behind it is a preference, not a limit.** Gaia supports four live lanes per workspace. Not because four is tidy, but because four is the largest number anyone has actually exercised end to end. Lesson 5 reads that evidence ladder, and the refusal messages that name what is still unproven.

The failure mode all four are aimed at is the same one: **a system that produces a reassuring answer where it should produce a refusal.** Gaia fails closed — a lock timeout, a torn log, a stale revision or an identity mismatch writes nothing and says so, rather than leaving a partial result that looks fine.

## Who this course is for

You write C# or Java professionally, and you have used a coding agent enough to have been burned once — a change you did not ask for, a test that was never run, a "done" that was not. You do not need to know Node.js: Gaia's source is plain ES modules, and this course quotes it rather than asking you to write it.

The [agentic coding course](../agentic-coding/) helps but is not required. Where a concept comes from there — the tool loop, MCP, permission modes — this course links back to that lesson instead of repeating it.

## Gaia's vocabulary in one table

The words matter here more than usual, because the whole design is about keeping them apart. From the architecture map:

| Concept | What it is | What it is **not** |
|---|---|---|
| Claim | reserves or reports observed work | permission to do anything |
| Intent | the exact proposed mutation, bound to identity, generation, policy and revision | an effect |
| Effect | one bounded attempt by one named owner | something an agent can start by asking |
| Receipt | preconditions, outcome, evidence revision, authority actually spent | proof that the result is correct |
| Delivery | accepted for delivery | read, agreed, or completed |
| Acknowledgement | receipt of a message | agreement, approval, or completion |
| Handoff | transfer of work and context | transfer of privilege |
| Lane | an execution surface | authority, or proof of useful work |

If you read only one part of that table, read the last three rows. *Delivered*, *acked* and *handed off* are the three words agent orchestration normally uses to mean "it is taken care of" — and in Gaia all three are explicitly defined not to mean that.

## By the end of this course, I will be able to

- explain what an evidence-bearing factory is, and which question it answers that a green CI check does not;
- run the bus, register several actors, and read the append-only log they produce;
- say exactly what the six verbs can and cannot do, and *demonstrate* the refusal rather than assert it;
- replay a log, verify it, and tell the three exit codes apart — refused, fail-closed, and ok;
- read a factory receipt and state what it proves and what it leaves as a disclosed residual;
- justify the four-lane limit from its evidence, and say what would raise it.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [The problem: what "done" is worth](01-the-problem/) | a code review, a flaky test suite |
| 2 | [Six verbs, and the authority missing on purpose](02-six-verbs/) | a message queue, an ACL |
| 3 | [The event log: append-only, replayed, fail-closed](03-event-log-and-replay/) | event sourcing, a write-ahead log |
| 4 | [The factory: candidates, reviewers and receipts](04-factory-and-receipts/) | a pull request, a build artifact |
| 5 | [Limits, evidence and the ecosystem](05-limits-and-ecosystem/) | capacity planning, an integration decision |
| — | [Journal](journal/) | |

## Prerequisites

- [Node.js](https://nodejs.org/en). At the studied revision Gaia pins one exact release: `.node-version` and `package.json`'s `engines.node` both read `26.8.1`. Nothing enforces that when you invoke `node` directly, and everything in this course ran on v24.12.0 without a warning or a failure — but running it on the pinned release is *to verify*.
- [Git](https://git-scm.com/), for the linked worktrees lesson 4 uses.
- A terminal. Gaia has no network listener, no remote execution and no shell transport — nothing here opens a port.

```bash
git clone https://github.com/GuitarAlchemist/gaia
cd gaia
node scripts/gaia-interagent.mjs doctor
```

## Resources

- [GuitarAlchemist/gaia](https://github.com/GuitarAlchemist/gaia) — the repository. `README.md` is the product document, `ARCHITECTURE.md` the authoritative boundary map, and `docs/` holds the design and operating records.
- [Engineering and research principles](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/engineering-and-research-principles.md) — the doctrine lesson 1 reads, and the one document to read before proposing a change to Gaia.
- [Scale and lanes](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/scale-and-lanes.md) — the claim ladder behind the number four.
- [Model Context Protocol](https://modelcontextprotocol.io/) — the protocol the bus speaks over stdio, covered in [agentic coding lesson 4](../agentic-coding/04-mcp/).
- David L. Parnas, [On the Criteria To Be Used in Decomposing Systems into Modules](https://dl.acm.org/doi/10.1145/361598.361623), and Jerome H. Saltzer and Michael D. Schroeder, [The Protection of Information in Computer Systems](https://www.mit.edu/~Saltzer/publications/protection/index.html) — the two papers Gaia's principles cite for module depth and for least privilege.
