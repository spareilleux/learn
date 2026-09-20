---
title: "5. Matt Pocock skills: executable engineering methods"
description: Install one distribution of the AI Hero skills, configure it for a repository, and turn an idea into a tracer-bullet implementation with explicit evidence.
sidebar:
  order: 5
---

A `SKILL.md` is a procedure an agent can load when a task matches it. It is more focused than `AGENTS.md`: project instructions apply to every turn, while a skill describes one repeatable job such as research, TDD or code review.

This lesson uses [Matt Pocock's skills](https://github.com/mattpocock/skills/tree/c55ee46073ed923f86ce59a5eb3b6d895095d1b7), pinned at `c55ee460` on 2026-09-20, and the methodology described by [AI Hero](https://www.aihero.dev/skills).

## Install exactly one distribution

The upstream project offers two installation models. Installing both duplicates the same skills.

```bash
# Claude Code: managed, read-only plugin
claude plugins install mattpocock-skills

# Codex and other compatible agents: editable project files
npx skills@latest add mattpocock/skills
```

For copied skills, update later with `npx skills update`. Then invoke `setup-matt-pocock-skills` once in the repository. The setup skill inspects the issue tracker, triage labels and domain-document layout, proposes changes, and asks before writing them. Review the proposal: it is not a deterministic installer.

## The main flow

```mermaid
flowchart LR
    A[Ambiguous idea] --> B[grill-with-docs]
    B --> C[to-spec]
    C --> D[to-tickets]
    D --> E[tdd or implement]
    E --> F[code-review]
```

- `grill-with-docs` discovers requirements and records domain language or ADRs.
- `to-spec` turns the agreed conversation into a specification without repeating the interview.
- `to-tickets` produces independently verifiable, dependency-aware tracer bullets.
- `tdd` agrees on a public seam, writes one failing test, then the smallest passing implementation.
- `code-review` checks the same diff separately against repository standards and the specification.

A tracer bullet is a thin vertical slice through every required integration layer. It is not a horizontal task such as “build the entire data layer”. It should expose integration mistakes early and end in observable evidence.

## A bounded exercise

Choose a harmless feature in a disposable repository.

1. Write the user-visible outcome in one sentence.
2. Run `grill-with-docs`; answer only the questions that change the design.
3. Inspect the spec before accepting it.
4. Reject any ticket that cannot be verified independently or that covers only one architectural layer.
5. Implement one tracer bullet with one test seam.
6. Review the fixed diff against both standards and spec.

Stop after one slice. Record the commit, test command and remaining uncertainty. A completed agent turn is not evidence that the intended outcome works.

## When work exceeds one context window

Use `wayfinder` to map decisions, not as a synonym for a large implementation plan. Its tickets answer unknowns through research, a prototype, grilling or one bounded task. The map is complete when the route is clear, not when every possible feature is listed.

## Failure modes

- installing the managed plugin and copied skills together;
- treating an article or remembered alias as the runtime contract instead of reading the installed `SKILL.md`;
- producing horizontal tickets that postpone integration;
- letting a skill silently expand authority to push, merge, spend money or contact external systems.

The repository-specific authority still comes from the user and the host. A skill changes procedure, not permission.

Continue with [Sandcastle](../06-sandcastle/) to run an agent inside an explicit execution boundary.

