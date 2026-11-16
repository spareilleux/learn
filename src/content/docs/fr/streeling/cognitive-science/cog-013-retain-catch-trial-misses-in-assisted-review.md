---
title: Conserver les erreurs manquées dans les essais pièges de revue assistée
description: Conserver les erreurs manquées dans les essais pièges de revue assistée — Sciences cognitives
sidebar:
  label: COG-013 · Conserver les erreurs manquées dans les essais pièges de revue assistée
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/fr/cog-013-retain-catch-trial-misses-in-assisted-review.fr.md
---

:::note[Streeling University]
**COG-013** · Conserver les erreurs manquées dans les essais pièges de revue assistée · intermédiaire · 45 minutes

Généré par le département *Sciences cognitives* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/fr/cog-013-retain-catch-trial-misses-in-assisted-review.fr.md) · [Mon journal](../../journal/)

Prérequis: [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/), [COG-009](../../cognitive-science/cog-009-counterbalance-practice-order-before-comparing-interfaces/)
:::

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un rapport de dogfooding affirme qu’un assistant facilite la revue parce que davantage de tâches sont terminées. On peut terminer tout en acceptant sa suggestion erronée. Le prérequis distingue les modes d’aide ; celui sur l’ordre traite les effets de séquence. Ce cours utilise des essais pièges avec des suggestions volontairement fausses et conserve les erreurs manquées dans chaque mode. Il examine une frontière explicite de surveillance plutôt que l’apprentissage général.

La clé externe doit être établie avant de présenter l’élément. Une erreur manquée signifie accepter la suggestion fausse, avec la même définition dans les deux conditions. Appariez les résultats par identité avant de soustraire les totaux. Les erreurs manquées uniquement avec assistance désignent des explications précises à inspecter ; celles manquées dans les deux modes peuvent relever d’une autre difficulté. La seule différence moyenne perd ce diagnostic.

La discussion des blocs du [NIST](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm) motive les comparaisons dans des groupes où les facteurs parasites sont contrôlés. Nos vecteurs construits illustrent le comptage ; ils ne constituent pas une expérience randomisée réelle. Voir un élément peut enseigner sa réponse, et une suggestion fausse peut influencer un jugement manuel ultérieur. Une étude réelle exige donc des éléments parallèles adaptés ou une affectation et un ordre justifiés avant toute conclusion causale.

Les observations conservées laissent explicitement l’étude non implémentée et ne montrent aucun événement de réponse dans les sources sélectionnées. Elles ne fournissent pas les observations appariées ci-dessous. Une fiche d’évaluation proposée devrait conserver clé, suggestion initiale, réponse et mode d’aide. La référence directe est le tableau apparié avec ses résultats négatifs. Ni une impression de facilité ni un meilleur taux de complétion ne fournit cette preuve manquante.

Les deux conditions examinent la même réponse proposée et la même clé. La condition manuelle ne reçoit aucune approbation d’assistant ; la condition assistée voit en plus une approbation de la réponse proposée. Ce sont des présentations stipulées pour le modèle, sans exposition réelle de participants.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cog-007-separate-unaided-recall-from-assisted-success](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/)

[Prérequis: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/cog-009-counterbalance-practice-order-before-comparing-interfaces/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire: NIST/SEMATECH e-Handbook section 5.3.3.2, read 2026-10-24](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

## Modèle fixé et contrôle

```json
{
  "values": {
    "item_ids": [
      "a",
      "b",
      "c",
      "d"
    ],
    "manual_miss": [
      1,
      0,
      0,
      0
    ],
    "assisted_miss": [
      1,
      1,
      1,
      0
    ]
  },
  "formula": "Miss=1 means accepting the planted wrong suggestion; miss_rate=sum(miss)/n; paired excess=(assisted misses-manual misses)/n; count discordant paired items.",
  "expected": {
    "manual_miss_rate": 0.25,
    "assisted_miss_rate": 0.75,
    "paired_excess": 0.5,
    "assisted_only_misses": [
      "b",
      "c"
    ],
    "manual_only_misses": []
  },
  "negative_control": {
    "values": {
      "item_ids": [
        "a",
        "b",
        "c",
        "d"
      ],
      "manual_miss": [
        1,
        0,
        0,
        0
      ],
      "assisted_miss": [
        1,
        0,
        0,
        0
      ]
    },
    "expected": {
      "manual_miss_rate": 0.25,
      "assisted_miss_rate": 0.25,
      "paired_excess": 0,
      "assisted_only_misses": [],
      "manual_only_misses": []
    },
    "why": "Equal paired outcomes remove the excess without manufacturing independent human observations."
  },
  "assumptions": [
    "Same stipulated item key and paired item identities.",
    "Vectors are authored; no causal effect of assistance is inferred."
  ],
  "limits": "Catch items assess these planted errors; tiny paired counts and unobserved order cannot establish automation complacency in users."
}
```

### Exercice 1

Calculez les deux taux d’erreurs manquées selon la définition.

<details><summary>Réponse 1</summary>

Le taux manuel vaut `0.25` ; le taux assisté vaut `0.75`. Manquer signifie accepter la réponse fausse introduite. Ce sont des vecteurs construits, sans observation de réviseurs réels.

</details>

### Exercice 2

Calculez l’excès apparié et nommez les éléments discordants.

<details><summary>Réponse 2</summary>

L’excès vaut `0.5`. Les éléments `b` et `c` sont manqués seulement avec assistance ; aucun ne l’est seulement manuellement. Gardez leurs identités pour pouvoir examiner le raisonnement réel plus tard.

</details>

### Exercice 3

Appliquez le contrôle aux vecteurs identiques. Copier crée-t-il un autre réviseur ?

<details><summary>Réponse 3</summary>

Les deux taux deviennent `0.25` et l’excès `0`. Aucun élément n’est discordant. La copie sert de contrôle mathématique, sans créer de revue indépendante ni de seconde condition réelle.

</details>

### Exercice 4

La différence principale prouve-t-elle que l’aide provoque une complaisance ?

<details><summary>Réponse 4</summary>

Non. Les données sont inventées et l’ordre, la familiarité, l’équivalence des éléments et l’affectation n’ont pas été observés. Le calcul révèle un signal possible de défaut de surveillance sans en diagnostiquer la cause psychologique.

</details>

### Exercice 5

Que faut-il conserver avant de révéler une correction dans un essai réel ?

<details><summary>Réponse 5</summary>

Gardez suggestion initiale, erreur de la clé, réponse, identité, mode, ordre et autres aides. Conservez l’erreur initiale avant la réponse corrigée ; la remplacer par le résultat final effacerait l’événement évalué.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
