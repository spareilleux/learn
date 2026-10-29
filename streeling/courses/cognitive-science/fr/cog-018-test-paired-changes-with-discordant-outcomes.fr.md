---
module_id: "cog-018-test-paired-changes-with-discordant-outcomes"
department: "cognitive-science"
course: "Tester des changements appariés à partir des résultats discordants"
title: "Tester des changements appariés à partir des résultats discordants"
level: "intermediate"
prerequisites: ["cog-009-counterbalance-practice-order-before-comparing-interfaces", "cog-011-measure-rubric-disagreement-before-adjudication"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Tester des changements appariés à partir des résultats discordants

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un agent de pratique GA affirme qu’une explication révisée répond correctement à davantage d’items. Si les versions sont jugées sur les mêmes items, les résultats sont appariés. Traiter les totaux comme deux échantillons indépendants perd cet appariement. Gardez l’identité des changements de direction avant de choisir un test ou d’annoncer une aide utile.

Formez le tableau des réussites communes, échecs communs et deux directions discordantes. La différence de précision utilise tous les items appariés. Le test directionnel conditionnel n’utilise que les paires discordantes : les résultats communs n’indiquent pas quelle version gagne parmi les changements. Sous l’hypothèse nulle déclarée, les directions sont équiprobables pour chaque paire discordante indépendante.

Le calcul exact double la plus petite queue binomiale, avec un plafond à l’unité. Le cas fixé présente une différence descriptive importante, alors que sa probabilité bilatérale reste au-dessus du seuil conventionnel habituel. Il n’y a pas contradiction : amplitude de l’effet et preuve sous une hypothèse nulle répondent à des questions distinctes. Un grand pourcentage ne garantit pas un test décisif.

Le contrôle équilibre les directions discordantes tout en gardant le nombre d’items. Le prérequis traite déjà du désaccord apparié brut ; cette opération ajoute une comparaison probabiliste avec des hypothèses explicites d’indépendance et d’attribution. Un item manqué par les deux versions reste pertinent pour leur utilité, même s’il ne compte pas dans l’échantillon conditionnel. Aucun apprenant n’a essayé ces explications et aucune interface n’a été attribuée. Une étude en dogfood devrait conserver notation masquée, ordre, identités et paires échouées avant toute synthèse par agent.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/en/cog-009-counterbalance-practice-order-before-comparing-interfaces.md)

[Prérequis: cog-011-measure-rubric-disagreement-before-adjudication](../../cognitive-science/en/cog-011-measure-rubric-disagreement-before-adjudication.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binomtest.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "both_correct": 2,
    "old_only": 1,
    "new_only": 7,
    "both_wrong": 2
  },
  "formula": "n=old_only+new_only; k=min(old_only,new_only); exact two-sided p=min(1,2*sum(comb(n,j),j=0..k)/2**n) for n>0; if n=0 set p=1. Total includes all four cells. Report accuracy difference=(new_only-old_only)/total.",
  "expected": {
    "paired": 12,
    "discordant": 8,
    "old_correct": 3,
    "new_correct": 9,
    "accuracy_difference": 0.5,
    "p_value": 0.0703125
  },
  "negative_control": {
    "values": {
      "both_correct": 2,
      "old_only": 4,
      "new_only": 4,
      "both_wrong": 2
    },
    "expected": {
      "paired": 12,
      "discordant": 8,
      "old_correct": 6,
      "new_correct": 6,
      "accuracy_difference": 0,
      "p_value": 1
    },
    "why": "Balanced discordant directions remove the directional evidence while keeping pair count fixed."
  },
  "input_types": {
    "both_correct": "nonnegative integer",
    "old_only": "nonnegative integer",
    "new_only": "nonnegative integer",
    "both_wrong": "nonnegative integer"
  },
  "assumptions": [
    "Independent pairs; under the null each discordant direction is equally likely.",
    "Same binary criterion for matched items; no missing pairs; test and alternatives declared in advance."
  ],
  "limits": "Authored counts are not learner responses. This is not a causal effect without an appropriate allocation and observation design."
}
```

### Exercice 1

Quel dénominateur correspond à chaque calcul ?

<details><summary>Réponse 1</summary>

Il y a `12` items appariés, mais `8` paires discordantes. La précision utilise tous les items ; le test binomial conditionnel utilise les discordances.

</details>

### Exercice 2

Calculez le changement descriptif.

<details><summary>Réponse 2</summary>

L’ancienne version réussit `3` items, la nouvelle `9`, et la différence vaut `0.5`. Gardez le tableau : les totaux seuls perdent l’identité des changements.

</details>

### Exercice 3

Calculez la probabilité bilatérale exacte.

<details><summary>Réponse 3</summary>

Elle vaut `0.0703125`, à partir des deux queues symétriques. Ce n’est pas une probabilité a posteriori d’équivalence des explications ou d’échec de l’aide.

</details>

### Exercice 4

Appliquez le contrôle équilibré.

<details><summary>Réponse 4</summary>

Les deux versions réussissent `6` items ; la différence vaut `0` et la probabilité `1`. Des désaccords subsistent, mais leurs directions s’équilibrent.

</details>

### Exercice 5

Quelle conclusion causale est justifiée ?

<details><summary>Réponse 5</summary>

Aucune à partir de comptes inventés. Il faut attribution appropriée, identités appariées, notation commune et justification d’indépendance ; des items répétés d’un apprenant peuvent la violer.

</details>

## Travail avec consultation des sources

Préparez l’analyse appariée d’une comparaison fixe d’explications GA avant de recueillir des réponses.

**Référence manuelle directe:** Remplissez le tableau et calculez la queue binomiale symétrique avec les combinaisons entières.

**Critère de réfutation:** La synthèse proposée change le dénominateur apparié ou perd la direction des discordances.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Quel dénominateur correspond à chaque calcul ? — Décision indéterminée.
- Exercice 2: Calculez le changement descriptif. — Décision indéterminée.
- Exercice 3: Calculez la probabilité bilatérale exacte. — Décision indéterminée.
- Exercice 4: Appliquez le contrôle équilibré. — Décision indéterminée.
- Exercice 5: Quelle conclusion causale est justifiée ? — Décision indéterminée.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
