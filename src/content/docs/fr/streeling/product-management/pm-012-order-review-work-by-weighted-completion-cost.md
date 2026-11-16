---
title: Ordonner les revues selon le coût pondéré d’achèvement
description: Ordonner les revues selon le coût pondéré d’achèvement — Gestion de produit et de projet
sidebar:
  label: PM-012 · Ordonner les revues selon le coût pondéré d’achèvement
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-012-order-review-work-by-weighted-completion-cost.fr.md
---

:::note[Streeling University]
**PM-012** · Ordonner les revues selon le coût pondéré d’achèvement · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-012-order-review-work-by-weighted-completion-cost.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-003](../../product-management/pm-003-review-queue-flow-metrics/), [NET-010](../../network-science/net-010-compute-critical-paths-with-resource-assumptions/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Une file de revues Learn dispose d’un seul réviseur. Deux ordres peuvent achever toute la file au même instant en laissant attendre certaines tâches plus longtemps. Le débit et la durée totale ne suffisent pas à choisir. Il faut déclarer l’objectif et justifier les poids avant qu’un agent optimise l’ordre.

La lecture OR-Tools décrit non-préemption, précédence et ressource exclusive, avec un objectif de durée totale. Notre petit cas n’a pas de précédence et choisit un autre objectif : chaque tâche accumule sa perte annoncée par unité de temps jusqu’à son achèvement. Énumérez les ordres sans introduire de solveur ni prétendre établir une politique universelle.

Calculez les instants d’achèvement, pas seulement de début. Avancer une tâche courte à poids élevé peut réduire le coût, mais la règle « plus courte d’abord » ne reste pas optimale quand les poids changent. Le contrôle ne change que ceux-ci et inverse la première tâche préférée. Ces points fictifs ne sont ni des minutes mesurées ni une autorisation de contourner une revue.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: pm-003-review-queue-flow-metrics](../../product-management/pm-003-review-queue-flow-metrics/)

[Prérequis: net-010-compute-critical-paths-with-resource-assumptions](../../network-science/net-010-compute-critical-paths-with-resource-assumptions/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://developers.google.com/optimization/scheduling/job_shop)

## Modèle fixé et contrôle

```json
{
  "values": {
    "jobs": [
      "A",
      "B",
      "C"
    ],
    "duration_ticks": {
      "A": 4,
      "B": 1,
      "C": 2
    },
    "weight_per_tick": {
      "A": 4,
      "B": 3,
      "C": 1
    },
    "baseline_order": [
      "A",
      "B",
      "C"
    ]
  },
  "formula": "Single nonpreemptive reviewer, all jobs ready at time zero. Completion time is cumulative duration. Cost=sum(weight[j]*completion[j]). Enumerate all permutations; choose minimum cost.",
  "expected": {
    "optimal_order": [
      "B",
      "A",
      "C"
    ],
    "optimal_completion": {
      "B": 1,
      "A": 5,
      "C": 7
    },
    "optimal_cost": 30,
    "baseline_cost": 38,
    "makespan": 7
  },
  "negative_control": {
    "values": {
      "jobs": [
        "A",
        "B",
        "C"
      ],
      "duration_ticks": {
        "A": 4,
        "B": 1,
        "C": 2
      },
      "weight_per_tick": {
        "A": 8,
        "B": 1,
        "C": 1
      },
      "baseline_order": [
        "A",
        "B",
        "C"
      ]
    },
    "expected": {
      "optimal_order": [
        "A",
        "B",
        "C"
      ],
      "optimal_completion": {
        "A": 4,
        "B": 5,
        "C": 7
      },
      "optimal_cost": 44,
      "baseline_cost": 44,
      "makespan": 7
    },
    "why": "Changing delay weights reverses the preferred first job despite identical durations and makespan."
  },
  "assumptions": [
    "All work available initially; one exclusive reviewer; no interruptions, deadlines or setup costs.",
    "Weights are stipulated cardinal delay loss per tick, not human importance or measured money."
  ],
  "limits": "No real review capacity, optimal general scheduler, quality tradeoff or authority to skip gates.",
  "input_types": {
    "jobs": "list<unique string>",
    "duration_ticks": "map<job,positive integer>",
    "weight_per_tick": "map<job,nonnegative real>",
    "baseline_order": "permutation<jobs>"
  }
}
```

### Exercice 1

Calculez le coût de référence.

<details><summary>Réponse 1</summary>

Dans `ABC`, les achèvements sont `[4,5,7]` ; le coût vaut `4*4+3*5+1*7=38`. La durée totale vaut `7`.

</details>

### Exercice 2

Calculez le coût de l’ordre proposé.

<details><summary>Réponse 2</summary>

Dans `BAC`, les achèvements sont `[1,5,7]` ; le coût vaut `3*1+4*5+1*7=30`. La durée totale reste `7`.

</details>

### Exercice 3

Comment vérifier l’optimalité sans solveur ?

<details><summary>Réponse 3</summary>

Énumérez les `6` permutations et calculez l’objectif de chacune. Un ordre réalisable favorable ne prouve pas son optimalité.

</details>

### Exercice 4

Appliquez le contrôle de poids.

<details><summary>Réponse 4</summary>

`ABC` devient optimal avec un coût `44`, tandis que `BAC` coûte `48`. Des durées fixes n’imposent pas des priorités fixes.

</details>

### Exercice 5

Le meilleur ordre permet-il de sauter une validation apprenant ?

<details><summary>Réponse 5</summary>

Non. Optimiser des tâches admissibles ne change ni leur admissibilité ni l’autorité requise. Les décisions et coûts réels restent distincts.

</details>

## Travail avec consultation des sources

Préparez une fiche d’ordre de revue Learn fictive avec un objectif explicite de coût du retard.

**Référence manuelle directe:** Énumérez tous les ordres sur papier avec leurs achèvements et coûts pondérés.

**Critère de réfutation:** Un optimum annoncé coûte plus qu’un ordre réalisable ou optimise discrètement la durée totale.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
