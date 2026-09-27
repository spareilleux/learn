---
title: Journal Streeling
description: Ce que j'ai étudié à Streeling University, ce que j'ai vérifié et ce que j'ai trouvé d'erroné.
sidebar:
  label: Journal
  order: 1
---

Coche un module une fois étudié. Sous **Notes**, ajoute une entrée datée : ce que j'ai compris, ce que j'ai testé, et toute erreur trouvée dans le module (avec une source).

## Progression

### Ingénierie audio

- [ ] [AUD-001 · EQ et compression](../audio-engineering/aud-001-eq-compression-order/) <!-- aud-001-eq-compression-order -->

### Sciences cognitives

- [ ] [COG-001 · Votre cerveau vous ment](../cognitive-science/cog-001-your-brain-lies-to-you/) <!-- cog-001-your-brain-lies-to-you -->

### Informatique

- [ ] [CS-001 · Penser algorithmiquement](../computer-science/cs-001-thinking-algorithmically/) <!-- cs-001-thinking-algorithmically -->
- [ ] [CS-002 · Governing Agentic Loops](../computer-science/cs-002-governing-agentic-loops/) <!-- cs-002-governing-agentic-loops -->

### Cybernétique

- [ ] [CYB-001 · Viable System Model Mapping to AI Governance](../cybernetics/cyb-001-vsm-ai-governance-mapping/) <!-- cyb-001-vsm-ai-governance-mapping -->
- [ ] [CYB-002 · Active Dampening Mechanisms for Cross-Repo Oscillation Control](../cybernetics/cyb-002-active-dampening-cross-repo-oscillation/) <!-- cyb-002-active-dampening-cross-repo-oscillation -->
- [ ] [CYB-003 · Measuring the Variety Ratio Quantitatively](../cybernetics/cyb-003-measuring-variety-ratio-quantitatively/) <!-- cyb-003-measuring-variety-ratio-quantitatively -->

### Futurologie

- [ ] [FUT-001 · Penser à demain](../futurology/fut-001-thinking-about-tomorrow/) <!-- fut-001-thinking-about-tomorrow -->

### Guitar Alchemist Academy

- [ ] [GAA-001 · Votre Premier Accord](../guitar-alchemist-academy/gaa-001-your-first-chord/) <!-- gaa-001-your-first-chord -->
- [ ] [GAA-002 · Training Your Ear](../guitar-alchemist-academy/gaa-002-training-your-ear/) <!-- gaa-002-training-your-ear -->
- [ ] [GAA-003 · Improvisation Foundations](../guitar-alchemist-academy/gaa-003-improvisation-foundations/) <!-- gaa-003-improvisation-foundations -->

### Études de guitare

- [ ] [GTR-001 · La carte du manche](../guitar-studies/gtr-001-the-fretboard-map/) <!-- gtr-001-the-fretboard-map -->
- [ ] [GTR-002 · La géométrie du CAGED](../guitar-studies/gtr-002-caged-geometry/) <!-- gtr-002-caged-geometry -->

### Théorie de l'information

- [ ] [INF-001 · The Entropy of Governance](../information-theory/inf-001-entropy-of-governance/) <!-- inf-001-entropy-of-governance -->

### Mathématiques

- [ ] [MAT-001 · Stratégies de démonstration](../mathematics/mat-001-proof-strategies/) <!-- mat-001-proof-strategies -->

- [ ] [MAT-003 · Arithmétique flottante et conditionnement](../mathematics/mat-003-floating-point-conditioning/) <!-- mat-003-floating-point-conditioning -->

### Musique

- [ ] [MUS-001 · Qu'est-ce qu'un accord ?](../music/mus-001-what-is-a-chord/) <!-- mus-001-what-is-a-chord -->
- [ ] [MUS-002 · Beyond Tonality](../music/mus-002-beyond-tonality/) <!-- mus-002-beyond-tonality -->
- [ ] [MUS-003 · How Harmony Works](../music/mus-003-functional-harmony/) <!-- mus-003-functional-harmony -->
- [ ] [MUS-004 · Rhythm, Meter, and Groove](../music/mus-004-rhythm-and-groove/) <!-- mus-004-rhythm-and-groove -->
- [ ] [MUS-005 · Jazz Harmony for Guitar](../music/mus-005-jazz-harmony/) <!-- mus-005-jazz-harmony -->
- [ ] [MUS-006 · The Scale Universe](../music/mus-006-the-scale-universe/) <!-- mus-006-the-scale-universe -->

### Musicologie

- [ ] [MCL-001 · Comment la musique évolue](../musicology/mcl-001-how-music-evolves/) <!-- mcl-001-how-music-evolves -->
- [ ] [MCL-002 · Musical Form and Structure](../musicology/mcl-002-musical-form/) <!-- mcl-002-musical-form -->

### Science des réseaux

- [ ] [NET-001 · Scale-Free Tool Networks](../network-science/net-001-scale-free-tool-networks/) <!-- net-001-scale-free-tool-networks -->

### Philosophie

- [ ] [PHI-001 · Bien argumenter](../philosophy/phi-001-how-to-argue-well/) <!-- phi-001-how-to-argue-well -->

### Physique

- [ ] [PHY-001 · La science du son de la guitare](../physics/phy-001-science-of-guitar-sound/) <!-- phy-001-science-of-guitar-sound -->

### Gestion de produit et de projet

- [ ] [PM-001 · Livrer vs parler](../product-management/pm-001-shipping-vs-talking/) <!-- pm-001-shipping-vs-talking -->

### Psychohistoire

- [ ] [PSY-001 · Introduction à la Capitalisation Fractale](../psychohistory/psy-001-intro-fractal-compounding/) <!-- psy-001-intro-fractal-compounding -->
- [ ] [PSY-002 · Governance Phase Transitions](../psychohistory/psy-002-governance-phase-transitions/) <!-- psy-002-governance-phase-transitions -->

### Sémiotique

- [ ] [SEM-001 · Signs in Governance](../semiotics/sem-001-signs-in-governance/) <!-- sem-001-signs-in-governance -->

### Musiques et langues du monde

- [ ] [WML-001 · La guitare autour du monde](../world-music-languages/wml-001-guitar-around-the-world/) <!-- wml-001-guitar-around-the-world -->

## Notes

<!-- ## AAAA-MM-JJ — CODE · Titre -->

## 2026-09-27 — MAT-003 · Arithmétique flottante et conditionnement

Synchronisé depuis Demerzel au commit [`89a1bdb`](https://github.com/GuitarAlchemist/Demerzel/commit/89a1bdb2801d32424dd17287ba67185572610277) (PR n° 1134). Les nombres du module viennent du laboratoire Learn [`code/streeling-mathematics`](https://github.com/spareilleux/learn/tree/c8135fa508fcb9d35593e8dedbb925c44282b3a2/code/streeling-mathematics), qui épingle `ix-math` d'IX à `e35138b9` et vérifie les matrices de Hilbert H_2 à H_16 contre leur inverse entière exacte. Ils ont été mesurés sous Windows 11 x86-64 ; la CI hébergée a reproduit la sortie imprimée sous Linux, Windows et macOS.

- La fonction `inverse` d'IX répond `Singular` pour la première fois à n = 11. Multiplier H par 2^-20 ramène ce seuil à n = 6 ; la multiplier par 2^20 le supprime jusqu'à n = 16, et une inverse acceptée à n = 14 a une erreur directe de 1,04 (aucun chiffre juste).
- Erreur trouvée et corrigée avant publication : le κ₂ d'IX passe sous κ∞/n dès n = 10, et une première lecture y voyait la preuve d'une SVD fausse. La bande κ∞/n ≤ κ₂ ≤ κ∞ vaut pour une seule matrice, et le laboratoire comparait la H_n exacte à la fl(H_n) stockée : c'est une observation, pas un défaut.
- Encore ouvert : multiplier fl(H) par une puissance de deux exacte change le κ₂ d'IX (bits identiques aux trois échelles pour 5 tailles sur 15), donc au moins deux des trois réponses ne sont pas le κ₂ de leur entrée. Laquelle est juste n'est pas établi.
