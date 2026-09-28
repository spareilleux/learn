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
