---
title: "5. Jev × Petri: classify evidence, never grant effects"
description: A runnable, offline tracer that exposes the unsafe advisory-to-authority path and checks a guarded alternative.
sidebar:
  order: 5
---

This experiment connects two courses without putting a model on the production control path. [Jev](https://docs.typesafe.ai/models) supplies a **synthetic advisory classification** in our [confidence-gate lab](../../typesafe-ai-system-one/05-confidence-gate-stress/); the [Petri-net engine](../../petri-nets/14-on-our-systems/) enumerates what a proposed control flow would permit. Neither alone verifies a real Gaia or IX transition.

## Question and baseline

Can a confidence threshold authorize implementation? The pinned [`gaia_design_authority` case](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/benchmark-corpus.json) expects `contradicted`: an approved design receipt exists, but no implementation grant does. The synthetic stress harness deliberately returns `supported` at 0.98. This is **not** a Jev API response or a measured model error.

The unsafe net consumes that advisory token to produce `effect`. Its shortest witness is `classify → authorize_from_advisory`. The guarded net instead routes advisory output to review, and `authorize` requires **both** independently verified evidence and implementation authority. Its tokens are single-use in this deliberately finite model; production policy may differ.

```text
synthetic Jev choice ──> advisory ──> review ──> confirmed ──┐
                                 verified evidence ──────────┤ authorize ──> effect
                                 implementation grant ───────┘
```

The two right-hand inputs must come from independently checked receipts, not from Jev's confidence or the model itself. A Petri marking describes assumptions; it does not create real receipts.

## Run the bounded tracer

From the repository root:

```bash
python -m unittest discover -s code/typesafe-ai-system-one -p 'test_jev_gate_audit.py' -v
python -m unittest discover -s code/repository-dogfooding-lab -p 'test_jev_petri_fixture.py' -v
dotnet test code/petri-nets/Tests -c Release --filter JevEvidenceGateTests
```

The [fixture](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/jev-petri-fixture.json) is checked against the Python synthetic response and read by the [C# tests](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs). The [net definition](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/JevEvidenceGate.cs) uses the existing course engine. Tests require complete reachability; they show the unsafe effect is reachable, no guarded effect is reachable with either prerequisite absent, and a separately authorized path remains possible when both are present.

## What this does **not** establish

- The original Petri tracer made no TypeSafe call and measured no billed tokens or Jev quality. Later live synthetic pilots and a pinned Gaia-seam check are reported in the [dated journal](../journal/); they do not validate the production transition.
- No production Gaia or IX state was read or changed. The case text is a pinned teaching fixture, not a current authority receipt.
- The guarded net checks a finite abstraction. It cannot establish that real code enforces the same guards, that receipts are authentic, or that concurrency and retries preserve them.

## Next dogfooding gate

Pin one actual Gaia or IX transition and its revision. Map its source-of-truth receipt fields to the net's places; seed missing and forged evidence; replay the unsafe witness through a public test seam. Compare against a simple deterministic guard test. Incubate only if the model catches an otherwise missed defect and an independent reviewer accepts the mapping. Otherwise retain the simpler test and reject this extra model.

## Exercise

In a disposable copy of the guarded net, remove the `implementation_authority → authorize` arc. Predict which missing-token test will fail, then run the focused C# tests. Restore the arc afterwards.

<details>
<summary>Solution</summary>

With verified evidence present but no implementation grant, `authorize` becomes enabled after `confirm`. The test that explores `(verified=true, authority=false)` finds a reachable `effect` and fails. This is a model counterexample, not a real Gaia defect.

</details>
