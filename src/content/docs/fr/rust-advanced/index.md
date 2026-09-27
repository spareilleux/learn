---
title: Rust avancé — Mission
description: Rust sous le capot — représentation, allocation, contrats unsafe, génération de code, runtimes async, concurrence, profiling et services en production — chaque affirmation livrée étant vérifiée par un programme ou un test compile-fail.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Les preuves se trouvent dans [`code/rust-advanced`](https://github.com/spareilleux/learn/tree/main/code/rust-advanced). `check.sh` exécute le formatage, Clippy avec les warnings refusés, les tests unitaires, les doctests compile-fail et les programmes des leçons, puis compare leurs sorties aux fichiers versionnés. Le workflow CI dédié répète ce gate sous Linux, Windows et macOS. Les résultats pas encore observés sur ces trois runners restent dans la section **À vérifier** du journal.
:::

## Pourquoi j'apprends ça

Le cours [Rust pour développeurs C#/Java](../rust-for-csharp-java/) apprend à écrire du Rust correct. Celui-ci commence là où il s'arrête : quelle représentation le compilateur peut choisir, ce que coûte une abstraction, quel invariant rend un bloc `unsafe` sound, comment un `Future` devient du travail exécutable et comment mesurer avant de modifier le code.

Le but n'est pas d'accumuler des optimisations astucieuses. Il est de remplacer le folklore par des preuves inspectables : tailles et offsets imprimés par un programme, contrats rejetés conservés comme tests compile-fail, code généré examiné volontairement et affirmations de performance liées à un benchmark reproductible.

## À qui s'adresse ce cours

Vous utilisez déjà ownership, emprunts, lifetimes, traits, itérateurs, `Result`, threads et Rust async de base. Sinon, commencez par [Rust pour développeurs C#/Java](../rust-for-csharp-java/). Les comparaisons avec C# et Java expliquent les choix du runtime, mais les exercices supposent que vous savez écrire du Rust.

## À la fin de ce cours, je saurai

- distinguer la représentation par défaut de Rust de `repr(C)` et `repr(transparent)`, puis mesurer taille, alignement, padding et optimisation par niche ;
- raisonner sur l'allocation, l'ordre de `Drop`, la provenance et le contrat de sûreté autour d'un petit noyau `unsafe` ;
- prévoir les compromis entre monomorphisation et dispatch dynamique, puis inspecter au lieu de deviner ;
- expliquer `Pin`, `Future`, le réveil et l'ordonnancement d'un executor ;
- concevoir des pipelines Tokio bornés avec annulation, backpressure et états terminaux explicites ;
- employer les atomics et les memory orderings sans prendre `SeqCst` pour une preuve ;
- profiler CPU, allocations et taille du binaire avant d'optimiser ;
- reconnaître les bonnes frontières pour les macros procédurales, la FFI, Axum, Tower et Hyper.

## Plan

### Partie 1 — Représentation et génération de code

| # | Leçon | Preuve |
|---|---|---|
| 1 | [Disposition mémoire et représentation](01-memory-layout-and-representation/) | `size_of`, `align_of`, `offset_of`, contrat `repr(transparent)` en compile-fail |
| 2 | Allocation, coût de l'ownership et `Drop` | observations de l'allocateur et traces déterministes de destruction — planifié |
| 3 | Contrats unsafe, pointeurs, provenance et `Pin` | wrapper sûr et vérifications Miri — planifié |
| 4 | Traits, monomorphisation et dispatch dynamique | code généré et comparaison de taille des binaires — planifié |
| 5 | Profiling et optimisation mesurée | Criterion, flamegraphs et preuve d'allocation — planifié |

### Partie 2 — Concurrence et runtimes async

| # | Leçon | Preuve |
|---|---|---|
| 6 | Atomics et modèle mémoire | litmus tests avec limites déclarées — planifié |
| 7 | `Future`, wakers et executors | executor minimal avant Tokio — planifié |
| 8 | Ordonnancement Tokio, channels et backpressure | pipeline borné, annulation et tests des états terminaux — planifié |

### Partie 3 — Frontières avancées

| # | Leçon | Preuve |
|---|---|---|
| 9 | Macros procédurales | expansion et diagnostics de compilation — planifié |
| 10 | Conception FFI et ABI | frontière Rust/C appelée depuis un autre langage — planifié |
| 11 | Axum, Tower et Hyper | requête à travers les layers, annulation et arrêt propre — planifié |
| 12 | Observabilité, cross-compilation et taille du binaire | traces, métriques et artifacts de release reproductibles — planifié |
| — | [Journal](journal/) | progression mesurée, expériences et questions ouvertes |

## Prérequis

- Rust 1.94.0, édition 2024, et Cargo ;
- les concepts de [Rust pour développeurs C#/Java](../rust-for-csharp-java/) ;
- Git et un shell. Sous Windows, le gate du cours s'exécute depuis Git Bash.

## Sources primaires

- [The Rust Reference — type layout](https://doc.rust-lang.org/reference/type-layout.html)
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/)
- [The Async Book](https://rust-lang.github.io/async-book/)
- [The Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [Documentation de Tokio](https://tokio.rs/tokio/tutorial)
