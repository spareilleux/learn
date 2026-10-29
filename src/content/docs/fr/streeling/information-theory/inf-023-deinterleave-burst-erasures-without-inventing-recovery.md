---
title: Désentrelacer les effacements en rafale sans inventer de récupération
description: Désentrelacer les effacements en rafale sans inventer de récupération — Théorie de l'information
sidebar:
  label: INF-023 · Désentrelacer les effacements en rafale sans inventer de récupération
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-023-deinterleave-burst-erasures-without-inventing-recovery.fr.md
---

:::note[Streeling University]
**INF-023** · Désentrelacer les effacements en rafale sans inventer de récupération · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-023-deinterleave-burst-erasures-without-inventing-recovery.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-020](../../information-theory/inf-020-separate-parity-detection-from-correction/), [INF-012](../../information-theory/inf-012-retain-event-order-in-a-handoff-summary/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un futur transport audio de guitare pourrait vouloir répartir l’effet d’une brève perte de paquets en rafale. L’entrelacement modifie l’origine des positions transmises consécutivement. Il peut réduire la concentration des symboles manquants dans un bloc. Il ne recrée pas les valeurs jamais reçues, et compter des positions ne démontre aucun gain perceptif.

Écrivez les blocs sources dans un tableau rectangulaire et lisez les colonnes pour obtenir l’ordre entrelacé. Chaque indice transmis correspond à une ligne et une colonne d’origine. Effacez les positions déclarées, puis inversez cette correspondance pour retrouver la disposition source. Gardez un marqueur explicite d’absence. On reconstruit la disposition, pas les valeurs des symboles perdus.

Le contrôle transmet les mêmes symboles par lignes. La même rafale efface alors un bloc entier au lieu de répartir les pertes. Le nombre total de symboles absents ne change pas. Une correction ultérieure exigerait une redondance réelle, un code spécifié et des tests de décodage distincts. Latence de mise en tampon et mémoire du récepteur ne sont pas modélisées ; la RFC rappelle que l’entrelacement peut ajouter du retard. Un tableau de permutation sur papier précède toute modification d’un transport audio réel.

## Sources et périmètre du projet

[Prérequis: inf-020-separate-parity-detection-from-correction](../../information-theory/inf-020-separate-parity-detection-from-correction/)

[Prérequis: inf-012-retain-event-order-in-a-handoff-summary](../../information-theory/inf-012-retain-event-order-in-a-handoff-summary/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://www.rfc-editor.org/rfc/rfc8088.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "blocks": [
      [
        "A",
        "B",
        "C"
      ],
      [
        "D",
        "E",
        "F"
      ],
      [
        "G",
        "H",
        "I"
      ]
    ],
    "order": "column-major",
    "erased_indices": [
      0,
      1,
      2
    ]
  },
  "formula": "Serialize rectangular blocks in declared row-major or column-major position order. Replace erased zero-based wire indices by null, inverse-map positions, then count nulls per original block. Do not infer erased values.",
  "expected": {
    "wire": [
      "A",
      "D",
      "G",
      "B",
      "E",
      "H",
      "C",
      "F",
      "I"
    ],
    "reconstructed": [
      [
        null,
        "B",
        "C"
      ],
      [
        null,
        "E",
        "F"
      ],
      [
        null,
        "H",
        "I"
      ]
    ],
    "missing_per_block": [
      1,
      1,
      1
    ],
    "missing_total": 3
  },
  "negative_control": {
    "values": {
      "blocks": [
        [
          "A",
          "B",
          "C"
        ],
        [
          "D",
          "E",
          "F"
        ],
        [
          "G",
          "H",
          "I"
        ]
      ],
      "order": "row-major",
      "erased_indices": [
        0,
        1,
        2
      ]
    },
    "expected": {
      "wire": [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I"
      ],
      "reconstructed": [
        [
          null,
          null,
          null
        ],
        [
          "D",
          "E",
          "F"
        ],
        [
          "G",
          "H",
          "I"
        ]
      ],
      "missing_per_block": [
        3,
        0,
        0
      ],
      "missing_total": 3
    },
    "why": "The same burst has different block concentration, but no values are recovered."
  },
  "input_types": {
    "blocks": "rectangular nonempty array of distinct symbol strings",
    "order": "row-major or column-major",
    "erased_indices": "distinct valid zero-based transmitted positions"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No redundancy, erasure correction, packet capture, perceptual benefit, latency measurement or implemented RTP payload is claimed."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Dessiner la permutation et son inverse, marquer les effacements et compter les cases absentes.

**Critère de réfutation:** Le désentrelacement annonce des valeurs perdues sans redondance ni retransmission.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Écrivez l’ordre transmis entrelacé.

> **Réponse:** La lecture par colonnes donne `[A,D,G,B,E,H,C,F,I]` ; les indices `[0,1,2]` effacent le premier symbole de chaque bloc.

### Exercice 2

Comparez les pertes du contrôle.

> **Réponse:** L’entrelacement donne `[1,1,1]` absences par bloc ; l’ordre par lignes donne `[3,0,0]`. Les deux totaux valent `3`.

### Exercice 3

La permutation inverse peut-elle remplir les valeurs absentes ?

> **Réponse:** Non. Les positions absentes restent `null` ; la permutation déplace sans ajouter d’information redondante.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: La lecture par colonnes donne `[A,D,G,B,E,H,C,F,I]` ; les indices `[0,1,2]` effacent le premier symbole de chaque bloc.
- Exercice 2: L’entrelacement donne `[1,1,1]` absences par bloc ; l’ordre par lignes donne `[3,0,0]`. Les deux totaux valent `3`.
- Exercice 3: Non. Les positions absentes restent `null` ; la permutation déplace sans ajouter d’information redondante.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
