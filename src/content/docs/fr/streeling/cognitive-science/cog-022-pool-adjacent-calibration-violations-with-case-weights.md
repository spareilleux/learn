---
title: Regrouper les violations de calibration avec leurs poids
description: Regrouper les violations de calibration avec leurs poids — Sciences cognitives
sidebar:
  label: COG-022 · Regrouper les violations de calibration avec leurs poids
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/fr/cog-022-pool-adjacent-calibration-violations-with-case-weights.fr.md
---

:::note[Streeling University]
**COG-022** · Regrouper les violations de calibration avec leurs poids · intermédiaire · 45 minutes

Généré par le département *Sciences cognitives* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/fr/cog-022-pool-adjacent-calibration-violations-with-case-weights.fr.md) · [Mon journal](../../journal/)

Prérequis: [COG-003](../../cognitive-science/cog-003-calibrating-fretboard-confidence/), [PSY-017](../../psychohistory/psy-017-calibration-with-six-observations/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un rapport de revue agentique trie les niveaux de confiance, mais les fréquences de réussite diminuent entre deux groupes voisins. Un ajustement monotone peut supprimer ce conflit d’ordre en conservant le poids de chaque groupe. Il ne corrige pas un biais d’échantillonnage et ne prouve pas la fiabilité des prévisions. Gardez les fréquences originales et leurs poids à côté de la courbe ajustée.

Commencez par un bloc pour chaque score ordonné. Si la moyenne d’un bloc dépasse celle du suivant, fusionnez-les et prenez leur moyenne pondérée. Vérifiez ensuite la frontière précédente : une fusion peut révéler une autre violation. Les valeurs finales minimisent l’erreur quadratique pondérée sous la contrainte de croissance. Trier les fréquences à la place détacherait les résultats de leurs groupes de confiance.

Les groupes centraux du cas proposé violent l’ordre demandé. Modifier leurs poids déplace la valeur commune sans changer les résultats observés ni l’ordre des scores. Des poids égaux répondraient à une autre question. La courbe ne décrit que les groupes d’entraînement : validation sur des tentatives réservées, suivi de l’assistance et traitement des scores inédits restent nécessaires. Un futur DSL devrait conserver les identités et les poids des groupes.

## Sources et périmètre du projet

[Prérequis: cog-003-calibrating-fretboard-confidence](../../cognitive-science/cog-003-calibrating-fretboard-confidence/)

[Prérequis: psy-017-calibration-with-six-observations](../../psychohistory/psy-017-calibration-with-six-observations/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://docs.scipy.org/doc/scipy-1.14.0/reference/generated/scipy.optimize.isotonic_regression.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "y": [
      0.2,
      0.8,
      0.4,
      0.9
    ],
    "weights": [
      1,
      1,
      3,
      1
    ]
  },
  "formula": "Weighted nondecreasing least squares: minimize sum(weights[i]*(fit[i]-y[i])**2) subject to fit[i]<=fit[i+1]. PAVA merges adjacent decreasing block means using summed weights.",
  "expected": {
    "fit": [
      0.2,
      0.5,
      0.5,
      0.9
    ],
    "weighted_squared_error": 0.12
  },
  "negative_control": {
    "values": {
      "y": [
        0.2,
        0.8,
        0.4,
        0.9
      ],
      "weights": [
        1,
        3,
        1,
        1
      ]
    },
    "expected": {
      "fit": [
        0.2,
        0.7,
        0.7,
        0.9
      ],
      "weighted_squared_error": 0.12
    },
    "why": "Changing case weights changes the pooled mean; sorting responses is not weighted fitting."
  },
  "input_types": {
    "y": "ordered finite observed frequencies",
    "weights": "same-length strictly positive case weights"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No held-out calibration, actual learner counts or behavior of a deployed agent is established."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Écrire les sommes pondérées des blocs et fusionner les frontières décroissantes.

**Critère de réfutation:** L’ajustement ignore les poids ou déplace les résultats entre groupes.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Calculez le bloc fusionné.

> **Réponse:** Les valeurs en conflit donnent `(1*0.8+3*0.4)/4=0.5` ; l’ajustement est `[0.2,0.5,0.5,0.9]`.

### Exercice 2

Appliquez le contrôle qui échange les poids.

> **Réponse:** La valeur commune devient `(3*0.8+1*0.4)/4=0.7`. Les deux objectifs valent `0.12`, mais les séquences ajustées diffèrent.

### Exercice 3

Pourquoi conserver l’ordre initial des groupes ?

> **Réponse:** L’ordre est celui des scores de confiance. Trier les fréquences déplacerait les résultats vers d’autres scores.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: Les valeurs en conflit donnent `(1*0.8+3*0.4)/4=0.5` ; l’ajustement est `[0.2,0.5,0.5,0.9]`.
- Exercice 2: La valeur commune devient `(3*0.8+1*0.4)/4=0.7`. Les deux objectifs valent `0.12`, mais les séquences ajustées diffèrent.
- Exercice 3: L’ordre est celui des scores de confiance. Trier les fréquences déplacerait les résultats vers d’autres scores.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
