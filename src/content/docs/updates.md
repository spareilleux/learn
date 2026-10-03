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

## 2026-09-27 — Streeling MAT-006 published

Codex merged [Learn PR #38](https://github.com/spareilleux/learn/pull/38) as `0853739`, after two corrections to this journal asked for in review, and its [Pages deployment](https://github.com/spareilleux/learn/actions/runs/36375002691) succeeded. The [MAT-006 module](../streeling/mathematics/mat-006-svd-low-rank-approximation/), the mathematics index, the [Streeling journal](../streeling/journal/) and this journal were read back anonymously in the three languages: 12 pages, each answering 200 and mentioning MAT-006.

MAT-006 therefore moves from awaiting verification to verified; its entry above is left as written. At that readback, the MAT-006 pages linked their source at `0b13b9d`; this update repins them to `8c14336`. As for the modules before it, published is not studied: MAT-006 has not been run or studied here, and its experiment remains proposed.

## 2026-09-27 — Streeling MAT-007 synced, awaiting verification

[Demerzel PR #1140](https://github.com/GuitarAlchemist/Demerzel/pull/1140) was merged as `8c14336`, after the MAT-006 pin. This update syncs it into Learn:
- the [MAT-007 module](../streeling/mathematics/mat-007-least-squares-regularisation/) in the three languages;
- the mathematics index;
- the [Streeling journal entry](../streeling/journal/).

MAT-007 stays **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously.

## 2026-10-02 — Streeling MAT-007 published

[Learn PR #39](https://github.com/spareilleux/learn/pull/39) was merged as `0436325`, and its [Pages deployment](https://github.com/spareilleux/learn/actions/runs/36377803965) succeeded. On 2026-10-02, with `main` at `c547150` and its [deployment](https://github.com/spareilleux/learn/actions/runs/37065792242) succeeded, the [MAT-007 module](../streeling/mathematics/mat-007-least-squares-regularisation/), the mathematics index, the [Streeling journal](../streeling/journal/) and this journal were read back anonymously in the three languages: 12 pages, each answering 200 and mentioning MAT-007.

MAT-007 therefore moves from awaiting verification to verified; its entry above is left as written. At that readback, the MAT-007 pages linked their source at `8c14336`; this update repins them to `e203e5a`. As for the modules before it, published is not studied: MAT-007 has not been run or studied here, and its experiment remains proposed.

## 2026-10-02 — Streeling MAT-008 to MAT-025 and five music modules synced, awaiting verification

Demerzel's `master` reached [`e203e5a`](https://github.com/GuitarAlchemist/Demerzel/commit/e203e5a25e10b85b8d22ece9a700e12447f4a236), after the MAT-007 pin. This update syncs it into Learn:
- 23 new modules in the three languages: [MAT-008 to MAT-025](../streeling/mathematics/) and, in [music](../streeling/music/), MUS-007, MUS-008, MUS-009, MUS-018 and MUS-020;
- French and Spanish pages for fifteen modules that had only English here, and the corrections and restored Spanish accents merged in Demerzel since `8c14336`;
- the department indexes;
- the [Streeling journal entry](../streeling/journal/).

These modules and translations stay **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously.

## 2026-10-02 — Streeling MAT-008 to MAT-025, five music modules and fifteen translations published

[Learn PR #114](https://github.com/spareilleux/learn/pull/114) was merged as `48d4e74`, after two corrections to the Streeling journal asked for in an independent review, and its [Pages deployment](https://github.com/spareilleux/learn/actions/runs/37070579523) succeeded. The pages were then read back anonymously in the three languages, 99 module pages in all, each answering 200, naming its module and linking its source at `e203e5a`:
- the 23 new modules, [MAT-008 to MAT-025](../streeling/mathematics/) and, in [music](../streeling/music/), MUS-007, MUS-008, MUS-009, MUS-018 and MUS-020, in English, French and Spanish;
- the French and Spanish pages of the fifteen newly translated modules.

The mathematics and music indexes, the [Streeling journal](../streeling/journal/) and this journal answered 200 as well. These modules and translations therefore move from awaiting verification to verified; their entry above is left as written. This update repins their source links to `d459d8e`. Published is not studied: none of them has been run or studied here, and their experiments remain proposed.

## 2026-10-02 — Music theory lessons 9 to 14 published

Each lesson was merged after its CI passed and an independent review of its final head found nothing left open:
- [Lesson 9](../music-theory-ga/09-voice-leading-and-common-tones/): [PR #90](https://github.com/spareilleux/learn/pull/90), merged as `c547150`;
- [Lesson 10](../music-theory-ga/10-substitutions-and-modal-mixture/): [PR #99](https://github.com/spareilleux/learn/pull/99), merged as `9722af8`;
- [Lesson 11](../music-theory-ga/11-modes-in-depth/): [PR #100](https://github.com/spareilleux/learn/pull/100), merged as `c0abd0e`;
- [Lesson 12](../music-theory-ga/12-symmetry-and-limited-transposition/): [PR #104](https://github.com/spareilleux/learn/pull/104), merged as `641df75`;
- [Lesson 13](../music-theory-ga/13-extended-and-altered-chords/): [PR #108](https://github.com/spareilleux/learn/pull/108), merged as `e2ce788`;
- [Lesson 14](../music-theory-ga/14-guitar-voicings/): [PR #111](https://github.com/spareilleux/learn/pull/111), merged as `1364ba4`.

The [Pages deployment](https://github.com/spareilleux/learn/actions/runs/37070289373) of `1364ba4` succeeded, and so did the later one for #114. All six lessons answered 200 anonymously in the three languages, 18 pages in all.

## 2026-10-02 — Streeling PHY-001 correction synced, awaiting verification

[Demerzel PR #1179](https://github.com/GuitarAlchemist/Demerzel/pull/1179) was merged as `d459d8e`, after the `e203e5a` pin. This update syncs it into Learn:
- the corrected exercise of the [PHY-001 module](../streeling/physics/phy-001-science-of-guitar-sound/), in the three languages: the 2/3 of a perfect fifth is measured from fret 7 to the saddle, not from the nut;
- the [Streeling journal entry](../streeling/journal/).

PHY-001's correction stays **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously.

## 2026-10-03 — Streeling PHY-001 correction published

[Learn PR #117](https://github.com/spareilleux/learn/pull/117) was merged as `8183127`, and its [Pages deployment](https://github.com/spareilleux/learn/actions/runs/37072084405) succeeded. The [PHY-001 module](../streeling/physics/phy-001-science-of-guitar-sound/) and the [Streeling journal](../streeling/journal/) were then read back anonymously in the three languages: six pages, each answering 200. The module pages name PHY-001 and link their source at `d459d8e`; the journal pages carry its 2026-10-02 entry.

PHY-001's correction therefore moves from awaiting verification to verified; its entry above is left as written. This update repins the module's source links to `450fc67`. Published is not studied: PHY-001 has not been run or studied here.

## 2026-10-03 — Music theory lesson 15 published

[Lesson 15](../music-theory-ga/15-the-fretboard/) was merged after its CI passed: [PR #119](https://github.com/spareilleux/learn/pull/119), merged as `89dc3e6`. Its [Pages deployment](https://github.com/spareilleux/learn/actions/runs/37083729662) succeeded. The lesson and the [course journal](../music-theory-ga/journal/) answered 200 anonymously in the three languages, six pages in all.

## 2026-10-03 — Streeling MUS-012 synced, awaiting verification

[Demerzel PR #1180](https://github.com/GuitarAlchemist/Demerzel/pull/1180) was merged as `450fc67`, after the `d459d8e` pin. This update syncs it into Learn:
- the new [MUS-012 module](../streeling/music/mus-012-chord-formulas-essential-tones-doubling/), Chord Formulas, Essential Tones and Doubling, in the three languages;
- its line in the [music index](../streeling/music/) and in the [Streeling journal](../streeling/journal/), with a dated entry there.

MUS-012 stays **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously.

## 2026-10-03 — Streeling MUS-012 published

[Learn PR #124](https://github.com/spareilleux/learn/pull/124) was merged as `062e3cb`, after two corrections to the Streeling journal asked for in an independent review, and its [Pages deployment](https://github.com/spareilleux/learn/actions/runs/37143956527) succeeded. The pages were then read back anonymously in the three languages: twelve pages, each answering 200. The [MUS-012 module](../streeling/music/mus-012-chord-formulas-essential-tones-doubling/) pages name MUS-012 and link their source at `450fc67`; the [music index](../streeling/music/) lists it, and the [Streeling journal](../streeling/journal/) and this journal carry their 2026-10-03 entries.

MUS-012 therefore moves from awaiting verification to verified; its entry above is left as written. This update repins its source links to `928fbb2`. Published is not studied: MUS-012 has not been run or studied here, and its experiment remains proposed.

## 2026-10-03 — Streeling MUS-013 synced, awaiting verification

[Demerzel PR #1181](https://github.com/GuitarAlchemist/Demerzel/pull/1181) was merged as `928fbb2`, after the `450fc67` pin. This update syncs it into Learn:
- the new [MUS-013 module](../streeling/music/mus-013-root-bass-pitch-class-set/), Root, Bass and Pitch-Class Set, in the three languages;
- its line in the [music index](../streeling/music/) and in the [Streeling journal](../streeling/journal/), with a dated entry there.

MUS-013 stays **awaiting verification** until this change is merged, its deployment succeeds and the pages are read back anonymously.

## To verify

- Check this update's public URLs and catalog after deployment; keep the deploy receipt with the integration record.
- Review TARS history at pinned revisions before explaining why v1 approaches changed.
- Add scheduling only after owners, dependencies and estimates are established. No fictional completion dates.

## Open questions

- Can Gaia's existing candidate and operation receipts enforce the same delivery distinction without a second competing state machine?
- Which Streeling gaps should be filled upstream before the canonical Learn sync?
