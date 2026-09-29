---
title: Streeling journal
description: What I studied in Streeling University, what I verified, and what I found wrong.
sidebar:
  label: Journal
  order: 1
---

Tick a module once studied. Under **Notes**, add a dated entry: what I understood, what I tested, and any error found in the module (with a source).

## Progress

### Audio Engineering

- [ ] [AUD-001 · EQ and Compression Order](../audio-engineering/aud-001-eq-compression-order/) <!-- aud-001-eq-compression-order -->

### Cognitive Science

- [ ] [COG-001 · Your Brain Lies to You](../cognitive-science/cog-001-your-brain-lies-to-you/) <!-- cog-001-your-brain-lies-to-you -->

### Computer Science

- [ ] [CS-001 · Thinking Algorithmically](../computer-science/cs-001-thinking-algorithmically/) <!-- cs-001-thinking-algorithmically -->
- [ ] [CS-002 · Governing Agentic Loops](../computer-science/cs-002-governing-agentic-loops/) <!-- cs-002-governing-agentic-loops -->

### Cybernetics

- [ ] [CYB-001 · Viable System Model Mapping to AI Governance](../cybernetics/cyb-001-vsm-ai-governance-mapping/) <!-- cyb-001-vsm-ai-governance-mapping -->
- [ ] [CYB-002 · Active Dampening Mechanisms for Cross-Repo Oscillation Control](../cybernetics/cyb-002-active-dampening-cross-repo-oscillation/) <!-- cyb-002-active-dampening-cross-repo-oscillation -->
- [ ] [CYB-003 · Measuring the Variety Ratio Quantitatively](../cybernetics/cyb-003-measuring-variety-ratio-quantitatively/) <!-- cyb-003-measuring-variety-ratio-quantitatively -->

### Futurology

- [ ] [FUT-001 · Thinking About Tomorrow](../futurology/fut-001-thinking-about-tomorrow/) <!-- fut-001-thinking-about-tomorrow -->

### Guitar Alchemist Academy

- [ ] [GAA-001 · Your First Chord](../guitar-alchemist-academy/gaa-001-your-first-chord/) <!-- gaa-001-your-first-chord -->
- [ ] [GAA-002 · Training Your Ear](../guitar-alchemist-academy/gaa-002-training-your-ear/) <!-- gaa-002-training-your-ear -->
- [ ] [GAA-003 · Improvisation Foundations](../guitar-alchemist-academy/gaa-003-improvisation-foundations/) <!-- gaa-003-improvisation-foundations -->

### Guitar Studies

- [ ] [GTR-001 · The Fretboard Map](../guitar-studies/gtr-001-the-fretboard-map/) <!-- gtr-001-the-fretboard-map -->
- [ ] [GTR-002 · CAGED Geometry](../guitar-studies/gtr-002-caged-geometry/) <!-- gtr-002-caged-geometry -->

### Information Theory

- [ ] [INF-001 · The Entropy of Governance](../information-theory/inf-001-entropy-of-governance/) <!-- inf-001-entropy-of-governance -->

### Mathematics

- [ ] [MAT-001 · Proof Strategies](../mathematics/mat-001-proof-strategies/) <!-- mat-001-proof-strategies -->
- [ ] [MAT-002 · Counterexamples, Witnesses and Exhaustive Checks](../mathematics/mat-002-counterexamples-and-exhaustive-checks/) <!-- mat-002-counterexamples-and-exhaustive-checks -->
- [ ] [MAT-003 · Floating-Point Arithmetic and Conditioning](../mathematics/mat-003-floating-point-conditioning/) <!-- mat-003-floating-point-conditioning -->
- [ ] [MAT-004 · Vectors, Matrices, Norms and Linear Maps](../mathematics/mat-004-vectors-matrices-norms/) <!-- mat-004-vectors-matrices-norms -->
- [ ] [MAT-005 · Symmetric Eigenproblems](../mathematics/mat-005-symmetric-eigenproblems/) <!-- mat-005-symmetric-eigenproblems -->
- [ ] [MAT-006 · Singular Value Decomposition and Low-Rank Approximation](../mathematics/mat-006-svd-low-rank-approximation/) <!-- mat-006-svd-low-rank-approximation -->
- [ ] [MAT-007 · Least Squares, Regularisation and Identifiability](../mathematics/mat-007-least-squares-regularisation/) <!-- mat-007-least-squares-regularisation -->

### Music

- [ ] [MUS-001 · What Is a Chord?](../music/mus-001-what-is-a-chord/) <!-- mus-001-what-is-a-chord -->
- [ ] [MUS-002 · Beyond Tonality](../music/mus-002-beyond-tonality/) <!-- mus-002-beyond-tonality -->
- [ ] [MUS-003 · How Harmony Works](../music/mus-003-functional-harmony/) <!-- mus-003-functional-harmony -->
- [ ] [MUS-004 · Rhythm, Meter, and Groove](../music/mus-004-rhythm-and-groove/) <!-- mus-004-rhythm-and-groove -->
- [ ] [MUS-005 · Jazz Harmony for Guitar](../music/mus-005-jazz-harmony/) <!-- mus-005-jazz-harmony -->
- [ ] [MUS-006 · The Scale Universe](../music/mus-006-the-scale-universe/) <!-- mus-006-the-scale-universe -->

### Musicology

- [ ] [MCL-001 · How Music Evolves](../musicology/mcl-001-how-music-evolves/) <!-- mcl-001-how-music-evolves -->
- [ ] [MCL-002 · Musical Form and Structure](../musicology/mcl-002-musical-form/) <!-- mcl-002-musical-form -->

### Network Science

- [ ] [NET-001 · Scale-Free Tool Networks](../network-science/net-001-scale-free-tool-networks/) <!-- net-001-scale-free-tool-networks -->

### Philosophy

- [ ] [PHI-001 · How to Argue Well](../philosophy/phi-001-how-to-argue-well/) <!-- phi-001-how-to-argue-well -->

### Physics

- [ ] [PHY-001 · The Science of Guitar Sound](../physics/phy-001-science-of-guitar-sound/) <!-- phy-001-science-of-guitar-sound -->

### Product and Project Management

- [ ] [PM-001 · Shipping vs Talking](../product-management/pm-001-shipping-vs-talking/) <!-- pm-001-shipping-vs-talking -->

### Psychohistory

- [ ] [PSY-001 · Introduction to Fractal Compounding](../psychohistory/psy-001-intro-fractal-compounding/) <!-- psy-001-intro-fractal-compounding -->
- [ ] [PSY-002 · Governance Phase Transitions](../psychohistory/psy-002-governance-phase-transitions/) <!-- psy-002-governance-phase-transitions -->

### Semiotics

- [ ] [SEM-001 · Signs in Governance](../semiotics/sem-001-signs-in-governance/) <!-- sem-001-signs-in-governance -->

### World Music & Languages

- [ ] [WML-001 · Guitar Around the World](../world-music-languages/wml-001-guitar-around-the-world/) <!-- wml-001-guitar-around-the-world -->

## QA

| Expected | What happens | Where | Measurement | Status |
|---|---|---|---|---|
| A least-squares fit of a full-rank design returns the fit, or an error | IX's `LinearRegression::fit` returns a wrong line without any error at c = 10^6, for y = 2x + 1 on x = c + (0, 1, 2), and panics at c = 10^7 | [`linear_regression.rs:68`](https://github.com/GuitarAlchemist/ix/blob/e35138b9d4c707d48f802649a7fcb3f7fc94934d/crates/ix-supervised/src/linear_regression.rs#L68), [`linalg.rs:110`](https://github.com/GuitarAlchemist/ix/blob/e35138b9d4c707d48f802649a7fcb3f7fc94934d/crates/ix-math/src/linalg.rs#L110) at `e35138b9` | At c = 10^6: slope 2 + 2^-11, bias 0, largest miss 487.3. At c = 10^7: the panic `X^T X is singular: Singular`. Centering the feature gives the exact answer at every c | Reproduced in the [MAT-007 lab](#2026-09-28--mat-007--the-lab-steps-1-and-2) (Windows 11 x86-64); not reported to IX |
| `reconstruct` returns U Σ Vᵀ with the singular values `svd` returned | Below the absolute threshold 10^-12, IX leaves the column of U at zero, so `reconstruct` silently drops that term while the singular values stay right | [`svd.rs:199`](https://github.com/GuitarAlchemist/ix/blob/e35138b9d4c707d48f802649a7fcb3f7fc94934d/crates/ix-math/src/svd.rs#L199) at `e35138b9` | 10^-12 · A: relative error 0.0539, the rank-1 truncation. 10^-13 · A: 1, the zero matrix. The singular values are within 1.1 × 10^-15 at both | Reproduced in the [MAT-006 lab](#2026-09-28--mat-006--the-lab) (Windows 11 x86-64); not reported to IX |
| A stopping test that is scale-invariant, as its comment says | The test compares a sum of degree 4 in A with ‖A‖_F², of degree 2: for a small A it stops after the first sweep and returns `Ok`; for a large A the call takes longer | [`svd.rs:174`](https://github.com/GuitarAlchemist/ix/blob/e35138b9d4c707d48f802649a7fcb3f7fc94934d/crates/ix-math/src/svd.rs#L174) at `e35138b9` | 10^-13 · M: a singular value off by 196%. 10^6 · A and 10^6 · M: 10.10 and 8.77 times as long as A and M, on one machine | Reproduced in the [MAT-006 lab](#2026-09-28--mat-006--the-lab) (Windows 11 x86-64; timing local only); not reported to IX |

## Experiments

| Question | Hypothesis, written before measuring | Result | Verdict | Links |
|---|---|---|---|---|
| Where does IX's normal-equation fit fail on offset data x = c + (0, 1, 2)? | MAT-007 §6: slope within 10^-9 of 2 up to c = 10^3; slope 2 − 2^-18 and bias 1.5 at 10^5; slope 2 + 2^-11 and bias 0 at 10^6; a panic at 10^7 | All four, bit for bit where the value is exact; largest miss 487.3 at 10^6 | Confirmed | [entry](#2026-09-28--mat-007--the-lab-steps-1-and-2), [code](https://github.com/spareilleux/learn/tree/41f70224075dcfc3d6155485672eff102c22d547/code/streeling-mathematics) |
| Does centering the feature fix it? | Slope exactly 2 and bias 2c + 3 within a relative 10^-15, at every c | Exact at every c up to 10^7 | Confirmed | [entry](#2026-09-28--mat-007--the-lab-steps-1-and-2), [code](https://github.com/spareilleux/learn/tree/41f70224075dcfc3d6155485672eff102c22d547/code/streeling-mathematics) |
| How much do the normal equations lose against the SVD on a nearly collinear design? | Error below 10^-9 up to N = 10^3, about 3 × 10^-5 at 10^5, about 0.25 at 10^7 with no error raised; SVD route below 10^-7 | At most 3.3 × 10^-10, then 3.05 × 10^-5 and 0.250; SVD route at most 1.5 × 10^-8 | Confirmed | [entry](#2026-09-28--mat-007--the-lab-steps-1-and-2), [code](https://github.com/spareilleux/learn/tree/41f70224075dcfc3d6155485672eff102c22d547/code/streeling-mathematics) |
| Does IX's `truncated_svd` meet Eckart–Young? | MAT-006 §7: ‖X − Xₖ‖_F equals √(σₖ₊₁² + …) for every k, on A and M, and falls to 0 at full rank up to rounding | Equal within 4.8 × 10^-15 at every k | Confirmed | [entry](#2026-09-28--mat-006--the-lab), [code](https://github.com/spareilleux/learn/tree/ebe3f98e80657a12ca8fdd683850d5e09b73eb84/code/streeling-mathematics) |
| How does IX's `svd` behave from 10^-14 · X to 10^12 · X? | A: singular values within 10^-12 at every scale; `reconstruct` error below 10^-12 from 10^-11, about 0.054 at 10^-12, exactly 1 below. M: within 10^-12 from 10^-10, over 100% off at 10^-13 and below | A: within 1.1 × 10^-15; error 0.0539 at 10^-12, 1 below. M: within 6.6 × 10^-15 from 10^-10, 196% off at 10^-13 and below | Confirmed | [entry](#2026-09-28--mat-006--the-lab), [code](https://github.com/spareilleux/learn/tree/ebe3f98e80657a12ca8fdd683850d5e09b73eb84/code/streeling-mathematics) |
| Does scale cost time? | MAT-006 §7: `svd` of 10^6 · X takes several times as long as `svd` of X (judged as a ratio of at least 3) | 10.10 for A, 8.77 for M, on one machine | Confirmed, locally | [entry](#2026-09-28--mat-006--the-lab), [code](https://github.com/spareilleux/learn/tree/ebe3f98e80657a12ca8fdd683850d5e09b73eb84/code/streeling-mathematics) |
| Does the number of sweeps explain MAT-003's puzzle? | MAT-006 §7: capped at k sweeps, the singular values of `svd_with_opts` on 2^20 · fl(H_n), divided by 2^20, equal bit for bit those of `svd(fl(H_n))` for a first value of k, and those of `svd(2^-20 · fl(H_n))` divided by 2^-20 for a second one: 2 and 2 for n = 2, 4 and 3 for n = 3 to 6, 5 and 4 for n = 7 to 14, 6 and 4 for n = 15 and 16 | Both sets of singular values reproduced for every n; U and V not compared. The first k is the predicted one from n = 6 and lower for n = 2 to 5; post hoc, the predicted k matches too | Refuted in part | [entry](#2026-09-28--mat-006--the-lab), [code](https://github.com/spareilleux/learn/tree/ebe3f98e80657a12ca8fdd683850d5e09b73eb84/code/streeling-mathematics) |
| Does an absolute rank tolerance see 10^-12 · I₃? | MAT-006 §7: `rank(1e-10)` is 0, `rank(3 σ₁ ε)` is 3 | 0 and 3 | Confirmed | [entry](#2026-09-28--mat-006--the-lab), [code](https://github.com/spareilleux/learn/tree/ebe3f98e80657a12ca8fdd683850d5e09b73eb84/code/streeling-mathematics) |
| How tight is IX's rank-1 truncation test? | MAT-006 §6: a relative error of about 0.054, against the 0.10 the test accepts | 0.053913 | Confirmed | [entry](#2026-09-28--mat-006--the-lab), [code](https://github.com/spareilleux/learn/tree/ebe3f98e80657a12ca8fdd683850d5e09b73eb84/code/streeling-mathematics) |

## Notes

<!-- ## YYYY-MM-DD — CODE · Title -->

## 2026-09-27 — MAT-003 · Floating-Point Arithmetic and Conditioning

Synced from Demerzel at [`89a1bdb`](https://github.com/GuitarAlchemist/Demerzel/commit/89a1bdb2801d32424dd17287ba67185572610277) (PR #1134). The module's numbers come from the Learn lab [`code/streeling-mathematics`](https://github.com/spareilleux/learn/tree/c8135fa508fcb9d35593e8dedbb925c44282b3a2/code/streeling-mathematics), which pins IX `ix-math` at `e35138b9` and checks the Hilbert matrices H_2 to H_16 against their exact integer inverse. They were measured on Windows 11 x86-64; hosted CI reproduced the printed output on Linux, Windows and macOS.

- IX's `inverse` first answers `Singular` at n = 11. Multiplying H by 2^-20 moves that to n = 6; multiplying it by 2^20 removes it up to n = 16, and an inverse accepted at n = 14 has a forward error of 1.04 (no correct digit).
- Error found and corrected before publication: IX's κ₂ falls below κ∞/n from n = 10, and a first reading took that as proof of a wrong SVD. The band κ∞/n ≤ κ₂ ≤ κ∞ holds for one matrix, and the lab compared the exact H_n with the stored fl(H_n): an observation, not a defect.
- Still open: multiplying fl(H) by an exact power of two changes IX's κ₂ (identical bits at the three scales for 5 sizes out of 15), so at least two of the three answers are not κ₂ of their input. Which one is right is not established.

## 2026-09-27 — MAT-002 · Counterexamples, Witnesses and Exhaustive Checks

Synced from Demerzel at [`a3a07df`](https://github.com/GuitarAlchemist/Demerzel/commit/a3a07df103c1f13a4dec45514fe775bfd4f76e77) ([PR #1136](https://github.com/GuitarAlchemist/Demerzel/pull/1136), reviewed independently at `5e6b733` before its merge). The module reads IX's code at [`e35138b9`](https://github.com/GuitarAlchemist/ix/tree/e35138b9d4c707d48f802649a7fcb3f7fc94934d) and covers two things:
- what the exhaustive tests of the dihedral group D12 establish;
- why the Petri-net analyser can report a deadlock from an unfinished search, but not its absence.

Nothing in it was run here.

- **The experiment in its section 7 is only proposed.** It would run in a Learn lab, with predictions written before any run: associativity of IX's `compose` over the 13,824 triples, two faulty product rules as negative controls, and the replay of a deadlock witness. No such lab exists yet, and nothing in the module is a measurement.
- **It has not been studied here,** so its checkbox above stays empty.

## 2026-09-27 — MAT-004 · Vectors, Matrices, Norms and Linear Maps

Synced from Demerzel at [`d451c90`](https://github.com/GuitarAlchemist/Demerzel/commit/d451c909f69d9774901bdd99195ead8444098320) ([PR #1137](https://github.com/GuitarAlchemist/Demerzel/pull/1137)). The module reads IX's code at [`e35138b9`](https://github.com/GuitarAlchemist/ix/tree/e35138b9d4c707d48f802649a7fcb3f7fc94934d) and covers two things:
- what IX's linear-algebra functions compute, among them a determinant by cofactor expansion, and that `linalg.rs` has no function that returns a matrix norm;
- which of IX's distances are metrics: `minkowski` rejects every p below 1 but lets p = ∞ through, and `cosine_distance` does not satisfy the triangle inequality.

Nothing in it was run here.

- **The experiment in its section 7 is only proposed.** It would run in a Learn lab, with predictions written before any run: the triangle inequality over the 15,625 triples of a 5 × 5 grid for four distances; `minkowski` with p = 1/2, p = ∞ and p = 1000; the cost of `determinant` for n = 2 to 11, and its product rule on 3 × 3 integer matrices. No such lab exists yet, and nothing in the module is a measurement.
- **It has not been studied here,** so its checkbox above stays empty.

## 2026-09-27 — MAT-005 · Symmetric Eigenproblems

Synced from Demerzel at [`8bd026f`](https://github.com/GuitarAlchemist/Demerzel/commit/8bd026f9e48065c482faeae5cacf8e4808fff4cc) ([PR #1138](https://github.com/GuitarAlchemist/Demerzel/pull/1138); before the merge, a Codex review found no major issues on its final head, `4ac3ca6`). The module reads IX's code at [`e35138b9`](https://github.com/GuitarAlchemist/ix/tree/e35138b9d4c707d48f802649a7fcb3f7fc94934d) and covers two things:
- the contract of IX's symmetric solver, `symmetric_eigen`, a cyclic Jacobi method: it does not check symmetry and does not report convergence;
- why plain PCA in IX does not use that solver: it extracts its components by power iteration and deflation, from a fixed start vector.

Nothing in it was run here.

- **The experiment in its section 8 is only proposed.** It would run in a Learn lab, with predictions written before any run: the invariants A v = λ v, VᵀV = I and A = V Λ Vᵀ on four matrices; the eigenspace of a repeated eigenvalue; `symmetric_eigen` and `ix_eigen` on a non-symmetric matrix; and PCA on six points whose main axis it is predicted to miss. No such lab exists yet, and nothing in the module is a measurement.
- **It has not been studied here,** so its checkbox above stays empty.

## 2026-09-27 — MAT-006 · Singular Value Decomposition and Low-Rank Approximation

Synced from Demerzel at [`0b13b9d`](https://github.com/GuitarAlchemist/Demerzel/commit/0b13b9d56cc4b657cde6f3ce958c162610065c2f) ([PR #1139](https://github.com/GuitarAlchemist/Demerzel/pull/1139); before the merge, a Codex review found no major issues on its final head, `4839e89`). Its prerequisites, MAT-004 and MAT-005, are already on this site. The module reads IX's code at [`e35138b9`](https://github.com/GuitarAlchemist/ix/tree/e35138b9d4c707d48f802649a7fcb3f7fc94934d) and covers two things:
- the contract of IX's `svd`, a one-sided Jacobi method: its stopping test is not scale-invariant, although its comment says it is; it returns `Ok` after 50 sweeps whether or not that test was met; and a column of U stays zero when its singular value is below the absolute threshold 10^-12;
- the rank tolerance, which `rank` and `pseudo_inverse` leave to the caller.

It also offers an explanation for the question the MAT-003 entry above leaves open: multiplying fl(H) by a power of two is exact, so only the number of sweeps can change IX's κ₂. That is the module's analysis, made on a Python transcription of `svd`, not an IX run. The MAT-003 item stays open until the lab runs the check.

Nothing in it was run here.

- **The experiment in its section 7 is only proposed.** It would run in a Learn lab, with predictions written before any run: Eckart–Young for every k on two matrices; a scale sweep from 10^-14 to 10^12; the cost of scale; MAT-003's puzzle with `svd_with_opts`; two rank conventions; and the bound that one of IX's tests checks. No such lab exists yet, and nothing in the module is a measurement.
- **It has not been studied here,** so its checkbox above stays empty.

## 2026-09-27 — MAT-007 · Least Squares, Regularisation and Identifiability

Synced from Demerzel at [`8c14336`](https://github.com/GuitarAlchemist/Demerzel/commit/8c14336ecd9601615e08c20dca696cd0e021563e) ([PR #1140](https://github.com/GuitarAlchemist/Demerzel/pull/1140); before the merge, a Codex review found no major issues on its final head, `cc6788d`). Its prerequisites, MAT-003 and MAT-006, are already synced here. The module reads IX's code at [`e35138b9`](https://github.com/GuitarAlchemist/ix/tree/e35138b9d4c707d48f802649a7fcb3f7fc94934d) and covers two things:
- what IX's `LinearRegression::fit` does: it solves the normal equations with an explicit inverse, so it squares the condition number, its verdict depends on the scale and offset of the data, and it panics when `inverse` answers `Singular`;
- what that panic does to its callers: `ix-duck` catches it, the MCP handler of `ix_linear_regression` does not, and the module predicts, from reading the code, that one such request poisons a mutex and leaves the later registry-backed calls without a response until the server restarts.

Nothing in it was run here.

- **The experiment in its section 6 is only proposed.** It would run in a Learn lab, with predictions written before any run: an offset sweep from c = 1 to 10^7; the normal equations against the SVD route; the MCP server after a panic, in a disposable process only; and the input schema's `"X"` key against the `"x"` the handler reads. No such lab exists yet, and nothing in the module is a measurement.
- **It has not been studied here,** so its checkbox above stays empty.

## 2026-09-28 — MAT-007 · The lab, steps 1 and 2

The Learn lab [`code/streeling-mathematics`](https://github.com/spareilleux/learn/tree/41f70224075dcfc3d6155485672eff102c22d547/code/streeling-mathematics) ran steps 1 and 2 of the experiment in MAT-007's section 6, against IX `ix-supervised` and `ix-math` pinned at `e35138b9`. The predictions are the module's own. They are quoted in a [pre-registration](https://github.com/spareilleux/learn/blob/d269063dc904d2e2c5d1e74e2e2334cc8a2b5a34/code/streeling-mathematics/preregistration-mat007.md), committed on its own before any code of the lab existed, which also set the margins for the module's approximate values before the run. The measurements were made on Windows 11 x86-64; hosted CI [reproduced the printed output](https://github.com/spareilleux/learn/actions/runs/36475256549) on Linux, Windows and macOS.

- **All nine predictions held on the first run** (tables above), the exact ones bit for bit. At c = 10^6, IX's `fit` returns the slope 2 + 2^-11 and the bias 0 with no error, and misses the data by up to 487.3; at c = 10^7, it panics.
- **Measured without a prediction, and only reported:** at c = 10^4, the slope is 2 + 2^-24 and the bias 1 − 2^-11. At N = 10^2, the SVD route's error, 1.29 × 10^-10, is larger than the normal equations' error, 2.05 × 10^-11. The cause is not established.
- **Not run:** steps 3 and 4, the MCP server after a panic and the input schema. They need `ix-agent` and a disposable `ix-mcp` process, and they stay proposed.
- **The module at `8c14336` says its experiment has not been run.** Reporting these results in it is for its Demerzel source. Its checkbox above stays empty: running the lab is not studying the module.

## 2026-09-28 — MAT-006 · The lab

The Learn lab [`code/streeling-mathematics`](https://github.com/spareilleux/learn/tree/ebe3f98e80657a12ca8fdd683850d5e09b73eb84/code/streeling-mathematics) ran the experiment in MAT-006's section 7, and the exercise of its section 6, against IX `ix-math` pinned at `e35138b9`. The predictions are the module's own. They are quoted in a [pre-registration](https://github.com/spareilleux/learn/blob/b141d3bbe984744fff21a4b7a7c465da29b795dc/code/streeling-mathematics/preregistration-mat006.md), committed on its own before any code of this part existed, which also set before the run how "about", "up to rounding" and "several" are judged. The measurements were made on Windows 11 x86-64; hosted CI [reproduced the printed output](https://github.com/spareilleux/learn/actions/runs/36477204960) on Linux, Windows and macOS.

- **Eight predictions held on the first run** (tables above). Eckart–Young holds for every k within 4.8 × 10^-15. At 10^-12 · A, `reconstruct` returns the rank-1 truncation, a relative error of 0.0539, while the singular values stay right; at 10^-13 · A, it returns the zero matrix. At 10^-13 · M, `svd` returns `Ok` with a singular value off by 196%.
- **One was refuted in part: MAT-003's puzzle.** Capped at k sweeps, the singular values of `svd_with_opts` on 2^20 · fl(H_n), divided by 2^20, equal bit for bit those of IX's result on fl(H_n), and those of its result on 2^-20 · fl(H_n) divided by 2^-20, for every n from 2 to 16; U and V are not compared. That is what the module's explanation needs: the question the MAT-003 entry leaves open is consistent with a difference in the number of sweeps, although the lab does not count the sweeps the uncapped calls execute. The smallest such k is the predicted one from n = 6 to 16, but it is lower for n = 2 to 5. Post hoc, the predicted k also reproduces both results for every n: for n = 2 to 5, the last sweeps change no bit. Which of MAT-003's three κ₂ is closest to κ₂ of fl(H_n) is still not established here.
- **The cost of scale was timed on one machine only:** 20,000 calls on 10^6 · A take 10.10 times as long as on A, and 8.77 times for M, on an Intel Core Ultra 9 285K under Windows 11 Pro. CI does not time anything.
- **Measured without a prediction, and only reported:** at 10^-12 and 10^-11, the singular values of M are off by 3.4 × 10^-9, between the accurate range and the failing one. The singular values of fl(H_n) at scale 1 and at scale 2^-20 differ for 11 of the 15 sizes; MAT-003 compared κ₂, not the singular values.
- **Not run:** the `ix_svd` half of step 5, which goes through the MCP server.
- **The module at `0b13b9d` says its experiment has not been run.** Reporting these results in it is for its Demerzel source. Its checkbox above stays empty: running the lab is not studying the module.
