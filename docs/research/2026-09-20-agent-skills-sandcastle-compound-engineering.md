# Research: Matt Pocock skills, Sandcastle, and Compound Engineering

Date: 2026-09-20

## Question

What should `learn` teach about Matt Pocock's skills and AI Hero methodology, Sandcastle, and Every's Compound Engineering plugin, using current first-party sources and commands rather than remembered aliases?

## Source snapshot

The GitHub sources below are pinned because all three projects are moving quickly.

| Project | Snapshot used | Relevant upstream version |
| --- | --- | --- |
| Matt Pocock skills | [`c55ee460`](https://github.com/mattpocock/skills/tree/c55ee46073ed923f86ce59a5eb3b6d895095d1b7) | AI Hero calls the published set v1.2 and lists 25 skills |
| Sandcastle | [`e99f832f`](https://github.com/mattpocock/sandcastle/tree/e99f832f26dc9d245c019a9ddd19fa5dee792427) | [`@ai-hero/sandcastle` 0.12.0](https://github.com/mattpocock/sandcastle/blob/e99f832f26dc9d245c019a9ddd19fa5dee792427/package.json) |
| Compound Engineering | [`6be0932b`](https://github.com/EveryInc/compound-engineering-plugin/tree/6be0932b91dc369508da19e6e2bc753b4c038830) | [plugin 3.27.0](https://github.com/EveryInc/compound-engineering-plugin/blob/6be0932b91dc369508da19e6e2bc753b4c038830/.codex-plugin/plugin.json), 36 skills |

AI Hero pages are live rather than commit-pinned. Their visible update dates should be recorded when material is copied into a lesson.

## Findings

### 1. Matt Pocock's skills are a composable engineering method

The upstream distinction that matters most is the installation model. The Claude Code plugin is a managed, read-only bundle that updates with the marketplace; `skills.sh` copies editable files into a project. Upstream explicitly says to choose one because installing both duplicates every skill. The current commands are:

```bash
# Claude Code managed plugin
claude plugins install mattpocock-skills

# Codex and other supported agents: editable project files
npx skills@latest add mattpocock/skills

# Update a copied installation later
npx skills update
```

Source: [repository README, installation section](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/README.md#installation-30-second-setup).

After installation, the exact upstream setup skill is `setup-matt-pocock-skills`. It is prompt-driven, not a deterministic script. It discovers the issue tracker, triage vocabulary, and domain-document layout, shows the proposed edits, and only then writes them. It defaults to GitHub when the remote is GitHub and to a single root `CONTEXT.md` plus `docs/adr/` for ordinary repositories. Source: [`setup-matt-pocock-skills/SKILL.md`](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/setup-matt-pocock-skills/SKILL.md).

The main flow currently published by [AI Hero's first-party skills catalog](https://www.aihero.dev/skills) is:

1. `grill-with-docs`: align through questions and capture domain language/ADRs.
2. `to-spec`: synthesize the agreed conversation into a spec; do not repeat the interview.
3. `to-tickets`: create independently verifiable tracer-bullet tickets and their blocking edges.
4. `implement`: implement at pre-agreed test seams, then run review and commit.
5. `code-review`: review the same diff separately against repository standards and the originating spec.

This sequence is supported by the authoritative skill contracts: [`to-spec`](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/to-spec/SKILL.md), [`to-tickets`](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/to-tickets/SKILL.md), [`implement`](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/implement/SKILL.md), and [`code-review`](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/code-review/SKILL.md).

Two concepts deserve their own exercises:

- A tracer bullet is a small vertical slice through all integration layers, tested immediately, rather than completing horizontal layers in isolation. This is both the rule in `to-tickets` and the method explained in [AI Hero's tracer-bullets article](https://www.aihero.dev/tracer-bullets).
- TDD begins by agreeing on public test seams. The current `tdd` contract says one seam, one failing test, and the minimum implementation per cycle; it rejects implementation-coupled and tautological tests. It also places refactoring in review rather than inside the red/green loop. Source: [`tdd/SKILL.md`](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/tdd/SKILL.md).

For work larger than one context window, teach `wayfinder` as decision mapping, not as a synonym for implementation planning. Its map consists of decision tickets; work is complete when the route to the destination is clear. It resolves at most one non-research ticket per session and distinguishes HITL prototypes/grilling from AFK research. Source: [`wayfinder/SKILL.md`](https://github.com/mattpocock/skills/blob/c55ee46073ed923f86ce59a5eb3b6d895095d1b7/skills/engineering/wayfinder/SKILL.md).

The useful pedagogical bridge from AI Hero is its seven-phase description: idea, optional research, optional prototype, requirements, dependency-aware tickets, execution, and QA. Research artifacts are described as sprint-local and potentially stale; AFK execution is presented as dependent on adequate research, a concrete prototype, clear requirements, and tickets with acceptance criteria. Source: [My 7 Phases of AI Development](https://www.aihero.dev/my-7-phases-of-ai-development). The course should preserve these conditions instead of presenting AFK as a mode switch.

### 2. Sandcastle is an execution harness, not another planning skill set

Sandcastle is a TypeScript library that runs coding agents in a sandbox, manages a branch strategy, and returns their commits. The current README documents Docker, Podman, Vercel, and `noSandbox`; the last one explicitly provides no isolation. Source: [Sandcastle README](https://github.com/mattpocock/sandcastle/blob/e99f832f26dc9d245c019a9ddd19fa5dee792427/README.md).

The current quick start is:

```bash
npm install --save-dev @ai-hero/sandcastle
npx @ai-hero/sandcastle init
# Fill .sandcastle/.env; never commit it.
npx tsx .sandcastle/main.mts
```

The README permits either `main.ts` or `main.mts`; the current templates generate `main.mts`. The smallest current API is:

```ts
import { run, claudeCode } from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";

await run({
  agent: claudeCode("<model-id>"),
  sandbox: docker(),
  branchStrategy: { type: "branch", branch: "agent/tutorial" },
  promptFile: ".sandcastle/prompt.md",
  maxIterations: 1,
});
```

Use a placeholder model in the lesson rather than copying a model name that will age. The checked-in [blank template](https://github.com/mattpocock/sandcastle/blob/e99f832f26dc9d245c019a9ddd19fa5dee792427/src/templates/blank/main.mts) and [simple-loop template](https://github.com/mattpocock/sandcastle/blob/e99f832f26dc9d245c019a9ddd19fa5dee792427/src/templates/simple-loop/main.mts) show the exact imports and options.

The branch strategies are materially different and must be taught before an AFK lab:

- `head`: direct writes to the host working directory; default for bind-mount providers.
- `merge-to-head`: a temporary branch that Sandcastle merges back to `HEAD`; default for isolated providers.
- `branch`: commits remain on an explicit named branch.

For a tutorial, use Docker plus an explicit `branch` strategy in a disposable repository, `maxIterations: 1`, and inspect `result.commits`, `result.branch`, the diff, and test output before any merge. Do not start with `head`, `merge-to-head`, Vercel, parallel planning, or `noSandbox`.

There is a security point that cannot be hidden in an appendix: Sandcastle's Claude provider normally runs AFK with bypassed permissions unless a `permissionMode` is selected, and its Codex provider similarly has an optional automated approvals reviewer. A sandbox limits filesystem scope; it does not make a prompt, network access, secrets, or a merge correct. The lesson should use a harmless fixture repository, a local container, no production credentials, no paid cloud provider, and an explicit iteration/time budget. Source: the provider options in the [current README](https://github.com/mattpocock/sandcastle/blob/e99f832f26dc9d245c019a9ddd19fa5dee792427/README.md).

After the one-shot lab, a second lab can reuse one sandbox for implementation and review, with a host-controlled test gate between them. The current README exposes `createSandbox()`, repeated `sandbox.run()`, and `sandbox.exec()`. The upstream [`sequential-reviewer` template](https://github.com/mattpocock/sandcastle/blob/e99f832f26dc9d245c019a9ddd19fa5dee792427/src/templates/sequential-reviewer/main.mts) demonstrates implement-then-review on one named branch. The [`parallel-planner-with-review` template](https://github.com/mattpocock/sandcastle/blob/e99f832f26dc9d245c019a9ddd19fa5dee792427/src/templates/parallel-planner-with-review/main.mts) should be an advanced reading exercise, not the first runnable example: it adds structured planning output, parallel sandboxes, review, and a merge agent.

#### Upstream documentation drift to handle explicitly

At this snapshot, Sandcastle's [short documentation page](https://github.com/mattpocock/sandcastle/blob/e99f832f26dc9d245c019a9ddd19fa5dee792427/docs/content/docs/configuration.mdx) still describes a `.sandcastle/config.json` with `agent` and `maxIterations`, while the current README and templates configure the TypeScript API directly. The docs page also says the default maximum is 10; the current README API reference says `maxIterations` defaults to 1. The course should teach the commit-pinned README and generated templates, not `config.json`, and include a version-check step before each update.

### 3. Compound Engineering is a packaged lifecycle with durable learning

The current plugin is version 3.27.0 and declares 36 skills. Its differentiator is not simply having many skills: it closes a feedback loop by writing durable solutions that later planning reads. The documented full loop is brainstorm, plan, work, simplify, review, and compound. Source: [Compound Engineering README](https://github.com/EveryInc/compound-engineering-plugin/blob/6be0932b91dc369508da19e6e2bc753b4c038830/README.md) and [skill catalog](https://github.com/EveryInc/compound-engineering-plugin/blob/6be0932b91dc369508da19e6e2bc753b4c038830/docs/guides/README.md).

Current install commands:

```text
# Claude Code
/plugin marketplace add EveryInc/compound-engineering-plugin
/plugin install compound-engineering

# Codex CLI
codex plugin marketplace add EveryInc/compound-engineering-plugin
codex plugin add compound-engineering@compound-engineering-plugin
```

The Codex app uses its Plugins UI to add the GitHub repository as a custom marketplace, install `compound-engineering-plugin`, and restart. Source: [README install section](https://github.com/EveryInc/compound-engineering-plugin/blob/6be0932b91dc369508da19e6e2bc753b4c038830/README.md#install).

Invocation syntax is host-specific. The upstream docs use `/ce-plan` style for slash-skill hosts and `$ce-plan` in Codex. The course must show both instead of silently translating one into the other.

The first command after installation is `ce-setup`. It creates or repairs `.compound-engineering/config.yaml`. The team file is committed; `.compound-engineering/config.local.yaml` is for checkout-local preferences and overrides ordinary keys. `docs_root` is deliberately different: it is read only from the tracked team config, must remain inside the repository, and fails closed when invalid. This matters in `learn`, where `docs/` may already have a distinct meaning. Source: [configuration guide](https://github.com/EveryInc/compound-engineering-plugin/blob/6be0932b91dc369508da19e6e2bc753b4c038830/docs/guides/configuration.md).

A tutorial should use one small bug or feature through the whole loop:

```text
ce-brainstorm <problem>
ce-plan
ce-work
ce-simplify-code
ce-code-review
ce-compound
```

The exercise should inspect every artifact boundary: requirements/plan, verified commits, review findings, and the resulting `docs/solutions/` learning. `ce-work` keeps the plan authoritative for WHAT while deciding HOW from live code, uses host-owned verification and commits even when another model implements, and requires review evidence or an explicit reason for skipping it. Source: [`ce-work` guide](https://github.com/EveryInc/compound-engineering-plugin/blob/6be0932b91dc369508da19e6e2bc753b4c038830/docs/guides/ce-work.md).

Teach `lfg` only after the explicit loop. Upstream describes it as a hands-off pipeline that can push, open a PR, and watch CI when a remote exists; merging remains separate unless granted. It is not a safe first exercise in a real repository. Source: [autonomous pipeline catalog entry](https://github.com/EveryInc/compound-engineering-plugin/blob/6be0932b91dc369508da19e6e2bc753b4c038830/docs/guides/README.md#autonomous-pipeline).

## Recommended course structure

Add a focused course under AI-assisted development rather than stretching the existing introductory agent course into a catalog of products. Suggested lessons:

1. **Skills as executable process** — distinguish project instructions, skills, hooks, and orchestration; install exactly one Matt-skills distribution.
2. **Set up a repository** — run `setup-matt-pocock-skills`, review every proposed file, and verify issue-tracker/domain-doc configuration.
3. **Idea to tracer-bullet tickets** — use `grill-with-docs`, `to-spec`, and `to-tickets`; evaluate verticality and blocking edges.
4. **Test-first implementation and two-axis review** — agree on seams, demonstrate a red test, minimal green implementation, and separate Standards/Spec review.
5. **Decision maps for work larger than one context** — use `wayfinder` on a planning-only example and classify research/prototype/grilling/task tickets.
6. **Sandcastle one-shot isolation lab** — Docker, disposable fixture repo, explicit branch, one iteration, no auto-merge, inspect evidence.
7. **Sandcastle implement-review pipeline** — one reusable sandbox, deterministic host test gate, second reviewing agent; discuss why sandboxing is not authorization.
8. **Compound Engineering's explicit loop** — install/setup, run one small change from brainstorm through compound, then prove the next plan can retrieve the learning.
9. **Choosing and composing safely** — compare a method library (Matt skills), an execution harness (Sandcastle), and a lifecycle plugin (Compound Engineering); document the authority and artifact boundary between them.

Each lesson should include one runnable or inspectable artifact, one failure mode, and one explicit stop condition. Keep Sandcastle credentials and real agent execution out of CI; CI can type-check the harness, validate config, and run fixture tests without invoking a model.

## Comparison for the concluding lesson

| Concern | Matt Pocock skills | Sandcastle | Compound Engineering |
| --- | --- | --- | --- |
| Primary role | Small composable engineering procedures | Run agents in isolated environments and manage branches/commits | End-to-end engineering lifecycle with durable artifacts |
| Planning model | Conversation, specs, tracer-bullet tickets, decision maps | Supplied by prompts/templates; not intrinsic to the runtime | Requirements, implementation plan, work, review, captured learning |
| Execution | Host agent follows `implement` and `tdd` | `run()` / `createSandbox()` invoke agent providers | `ce-work` owns routing, verification, commits, and shipping handoff |
| Isolation | Depends on the host | Explicit provider and branch strategy | Depends on the host/worktree skill |
| Durable learning | `CONTEXT.md`, ADRs, specs, tickets | Logs, branches, commits; no equivalent compounding model | `docs/solutions/` feeds later brainstorms/plans |
| Best first lab | One small feature through the main flow | One Docker run on an explicit branch | One small change through the explicit six-step loop |

Do not install overlapping workflow suites into the same teaching fixture for the first pass. Learners should first observe each system's native vocabulary and artifacts. A final composition exercise can use Matt's method to define work, Sandcastle to execute one bounded branch, and a host-owned review/compound step, but only after the boundary is written down: who may write, commit, push, merge, spend money, and declare completion.

## Verification checklist for course authors

- Re-read the three upstream README files and record their commit SHAs before publishing.
- Run installers only in a disposable fixture and capture their actual file outputs; never infer them from screenshots.
- Verify every model ID separately or use a placeholder in prose.
- Never copy a live token into a lesson, transcript, journal, or CI secret fixture.
- For Sandcastle, prove the selected branch strategy and inspect the resulting commit before describing behavior.
- For skills, inspect the installed `SKILL.md`; it is the runtime contract, while articles explain motivation.
- For Compound Engineering, distinguish Claude slash invocation from Codex `$skill` invocation.
- Mark model-backed executions and paid/cloud providers as optional, manually verified experiments rather than deterministic CI exercises.
