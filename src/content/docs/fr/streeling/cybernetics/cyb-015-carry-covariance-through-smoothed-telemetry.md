---
title: Propager la covariance dans une télémétrie lissée
description: Propager la covariance dans une télémétrie lissée — Cybernétique
sidebar:
  label: CYB-015 · Propager la covariance dans une télémétrie lissée
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-015-carry-covariance-through-smoothed-telemetry.fr.md
---

:::note[Streeling University]
**CYB-015** · Propager la covariance dans une télémétrie lissée · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-015-carry-covariance-through-smoothed-telemetry.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-010](../../cybernetics/cyb-010-separate-derivative-noise-from-plant-motion/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un tableau de bord plus calme n’est pas nécessairement plus précis. Des mesures successives peuvent partager une source d’erreur. Leur appliquer une formule supposant l’indépendance peut sous-estimer l’incertitude malgré un lissage arithmétiquement correct. Le cours sur la dérivée donne déjà la récurrence ; celui-ci ajoute le calcul de son incertitude sur une histoire finie.

NIST fournit une approximation de variance pour une série longue et précise les conditions d’indépendance. Ici, la série est courte et initialisée. Développez d’abord les poids, puis utilisez toute la matrice de covariance. Les termes hors diagonale comptent lorsque les erreurs évoluent ensemble. L’état initial déterministe garde aussi un poids et peut créer un biais.

Conservez des unités de suivi symboliques. L’espérance résulte des erreurs stipulées ; elle n’est pas une moyenne observée de traces du projet. Avant de proposer un réglage d’agent, conservez l’initialisation, les hypothèses de covariance et le retard de réponse absent de ce modèle constant.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cyb-010-separate-derivative-noise-from-plant-motion](../../cybernetics/cyb-010-separate-derivative-noise-from-plant-motion/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc324.htm)

## Modèle fixé et contrôle

```json
{
  "values": {
    "alpha": 0.5,
    "initial": 0,
    "true_level": 4,
    "error_covariance": [
      [
        4,
        2
      ],
      [
        2,
        4
      ]
    ]
  },
  "formula": "After two EWMA updates weights are [alpha*(1-alpha),alpha]; expected=sum(weights)*true_level+(1-alpha)^2*initial; bias=expected-true_level; variance=w^T*Cov*w.",
  "expected": {
    "weights": [
      0.25,
      0.5
    ],
    "expected_level": 3,
    "bias": -1,
    "variance": 1.75
  },
  "negative_control": {
    "values": {
      "alpha": 0.5,
      "initial": 0,
      "true_level": 4,
      "error_covariance": [
        [
          4,
          0
        ],
        [
          0,
          4
        ]
      ]
    },
    "expected": {
      "weights": [
        0.25,
        0.5
      ],
      "expected_level": 3,
      "bias": -1,
      "variance": 1.25
    },
    "why": "Removing cross-covariance changes variance while the initialized mean and bias stay fixed."
  },
  "assumptions": [
    "Two zero-mean errors with the stipulated covariance matrix; deterministic initial state.",
    "No feedback or changing true level."
  ],
  "limits": "Finite authored moments, not estimated GA noise, confidence intervals or closed-loop stability.",
  "input_types": {
    "alpha": "real in (0,1]",
    "initial": "real",
    "true_level": "real",
    "error_covariance": "positive semidefinite 2x2 matrix"
  }
}
```

### Exercice 1

Développez les poids des mesures.

<details><summary>Réponse 1</summary>

Les poids valent `[0.25,0.5]` ; l’état initial garde `0.25`. Les mesures totalisent `0.75`, donc l’initialisation compte encore.

</details>

### Exercice 2

Calculez l’espérance et le biais.

<details><summary>Réponse 2</summary>

Le niveau attendu vaut `3` ; le biais par rapport à `4` vaut `-1`. Cette histoire finie n’atteint pas encore le niveau stipulé.

</details>

### Exercice 3

Calculez la variance complète.

<details><summary>Réponse 3</summary>

La diagonale contribue `1.25` et les termes croisés `0.5`, soit `1.75`. Omettre la covariance change le calcul.

</details>

### Exercice 4

Appliquez le contrôle indépendant.

<details><summary>Réponse 4</summary>

La variance devient `1.25`. L’espérance reste `3` et le biais `-1` ; l’indépendance ne supprime pas le biais initial.

</details>

### Exercice 5

Un affichage plus calme établit-il la stabilité ?

<details><summary>Réponse 5</summary>

Non. Le modèle ne contient ni système commandé ni rétroaction. Il faut des erreurs, des durées et des coûts réels avant de choisir une politique.

</details>

## Travail avec consultation des sources

Préparez une note d’incertitude sur deux mises à jour de suivi GA fictives.

**Référence manuelle directe:** Développez les mises à jour sur papier, gardez le poids initial et utilisez la covariance complète.

**Critère de réfutation:** Une variance favorable omet les termes croisés ou emploie la formule asymptotique pour ce cas fini initialisé.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
