---
title: Diario Streeling
description: Lo que estudié en Streeling University, lo que verifiqué y los errores que encontré.
sidebar:
  label: Diario
  order: 1
---

Marca un módulo una vez estudiado. En **Notas**, añade una entrada fechada: lo que entendí, lo que probé y cualquier error encontrado en el módulo (con una fuente).

## Progreso

### Ingeniería de audio

- [ ] [AUD-001 · EQ y compresión](../audio-engineering/aud-001-eq-compression-order/) <!-- aud-001-eq-compression-order -->

### Ciencia cognitiva

- [ ] [COG-001 · Tu cerebro te miente](../cognitive-science/cog-001-your-brain-lies-to-you/) <!-- cog-001-your-brain-lies-to-you -->

### Ciencias de la computación

- [ ] [CS-001 · Pensar algorítmicamente](../computer-science/cs-001-thinking-algorithmically/) <!-- cs-001-thinking-algorithmically -->
- [ ] [CS-002 · Governing Agentic Loops](../computer-science/cs-002-governing-agentic-loops/) <!-- cs-002-governing-agentic-loops -->

### Cibernética

- [ ] [CYB-001 · Viable System Model Mapping to AI Governance](../cybernetics/cyb-001-vsm-ai-governance-mapping/) <!-- cyb-001-vsm-ai-governance-mapping -->
- [ ] [CYB-002 · Active Dampening Mechanisms for Cross-Repo Oscillation Control](../cybernetics/cyb-002-active-dampening-cross-repo-oscillation/) <!-- cyb-002-active-dampening-cross-repo-oscillation -->
- [ ] [CYB-003 · Measuring the Variety Ratio Quantitatively](../cybernetics/cyb-003-measuring-variety-ratio-quantitatively/) <!-- cyb-003-measuring-variety-ratio-quantitatively -->

### Futurología

- [ ] [FUT-001 · Pensar en el mañana](../futurology/fut-001-thinking-about-tomorrow/) <!-- fut-001-thinking-about-tomorrow -->

### Guitar Alchemist Academy

- [ ] [GAA-001 · Tu primer acorde](../guitar-alchemist-academy/gaa-001-your-first-chord/) <!-- gaa-001-your-first-chord -->
- [ ] [GAA-002 · Training Your Ear](../guitar-alchemist-academy/gaa-002-training-your-ear/) <!-- gaa-002-training-your-ear -->
- [ ] [GAA-003 · Improvisation Foundations](../guitar-alchemist-academy/gaa-003-improvisation-foundations/) <!-- gaa-003-improvisation-foundations -->

### Estudios de guitarra

- [ ] [GTR-001 · El mapa del diapasón](../guitar-studies/gtr-001-the-fretboard-map/) <!-- gtr-001-the-fretboard-map -->
- [ ] [GTR-002 · Geometría CAGED](../guitar-studies/gtr-002-caged-geometry/) <!-- gtr-002-caged-geometry -->

### Teoría de la información

- [ ] [INF-001 · The Entropy of Governance](../information-theory/inf-001-entropy-of-governance/) <!-- inf-001-entropy-of-governance -->

### Matemáticas

- [ ] [MAT-001 · Estrategias de demostración](../mathematics/mat-001-proof-strategies/) <!-- mat-001-proof-strategies -->

- [ ] [MAT-003 · Aritmética de punto flotante y condicionamiento](../mathematics/mat-003-floating-point-conditioning/) <!-- mat-003-floating-point-conditioning -->

### Música

- [ ] [MUS-001 · ¿Qué es un acorde?](../music/mus-001-what-is-a-chord/) <!-- mus-001-what-is-a-chord -->
- [ ] [MUS-002 · Beyond Tonality](../music/mus-002-beyond-tonality/) <!-- mus-002-beyond-tonality -->
- [ ] [MUS-003 · How Harmony Works](../music/mus-003-functional-harmony/) <!-- mus-003-functional-harmony -->
- [ ] [MUS-004 · Rhythm, Meter, and Groove](../music/mus-004-rhythm-and-groove/) <!-- mus-004-rhythm-and-groove -->
- [ ] [MUS-005 · Jazz Harmony for Guitar](../music/mus-005-jazz-harmony/) <!-- mus-005-jazz-harmony -->
- [ ] [MUS-006 · The Scale Universe](../music/mus-006-the-scale-universe/) <!-- mus-006-the-scale-universe -->

### Musicología

- [ ] [MCL-001 · Cómo evoluciona la música](../musicology/mcl-001-how-music-evolves/) <!-- mcl-001-how-music-evolves -->
- [ ] [MCL-002 · Musical Form and Structure](../musicology/mcl-002-musical-form/) <!-- mcl-002-musical-form -->

### Ciencia de redes

- [ ] [NET-001 · Scale-Free Tool Networks](../network-science/net-001-scale-free-tool-networks/) <!-- net-001-scale-free-tool-networks -->

### Filosofía

- [ ] [PHI-001 · Cómo argumentar bien](../philosophy/phi-001-how-to-argue-well/) <!-- phi-001-how-to-argue-well -->

### Física

- [ ] [PHY-001 · La ciencia del sonido de la guitarra](../physics/phy-001-science-of-guitar-sound/) <!-- phy-001-science-of-guitar-sound -->

### Gestión de productos y proyectos

- [ ] [PM-001 · Entregar vs hablar](../product-management/pm-001-shipping-vs-talking/) <!-- pm-001-shipping-vs-talking -->

### Psicohistoria

- [ ] [PSY-001 · Introducción al compuesto fractal](../psychohistory/psy-001-intro-fractal-compounding/) <!-- psy-001-intro-fractal-compounding -->
- [ ] [PSY-002 · Governance Phase Transitions](../psychohistory/psy-002-governance-phase-transitions/) <!-- psy-002-governance-phase-transitions -->

### Semiótica

- [ ] [SEM-001 · Signs in Governance](../semiotics/sem-001-signs-in-governance/) <!-- sem-001-signs-in-governance -->

### Músicas y lenguas del mundo

- [ ] [WML-001 · La guitarra alrededor del mundo](../world-music-languages/wml-001-guitar-around-the-world/) <!-- wml-001-guitar-around-the-world -->

## Notas

<!-- ## AAAA-MM-DD — CÓDIGO · Título -->

## 2026-09-27 — MAT-003 · Aritmética de punto flotante y condicionamiento

Sincronizado desde Demerzel en el commit [`89a1bdb`](https://github.com/GuitarAlchemist/Demerzel/commit/89a1bdb2801d32424dd17287ba67185572610277) (PR n.º 1134). Los números del módulo vienen del laboratorio de Learn [`code/streeling-mathematics`](https://github.com/spareilleux/learn/tree/c8135fa508fcb9d35593e8dedbb925c44282b3a2/code/streeling-mathematics), que fija `ix-math` de IX en `e35138b9` y comprueba las matrices de Hilbert H_2 a H_16 contra su inversa entera exacta. Se midieron en Windows 11 x86-64; la CI alojada reprodujo la salida impresa en Linux, Windows y macOS.

- La función `inverse` de IX responde `Singular` por primera vez en n = 11. Multiplicar H por 2^-20 adelanta ese umbral a n = 6; multiplicarla por 2^20 lo elimina hasta n = 16, y una inversa aceptada en n = 14 tiene un error hacia delante de 1,04 (ningún dígito correcto).
- Error encontrado y corregido antes de publicar: el κ₂ de IX cae por debajo de κ∞/n desde n = 10, y una primera lectura lo tomó como prueba de una SVD errónea. La banda κ∞/n ≤ κ₂ ≤ κ∞ vale para una sola matriz, y el laboratorio comparaba la H_n exacta con la fl(H_n) almacenada: es una observación, no un defecto.
- Sigue abierto: multiplicar fl(H) por una potencia de dos exacta cambia el κ₂ de IX (bits idénticos en las tres escalas para 5 de 15 tamaños), así que al menos dos de las tres respuestas no son el κ₂ de su entrada. Cuál es la correcta no está establecido.
