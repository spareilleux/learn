---
title: Soustraire la tendance de comparaison avant de créditer l’assistance
description: Soustraire la tendance de comparaison avant de créditer l’assistance — Sciences cognitives
sidebar:
  label: COG-017 · Soustraire la tendance de comparaison avant de créditer l’assistance
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/fr/cog-017-subtract-a-comparison-trend-before-crediting-assistance.fr.md
---

:::note[Streeling University]
**COG-017** · Soustraire la tendance de comparaison avant de créditer l’assistance · intermédiaire · 45 minutes

Généré par le département *Sciences cognitives* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/fr/cog-017-subtract-a-comparison-trend-before-crediting-assistance.fr.md) · [Mon journal](../../journal/)

Prérequis: [COG-009](../../cognitive-science/cog-009-counterbalance-practice-order-before-comparing-interfaces/), [PHI-007](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un groupe assisté progresse après un changement de fonctionnement Learn. Un groupe de comparaison progresse aussi. Ne rapporter que le changement du groupe assisté ignore une tendance commune possible. Le prérequis contrefactuel explique la limite du simple avant/après ; ce cours ajoute une comparaison précise et son hypothèse supplémentaire.

La présentation du World Bank soustrait le changement du groupe de comparaison à celui du groupe traité. L’interprétation causale exige des tendances parallèles des résultats sans intervention. Cela ne signifie pas que les niveaux initiaux observés doivent être identiques. Une seule mesure antérieure ne prouve pas non plus ce que les groupes auraient fait ensuite sans assistance.

Travaillez en proportions avec des identités de groupes fixes. Conservez les deux changements avant leur contraste. Le contrôle leur donne le même changement tout en laissant subsister une histoire favorable d’avant/après assisté. Le rapport de l’agent doit garder ce contre-exemple. Participants réels, tâches comparables et plan justifié restent absents du tableau construit.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/cog-009-counterbalance-practice-order-before-comparing-interfaces/)

[Prérequis: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://blogs.worldbank.org/en/impactevaluations/did-you-see-beta-beta-who-part-1)

## Modèle fixé et contrôle

```json
{
  "values": {
    "assisted_before": 0.4,
    "assisted_after": 0.7,
    "comparison_before": 0.5,
    "comparison_after": 0.6
  },
  "formula": "assisted_change=after-before; comparison_change=after-before; contrast=assisted_change-comparison_change.",
  "expected": {
    "assisted_change": 0.3,
    "comparison_change": 0.1,
    "contrast": 0.2
  },
  "negative_control": {
    "values": {
      "assisted_before": 0.4,
      "assisted_after": 0.7,
      "comparison_before": 0.5,
      "comparison_after": 0.8
    },
    "expected": {
      "assisted_change": 0.3,
      "comparison_change": 0.3,
      "contrast": 0
    },
    "why": "Equal group changes erase the differential despite assisted before-after improvement."
  },
  "assumptions": [
    "Comparable endpoints and stable group composition; no interference.",
    "A causal reading additionally requires parallel untreated trends and no differential concurrent change."
  ],
  "limits": "Arithmetic contrast is descriptive; two periods cannot establish parallel trends, randomization or learner benefit.",
  "input_types": {
    "assisted_before": "proportion",
    "assisted_after": "proportion",
    "comparison_before": "proportion",
    "comparison_after": "proportion"
  }
}
```

### Exercice 1

Calculez le changement assisté.

<details><summary>Réponse 1</summary>

`0.7-0.4=0.3`. Il décrit le groupe fourni, sans identifier un effet d’intervention.

</details>

### Exercice 2

Calculez le changement de comparaison et le contraste.

<details><summary>Réponse 2</summary>

`0.6-0.5=0.1`, donc le contraste vaut `0.3-0.1=0.2`. Gardez le même sens de soustraction.

</details>

### Exercice 3

Appliquez le contrôle de changements égaux.

<details><summary>Réponse 3</summary>

Le changement de comparaison devient `0.8-0.5=0.3` ; le contraste vaut `0`. L’amélioration assistée seule subsiste.

</details>

### Exercice 4

Des niveaux initiaux différents réfutent-ils les tendances parallèles ?

<details><summary>Réponse 4</summary>

Non. L’hypothèse concerne les changements des résultats potentiels sans intervention, pas l’égalité initiale. Elle reste non vérifiée ici.

</details>

### Exercice 5

Pourquoi ces nombres seuls ne prouvent-ils pas un effet causal ?

<details><summary>Réponse 5</summary>

Les tendances non observées, la composition des groupes ou des changements simultanés peuvent modifier l’interprétation. L’arithmétique n’observe pas ces contrefactuels.

</details>

## Travail avec consultation des sources

Préparez une fiche de comparaison de groupes de revue GA fictifs avant de demander un bilan de bénéfice à un agent.

**Référence manuelle directe:** Écrivez les deux différences avant/après, puis soustrayez-les en gardant les étiquettes de groupes.

**Critère de réfutation:** L’agent assimile le changement assisté à un bénéfice alors que le contrôle donne un contraste nul.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
