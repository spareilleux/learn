---
title: "6. Sandcastle: one isolated agent run"
description: Build a bounded Sandcastle lab with Docker, an explicit branch, one iteration and host-owned verification.
sidebar:
  order: 6
---

[Sandcastle](https://github.com/mattpocock/sandcastle/tree/e99f832f26dc9d245c019a9ddd19fa5dee792427) is a TypeScript library that runs coding agents in sandboxes and manages their branches and commits. This lesson is pinned to commit `e99f832f` and package version 0.12.0, checked on 2026-09-20.

Sandcastle is an execution harness, not a requirements method. The prompt and the host still decide what work is valid, how it is verified and whether a resulting commit may be merged.

## Prepare a disposable lab

Prerequisites: Git, Node.js and Docker or Podman. Do not begin in a production repository.

```bash
npm install --save-dev @ai-hero/sandcastle
npx @ai-hero/sandcastle init
```

The initializer creates `.sandcastle/`. Put provider credentials only in `.sandcastle/.env`, keep it ignored, and never copy a token into a lesson or transcript. A subscription token and an API key have different cost semantics: verify which provider is selected before running.

## The smallest useful run

```ts
import { run, claudeCode } from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";

const result = await run({
  agent: claudeCode("<verified-model-id>"),
  sandbox: docker(),
  branchStrategy: { type: "branch", branch: "agent/tutorial" },
  promptFile: ".sandcastle/prompt.md",
  maxIterations: 1,
});

console.log(result.branch, result.commits);
```

Run the generated entry point with the filename created by your installed version, currently:

```bash
npx tsx .sandcastle/main.mts
```

`prompt.md` is a convention, not an automatic fallback: pass it with `promptFile`. An explicit `branch` strategy leaves the work for inspection. `head` writes directly to the host checkout; `merge-to-head` merges a temporary branch back. Neither is appropriate for a first exercise.

## The evidence gate

After the run, the host—not the model—must inspect:

1. `result.branch` and `result.commits`;
2. the exact diff against the starting commit;
3. the deterministic test output;
4. the sandbox log and exit status;
5. any network, credential or cost boundary crossed.

Do not merge during this exercise. One iteration is enough to prove whether the harness, branch boundary and evidence path work.

## Isolation is not authorization

A sandbox constrains a filesystem and process environment. It does not make an untrusted prompt correct, protect every network secret, grant permission to push, or prove that a change satisfies the user. Provider defaults may automate approval inside the sandbox, so the host must still impose scope, budget and a stop condition.

Avoid `noSandbox()` in this lab: it deliberately removes isolation. Avoid cloud providers and paid APIs until their budget and credential paths have been reviewed explicitly.

:::caution[Upstream documentation drift]
At the pinned revision, an older configuration page still mentions `.sandcastle/config.json` and a default of ten iterations. The current README and generated templates configure the TypeScript API directly and document a default of one. Follow the pinned README and generated template, then re-check upstream before updating this lesson.
:::

## Exercise

Create a disposable repository with one failing test and ask the agent to make only that test pass. Use Docker, a named branch and `maxIterations: 1`. The exercise passes only when the host can show the starting SHA, resulting commit, diff and passing test without merging anything.

Continue with [Compound Engineering](../07-compound-engineering/) to make the planning, implementation, review and learning artifacts explicit.

