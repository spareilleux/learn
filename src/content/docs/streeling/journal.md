---
title: Streeling journal
description: What I studied in Streeling University, what I verified, and what I found wrong.
sidebar:
  label: Journal
  order: 1
---

Tick a module once studied. Under **Notes**, add a dated entry: what I understood, what I tested, and any error found in the module (with a source).

## Progress

## QA

| Expected | Observed defect | Correction and measurement | Status and evidence |
| --- | --- | --- | --- |
| Localized course descriptions match their titles. | 32 FR/ES metadata values remained English. | 118 passes/32 failures before; 150 passes/0 failures after 32 scalar corrections. | Fixed in this batch; [exact source changes](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/root-metadata-fix.json), [failed run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/metadata-before-fix.json), [replay](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/metadata-after-guard.json). |
| Tests reject missing coverage and record enough diagnostics. | Empty-plan false green; assertions before observations; printed delay/coverage expectations not independently asserted. | Cardinality guard, reordered observation paths, independent values/support checks. Replays: 69 new-course tests and six baseline tests pass. | Fixed in the reviewed test harness; [diagnosis and retained attempts](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal.md). Fixed-model evidence; real software, listening and learner trials remain pending. |


## Experiments

| Question | Hypothesis/status | Observed result | Verdict and limits | Record |
| --- | --- | --- | --- | --- |
| Are the supplied FUT011 point widths interval centres? | Actual classroom premise check, before prose correction. | Two mismatches (samples 1 and 5); supplied trace has 3 switches, centre trace 1. | Refuted. Corrected to admissible points, not necessarily centres; no measured uncertainty or engine benefit. | [Failed premise](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/fut011-midpoint-before-fix.json), [correction replay](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/fut011-point-label-after-fix.json) |
| Does the existing Streeling generator regression suite still pass? | Regression check; not a scientific preregistration. | 18 passed, 0 failed; Node v24.12.0. | Pass for these generator checks; no domain or learner claim. | [Retained run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/generator-initial.json) |
| Does the generator remain compatible at the next batch baseline (2026-10-24)? | Retrospective regression expectation; no scientific preregistration. | 18 passed, zero failed. | Pass for generator checks only. | [Actual run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/generator-initial.json) |
| Does the generator remain compatible at the next batch baseline (2026-10-25)? | Retrospective regression expectation; no scientific preregistration. | 18 passed, zero failed. | Pass for generator checks only. | [Actual run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/test-runs/generator-initial.json) |


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

### IX Research

- [ ] [IXR-001 · Streams Under Budgets](../ix-research/ixr-001-streams-under-budgets/) <!-- ixr-001-streams-under-budgets -->

### Mathematics

- [ ] [MAT-001 · Proof Strategies](../mathematics/mat-001-proof-strategies/) <!-- mat-001-proof-strategies -->
- [ ] [MAT-002 · Counterexamples, Witnesses and Exhaustive Checks](../mathematics/mat-002-counterexamples-and-exhaustive-checks/) <!-- mat-002-counterexamples-and-exhaustive-checks -->
- [ ] [MAT-003 · Floating-Point Arithmetic and Conditioning](../mathematics/mat-003-floating-point-conditioning/) <!-- mat-003-floating-point-conditioning -->
- [ ] [MAT-004 · Vectors, Matrices, Norms and Linear Maps](../mathematics/mat-004-vectors-matrices-norms/) <!-- mat-004-vectors-matrices-norms -->
- [ ] [MAT-005 · Symmetric Eigenproblems](../mathematics/mat-005-symmetric-eigenproblems/) <!-- mat-005-symmetric-eigenproblems -->
- [ ] [MAT-006 · Singular Value Decomposition and Low-Rank Approximation](../mathematics/mat-006-svd-low-rank-approximation/) <!-- mat-006-svd-low-rank-approximation -->
- [ ] [MAT-007 · Least Squares, Regularisation and Identifiability](../mathematics/mat-007-least-squares-regularisation/) <!-- mat-007-least-squares-regularisation -->
- [ ] [MAT-008 · Probability and Conditional Reasoning](../mathematics/mat-008-probability-conditional-reasoning/) <!-- mat-008-probability-conditional-reasoning -->
- [ ] [MAT-009 · Estimation, Uncertainty and Reproducible Sampling](../mathematics/mat-009-estimation-uncertainty-sampling/) <!-- mat-009-estimation-uncertainty-sampling -->
- [ ] [MAT-010 · Entropy, Divergences and Mutual Information](../mathematics/mat-010-information-entropy-divergences/) <!-- mat-010-information-entropy-divergences -->
- [ ] [MAT-011 · Gradients and Reverse-Mode Automatic Differentiation](../mathematics/mat-011-gradients-reverse-mode-autodiff/) <!-- mat-011-gradients-reverse-mode-autodiff -->
- [ ] [MAT-012 · Iterative Optimisation](../mathematics/mat-012-iterative-optimisation/) <!-- mat-012-iterative-optimisation -->
- [ ] [MAT-013 · Distances, Kernels and Positive Semidefinite Matrices](../mathematics/mat-013-distances-kernels-psd/) <!-- mat-013-distances-kernels-psd -->
- [ ] [MAT-014 · PCA as Variance Preservation](../mathematics/mat-014-pca-variance-preservation/) <!-- mat-014-pca-variance-preservation -->
- [ ] [MAT-015 · Classical MDS and Distance Preservation](../mathematics/mat-015-classical-mds-distance-preservation/) <!-- mat-015-classical-mds-distance-preservation -->
- [ ] [MAT-016 · Kernel PCA and Misleading Projections](../mathematics/mat-016-kernel-pca-misleading-projections/) <!-- mat-016-kernel-pca-misleading-projections -->
- [ ] [MAT-017 · Non-negative Matrix Factorisation](../mathematics/mat-017-nonnegative-matrix-factorisation/) <!-- mat-017-nonnegative-matrix-factorisation -->
- [ ] [MAT-018 · Clustering, Density and Cluster Validity](../mathematics/mat-018-clustering-density-validity/) <!-- mat-018-clustering-density-validity -->
- [ ] [MAT-019 · Graphs, Centrality and Spectral Structure](../mathematics/mat-019-graphs-centrality-spectral/) <!-- mat-019-graphs-centrality-spectral -->
- [ ] [MAT-020 · Markov Chains and Hidden Markov Models](../mathematics/mat-020-markov-chains-hmm/) <!-- mat-020-markov-chains-hmm -->
- [ ] [MAT-021 · Fourier Analysis and Signals](../mathematics/mat-021-fourier-analysis-signals/) <!-- mat-021-fourier-analysis-signals -->
- [ ] [MAT-022 · Symmetry, Groups and Invariants](../mathematics/mat-022-symmetry-groups-invariants/) <!-- mat-022-symmetry-groups-invariants -->
- [ ] [MAT-023 · Petri Nets and Reachability](../mathematics/mat-023-petri-nets-reachability/) <!-- mat-023-petri-nets-reachability -->
- [ ] [MAT-024 · Dynamical Systems, Stability and Feedback](../mathematics/mat-024-dynamical-systems-stability-feedback/) <!-- mat-024-dynamical-systems-stability-feedback -->
- [ ] [MAT-025 · Allocation Under Constraints, Games, Bandits and Penalties](../mathematics/mat-025-allocation-games-bandits-penalties/) <!-- mat-025-allocation-games-bandits-penalties -->

### Music

- [ ] [MUS-001 · What Is a Chord?](../music/mus-001-what-is-a-chord/) <!-- mus-001-what-is-a-chord -->
- [ ] [MUS-002 · Beyond Tonality](../music/mus-002-beyond-tonality/) <!-- mus-002-beyond-tonality -->
- [ ] [MUS-003 · How Harmony Works](../music/mus-003-functional-harmony/) <!-- mus-003-functional-harmony -->
- [ ] [MUS-004 · Rhythm, Meter, and Groove](../music/mus-004-rhythm-and-groove/) <!-- mus-004-rhythm-and-groove -->
- [ ] [MUS-005 · Jazz Harmony for Guitar](../music/mus-005-jazz-harmony/) <!-- mus-005-jazz-harmony -->
- [ ] [MUS-006 · The Scale Universe](../music/mus-006-the-scale-universe/) <!-- mus-006-the-scale-universe -->
- [ ] [MUS-007 · Pitch, Spelling and Enharmonic Identity](../music/mus-007-pitch-spelling-enharmonic-identity/) <!-- mus-007-pitch-spelling-enharmonic-identity -->
- [ ] [MUS-008 · Intervals, Inversion and Compound Intervals](../music/mus-008-intervals-inversion-compound/) <!-- mus-008-intervals-inversion-compound -->
- [ ] [MUS-009 · Tuning and Fretboard Geometry](../music/mus-009-tuning-fretboard-geometry/) <!-- mus-009-tuning-fretboard-geometry -->
- [ ] [MUS-010 · Scale Patterns, Sets and the Diatonic Interval Vector](../music/mus-010-scales-pattern-set-interval-vector/) <!-- mus-010-scales-pattern-set-interval-vector -->
- [ ] [MUS-011 · Modes and Modal Families](../music/mus-011-modes-modal-families/) <!-- mus-011-modes-modal-families -->
- [ ] [MUS-012 · Chord Formulas, Essential Tones and Doubling](../music/mus-012-chord-formulas-essential-tones-doubling/) <!-- mus-012-chord-formulas-essential-tones-doubling -->
- [ ] [MUS-013 · Root, Bass and Pitch-Class Set](../music/mus-013-root-bass-pitch-class-set/) <!-- mus-013-root-bass-pitch-class-set -->
- [ ] [MUS-014 · Inversions and the Bass Line](../music/mus-014-inversions-bass-line/) <!-- mus-014-inversions-bass-line -->
- [ ] [MUS-018 · Key Finding, Roman Numerals and Cadences](../music/mus-018-key-finding-roman-numerals-cadences/) <!-- mus-018-key-finding-roman-numerals-cadences -->
- [ ] [MUS-019 · Transposition, the Capo and Cross-Instrument Equivalence](../music/mus-019-transposition-capo-cross-instrument/) <!-- mus-019-transposition-capo-cross-instrument -->
- [ ] [MUS-020 · Set Classes, Interval Vectors, the Z-Relation and Prime Forms](../music/mus-020-set-classes-interval-vectors-prime-forms/) <!-- mus-020-set-classes-interval-vectors-prime-forms -->
- [ ] [MUS-021 · The Pitch-Class DFT](../music/mus-021-pitch-class-dft-magnitudes-phases-homometry/) <!-- mus-021-pitch-class-dft-magnitudes-phases-homometry -->
- [ ] [MUS-022 · Grothendieck Deltas](../music/mus-022-grothendieck-deltas-icv-distance/) <!-- mus-022-grothendieck-deltas-icv-distance -->

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
- [ ] [PSY-003 · Measure Recursive Improvement Across Review and Publication](../psychohistory/psy-003-review-throughput-and-compounding/) <!-- psy-003-review-throughput-and-compounding -->
- [ ] [PSY-004 · How Large Is Large? Aggregate Predictability with Fourteen Agents](../psychohistory/psy-004-how-large-is-large/) <!-- psy-004-how-large-is-large -->
- [ ] [PSY-005 · Persistence First](../psychohistory/psy-005-persistence-baseline/) <!-- psy-005-persistence-baseline -->
- [ ] [PSY-006 · Estimate a Transition Matrix from Observed Counts](../psychohistory/psy-006-transition-matrix-from-counts/) <!-- psy-006-transition-matrix-from-counts -->
- [ ] [PSY-007 · Is It a Power Law? Eighteen Citation Counts](../psychohistory/psy-007-power-law-or-not/) <!-- psy-007-power-law-or-not -->
- [ ] [PSY-008 · Bursts Are Not Rates](../psychohistory/psy-008-bursts-are-not-rates/) <!-- psy-008-bursts-are-not-rates -->
- [ ] [PSY-009 · Concentration](../psychohistory/psy-009-concentration-and-heavy-tails/) <!-- psy-009-concentration-and-heavy-tails -->
- [ ] [PSY-010 · Exponential, Logistic or Steps? Fitting Growth to a Short History](../psychohistory/psy-010-growth-curves-short-series/) <!-- psy-010-growth-curves-short-series -->
- [ ] [PSY-011 · Measurement Change or System Change? Rebaselines in the Quality Trend](../psychohistory/psy-011-measurement-change-or-system-change/) <!-- psy-011-measurement-change-or-system-change -->
- [ ] [PSY-012 · Early-Warning Signals and Their False Alarms](../psychohistory/psy-012-early-warning-false-alarms/) <!-- psy-012-early-warning-false-alarms -->
- [ ] [PSY-013 · Four Scores and a Trend](../psychohistory/psy-013-four-scores-and-a-trend/) <!-- psy-013-four-scores-and-a-trend -->
- [ ] [PSY-014 · Prediction Horizons](../psychohistory/psy-014-prediction-horizons/) <!-- psy-014-prediction-horizons -->
- [ ] [PSY-015 · Belief Contagion in a Small Population](../psychohistory/psy-015-belief-contagion-small-population/) <!-- psy-015-belief-contagion-small-population -->
- [ ] [PSY-016 · Probability Forecasts and the Brier Score](../psychohistory/psy-016-brier-score/) <!-- psy-016-brier-score -->
- [ ] [PSY-017 · Calibration with Six Observations](../psychohistory/psy-017-calibration-with-six-observations/) <!-- psy-017-calibration-with-six-observations -->
- [ ] [PSY-018 · Backtesting Without Leakage](../psychohistory/psy-018-backtesting-without-leakage/) <!-- psy-018-backtesting-without-leakage -->
- [ ] [PSY-019 · Combining Forecasters Who Share a Source](../psychohistory/psy-019-combining-correlated-forecasters/) <!-- psy-019-combining-correlated-forecasters -->
- [ ] [PSY-020 · When the Measure Becomes the Target](../psychohistory/psy-020-goodhart-and-reflexivity/) <!-- psy-020-goodhart-and-reflexivity -->
- [ ] [PSY-021 · Conservation Claims You Can Check](../psychohistory/psy-021-conservation-claims/) <!-- psy-021-conservation-claims -->
- [ ] [PSY-022 · Competing Explanations](../psychohistory/psy-022-competing-explanations/) <!-- psy-022-competing-explanations -->
- [ ] [PSY-023 · Monitoring a Plan](../psychohistory/psy-023-monitoring-a-plan/) <!-- psy-023-monitoring-a-plan -->
- [ ] [PSY-024 · The Single Actor](../psychohistory/psy-024-the-single-actor/) <!-- psy-024-the-single-actor -->
- [ ] [PSY-025 · Capstone](../psychohistory/psy-025-capstone-preregistered-forecast/) <!-- psy-025-capstone-preregistered-forecast -->

### Semiotics

- [ ] [SEM-001 · Signs in Governance](../semiotics/sem-001-signs-in-governance/) <!-- sem-001-signs-in-governance -->

### World Music & Languages

- [ ] [WML-001 · Guitar Around the World](../world-music-languages/wml-001-guitar-around-the-world/) <!-- wml-001-guitar-around-the-world -->

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

## 2026-10-02 — MAT-008 to MAT-025, MUS-007, MUS-008, MUS-009, MUS-018, MUS-020, and fifteen translations

Synced from Demerzel at [`e203e5a`](https://github.com/GuitarAlchemist/Demerzel/commit/e203e5a25e10b85b8d22ece9a700e12447f4a236). Since the MAT-007 entry above, it brings 23 new modules, each in English, French and Spanish:
- mathematics: MAT-008 ([#1141](https://github.com/GuitarAlchemist/Demerzel/pull/1141)), MAT-009 ([#1147](https://github.com/GuitarAlchemist/Demerzel/pull/1147)), MAT-010 ([#1148](https://github.com/GuitarAlchemist/Demerzel/pull/1148)), MAT-011 ([#1149](https://github.com/GuitarAlchemist/Demerzel/pull/1149)), MAT-012 ([#1150](https://github.com/GuitarAlchemist/Demerzel/pull/1150)), MAT-013 ([#1151](https://github.com/GuitarAlchemist/Demerzel/pull/1151)), MAT-014 ([#1152](https://github.com/GuitarAlchemist/Demerzel/pull/1152)), MAT-015 ([#1153](https://github.com/GuitarAlchemist/Demerzel/pull/1153)), MAT-016 ([#1154](https://github.com/GuitarAlchemist/Demerzel/pull/1154)), MAT-017 ([#1155](https://github.com/GuitarAlchemist/Demerzel/pull/1155)), MAT-018 ([#1156](https://github.com/GuitarAlchemist/Demerzel/pull/1156)), MAT-019 ([#1157](https://github.com/GuitarAlchemist/Demerzel/pull/1157)), MAT-020 ([#1158](https://github.com/GuitarAlchemist/Demerzel/pull/1158)), MAT-021 ([#1159](https://github.com/GuitarAlchemist/Demerzel/pull/1159)), MAT-022 ([#1162](https://github.com/GuitarAlchemist/Demerzel/pull/1162)), MAT-023 ([#1163](https://github.com/GuitarAlchemist/Demerzel/pull/1163)), MAT-024 ([#1165](https://github.com/GuitarAlchemist/Demerzel/pull/1165)), MAT-025 ([#1166](https://github.com/GuitarAlchemist/Demerzel/pull/1166));
- music: MUS-007 ([#1172](https://github.com/GuitarAlchemist/Demerzel/pull/1172)), MUS-008 ([#1173](https://github.com/GuitarAlchemist/Demerzel/pull/1173)), MUS-009 ([#1174](https://github.com/GuitarAlchemist/Demerzel/pull/1174)), MUS-018 ([#1167](https://github.com/GuitarAlchemist/Demerzel/pull/1167)), MUS-020 ([#1171](https://github.com/GuitarAlchemist/Demerzel/pull/1171)).

It also brings:
- French and Spanish pages for fifteen modules that had only an English page here: CS-002, CYB-001, CYB-002, GAA-002, GAA-003, INF-001, MUS-003, MUS-004, MUS-005, MCL-002, NET-001, PSY-002, SEM-001, from [#1098](https://github.com/GuitarAlchemist/Demerzel/pull/1098), which also corrected their English text, and MUS-002 and MUS-006, from [#1091](https://github.com/GuitarAlchemist/Demerzel/pull/1091);
- corrections to MUS-002, MUS-006 and GTR-002 in every language that has them ([#1091](https://github.com/GuitarAlchemist/Demerzel/pull/1091));
- the accents restored in the Spanish pages of twelve modules ([#1120](https://github.com/GuitarAlchemist/Demerzel/pull/1120)).

Nothing in them was run here.

- **They have not been studied here,** so their checkboxes above stay empty.

## 2026-10-02 — PHY-001 · The Science of Guitar Sound, corrected

Synced from Demerzel at [`d459d8e`](https://github.com/GuitarAlchemist/Demerzel/commit/d459d8e5f0210cbad00f49c49196fc61160aba76) ([PR #1179](https://github.com/GuitarAlchemist/Demerzel/pull/1179)). The module's exercise said to measure from the nut to fret 7 and expect about 2/3 of the string length. The 2/3 is the length that vibrates, from fret 7 to the saddle; the nut-to-fret-7 stretch is the remaining third. The correction is in all six languages of the module, three of which are on this site. Every other page changes only its pinned references to Demerzel, from `e203e5a` to `d459d8e`.

Nothing in it was run here.

- **It has not been studied here,** so its checkbox above stays empty.

## 2026-10-03 — MUS-012 · Chord Formulas, Essential Tones and Doubling

Synced from Demerzel at [`450fc67`](https://github.com/GuitarAlchemist/Demerzel/commit/450fc670a71d1cfb190a53bfedd52ba81215fa5c) ([PR #1180](https://github.com/GuitarAlchemist/Demerzel/pull/1180)). A new intermediate music module on what a chord can lose: chord formulas up to the thirteenth, the essential tones a chord's name depends on and the optional ones it can drop, the doublings of a guitar voicing, and a thirteenth chord on six strings. It traces what GA stores about formulas, essential tones and doubling, and its section 6 proposes an experiment. The music index now lists it, the Streeling index counts 12 music modules instead of 11, and MUS-018 and MUS-020 move down one place in the sidebar; every other page changes only its pinned references to Demerzel, from `d459d8e` to `450fc67`.

Nothing in it was run here.

- **It has not been studied here,** so its checkbox above stays empty.

## 2026-10-03 — MUS-013 · Root, Bass and Pitch-Class Set

Synced from Demerzel at [`928fbb2`](https://github.com/GuitarAlchemist/Demerzel/commit/928fbb26539e451fd34a0e8baf0714cf919a1562) ([PR #1181](https://github.com/GuitarAlchemist/Demerzel/pull/1181)). A new intermediate music module on what a chord name fixes: the root, the bass and the pitch-class set, the sets that have several readings (sixth and seventh chords, sus2 and sus4, the augmented triad and the diminished seventh), and how the bass, the harmony and the resolution choose between them. It traces how GA names a set without looking at its bass, and its section 6 proposes an experiment. The music index now lists it, the Streeling index counts 13 music modules instead of 12, and MUS-018 and MUS-020 move down one place in the sidebar; every other page changes only its pinned references to Demerzel, from `450fc67` to `928fbb2`.

Nothing in it was run here.

- **It has not been studied here,** so its checkbox above stays empty.

## 2026-10-03 — MUS-010 · Scale Patterns, Sets and the Diatonic Interval Vector

Synced from Demerzel at [`d8c8da5`](https://github.com/GuitarAlchemist/Demerzel/commit/d8c8da550af12f339dbf9464cc1144084eb689b9) ([PR #1183](https://github.com/GuitarAlchemist/Demerzel/pull/1183)). A new intermediate music module on what is rare about the major scale: a scale as a step pattern and as a pitch-class set, the interval vectors of the major, harmonic minor, pentatonic and whole tone scales, the common-tone theorem, and four properties of the major scale: deep, Myhill's property, maximally even and generated by fifths. It traces how GA computes these properties, and its section 7 proposes an experiment. The music index now lists it, the Streeling index counts 14 music modules instead of 13, and MUS-012, MUS-013, MUS-018 and MUS-020 move down one place in the sidebar; every other page changes only its pinned references to Demerzel, from `928fbb2` to `d8c8da5`.

Nothing in it was run here.

- **It has not been studied here,** so its checkbox above stays empty.

## 2026-10-03 — MUS-011 · Modes and Modal Families

Synced from Demerzel at [`499fc64`](https://github.com/GuitarAlchemist/Demerzel/commit/499fc64abe83a5bf7d59efdd949bb23b72925ae2) ([PR #1184](https://github.com/GuitarAlchemist/Demerzel/pull/1184)). A new intermediate music module on modes and modal families: a mode as a rotation of a step pattern, relative and parallel modes, how many distinct modes a scale has, and why two scales can share an interval vector without being modes of each other, through mirror images and the Z-relation. It traces how GA groups sets into modal families, and its section 6 proposes an experiment. The music index now lists it, the Streeling index counts 15 music modules instead of 14, and MUS-012, MUS-013, MUS-018 and MUS-020 move down one place in the sidebar; every other page changes only its pinned references to Demerzel, from `d8c8da5` to `499fc64`.

Nothing in it was run here.

- **It has not been studied here,** so its checkbox above stays empty.

## 2026-10-04 — MUS-014 · Inversions and the Bass Line

Synced from Demerzel at [`518158b`](https://github.com/GuitarAlchemist/Demerzel/commit/518158b0568981b4ebe290d69f197995bd41ded0) ([PR #1185](https://github.com/GuitarAlchemist/Demerzel/pull/1185)). A new intermediate music module on chord positions read from the bass: root position and the inversions, figured bass for triads and seventh chords, the four kinds of six-four chord, and the cases where the sounding notes do not fix the position. It traces how GA handles inversions in its `Chord` type, its voicing documents and its modes catalogue, and its section 6 proposes an experiment. The music index now lists it, the Streeling index counts 16 music modules instead of 15, and MUS-018 and MUS-020 move down one place in the sidebar; every other page changes only its pinned references to Demerzel, from `499fc64` to `518158b`.

Nothing in it was run here.

- **It has not been studied here,** so its checkbox above stays empty.

## 2026-10-04 — MUS-019 · Transposition, the Capo and Cross-Instrument Equivalence

Synced from Demerzel at [`0f7a5fd`](https://github.com/GuitarAlchemist/Demerzel/commit/0f7a5fd110acfc4835776d38ab1a115533467d34) ([PR #1186](https://github.com/GuitarAlchemist/Demerzel/pull/1186)). A new intermediate music module on three kinds of sameness: transposition, spelled by interval and read on the line of fifths; the capo as a uniform tuning difference, shape names against sounding names, and the same shape on ukuleles and a bass; and transposing instruments in B♭, E♭ and F. It traces how GA transposes pitch-class sets and chord symbols and how it answers capo questions, and its section 6 proposes an experiment. The music index now lists it, the Streeling index counts 17 music modules instead of 16, and MUS-020 moves down one place in the sidebar; every other page changes only its pinned references to Demerzel, from `518158b` to `0f7a5fd`.

Nothing in it was run here.

- **It has not been studied here,** so its checkbox above stays empty.

## 2026-10-23 — Batch of50: test, record, refine and replay

This is production verification, not a completed learner attempt. The requested batch is50 distinct English courses with full French/Spanish translations. [The plan](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/batch-plan.json) records the exact150 source paths and baseline. Authoring/source reading is in progress in three disjoint units. No course checkbox is ticked from that work.

Executed `node --test scripts/tests/lazy-demo.test.mjs scripts/tests/streeling-copy-source.test.mjs scripts/tests/sync-streeling.test.mjs`: 18 passed, 0 failed. The [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/generator-initial.log) and [input hashes/exit status](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/generator-initial.json) are retained. This checks the existing generator, not the correctness of the new lesson calculations.

The user's additional requirement is an iterative [claim-validation loop](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal-validation-plan.md): derive and execute checks, preserve failures, correct courses/tests, replay and record limitations. Dedicated claim tests and independent review remain pending at this entry. No new audio, scene, material, human or learner trial has been performed.

## 2026-10-23 — Claim check baseline-audio-01

Executed `baseline-audio-01` for3 courses: exit0, 6 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/baseline-audio-01.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/baseline-audio-01.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-23 — Claim check claims-a-01

Executed `claims-a-01` for18 courses: exit0, 36 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-a-01.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-a-01.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-23 — Claim check claims-c-01

Executed `claims-c-01` for16 courses: exit0, 16 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-c-01.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-c-01.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-23 — Claim check claims-b-01

Executed `claims-b-01` for16 courses: exit0, 17 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-b-01.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-b-01.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-23 — Claim check claims-all-01

Executed `claims-all-01` for50 courses: exit0, 69 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-all-01.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-all-01.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-23 — Claim check claims-all-02

Executed `claims-all-02` for50 courses: exit0, 69 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-all-02.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/claims-all-02.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-23 — Claim check baseline-audio-02

Executed `baseline-audio-02` for3 courses: exit0, 6 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/baseline-audio-02.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/test-runs/baseline-audio-02.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-23/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-24 — Next fifty-course batch: verification baseline

The next batch targets 50 distinct English courses and 100 full French/Spanish translations, from 281 to 331 of 525 core course sources. The [production plan](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/production-plan.md) and [allocation](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/allocation.json) fix scope and ownership. Three native author units have selected topics after reading the actual catalogue. Production and source reading remain separate from learner, musician, renderer and physical-material evidence. Existing history and checklist states stay unchanged.

Actual generator regression command: `node --test scripts/tests/lazy-demo.test.mjs scripts/tests/streeling-copy-source.test.mjs scripts/tests/sync-streeling.test.mjs`; 18 passes, zero failures. This entry is retrospective. The [receipt](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/generator-initial.json) pins actual Node, inputs and log hash; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/generator-initial.log) is preserved. Each course will have independently checked model/control cases and retained failures, corrections and replays in the [batch journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/journal.md). Those results are still pending at this entry.

## 2026-10-25 — Claim check resumed-20261025-all

Executed `resumed-20261025-all` for 50 courses: exit0, 50 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/resumed-20261025-all.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/resumed-20261025-all.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-25 — Claim check final-claims-20261025

Executed `final-claims-20261025` for 50 courses: exit0, 50 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/final-claims-20261025.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/final-claims-20261025.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-25 — Next batch: retained review corrections and replay

The complete [claim replay](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/final-claims-20261025.json) executes 50 tests with 100 model/control observations, all passing; the [metadata replay](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/test-runs/final-metadata-20261025.json) passes 150 sources. These checks do not establish that every sentence is true. Independent content review found FUT011 called supplied values interval midpoints: two were not centres, and the actual centre replay gives one switch rather than three. The failed premise check is retained alongside the corrected admissible-point wording and replay. Model numbers were not changed to hide the mismatch.

CS018 and CYB012 now explicitly credit prior merge/delay lessons and add merge algebra and the delayed stability interval; FUT011 credits prior hysteresis and adds interval state propagation. COG014 distinguishes monotonic coverage from conditional risk. The [batch journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-24/journal.md) and amendment records retain old/new text, hashes, failures and limits. Independent reviews and test-code review are finalized separately; no learner, listening, physical-material or engine acceptance follows from these calculations.

## 2026-10-25 — Next fifty-course batch: verification baseline

The next batch targets 50 distinct English courses and 100 full French/Spanish translations, from 331 to 381 of 525 core course sources. The [production plan](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/production-plan.md) and [allocation](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/allocation.json) fix scope and ownership. Three native author units are inspecting the actual catalogue before fixing topics. Production and source reading remain separate from learner, musician, renderer and physical-material evidence. Existing history and checklist states stay unchanged.

Actual generator regression command: `node --test scripts/tests/lazy-demo.test.mjs scripts/tests/streeling-copy-source.test.mjs scripts/tests/sync-streeling.test.mjs`; 18 passes, zero failures. This entry is retrospective. The [receipt](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/test-runs/generator-initial.json) pins actual Node, inputs and log hash; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/test-runs/generator-initial.log) is preserved. Each course will have independently checked model/control cases and retained failures, corrections and replays in the [batch journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/journal.md). Those results are still pending at this entry.

## 2026-10-25 — Claim check integrated-final

Executed `integrated-final` for 50 courses: exit0, 50 tests, model/negative coverage True. Verdict: pass. The [run](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/test-runs/integrated-final.json) retains actual command, input/test hashes and computed observations; the [full output](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/test-runs/integrated-final.log) preserves failures. See the [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/journal.md) for the expectation recorded before execution, diagnosis, corrections and replay. Scope: authored cases only, not new runtime, musician or learner evidence.

## 2026-10-25 — Fifty-course independent content and model checks

This batch adds 50 distinct English course sources and 100 full French/Spanish translations. The inventory is now 381/525 core sources, with 144 source gaps; the extra IX Research module gives 382 per locale. Independent AI reviewers inspected 750 localized answers and 250 prepared criteria. Actual integrated checks executed 50 tests with 100 model/control observations and 150 metadata passes. The [selected runs](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/final-claim-runs.json), their full logs and final byte bindings preserve what was actually executed.

The [production journal](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/journal.md) keeps rejected duplicate topics, the raw-byte CRLF failure and correction, independent review findings and replay. The [validation record](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/batch50-2026-10-25/validation.json) will record final static integration; this entry does not anticipate its outcome. The tests check authored finite cases, not actual learner responses, listening, materials or native-engine scenes. Human/fluent-language and learner decisions remain null; the user will designate a reviewer. GitHub source publication and deployed HTML are separate gates.

## To verify

Human/language and learner acceptance, task-specific runtime trials and deployed HTML remain pending.

## Open questions

Which fixed-case claims transfer to actual project tasks? The detailed batch journal retains scope and unresolved work.
