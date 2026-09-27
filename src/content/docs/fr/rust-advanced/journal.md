---
title: Journal
description: Progression datée, expériences et questions ouvertes du cours Rust avancé.
sidebar:
  order: 99
---

## Progression

- [x] Mission et plan de douze leçons
- [x] Crate du cours avec formatage, Clippy, tests unitaires, doctests compile-fail et sortie capturée
- [x] Leçon 1 : disposition mémoire et représentation
- [ ] Leçon 2 : allocation, coût de l'ownership et `Drop`
- [ ] Leçons 3 à 12

## Expériences

| Question | Hypothèse écrite avant la mesure | Résultat | Verdict | Preuve |
|---|---|---|---|---|
| Placer d'abord le champ le plus aligné réduit-il ce packet `repr(C)` ? | `u8, u32, bool` exige plus de padding que `u32, u8, bool` sur les cibles 64 bits du cours | 12 octets deviennent 8 sur la machine Windows x86-64 de l'auteur ; les offsets passent de `0,4,8` à `0,4,5` | Confirmé localement ; cibles CI en attente | [Entrée](#2026-09-27--la-première-tranche-mesurée), [`code/rust-advanced`](https://github.com/spareilleux/learn/tree/main/code/rust-advanced) |
| `Option` peut-il réutiliser une valeur invalide de `NonZeroUsize` ? | `Option<NonZeroUsize>` devrait rester sur un mot, tandis que `Option<usize>` en demande un second | 8 octets contre 16 sur la même cible | Confirmé localement ; cas garanti et documenté par la bibliothèque standard | [Entrée](#2026-09-27--la-première-tranche-mesurée), [leçon](../01-memory-layout-and-representation/) |

## 2026-09-27 — La première tranche mesurée

Le cours commence par un tracer-bullet plutôt que par douze leçons vides : une mission, une leçon complète et une crate qui vérifie chaque nombre cité. Rust 1.94.0 produit :

```text
target_pointer_width=64
Packet size=12 align=4 offsets=0,4,8
CompactPacket size=8 align=4 offsets=0,4,5
Option<usize> size=16
Option<NonZeroUsize> size=8
```

`bash check.sh` a validé le formatage, Clippy avec les warnings refusés, un test unitaire, un doctest compile-fail et la comparaison de la sortie capturée. Une exécution doctest séparée sous nightly a aussi vérifié le code E0690 exact. Il s'agit d'une preuve Windows locale. Le workflow possède trois runners, mais leur résultat n'existe pas encore tant que la CI ne l'a pas exécuté.

La leçon exclut `repr(Rust)` de la comparaison des offsets, car l'ordre des champs n'est pas une promesse d'ABI. Les deux packets mesurés emploient `repr(C)` : le choix de représentation fait ainsi partie de la question au lieu d'être un détail accidentel du compilateur.

## À vérifier

- Confirmer `check.sh` sur les runners Linux, Windows et macOS avant de qualifier la tranche de multiplateforme.
- Décider si la leçon 2 doit mesurer directement l'allocateur système ou compter les allocations avec un allocateur de test strictement limité.
- Ne choisir un vrai type d'IX ou de hari qu'après stabilisation de la méthode autonome ; une expérience de cours ne doit pas devenir une optimisation non sollicitée.

## Questions ouvertes

- Quelles affirmations de layout aident les développeurs d'applications sans les pousser vers des engagements ABI prématurés ?
- Les exemples Miri de la leçon 3 peuvent-ils rester assez déterministes tout en séparant clairement détection d'undefined behaviour et preuve de soundness ?
