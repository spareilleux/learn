---
module_id: "pm-014-select-a-budgeted-portfolio-with-prerequisite-closure"
department: "product-management"
course: "Choisir un portefeuille sous budget en fermant les prérequis"
title: "Choisir un portefeuille sous budget en fermant les prérequis"
level: "intermediate"
prerequisites: ["pm-008-size-a-fifty-course-batch-by-review-capacity"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Choisir un portefeuille sous budget en fermant les prérequis

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un coordinateur Learn compare des améliorations facultatives de vérification pour un futur processus. Une fonction intéressante exige une fondation commune, mais son estimation affichée n’inclut que son coût propre. Choisir le meilleur rapport apparent peut donner un portefeuille qui tient dans le budget sur papier tout en omettant son prérequis. Comptez la fermeture complète des dépendances avant de comparer les bénéfices.

Le catalogue construit contient une fondation sans valeur autonome, une amélioration qui en dépend et des alternatives indépendantes. Chaque élément choisi contribue une seule fois au coût et à la valeur. Un sous-ensemble est admissible si tous ses prérequis sont présents et si son coût total respecte le budget. L’énumération du petit catalogue rend les rejets vérifiables et conserve les égalités sans inventer un optimum unique.

L’optimum fixé choisit les alternatives indépendantes. Une proposition séduisante associant fonction et petit élément échoue à la fermeture quand on inclut la fondation. Le contrôle supprime le prérequis et change l’optimum. Cette prémisse modifiée a un effet volontaire : on ne peut la justifier en rebaptisant la fondation détail d’implémentation ou en la facturant à un budget futur indéfini.

Le guide Google définit le problème ordinaire de valeur sous capacité. Notre contrainte de fermeture est une extension construite, pas une affirmation sur son schéma d’entrée. Le prérequis de capacité traite une demande fixe ; ici, on examine du travail facultatif avec des points comparables inventés. Ce cours ne réduit pas la demande et ne dispense d’aucune revue. Une décision réelle exigerait valeurs défendables, coûts mesurés, preuves de dépendance et autorité de choix. Le tableau des sous-ensembles précède tout optimiseur d’agent ou DSL de planification.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/en/pm-008-size-a-fifty-course-batch-by-review-capacity.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://developers.google.com/optimization/pack/knapsack)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "items": {
      "A": {
        "cost": 3,
        "value": 0,
        "requires": []
      },
      "B": {
        "cost": 3,
        "value": 8,
        "requires": [
          "A"
        ]
      },
      "C": {
        "cost": 4,
        "value": 7,
        "requires": []
      },
      "D": {
        "cost": 2,
        "value": 3,
        "requires": []
      }
    },
    "budget": 6
  },
  "formula": "Enumerate all item subsets including empty. Feasible iff total cost<=budget and every selected item has all requires selected. Sum each selected item cost/value once. Maximize total value; retain every optimal subset, sorted lexicographically.",
  "expected": {
    "feasible_count": 7,
    "optimal_sets": [
      [
        "C",
        "D"
      ]
    ],
    "optimal_costs": [
      6
    ],
    "optimal_value": 10
  },
  "negative_control": {
    "values": {
      "items": {
        "A": {
          "cost": 3,
          "value": 0,
          "requires": []
        },
        "B": {
          "cost": 3,
          "value": 8,
          "requires": []
        },
        "C": {
          "cost": 4,
          "value": 7,
          "requires": []
        },
        "D": {
          "cost": 2,
          "value": 3,
          "requires": []
        }
      },
      "budget": 6
    },
    "expected": {
      "feasible_count": 9,
      "optimal_sets": [
        [
          "B",
          "D"
        ]
      ],
      "optimal_costs": [
        5
      ],
      "optimal_value": 11
    },
    "why": "Removing the real prerequisite changes which subset is admissible, not merely its display order."
  },
  "input_types": {
    "items": "mapping of item to nonnegative integer cost/value and prerequisite-name list",
    "budget": "nonnegative integer"
  },
  "assumptions": [
    "All named prerequisites are items; acyclic dependency model.",
    "Values are additive stipulated comparable points; costs are charged once per selected item."
  ],
  "limits": "No portfolio value, real review cost, authorization or scope change is measured. This does not alter the user-requested course batch."
}
```

### Exercice 1

Pourquoi la paire séduisante est-elle impossible ?

<details><summary>Réponse 1</summary>

Le sous-ensemble `[B,D]` coûte directement `5`, mais omet `A`. Sa fermeture `[A,B,D]` coûte `8`, au-delà du budget `6`. L’économie apparente vient d’une obligation oubliée.

</details>

### Exercice 2

Trouvez le portefeuille optimal fixé.

<details><summary>Réponse 2</summary>

Il existe `7` sous-ensembles admissibles. L’optimum est `[C,D]`, de coût `6` et de valeur `10`. Prérequis et budget sont respectés.

</details>

### Exercice 3

Appliquez le contrôle sans prérequis.

<details><summary>Réponse 3</summary>

Il y a `9` sous-ensembles admissibles ; `[B,D]` coûte maintenant `5` et vaut `11`. Ce résultat exige la dépendance modifiée, pas un optimiseur plus rapide.

</details>

### Exercice 4

Peut-on facturer plusieurs fois une fondation commune ?

<details><summary>Réponse 4</summary>

Pas selon ce modèle : chaque élément choisi est facturé une seule fois. Le répéter définirait un autre coût et pourrait inverser la comparaison.

</details>

### Exercice 5

Cela optimise-t-il le périmètre actuel de livraison ?

<details><summary>Réponse 5</summary>

Non. La demande réelle fixe le périmètre. Ces améliorations facultatives fictives illustrent la fermeture ; une sélection réelle exige coûts, valeurs et autorité explicite.

</details>

## Travail avec consultation des sources

Comparez des améliorations facultatives fictives sans omettre le travail préalable.

**Référence manuelle directe:** Énumérez les sous-ensembles et vérifiez fermeture et coût avant de comparer les valeurs.

**Critère de réfutation:** Un portefeuille ne tient que parce qu’une fondation obligatoire manque ou est imputée ailleurs sans justification.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Pourquoi la paire séduisante est-elle impossible ? — Décision indéterminée.
- Exercice 2: Trouvez le portefeuille optimal fixé. — Décision indéterminée.
- Exercice 3: Appliquez le contrôle sans prérequis. — Décision indéterminée.
- Exercice 4: Peut-on facturer plusieurs fois une fondation commune ? — Décision indéterminée.
- Exercice 5: Cela optimise-t-il le périmètre actuel de livraison ? — Décision indéterminée.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
