---
module_id: "cog-016-find-the-missing-answer-tipping-count"
department: "cognitive-science"
course: "Trouver le nombre de réponses manquantes qui inverse le classement"
level: "intermediate"
prerequisites: ["cog-007-separate-unaided-recall-from-assisted-success", "phi-007-test-a-learning-gain-against-counterfactuals"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Trouver le nombre de réponses manquantes qui inverse le classement

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un bilan de revue assistée omet les offres sans réponse, puis se place au-dessus d’une comparaison manuelle complète. Le prérequis fournit déjà les bornes de complétion. Nous posons maintenant une question de sensibilité : combien de réponses manquantes devraient être correctes pour rendre le classement strictement favorable ?

Gardez le dénominateur initial des offres admissibles. Chaque complétion hypothétique est une supposition, pas une observation. Énumérez les nombres possibles de réussites manquantes et comparez chaque taux complété au taux manuel fixé. L’égalité ne satisfait pas une supériorité stricte. Ce seuil entier se vérifie mieux qu’un récit choisissant discrètement la borne optimiste.

Le relevé conservé distingue réponse absente et erreur observée. La provenance W3C aide à distinguer l’activité produisant un résultat de son résumé dérivé. Aucune source ne fournit les réponses manquantes. Ici, il manque des réponses au point d’évaluation, pas le résultat sous une autre intervention étudié dans le cours contrefactuel. Une complétion favorable ne prouverait aucun bénéfice causal.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cog-007-separate-unaided-recall-from-assisted-success](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md)

[Prérequis: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/en/phi-007-test-a-learning-gain-against-counterfactuals.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Modèle fixé et contrôle

```json
{
  "values": {
    "offered": 10,
    "observed_successes": 6,
    "missing": 4,
    "comparison_successes": 7,
    "comparison_offered": 10
  },
  "formula": "For k missing successes in integers 0..missing, rate=(successes+k)/offered; strict superiority requires rate>comparison_successes/comparison_offered. Return smallest feasible k or null.",
  "expected": {
    "lower": 0.6,
    "upper": 1,
    "comparison_rate": 0.7,
    "minimum_missing_successes_for_strict_superiority": 2,
    "identified_strict_superiority": false
  },
  "negative_control": {
    "values": {
      "offered": 10,
      "observed_successes": 6,
      "missing": 0,
      "comparison_successes": 7,
      "comparison_offered": 10
    },
    "expected": {
      "lower": 0.6,
      "upper": 0.6,
      "comparison_rate": 0.7,
      "minimum_missing_successes_for_strict_superiority": null,
      "identified_strict_superiority": false
    },
    "why": "Complete inferior results leave no missing-answer assignment that can reverse the ranking."
  },
  "assumptions": [
    "One binary endpoint per eligible offer; comparison complete.",
    "Missing results may be either value; no missingness model."
  ],
  "limits": "Descriptive ranking sensitivity only; no causal benefit, probability for completions or statistical interval.",
  "input_types": {
    "offered": "positive integer",
    "observed_successes": "integer in [0,offered-missing]",
    "missing": "integer in [0,offered]",
    "comparison_successes": "integer",
    "comparison_offered": "positive integer"
  }
}
```

### Exercice 1

Calculez les bornes sur toutes les offres.

<details><summary>Réponse 1</summary>

Elles valent `0.6` et `1` ; le taux de comparaison complet vaut `0.7`. Plusieurs classements restent possibles.

</details>

### Exercice 2

Combien de réussites manquantes donnent l’égalité ?

<details><summary>Réponse 2</summary>

Avec `1` réussite manquante, le taux vaut `0.7`. L’égalité ne satisfait pas la supériorité stricte.

</details>

### Exercice 3

Trouvez le seuil de supériorité stricte.

<details><summary>Réponse 3</summary>

Le plus petit nombre est `2`, donnant `0.8`. C’est une exigence hypothétique, pas la preuve de réponses correctes.

</details>

### Exercice 4

Appliquez le contrôle sans manque.

<details><summary>Réponse 4</summary>

Les bornes valent toutes deux `0.6`, sous `0.7` ; le seuil vaut `null`. Aucune complétion admissible ne renverse le classement.

</details>

### Exercice 5

Ce seuil est-il une probabilité de bénéfice ?

<details><summary>Réponse 5</summary>

Non. Aucune probabilité n’est attribuée aux complétions, et un classement descriptif n’identifie pas un effet causal. Conservez les offres sans réponse.

</details>

## Travail avec consultation des sources

Préparez une note de sensibilité du classement pour des réponses fictives de revue GA assistée et manuelle.

**Référence manuelle directe:** Énumérez les réussites manquantes entières avec le dénominateur complet et marquez le premier dépassement strict.

**Critère de réfutation:** L’égalité devient une supériorité ou une réponse hypothétique est présentée comme observée.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
