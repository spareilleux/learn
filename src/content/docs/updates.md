---
title: Update journal
description: Published changes, delivery evidence and unfinished requests.
---

## Delivery rule

Requested, delegated, implemented locally, merged, deployed and publicly verified are different states. A running agent or an open PR is not a delivery. Each verified entry needs a revision, validation evidence and a public destination. This journal is a dated snapshot, not a live connection to GitHub or wmux.

## Delivery board — 2026-09-27

| Verified publication | Awaiting publication or verification | Requested, not delivered |
| --- | --- | --- |
| [LadybugDB lesson 9, graph lab](../ladybugdb/09-graph-lab/): PR #25 merged as `438b320`, Pages deployment succeeded, EN/FR/ES lesson and journal entry read back anonymously | [Streeling MAT-003](../streeling/mathematics/): source merged in Demerzel (`89a1bdb`); generator PR #26 merged as `67ffd4e` and Learn lab PR #24 as `00ae641`; the canonical sync awaits review | Streeling mathematics modules beyond MAT-001 and MAT-003: none exists in the canonical source yet; MAT-002 and MAT-004 are queued |

This board adds what was settled or opened on 2026-09-27; the 2026-09-26 board below is unchanged.

## Delivery board — 2026-09-26

| Verified publication | Awaiting publication or verification | Requested, not delivered |
| --- | --- | --- |
| SlashForge 4.5.0 retest and contribution lesson: PR #21, Pages deployment succeeded | Ocean is publicly shared; its catalog entry is introduced with this update | ComfyUI homepage hero |
| Test-quality lab and agentic observation format: same publication | Studio narration: local samples, not listening-approved or integrated | ComfyUI IX illustration |
| | Container recipe: present, runtime untested | TARS v1 → v2 prior-art journal |
| | | Additional Streeling courses and Jean-Pierre Petit comic references |
| | | Gantt view with supported estimates and dependencies |
| | | Gaia delivery-contract proposal; not an implemented feature |

The columns summarize these recent requests only. They are not a completed audit of every repository or of the entire conversation. Dates or owners not established by evidence remain unspecified.

## 2026-09-26 — SlashForge contributions published

[Learn PR #21](https://github.com/spareilleux/learn/pull/21) merged as `26a2f79f7901d8e4cd937ad291b0c4764f6d837e`. Its [Pages build and deployment](https://github.com/spareilleux/learn/actions/runs/36265141942) succeeded. The publication includes the three-language [SlashForge journal](../slashforge/journal/), [contribution lesson](../slashforge/07-contributing-back/), ComfyUI workshop illustration and [mutation/property-testing lesson](../repository-dogfooding-lab/06-mutation-property-testing/).

The retest keeps the earlier 4.4.3 measurements and records the Windows 4.5.0 results separately. SlashForge CI succeeded on Linux, Windows and macOS; this does not turn the Windows live retest into three live retests. Narration remains a local sample, and the container recipe remains untested.

## 2026-09-26 — Ocean shared artifact checked

The [GA Ocean artifact](https://claude.ai/artifact/P5JPUkCRR1cYc4herNiR9F) opened with a visible sign-in link rather than requiring sign-in, and showed the four preset controls and Saint-Malo attribution. It is now referenced in the [artifact catalog](../artifacts/). This establishes shared-page access, not WebGPU performance on every device.

## 2026-09-27 — LadybugDB lesson 9 and Streeling MAT-003 published

[Learn PR #25](https://github.com/spareilleux/learn/pull/25) merged as `438b320`, and its [Pages deployment](https://github.com/spareilleux/learn/actions/runs/36341917142) succeeded. The [LadybugDB lesson 9](../ladybugdb/09-graph-lab/) and its [journal entry](../ladybugdb/journal/) were read back anonymously in the three languages. The lab's two scripts passed the course CI on Linux, Windows and macOS; the measurements themselves were taken on Windows.

[Streeling MAT-003](../streeling/mathematics/mat-003-floating-point-conditioning/) arrived through three merges:
- the Learn lab ([PR #24](https://github.com/spareilleux/learn/pull/24), `00ae641`);
- the generator's English-only labels ([PR #26](https://github.com/spareilleux/learn/pull/26), `67ffd4e`);
- the canonical sync at Demerzel `89a1bdb` ([PR #27](https://github.com/spareilleux/learn/pull/27), `ce6021f`), whose [Pages deployment](https://github.com/spareilleux/learn/actions/runs/36343842316) succeeded.

The module, the mathematics index, the [Streeling journal entry](../streeling/journal/) and the 2026-09-27 board above were read back anonymously in the three languages. That board is a snapshot taken before these merges, and it is left as written.

These two items therefore move from awaiting to verified. The mathematics catalogue still has two modules, MAT-001 and MAT-003.

## 2026-09-27 — The homepage and IX illustrations published

[Learn PR #23](https://github.com/spareilleux/learn/pull/23) merged as `3c8c1de`, and its [Pages deployment](https://github.com/spareilleux/learn/actions/runs/36299159809) succeeded. The [home page](../) and the [IX course introduction](../machine-learning-ix/) now show the two images generated locally with ComfyUI and cached models. In the three languages, each is labelled conceptual art, not a diagram. The six pages answered 200 anonymously, and both images were byte-identical to a local build.

These are the two ComfyUI images the 2026-09-26 board lists as requested. That board is left as written.

## 2026-09-27 — Petri nets lesson 16 and the AutoHarness course published

[Learn PR #28](https://github.com/spareilleux/learn/pull/28) merged as `e5a4ddd`, and [PR #29](https://github.com/spareilleux/learn/pull/29) as `c406126`, whose [Pages deployment](https://github.com/spareilleux/learn/actions/runs/36368118824) succeeded. [Petri nets lesson 16](../petri-nets/16-interoperability-lab/), its [journal](../petri-nets/journal/), the [AutoHarness course](../autoharness/) and its [journal](../autoharness/journal/) were read back anonymously in the three languages.

- **Both PRs were repaired after review.** Codex's review asked for changes to each:
  - lesson 16's round-trip comparison and arc-kind guard were fixed with tests that failed first, and its QA links now point at a fixed commit;
  - the AutoHarness fixtures now run in CI on Linux, Windows and macOS.
- **The repaired heads were merged at the user's request,** without a second independent review.
- **What stays unmeasured.** Lesson 16's external analysers (TINA, pm4py, Graphviz) are recipes that were not run. AutoHarness was evaluated without being installed, and its verdict is "do not adopt" at `ca39a72`.

## 2026-09-27 — Streeling MAT-002 synced, awaiting verification

[Demerzel PR #1136](https://github.com/GuitarAlchemist/Demerzel/pull/1136) was reviewed independently at `5e6b733` and merged as `a3a07df`. This update syncs it into Learn:
- the [MAT-002 module](../streeling/mathematics/mat-002-counterexamples-and-exhaustive-checks/) in the three languages;
- the mathematics index;
- the [Streeling journal entry](../streeling/journal/).

MAT-002 stays **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously. MAT-004 was merged in Demerzel after this pin (`d451c90`, [PR #1137](https://github.com/GuitarAlchemist/Demerzel/pull/1137)); it is not synced here.

## 2026-09-27 — Streeling MAT-004 synced, awaiting verification

[Demerzel PR #1137](https://github.com/GuitarAlchemist/Demerzel/pull/1137) was merged as `d451c90`, after the MAT-002 pin. This update syncs it into Learn:
- the [MAT-004 module](../streeling/mathematics/mat-004-vectors-matrices-norms/) in the three languages;
- the mathematics index;
- the [Streeling journal entry](../streeling/journal/).

MAT-004 stays **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously.

## 2026-09-27 — Streeling MAT-005 synced, awaiting verification

[Demerzel PR #1138](https://github.com/GuitarAlchemist/Demerzel/pull/1138) was merged as `8bd026f`, after the MAT-004 pin. This update syncs it into Learn:
- the [MAT-005 module](../streeling/mathematics/mat-005-symmetric-eigenproblems/) in the three languages;
- the mathematics index;
- the [Streeling journal entry](../streeling/journal/).

MAT-005 stays **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously.

## 2026-09-27 — Streeling MAT-002, MAT-004 and MAT-005 published

Codex merged the three canonical syncs, and each Pages deployment succeeded:
- [MAT-002](../streeling/mathematics/mat-002-counterexamples-and-exhaustive-checks/), Demerzel `a3a07df`: [PR #35](https://github.com/spareilleux/learn/pull/35), merged as `1b4ec84`, [deployment](https://github.com/spareilleux/learn/actions/runs/36371547922);
- [MAT-004](../streeling/mathematics/mat-004-vectors-matrices-norms/), Demerzel `d451c90`: [PR #36](https://github.com/spareilleux/learn/pull/36), merged as `b0f4380`, [deployment](https://github.com/spareilleux/learn/actions/runs/36372857458);
- [MAT-005](../streeling/mathematics/mat-005-symmetric-eigenproblems/), Demerzel `8bd026f`: [PR #37](https://github.com/spareilleux/learn/pull/37), merged as `36d4d17`, [deployment](https://github.com/spareilleux/learn/actions/runs/36373405733).

The three modules, the mathematics index, the [Streeling journal](../streeling/journal/) and their entries in this journal were read back anonymously in the three languages. At that readback, after #37, the pages served linked their source at `8bd026f`; this update repins them to `0b13b9d`.

These three modules therefore move from awaiting verification to verified; their entries above are left as written. At the same readback, the mathematics catalogue had five modules, MAT-001 to MAT-005; this update adds MAT-006, the sixth. Published is not studied: none of them has been run or studied here, and their experiments remain proposed.

## 2026-09-27 — Streeling MAT-006 synced, awaiting verification

[Demerzel PR #1139](https://github.com/GuitarAlchemist/Demerzel/pull/1139) was merged as `0b13b9d`, after the MAT-005 pin. This update syncs it into Learn:
- the [MAT-006 module](../streeling/mathematics/mat-006-svd-low-rank-approximation/) in the three languages;
- the mathematics index;
- the [Streeling journal entry](../streeling/journal/).

MAT-006 stays **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously.

## To verify

- Check this update's public URLs and catalog after deployment; keep the deploy receipt with the integration record.
- Review TARS history at pinned revisions before explaining why v1 approaches changed.
- Add scheduling only after owners, dependencies and estimates are established. No fictional completion dates.

## Open questions

- Can Gaia's existing candidate and operation receipts enforce the same delivery distinction without a second competing state machine?
- Which Streeling gaps should be filled upstream before the canonical Learn sync?
