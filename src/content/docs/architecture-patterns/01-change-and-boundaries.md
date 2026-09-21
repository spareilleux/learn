---
title: 1 — Start with a change, not a diagram
description: Establish a practice-plan contract, explicit assumptions and measurements before choosing architectural boundaries.
sidebar:
  order: 1
---

## The same small problem throughout

A guitar teacher saves a student's practice plan through a web form. Tomorrow a batch importer may need the same validation. A plan contains a title, exactly three distinct catalog shape IDs, and the catalog revision against which they were selected. Successful saving returns a plan ID and revision; unknown shapes, duplicate IDs or a stale catalog produce a typed rejection with no write.

Assume one team, one deployed process, a local transactional store and an immutable catalog snapshot. Authorization has already established the teacher's identity, but the use case must still check that the teacher may change this student's plan. We do not need billing, event streaming or independent deployment yet. These assumptions delimit the exercise; they are not facts about a production system.

The contract is more useful than a folder tree:

| Input or event | Required observation |
|---|---|
| Three known distinct IDs and current catalog revision | One plan and one durable receipt |
| Repeated shape ID | `InvalidPlan`; no saved plan |
| Catalog revision no longer accepted | `StaleCatalog`; no write |
| Student belongs to another teacher | `Forbidden`; no write |
| Same request ID and same payload retried | Same receipt; no second plan |
| Same request ID with different payload | `RequestConflict`; no overwrite |

The last two requirements become important in [lesson 3](../03-failure-and-distribution/). They apply to a local web service too: a client can lose its connection after a commit.

## Start with a layered candidate

[Microsoft's architecture guide](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures) distinguishes logical layers from deployment. For this exercise, start with a request handler, an application operation and a persistence adapter in one process. A layer is a code organization rule; it does not imply another server.

Put the three-shape rule in one function. The handler parses input; the operation checks permission, loads the accepted catalog, calls that function and saves. This can be enough. A database type leaking into the rule is a concrete dependency to evaluate, not proof that every layered system is defective.

## State the experiment before measuring

**Hypothesis:** separating the save operation from the web host will let a batch entry point reuse it without copying the validation. **Strongest counterargument:** a single function called from both handlers already achieves that; a new project and a generic repository might add no value.

Try the simpler function first. Record these measurements on a fixed revision and fixture:

| Seam | Measurement | Proposed acceptance criterion |
|---|---|---|
| Handler → operation | Rule definitions and tests reused by two callers | One rule implementation; same rejection cases |
| Rule → infrastructure | Direct and transitive runtime dependencies | Rule test starts no host or database |
| Operation → storage | Files changed when adding a test store | No rule change; same contract fixtures pass |
| Build output → running process | Reproduce a locked-output failure separately | No claim that an interface fixes file locks |

The thresholds are a proposed experiment, **to verify**. Count semantic changes, including wiring and tests, rather than rewarding an arbitrary low file count. Record elapsed test time on the same machine only after controlling startup and caches.

## Exercise — Find the hidden assumption

Your validation function accepts a shape ID, then storage looks up the latest catalog again. Can the receipt truthfully say which catalog was validated? Propose the smallest fix and a falsifier for adding a separate domain project.

<details>
<summary>Worked solution</summary>

The two reads can observe different revisions. Carry the validated immutable revision through saving, and persist it in the receipt. If acceptance depends on the current revision at commit, check that precondition atomically with the write; a prior read is insufficient. A separate project is not required to express this contract. Reject that extraction if both callers already reuse the same pure rule, no forbidden dependency exists and the only observed effect is extra build or mapping work. Revisit when a concrete dependency or ownership problem appears.

</details>
