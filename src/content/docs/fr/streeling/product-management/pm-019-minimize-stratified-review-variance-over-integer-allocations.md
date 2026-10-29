---
title: Minimiser la variance d’une revue stratifiée par allocations entières
description: Minimiser la variance d’une revue stratifiée par allocations entières — Gestion de produit et de projet
sidebar:
  label: PM-019 · Minimiser la variance d’une revue stratifiée par allocations entières
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-019-minimize-stratified-review-variance-over-integer-allocations.fr.md
---

:::note[Streeling University]
**PM-019** · Minimiser la variance d’une revue stratifiée par allocations entières · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-019-minimize-stratified-review-variance-over-integer-allocations.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-010](../../product-management/pm-010-standardize-dogfood-failures-to-a-declared-task-mix/), [PM-008](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Une étude de revue répartit un budget d’échantillonnage fixé entre des catégories de variabilité différente. Donner le même nombre d’observations à chaque catégorie peut gaspiller de la précision. La question est limitée : quelle allocation entière strictement positive minimise la variance imposée d’une moyenne stratifiée sous les hypothèses annoncées ?

La moyenne cible est une somme pondérée de moyennes d’échantillons indépendants. Avec tirage indépendant avec remise et variances internes connues, sa variance est la somme des poids cibles au carré multipliés par la variance de catégorie, puis divisés par son effectif. Énumérez tous les partages entiers positifs du total. Comparez les rationnels exacts et conservez tous les minima. L’allocation continue éclaire le problème, mais son arrondi ne prouve pas en général l’optimum entier.

Les variances fixées favorisent davantage d’observations dans la catégorie variable ; le contrôle les échange et inverse la répartition. Les nombres ne proviennent ni de défauts observés ni de disponibilités réelles. Couverture obligatoire, apprenants répétés dépendants, coûts inégaux et correction de population finie changeraient le plan. Le résumé primaire distingue allocation entière exacte et arrondi continu. Un futur planificateur devrait conserver la table complète des partages admissibles.

## Sources et périmètre du projet

[Prérequis: pm-010-standardize-dogfood-failures-to-a-declared-task-mix](../../product-management/pm-010-standardize-dogfood-failures-to-a-declared-task-mix/)

[Prérequis: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://www.census.gov/library/working-papers/2014/adrm/rrs2014-07.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "total_samples": 8,
    "target_weights": [
      "1/2",
      "1/2"
    ],
    "stratum_variances": [
      1,
      9
    ]
  },
  "formula": "Enumerate [n1,total_samples-n1] with 1<=n1<total_samples. Under independent with-replacement samples, variance=sum(target_weights[h]**2*stratum_variances[h]/n[h]); keep all exact-rational minima in n1 order.",
  "expected": {
    "candidate_variances": [
      "4/7",
      "1/2",
      "8/15",
      "5/8",
      "4/5",
      "7/6",
      "16/7"
    ],
    "optimal_allocations": [
      [
        2,
        6
      ]
    ],
    "minimum_variance": "1/2"
  },
  "negative_control": {
    "values": {
      "total_samples": 8,
      "target_weights": [
        "1/2",
        "1/2"
      ],
      "stratum_variances": [
        9,
        1
      ]
    },
    "expected": {
      "candidate_variances": [
        "16/7",
        "7/6",
        "4/5",
        "5/8",
        "8/15",
        "1/2",
        "4/7"
      ],
      "optimal_allocations": [
        [
          6,
          2
        ]
      ],
      "minimum_variance": "1/2"
    },
    "why": "Swapping stratum variability reverses the exact optimal integer allocation."
  },
  "input_types": {
    "total_samples": "integer at least two",
    "target_weights": "two nonnegative rational strings summing to one",
    "stratum_variances": "two strictly positive rational variances"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No actual review precision, independent learner sampling, measured stratum variance, finite-population correction or staffing decision is established."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Énumérer chaque partage entier positif et calculer sa variance exacte.

**Critère de réfutation:** L’optimum annoncé ignore un partage moins variable ou assimile des tentatives dépendantes à des échantillons indépendants.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Trouvez l’optimum exact fixé.

> **Réponse:** L’allocation `[2,6]` donne la variance `1/2`, minimale sur les partages entiers positifs. Le partage égal donne `5/8`.

### Exercice 2

Appliquez le contrôle de variances échangées.

> **Réponse:** L’optimum devient `[6,2]` avec un minimum de `1/2`. Les poids cibles et l’effectif total ne changent pas.

### Exercice 3

L’allocation proportionnelle résout-elle cet objectif ?

> **Réponse:** Pas en général. Elle utilise les poids cibles seuls, alors que la variance dépend aussi de la variabilité interne et des contraintes entières.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: L’allocation `[2,6]` donne la variance `1/2`, minimale sur les partages entiers positifs. Le partage égal donne `5/8`.
- Exercice 2: L’optimum devient `[6,2]` avec un minimum de `1/2`. Les poids cibles et l’effectif total ne changent pas.
- Exercice 3: Pas en général. Elle utilise les poids cibles seuls, alors que la variance dépend aussi de la variabilité interne et des contraintes entières.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
