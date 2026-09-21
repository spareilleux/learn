---
title: 4 — Evaluate an ecosystem seam
description: Translate architectural ideas into bounded, revision-pinned experiments for GA, Gaia, IX and Demerzel without asserting adoption.
sidebar:
  order: 4
---

## Evidence before a migration

The practice-plan example is invented. The repositories below are real, but a repository's architecture description is not proof that every dependency complies with it. The linked README snapshots were consulted for this course; no ecosystem application was built, migrated or benchmarked here.

| Repository and documented context | Candidate seam to investigate | Evidence required before adopting it |
|---|---|---|
| [GA](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/README.md): five layers, music domain and application hosts | One host-neutral operation shared by two existing entry points | Exact callers, input/output parity fixtures, layer references and deployment routes |
| [Gaia](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/README.md): coordination and evidence workflows | Separate a transition decision from its external effect adapter | Replay fixtures, claim ownership, duplicate handling and authority checks at the effect boundary |
| [IX](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/README.md): Rust algorithms and tools | Stable algorithm inputs/results with tool-specific parsing outside | Numerical equivalence, versioned fixtures, allocation and latency measurements on a fixed workload |
| [Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/c72fb746116346ce1991a4f108cd12f5e012e3fb/README.md): governance framework | Separate evidence validation and policy evaluation from publication | Schema compatibility, provenance, negative permission tests and explicit publication authority |

These are **candidate experiments**, not verified refactors or declarations that a repository has adopted clean or hexagonal architecture. The pins come from this site's existing courses and Streeling lockfile; they are study baselines, not assertions about current production.

## A bounded GA decision, worked

**Pain:** two entry points may encode the same rule differently. **Assumption:** they intend identical semantics; verify that before unifying them. **Candidate:** expose one application operation while preserving the established layer rules. AI behavior stays at its permitted layer; “put everything in the core” is not a migration plan.

**Strongest counterargument:** the endpoints serve different clients and intentionally differ in streaming, history or errors. **Hidden costs:** model conversion, cancellation, diagnostics, deployment ownership and compatibility. **Simpler alternative:** share the pure rule while retaining separate orchestration.

**Probe:** pin a commit, select ten explicit inputs covering success, invalid input, permission failure and cancellation, and run both existing paths. Ten is a proposed fixture budget, not a reported pass count. Then extract only the smallest common operation in an isolated candidate and replay the same fixtures.

**Acceptance:** no unexplained observable change, no new forbidden layer reference, and the common rule can run without starting a web host. **Falsifier:** a supposedly shared input needs incompatible business semantics. **Rejection:** abandon unification if preserving those semantics creates more conditional branching than the existing shared-rule alternative. **Revisit:** a new caller or a reproduced parity bug changes the evidence.

## Keep authority separate from architecture

For Gaia or Demerzel, a clean interface does not grant permission to push, merge or publish. Keep the decision result separate from the effect, and validate authority again where the effect occurs. A fake adapter proves only how the caller handles its simulated response; it does not prove the real provider's permissions, concurrency or failure semantics.

Cross-repository artifact contracts also carry version, identity and provenance obligations. Before changing a field, identify producer and consumers and pin their schema revisions. A common interface name is not evidence that those contracts match.

## Exercise — Write a rejectable decision

Pick one row. Write six sentences: observed pain, assumption, candidate, strongest objection, measurable acceptance, and rejection/revisit trigger. Specify which evidence is currently missing.

<details>
<summary>Worked solution: IX</summary>

“We suspect tool parsing and numerical computation change together; this is not yet measured. We assume the algorithm has a stable deterministic input/result boundary. We will expose one existing computation behind that boundary and leave parsing at the tool edge. The objection is extra copying on a hot path. Accept only if fixed-seed numerical fixtures stay within the existing tolerance and measured allocations/latency remain within a budget agreed before running. Reject if conversion dominates or semantics differ; revisit when a second caller appears.” Missing evidence includes the exact implementation, baseline workload, tolerance, measurements and caller inventory. This is a testable proposal, not an adopted IX design.

</details>

Continue with the [journal](../journal/) to distinguish completed course validation from experiments still to run.
