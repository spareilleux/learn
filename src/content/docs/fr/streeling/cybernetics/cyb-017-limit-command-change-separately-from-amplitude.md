---
title: Limiter la variation de commande séparément de son amplitude
description: Limiter la variation de commande séparément de son amplitude — Cybernétique
sidebar:
  label: CYB-017 · Limiter la variation de commande séparément de son amplitude
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-017-limit-command-change-separately-from-amplitude.fr.md
---

:::note[Streeling University]
**CYB-017** · Limiter la variation de commande séparément de son amplitude · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-017-limit-command-change-separately-from-amplitude.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-011](../../cybernetics/cyb-011-prevent-integral-accumulation-under-saturation/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Une commande peut rester dans sa plage autorisée et varier trop vite. Le prérequis sur la saturation limite l’amplitude et suit un intégrateur. Ici, aucun intégrateur : on limite la différence entre commandes appliquées successives. L’agent doit conserver la valeur réellement appliquée et l’intervalle de mise à jour.

Le résumé de l’article cité présente les contraintes de vitesse comme un sujet de modélisation. Nos deux écrêtages sont déclarés indépendamment ; ils ne reproduisent pas sa méthode d’optimisation. Respectez d’abord la plage d’amplitude, puis l’intervalle accessible depuis la commande précédente. Une valeur initiale admissible garantit que ces intervalles se recouvrent.

La sortie finale d’une courte séquence peut différer de la demande. Ce résidu est une conséquence prévue de la contrainte. Vérifier seulement l’amplitude masquerait la nouvelle exigence. Un DSL doit préciser les unités et conserver l’état appliqué ; reprendre la dernière demande changerait l’intervalle suivant.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cyb-011-prevent-integral-accumulation-under-saturation](../../cybernetics/cyb-011-prevent-integral-accumulation-under-saturation/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://arxiv.org/abs/1903.05508)

## Modèle fixé et contrôle

```json
{
  "values": {
    "requests": [
      4,
      4,
      0
    ],
    "initial_command": 0,
    "rate_per_second": 2,
    "dt_seconds": 0.5,
    "lower": 0,
    "upper": 4
  },
  "formula": "First clip requested amplitude to [lower,upper]; then clip it to [previous-rate*dt,previous+rate*dt]. Initial command is inside amplitude range.",
  "expected": {
    "amplitude_only": [
      4,
      4,
      0
    ],
    "commands": [
      1,
      2,
      1
    ],
    "deltas": [
      1,
      1,
      -1
    ],
    "final": 1
  },
  "negative_control": {
    "values": {
      "requests": [
        4,
        4,
        0
      ],
      "initial_command": 0,
      "rate_per_second": 8,
      "dt_seconds": 0.5,
      "lower": 0,
      "upper": 4
    },
    "expected": {
      "amplitude_only": [
        4,
        4,
        0
      ],
      "commands": [
        4,
        4,
        0
      ],
      "deltas": [
        4,
        0,
        -4
      ],
      "final": 0
    },
    "why": "A wide rate bound makes these requests feasible without changing the amplitude range."
  },
  "assumptions": [
    "Uniform positive time step, initial command within bounds, no plant.",
    "Rate bound applies to applied command differences, not derivative estimates."
  ],
  "limits": "No physical actuator, settling guarantee or anti-windup policy was tested.",
  "input_types": {
    "requests": "list<real command units>",
    "initial_command": "real",
    "rate_per_second": "nonnegative real command units/second",
    "dt_seconds": "positive real",
    "lower": "real",
    "upper": "real >= lower"
  }
}
```

### Exercice 1

Calculez la variation permise par mise à jour.

<details><summary>Réponse 1</summary>

`2*0.5=1` unité de commande. Il faut multiplier la vitesse par l’intervalle réel.

</details>

### Exercice 2

Calculez commandes et différences.

<details><summary>Réponse 2</summary>

Les commandes sont `[1,2,1]` et les différences `[1,1,-1]`. Chacune respecte la limite annoncée.

</details>

### Exercice 3

Pourquoi la dernière demande ne donne-t-elle pas zéro ?

<details><summary>Réponse 3</summary>

La commande précédente vaut `2` ; la variation maximale vaut `1`, donc la nouvelle valeur appliquée est `1`.

</details>

### Exercice 4

Appliquez le contrôle à vitesse large.

<details><summary>Réponse 4</summary>

Les commandes sont `[4,4,0]`, les différences `[4,0,-4]` et la valeur finale `0`. La plage d’amplitude reste identique.

</details>

### Exercice 5

Réduire dt de moitié conserve-t-il le saut autorisé ?

<details><summary>Réponse 5</summary>

Non. À vitesse identique, la variation permise par mise à jour est divisée par deux. Cela décrit la contrainte, pas une réponse physique mesurée.

</details>

## Travail avec consultation des sources

Annotez une trace fictive de commande de charge GA avec les limites d’amplitude et de variation.

**Référence manuelle directe:** Tracez les colonnes demande, amplitude écrêtée, valeur précédente appliquée et intervalle admissible.

**Critère de réfutation:** Un saut appliqué dépasse vitesse fois intervalle ou la demande précédente remplace la commande appliquée.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
