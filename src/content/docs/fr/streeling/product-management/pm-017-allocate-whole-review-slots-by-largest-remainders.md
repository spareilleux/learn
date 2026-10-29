---
title: Répartir les créneaux entiers par les plus forts restes
description: Répartir les créneaux entiers par les plus forts restes — Gestion de produit et de projet
sidebar:
  label: PM-017 · Répartir les créneaux entiers par les plus forts restes
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-017-allocate-whole-review-slots-by-largest-remainders.fr.md
---

:::note[Streeling University]
**PM-017** · Répartir les créneaux entiers par les plus forts restes · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-017-allocate-whole-review-slots-by-largest-remainders.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-008](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/), [PM-010](../../product-management/pm-010-standardize-dogfood-failures-to-a-declared-task-mix/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un futur plan de revue possède un total fixé de créneaux indivisibles et une répartition déclarée des catégories de tâches. Multiplier le total par les proportions donne souvent des quotas fractionnaires. Arrondir chaque quota indépendamment peut produire un mauvais total. La méthode des plus forts restes conserve le nombre prévu en rendant les décisions d’arrondi visibles.

Calculez les quotas exacts à partir de poids non négatifs et de leur somme. Attribuez d’abord la partie entière de chaque quota, puis distribuez les créneaux restants par reste fractionnaire décroissant. Déclarez une règle d’égalité fondée sur l’ordre des indices avant d’examiner un cas ex æquo. Si le total change, recalculez toute la répartition plutôt que d’ajouter intuitivement un créneau.

Le contrôle augmente le total et change la catégorie ayant le plus grand reste. Les créneaux sont fictifs ; ils ne décrivent aucune disponibilité réelle. La méthode ne minimise pas une variance et ne garantit ni toute conception de l’équité ni les compétences requises. Les quotas expriment une politique à justifier. Un futur DSL devrait conserver poids, total, parties entières et règle d’égalité pour rendre le résultat entier reproductible.

## Sources et périmètre du projet

[Prérequis: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)

[Prérequis: pm-010-standardize-dogfood-failures-to-a-declared-task-mix](../../product-management/pm-010-standardize-dogfood-failures-to-a-declared-task-mix/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://www.census.gov/about/history/historical-censuses-and-surveys/census-programs-surveys/decennial-census/methods.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "total_slots": 7,
    "weights": [
      5,
      3,
      2
    ]
  },
  "formula": "quota[i]=total_slots*weights[i]/sum(weights). Assign floor quotas; allocate remaining slots to descending fractional remainders, breaking exact ties by lower index. Use exact rational arithmetic.",
  "expected": {
    "quotas": [
      "7/2",
      "21/10",
      "7/5"
    ],
    "floors": [
      3,
      2,
      1
    ],
    "remainder_order": [
      0,
      2,
      1
    ],
    "allocation": [
      4,
      2,
      1
    ]
  },
  "negative_control": {
    "values": {
      "total_slots": 8,
      "weights": [
        5,
        3,
        2
      ]
    },
    "expected": {
      "quotas": [
        "4",
        "12/5",
        "8/5"
      ],
      "floors": [
        4,
        2,
        1
      ],
      "remainder_order": [
        2,
        1,
        0
      ],
      "allocation": [
        4,
        2,
        2
      ]
    },
    "why": "Changing the total changes the remainder ordering and full allocation."
  },
  "input_types": {
    "total_slots": "nonnegative integer",
    "weights": "nonnegative integers with strictly positive sum"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No real reviewer capacity, universal fairness, population apportionment or variance-optimal sampling allocation is established."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Calculer quotas, parties entières et restes classés, puis vérifier la somme finale.

**Critère de réfutation:** L’arrondi change le total demandé ou une égalité est départagée sans règle déclarée.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Répartissez le total fixé.

> **Réponse:** Les quotas `[7/2,21/10,7/5]` ont pour parties entières `[3,2,1]`. Le créneau restant va à l’indice `0`, donnant `[4,2,1]`.

### Exercice 2

Recalculez le contrôle au total augmenté.

> **Réponse:** Pour `8` créneaux, les quotas sont `[4,12/5,8/5]` ; l’indice `2` reçoit le surplus et la répartition vaut `[4,2,2]`.

### Exercice 3

Pourquoi déclarer une règle d’égalité ?

> **Réponse:** Des restes égaux peuvent se disputer trop peu de créneaux. Une règle fixée rend le résultat reproductible sans se prétendre seule équitable.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: Les quotas `[7/2,21/10,7/5]` ont pour parties entières `[3,2,1]`. Le créneau restant va à l’indice `0`, donnant `[4,2,1]`.
- Exercice 2: Pour `8` créneaux, les quotas sont `[4,12/5,8/5]` ; l’indice `2` reçoit le surplus et la répartition vaut `[4,2,2]`.
- Exercice 3: Des restes égaux peuvent se disputer trop peu de créneaux. Une règle fixée rend le résultat reproductible sans se prétendre seule équitable.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
