---
title: Équilibrer les coûts de préparation et d’attente de la vérification
description: Équilibrer les coûts de préparation et d’attente de la vérification — Gestion de produit et de projet
sidebar:
  label: PM-015 · Équilibrer les coûts de préparation et d’attente de la vérification
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-015-balance-verification-setup-and-waiting-costs.fr.md
---

:::note[Streeling University]
**PM-015** · Équilibrer les coûts de préparation et d’attente de la vérification · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-015-balance-verification-setup-and-waiting-costs.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-008](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/), [PM-011](../../product-management/pm-011-include-review-and-correction-in-automation-break-even/)
:::

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un futur processus Learn pourrait vérifier chaque arrivée immédiatement ou en regrouper plusieurs avant de répéter une préparation fixe. La vérification immédiate minimise l’attente, mais répète souvent la préparation. Les groupes plus grands réduisent sa fréquence et font patienter les premiers items. Choisir une cadence exige les deux termes sur une échelle comparable, sans supposer que le plus petit ou le plus grand lot est toujours efficace.

Les arrivées construites suivent un intervalle régulier. La vérification est instantanée à l’arrivée du dernier item du groupe. Celui-ci n’attend pas ; son prédécesseur attend un intervalle, les précédents davantage. La somme de cet escalier donne des items-ticks, pas la durée calendaire du groupe entier. Facturez une préparation par groupe et une attente par item-tick.

N’énumérez que les diviseurs déclarés de la charge, afin de finir des groupes complets. Le coût fixé produit un optimum intérieur. Le contrôle réduit ce coût et crée une égalité exacte entre deux petites tailles. Gardez les deux minimiseurs : départager demanderait un critère supplémentaire déclaré. Le groupe maximal n’est pas meilleur simplement parce qu’il minimise les préparations.

Le cours MIT sur les stocks motive l’arbitrage préparation-conservation ; notre formule d’attente finie est dérivée séparément. Elle ne transforme pas les cours en stock physique et n’estime aucun coût réel. Capacité de revue et seuil de rentabilité répondent à d’autres questions. Surtout, le périmètre demandé reste fixé : cet exemple de cadence ne permet pas de le modifier. Une application exigerait de mesurer préparation, temps de vérification, arrivées et conséquences de l’attente, en gardant toutes les revues obligatoires. Le tableau manuel précède toute politique de lots ou ordonnanceur d’agents.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)

[Prérequis: pm-011-include-review-and-correction-in-automation-break-even](../../product-management/pm-011-include-review-and-correction-in-automation-break-even/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://live.ocw.mit.edu/courses/2-854-introduction-to-manufacturing-systems-fall-2016/6c8fec8f99bcf7059b73b82e96d43901_MIT2_854F16_Inventory.pdf)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "items": 12,
    "candidate_sizes": [
      1,
      2,
      3,
      4,
      6,
      12
    ],
    "setup_cost": 9,
    "waiting_cost_per_item_tick": 1
  },
  "formula": "Items arrive one per tick; each batch is verified instantly when its qth item arrives. For q dividing N, batch_count=N/q; waiting_item_ticks=(N/q)*q*(q-1)/2; total=setup_cost*N/q+waiting_cost_per_item_tick*waiting_item_ticks. Retain all minimum-cost candidate sizes.",
  "expected": {
    "total_costs": [
      108,
      60,
      48,
      45,
      48,
      75
    ],
    "waiting_item_ticks": [
      0,
      6,
      12,
      18,
      30,
      66
    ],
    "optimal_sizes": [
      4
    ],
    "minimum_cost": 45
  },
  "negative_control": {
    "values": {
      "items": 12,
      "candidate_sizes": [
        1,
        2,
        3,
        4,
        6,
        12
      ],
      "setup_cost": 1,
      "waiting_cost_per_item_tick": 1
    },
    "expected": {
      "total_costs": [
        12,
        12,
        16,
        21,
        32,
        67
      ],
      "waiting_item_ticks": [
        0,
        6,
        12,
        18,
        30,
        66
      ],
      "optimal_sizes": [
        1,
        2
      ],
      "minimum_cost": 12
    },
    "why": "Lower setup charge changes the balance and creates a tie that must remain explicit."
  },
  "input_types": {
    "items": "positive integer N",
    "candidate_sizes": "distinct positive integer divisors of N",
    "setup_cost": "nonnegative rational points per batch",
    "waiting_cost_per_item_tick": "nonnegative rational points per item-tick"
  },
  "assumptions": [
    "Periodic deterministic arrivals; verification time is zero in this toy cost model.",
    "Setup and waiting are converted to the same stipulated point scale; quality and required reviews are unchanged."
  ],
  "limits": "Not an instruction to alter the actual requested fifty-course batch, a measured cost model, a staffing schedule or a release approval."
}
```

### Exercice 1

Dérivez l’attente du candidat intérieur.

<details><summary>Réponse 1</summary>

Pour la taille `4`, l’attente totale vaut `18` items-ticks et il y a `3` préparations. Elles coûtent `27`, soit un total de `45` points selon la conversion déclarée.

</details>

### Exercice 2

Trouvez tous les optima fixés.

<details><summary>Réponse 2</summary>

Les coûts sont `[108,60,48,45,48,75]` ; seule la taille `[4]` les minimise. Réduire uniquement le nombre de préparations choisirait un candidat différent et plus coûteux.

</details>

### Exercice 3

Appliquez le contrôle de préparation réduite.

<details><summary>Réponse 3</summary>

Les coûts deviennent `[12,12,16,21,32,67]`. Les tailles optimales sont `[1,2]`, toutes deux à `12` points. Gardez l’égalité sans inventer de préférence.

</details>

### Exercice 4

Peut-on ajouter directement items-ticks et minutes ?

<details><summary>Réponse 4</summary>

Non. Le modèle convertit explicitement attente et préparation en points communs. Un arbitrage réel exige une conversion justifiée ou un autre objectif, pas des unités mélangées.

</details>

### Exercice 5

Le petit optimum change-t-il le périmètre demandé ?

<details><summary>Réponse 5</summary>

Non. C’est un calcul construit conditionnel pour une future cadence. Demande réelle, autorité de revue et exigences de qualité restent les contraintes applicables ; aucun coût réel n’a été mesuré.

</details>

## Travail avec consultation des sources

Comparez des cadences hypothétiques de vérification en gardant le périmètre réel demandé.

**Référence manuelle directe:** Dessinez les arrivées, comptez l’attente par item et additionnez préparation et attente pour chaque taille.

**Critère de réfutation:** Un optimum annoncé omet l’attente, mélange les unités ou écarte une égalité sans règle déclarée.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Dérivez l’attente du candidat intérieur. — Décision indéterminée.
- Exercice 2: Trouvez tous les optima fixés. — Décision indéterminée.
- Exercice 3: Appliquez le contrôle de préparation réduite. — Décision indéterminée.
- Exercice 4: Peut-on ajouter directement items-ticks et minutes ? — Décision indéterminée.
- Exercice 5: Le petit optimum change-t-il le périmètre demandé ? — Décision indéterminée.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
