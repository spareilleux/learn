---
title: Standardiser les échecs de dogfooding selon un mélange de tâches déclaré
description: Standardiser les échecs de dogfooding selon un mélange de tâches déclaré — Gestion de produit et de projet
sidebar:
  label: PM-010 · Standardiser les échecs de dogfooding selon un mélange de tâches déclaré
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-010-standardize-dogfood-failures-to-a-declared-task-mix.fr.md
---

:::note[Streeling University]
**PM-010** · Standardiser les échecs de dogfooding selon un mélange de tâches déclaré · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-010-standardize-dogfood-failures-to-a-declared-task-mix.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-009](../../product-management/pm-009-separate-release-adoption-from-artifact-downloads/), [COG-009](../../cognitive-science/cog-009-counterbalance-practice-order-before-comparing-interfaces/)
:::

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Une équipe compare deux rapports et célèbre un pourcentage global d’échec plus faible. L’un peut simplement contenir plus de tâches courantes et moins de cas limites. Le prérequis définit les personnes et actions du dénominateur ; ce cours examine le mélange des classes lorsque leur performance reste identique. Il faut déclarer un mélange cible avant d’interpréter le bilan global.

Calculez d’abord le taux d’échec dans chaque strate. Ces taux préservent les profils de difficulté représentés par les données construites. Le taux global pondère par les effectifs réellement fournis. Le taux standardisé utilise le mélange cible. Ils répondent à deux questions : que décrit l’échantillon, et que donneraient ces taux sous les poids choisis ? Aucun n’est automatiquement la distribution des futurs utilisateurs.

La discussion du [NIST](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm) motive la conservation des groupes parasites et les comparaisons internes. Notre arithmétique de mélange ne constitue ni une expérience randomisée ni une correction causale de tous les facteurs. Une strate peut encore mêler tâches, aides et apprenants répétés. Gardez ces limites au lieu de traiter la standardisation comme preuve d’équité complète. Le mélange cible reste un choix construit à justifier par le projet.

Le contrôle modifie les effectifs en conservant les taux de chaque strate. Le pourcentage global rejoint la valeur standardisée sans amélioration dans aucune classe. Cela réfute un bilan naïf de progrès. La source du projet énumère des champs d’exercices sans événements réels de réponse ; elle ne calibre donc pas nos nombres. Avant de demander un bilan à un agent, calculez les deux résumés à la main et gardez identité des tâches, révision et aides visibles.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/pm-009-separate-release-adoption-from-artifact-downloads/)

[Prérequis: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/cog-009-counterbalance-practice-order-before-comparing-interfaces/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire: NIST/SEMATECH e-Handbook section 5.3.3.2, read 2026-10-24](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

## Modèle fixé et contrôle

```json
{
  "values": {
    "strata": [
      "routine",
      "edge"
    ],
    "attempts": [
      30,
      10
    ],
    "failures": [
      3,
      4
    ],
    "target_weights": [
      0.9,
      0.1
    ]
  },
  "formula": "rate_i=failures_i/attempts_i; pooled=sum(failures)/sum(attempts); standardized=sum(target_weight_i*rate_i).",
  "expected": {
    "stratum_rates": [
      0.1,
      0.4
    ],
    "pooled_rate": 0.175,
    "standardized_rate": 0.13
  },
  "negative_control": {
    "values": {
      "strata": [
        "routine",
        "edge"
      ],
      "attempts": [
        90,
        10
      ],
      "failures": [
        9,
        4
      ],
      "target_weights": [
        0.9,
        0.1
      ]
    },
    "expected": {
      "stratum_rates": [
        0.1,
        0.4
      ],
      "pooled_rate": 0.13,
      "standardized_rate": 0.13
    },
    "why": "Changing sample mix to match the declared target aligns pooled and standardized rates without improving either stratum."
  },
  "assumptions": [
    "Target weights are authored, nonnegative and sum to unity.",
    "Within-stratum rates are descriptive of supplied attempts; no representativeness guarantee."
  ],
  "limits": "No real dogfood cohort, user distribution, causal improvement or statistical precision was measured."
}
```

### Exercice 1

Calculez les taux d’échec des deux strates.

<details><summary>Réponse 1</summary>

Le taux courant vaut `3/30=0.1` ; le taux des cas limites `4/10=0.4`. Gardez les classes et dénominateurs : le total masque le taux nettement supérieur des cas limites.

</details>

### Exercice 2

Calculez le taux global de l’échantillon principal.

<details><summary>Réponse 2</summary>

Il vaut `7/40=0.175`. Il décrit le mélange fourni, sans utiliser les poids cibles. Il ne doit donc pas être appelé taux standardisé de la population cible.

</details>

### Exercice 3

Calculez le taux standardisé au mélange déclaré.

<details><summary>Réponse 3</summary>

Il vaut `0.9*0.1+0.1*0.4=0.13`. On applique les poids construits aux taux des strates. Le calcul ne valide pas ces poids comme distribution réelle d’usage.

</details>

### Exercice 4

Appliquez le contrôle. Une strate s’est-elle améliorée ?

<details><summary>Réponse 4</summary>

Le taux global devient `13/100=0.13`, égal au taux standardisé. Les taux restent `[0.1,0.4]`. Le bilan plus faible vient du mélange modifié, sans progrès interne.

</details>

### Exercice 5

Que doit conserver une future comparaison de dogfooding ?

<details><summary>Réponse 5</summary>

Gardez définitions des classes, tentatives, échecs, poids et justification, réponses réelles, aides et révisions. Comparez les strates comparables avant le total. Un mélange modifié ou des nombres inventés ne prouve pas un progrès réel.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
