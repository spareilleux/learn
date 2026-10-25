---
title: Inclure revue et correction dans le seuil de rentabilité de l’automatisation
description: Inclure revue et correction dans le seuil de rentabilité de l’automatisation — Gestion de produit et de projet
sidebar:
  label: PM-011 · Inclure revue et correction dans le seuil de rentabilité de l’automatisation
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-011-include-review-and-correction-in-automation-break-even.fr.md
---

:::note[Streeling University]
**PM-011** · Inclure revue et correction dans le seuil de rentabilité de l’automatisation · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-011-include-review-and-correction-in-automation-break-even.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-006](../../product-management/pm-006-test-a-pilot-against-its-decision-horizon/), [PM-008](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)
:::

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Une équipe voit des brouillons générés rapidement et propose d’automatiser la prochaine tranche. La seule vitesse de rédaction omet préparation, revue et correction. Le prérequis sur l’horizon valorise l’information pour les décisions futures ; celui sur la capacité garde la revue visible. Ce cours calcule si un modèle de coût construit rembourse la préparation en préservant la même tâche terminée et sa revue obligatoire.

Définissez la référence manuelle comme du travail actif sur un élément accepté équivalent, sans la réduire à une note brute. Le chemin automatisé comprend rédaction et revue pour chaque élément, puis un coût de correction multiplié par sa probabilité. Celle-ci est inventée et désigne les éléments nécessitant la correction déclarée. Elle ne prouve ni indépendance des corrections ni détection de tous les défauts. Une comparaison réelle doit mesurer le chemin entier et conserver les échecs de qualité.

Soustrayez le coût automatisé par élément du coût manuel avant de calculer l’horizon. Seule une économie positive rembourse une préparation positive. L’égalité au seuil n’apporte aucune économie : il faut l’entier suivant pour une économie stricte. Si l’économie unitaire est nulle, agrandir le lot ne rend pas la préparation gratuite. Un rapport limité à la latence de rédaction masque facilement cette frontière.

Le dossier conservé sépare les points de perte construits du temps mesuré et rappelle qu’une méthode ne calibre pas la performance. Notre exemple utilise des minutes, mais reste inventé. Le [NIST](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm) motive la comparaison d’opérateurs et de tâches comparables lors d’une mesure future. Un DSL ou une boucle d’agent reste candidat tant qu’un essai ne conserve pas journaux manuels et assistés, périmètre équivalent, corrections et sorties réellement acceptées.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: pm-006-test-a-pilot-against-its-decision-horizon](../../product-management/pm-006-test-a-pilot-against-its-decision-horizon/)

[Prérequis: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lecture primaire: NIST/SEMATECH e-Handbook section 5.3.3.2, read 2026-10-24](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

## Modèle fixé et contrôle

```json
{
  "values": {
    "items": 40,
    "manual_minutes_per_item": 12,
    "setup_minutes": 60,
    "draft_minutes_per_item": 3,
    "review_minutes_per_item": 5,
    "correction_probability": 0.25,
    "correction_minutes_if_needed": 8
  },
  "formula": "automated_per_item=draft+review+p*correction; manual_total=n*manual; automated_total=setup+n*automated_per_item; net_saved=manual_total-automated_total; strict break-even requires n>setup/(manual-automated_per_item) when denominator positive.",
  "expected": {
    "automated_minutes_per_item": 10,
    "manual_total_minutes": 480,
    "automated_total_minutes": 460,
    "net_saved_minutes": 20,
    "equal_cost_items": 30,
    "minimum_integer_items_for_strict_saving": 31
  },
  "negative_control": {
    "values": {
      "items": 40,
      "manual_minutes_per_item": 12,
      "setup_minutes": 60,
      "draft_minutes_per_item": 3,
      "review_minutes_per_item": 5,
      "correction_probability": 0.25,
      "correction_minutes_if_needed": 16
    },
    "expected": {
      "automated_minutes_per_item": 12,
      "manual_total_minutes": 480,
      "automated_total_minutes": 540,
      "net_saved_minutes": -60,
      "equal_cost_items": null,
      "minimum_integer_items_for_strict_saving": null
    },
    "why": "Zero per-item savings cannot recover a positive setup cost at any finite batch size."
  },
  "assumptions": [
    "All times are invented active-work minutes on one comparable task.",
    "Correction probability and conditional cost are stable and review is always performed.",
    "Quality and completed scope must be comparable before cost comparison."
  ],
  "limits": "Expected-cost arithmetic, not measured throughput, real savings, learner value, monetary cost or production adoption."
}
```

### Exercice 1

Calculez le travail actif automatisé attendu par élément.

<details><summary>Réponse 1</summary>

Il vaut `3+5+0.25*8=10` minutes. La revue compte pour chaque élément et la correction selon sa probabilité stipulée. C’est une espérance, sans mesure de durée réelle.

</details>

### Exercice 2

Calculez les totaux et l’économie nette pour le lot déclaré.

<details><summary>Réponse 2</summary>

Le total manuel vaut `480` minutes, l’automatisé `460` minutes et l’économie `20` minutes. La préparation compte une fois ; le travail unitaire évolue avec les `40` éléments.

</details>

### Exercice 3

Trouvez l’égalité et le plus petit lot entier donnant une économie stricte.

<details><summary>Réponse 3</summary>

L’égalité arrive à `30` éléments : l’économie unitaire vaut `2` minutes et la préparation `60` minutes. Le premier entier strictement rentable est `31`. Une égalité n’est pas une économie positive.

</details>

### Exercice 4

Appliquez le contrôle avec correction plus longue. Un lot plus grand rembourse-t-il la préparation ?

<details><summary>Réponse 4</summary>

Le coût unitaire attendu devient `12` minutes. Le total déclaré vaut `540` et l’économie `-60`. L’économie unitaire est nulle ; aucun seuil fini strict n’existe dans ce modèle.

</details>

### Exercice 5

Qu’est-ce qui réfuterait une recommandation pratique d’automatisation ?

<details><summary>Réponse 5</summary>

Un travail actif réel de bout en bout sans l’économie prévue, à qualité acceptée comparable, la rejetterait. Gardez préparation, revues, échecs, corrections et aides. Une génération rapide ou ces durées inventées ne prouve ni adoption ni efficacité en production.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
