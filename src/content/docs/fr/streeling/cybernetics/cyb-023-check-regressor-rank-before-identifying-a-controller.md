---
title: Vérifier le rang des régresseurs avant l’identification
description: Vérifier le rang des régresseurs avant l’identification — Cybernétique
sidebar:
  label: CYB-023 · Vérifier le rang des régresseurs avant l’identification
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-023-check-regressor-rank-before-identifying-a-controller.fr.md
---

:::note[Streeling University]
**CYB-023** · Vérifier le rang des régresseurs avant l’identification · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-023-check-regressor-rank-before-identifying-a-controller.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-018](../../cybernetics/cyb-018-reconstruct-hidden-state-from-distinct-dynamics/), [CYB-016](../../cybernetics/cyb-016-test-feedforward-against-disturbance-mismatch/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Avant qu’un agent ajuste une règle de réponse, il faut savoir si les expériences distinguent les paramètres inconnus. Ajouter des lignes ne crée pas forcément d’information indépendante. Répéter le même rapport entre composantes d’entrée peut rendre plusieurs vecteurs de paramètres indiscernables, même avec des réponses ajustées exactement.

Écrivez la réponse imposée comme le produit d’une matrice de plan par un vecteur de paramètres. Examinez la matrice de Gram et son rang avant de résoudre les équations normales. Une matrice non singulière donne une solution de moindres carrés unique pour ce problème fini. Une matrice singulière révèle des directions de paramètres que les essais ne distinguent jamais. Ajouter silencieusement une régularisation sélectionnerait une solution grâce à une hypothèse supplémentaire.

Le plan fixé excite des directions indépendantes et retrouve la paire annoncée. Le contrôle a des colonnes proportionnelles : plusieurs paires de même somme pertinente reproduisent toutes les réponses. Le rang fini sert ici de contrôle concret d’excitation ; il ne prouve pas une excitation persistante uniforme sur un signal infini. Bruit, erreur de modèle et conditionnement demandent d’autres éléments. Un futur DSL devrait conserver régresseurs et identités des essais, pas seulement un petit résidu.

## Sources et périmètre du projet

[Prérequis: cyb-018-reconstruct-hidden-state-from-distinct-dynamics](../../cybernetics/cyb-018-reconstruct-hidden-state-from-distinct-dynamics/)

[Prérequis: cyb-016-test-feedforward-against-disturbance-mismatch](../../cybernetics/cyb-016-test-feedforward-against-disturbance-mismatch/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://underactuated.csail.mit.edu/sysid.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "X": [
      [
        1,
        0
      ],
      [
        0,
        1
      ],
      [
        1,
        1
      ]
    ],
    "y": [
      2,
      3,
      5
    ]
  },
  "formula": "Compute Gram=X^T*X, rhs=X^T*y, exact rank and determinant. If full column rank solve Gram*theta=rhs; otherwise unique_parameters=null and report rank deficiency without pseudoinverse.",
  "expected": {
    "gram": [
      [
        2,
        1
      ],
      [
        1,
        2
      ]
    ],
    "rhs": [
      7,
      8
    ],
    "determinant": 3,
    "rank": 2,
    "unique_parameters": [
      2,
      3
    ]
  },
  "negative_control": {
    "values": {
      "X": [
        [
          1,
          1
        ],
        [
          2,
          2
        ],
        [
          3,
          3
        ]
      ],
      "y": [
        5,
        10,
        15
      ]
    },
    "expected": {
      "gram": [
        [
          14,
          14
        ],
        [
          14,
          14
        ]
      ],
      "rhs": [
        70,
        70
      ],
      "determinant": 0,
      "rank": 1,
      "unique_parameters": null
    },
    "why": "Repeated proportional regressors identify only a sum of parameters."
  },
  "input_types": {
    "X": "nonempty rational matrix with two columns",
    "y": "same-length rational response vector"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "Finite rank is not a uniform infinite-horizon persistent-excitation guarantee, noise robustness or an identified production controller."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Former les matrices du plan et de Gram, puis exhiber une direction du noyau si nécessaire.

**Critère de réfutation:** Une identification unique est annoncée à partir d’un plan singulier.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Calculez la matrice de Gram fixée.

> **Réponse:** La matrice est `[[2,1],[1,2]]`, de déterminant `3` et de rang `2` ; les paramètres uniques sont `[2,3]`.

### Exercice 2

Diagnostiquez le contrôle colinéaire.

> **Réponse:** La matrice `[[14,14],[14,14]]` a le déterminant `0` et le rang `1`. Les paires `[2,3]` et `[1,4]` conviennent toutes deux.

### Exercice 3

Dupliquer les lignes du contrôle identifierait-il les deux paramètres ?

> **Réponse:** Non. Dupliquer des lignes proportionnelles change leur poids, pas la direction absente. Il faut un régresseur indépendant.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: La matrice est `[[2,1],[1,2]]`, de déterminant `3` et de rang `2` ; les paramètres uniques sont `[2,3]`.
- Exercice 2: La matrice `[[14,14],[14,14]]` a le déterminant `0` et le rang `1`. Les paires `[2,3]` et `[1,4]` conviennent toutes deux.
- Exercice 3: Non. Dupliquer des lignes proportionnelles change leur poids, pas la direction absente. Il faut un régresseur indépendant.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
