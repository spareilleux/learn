---
title: Ne transférer la précision des alertes qu’avec leur prévalence
description: Ne transférer la précision des alertes qu’avec leur prévalence — Sciences cognitives
sidebar:
  label: COG-015 · Ne transférer la précision des alertes qu’avec leur prévalence
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/fr/cog-015-transport-alert-precision-only-with-prevalence.fr.md
---

:::note[Streeling University]
**COG-015** · Ne transférer la précision des alertes qu’avec leur prévalence · intermédiaire · 45 minutes

Généré par le département *Sciences cognitives* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/fr/cog-015-transport-alert-precision-only-with-prevalence.fr.md) · [Mon journal](../../journal/)

Prérequis: [COG-012](../../cognitive-science/cog-012-separate-review-alert-hit-rate-from-response-bias/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un assistant de revue est évalué sur un exercice riche en défauts, puis appliqué à des sources Learn surtout correctes. Sa précision peut changer même si son taux de détection et son taux de fausses alertes restent identiques. Le prérequis distingue ces taux conditionnels ; ce cours reconstruit le mélange rencontré par l’utilisateur.

Google définit la précision comme les vrais positifs divisés par toutes les alertes. Pour prévoir ce dénominateur, séparez d’abord la population construite en éléments défectueux et corrects, puis appliquez le taux approprié à chaque groupe. Les nombres obtenus sont des espérances du modèle, pas une nouvelle matrice observée.

Supposer que les deux taux restent identiques est une hypothèse forte. De nouveaux défauts, réviseurs, seuils ou formats peuvent l’invalider. Un calcul juste ne démontre pas à lui seul la transférabilité. Dans un DSL de preuves, conservez séparément prévalence, taux et provenance. Reprendre une précision issue d’un exercice équilibré importerait silencieusement son mélange de tâches.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cog-012-separate-review-alert-hit-rate-from-response-bias](../../cognitive-science/cog-012-separate-review-alert-hit-rate-from-response-bias/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://developers.google.com/machine-learning/crash-course/classification/accuracy-precision-recall)

## Modèle fixé et contrôle

```json
{
  "values": {
    "items": 1000,
    "prevalence": 0.1,
    "hit_rate": 0.8,
    "false_alarm_rate": 0.1
  },
  "formula": "TP=N*pi*hit; FP=N*(1-pi)*false_alarm; precision=TP/(TP+FP); counts are expected counts under stipulated rates.",
  "expected": {
    "true_positives": 80,
    "false_positives": 90,
    "alerts": 170,
    "precision": 0.47058823529411764
  },
  "negative_control": {
    "values": {
      "items": 1000,
      "prevalence": 0.5,
      "hit_rate": 0.8,
      "false_alarm_rate": 0.1
    },
    "expected": {
      "true_positives": 400,
      "false_positives": 50,
      "alerts": 450,
      "precision": 0.8888888888888888
    },
    "why": "Class-conditional rates stay fixed while prevalence changes the composition of alerts."
  },
  "assumptions": [
    "Same fixed threshold and class-conditional response rates in both populations.",
    "Prevalence stipulated; expected counts happen to be integers."
  ],
  "limits": "No observed review behavior or evidence that class-conditional rates actually transport.",
  "input_types": {
    "items": "positive integer",
    "prevalence": "real in [0,1]",
    "hit_rate": "real in [0,1]",
    "false_alarm_rate": "real in [0,1]"
  }
}
```

### Exercice 1

Calculez les alertes attendues.

<details><summary>Réponse 1</summary>

On attend `80` vrais positifs et `90` faux positifs, soit `170` alertes. Chaque taux utilise son propre dénominateur de classe réelle.

</details>

### Exercice 2

Calculez la précision du cas fixé.

<details><summary>Réponse 2</summary>

`80/170=0.47058823529411764`. La précision décrit les alertes, pas la fraction des défauts détectés.

</details>

### Exercice 3

Appliquez le contrôle à prévalence supérieure.

<details><summary>Réponse 3</summary>

Les nombres deviennent `400` vrais positifs et `50` faux positifs, soit `450` alertes ; la précision vaut `0.8888888888888888`.

</details>

### Exercice 4

Le contrôle améliore-t-il les taux du réviseur ?

<details><summary>Réponse 4</summary>

Non. Les taux restent identiques ; seul le mélange change. Parler de progrès de compétence attribuerait mal le résultat construit.

</details>

### Exercice 5

Qu’est-ce qui invaliderait ce transfert ?

<details><summary>Réponse 5</summary>

Un changement de seuil ou de comportement conditionnel. Il faut des données réelles ; une définition de métrique ne fournit pas ces taux.

</details>

## Travail avec consultation des sources

Rédigez un bilan d’alertes tenant compte de la prévalence pour une revue Learn fictive.

**Référence manuelle directe:** Construisez les lignes défaut/correct avant le dénominateur des alertes.

**Critère de réfutation:** La précision est reprise dans une autre population sans recalculer son mélange.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
