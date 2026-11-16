---
title: Reconstruire un état caché grâce à des dynamiques distinctes
description: Reconstruire un état caché grâce à des dynamiques distinctes — Cybernétique
sidebar:
  label: CYB-018 · Reconstruire un état caché grâce à des dynamiques distinctes
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-018-reconstruct-hidden-state-from-distinct-dynamics.fr.md
---

:::note[Streeling University]
**CYB-018** · Reconstruire un état caché grâce à des dynamiques distinctes · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-018-reconstruct-hidden-state-from-distinct-dynamics.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-004](../../cybernetics/cyb-004-observe-before-correcting-a-feedback-loop/), [GAS-015](../../guitar-acoustics/gas-015-separate-mode-excitation-from-observation/)
:::

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un tableau Demerzel affiche une quantité globale de travail non résolu. Un même total peut cacher des proportions différentes de rédaction et de revue, qui appelleraient des interventions différentes. Répéter l’agrégat ne fournit pas forcément une seconde vue indépendante. Demandez si une dynamique connue permet à l’observation suivante de distinguer les composantes avant de concevoir un estimateur ou d’accuser un agent bloqué.

Le cours de guitare rend un mode invisible à une position d’observation. Ici, le problème devient temporel : un capteur voit une somme, puis une autre après une évolution connue. Écrivez l’observation actuelle comme le produit de la ligne du capteur et de l’état initial. Substituez la transition dans l’observation suivante. Empiler ces lignes forme un petit système dont le déterminant indique si la reconstruction exacte est unique.

Dans le modèle fixé, les composantes évoluent à des vitesses différentes. Le total suivant fournit donc une équation distincte ; une soustraction retrouve la seconde composante, puis la première. Dans le contrôle, elles évoluent de la même façon. Toute paire initiale de même somme donne la même paire observée. Répéter ces totaux identiques ne restitue pas la distinction manquante.

Les notes de Harvard définissent la matrice d’observabilité ; nos équations discrètes finies montrent directement le calcul. Les composantes sont des coordonnées pédagogiques, pas des comptes calibrés de files réelles. Une file reçoit des entrées, des sorties et du bruit. Une application agentique devrait identifier ces effets et vérifier la transition supposée. Un déterminant exact dans un cas inventé n’établit pas l’observabilité réelle et ne justifie aucune action sans preuves.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: cyb-004-observe-before-correcting-a-feedback-loop](../../cybernetics/cyb-004-observe-before-correcting-a-feedback-loop/)

[Prérequis: gas-015-separate-mode-excitation-from-observation](../../guitar-acoustics/gas-015-separate-mode-excitation-from-observation/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://hankyang.seas.harvard.edu/OptimalControlEstimation/app-lti-system-theory.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "A": [
      [
        1,
        0
      ],
      [
        0,
        2
      ]
    ],
    "C": [
      1,
      1
    ],
    "x0": [
      3,
      4
    ]
  },
  "formula": "x1=A*x0; y0=C*x0; y1=C*x1; O has rows C and C*A. For 2x2 O, det=O00*O11-O01*O10. Full rank iff det != 0. Reconstruct x0 by solving O*x0=[y0,y1].",
  "expected": {
    "O": [
      [
        1,
        1
      ],
      [
        1,
        2
      ]
    ],
    "determinant": 1,
    "rank": 2,
    "outputs": [
      7,
      11
    ],
    "reconstructed": [
      3,
      4
    ]
  },
  "negative_control": {
    "values": {
      "A": [
        [
          1,
          0
        ],
        [
          0,
          1
        ]
      ],
      "C": [
        1,
        1
      ],
      "x0": [
        3,
        4
      ]
    },
    "expected": {
      "O": [
        [
          1,
          1
        ],
        [
          1,
          1
        ]
      ],
      "determinant": 0,
      "rank": 1,
      "outputs": [
        7,
        7
      ],
      "reconstructed": null
    },
    "why": "Equal dynamics keep the two components inseparable through this sensor."
  },
  "input_types": {
    "A": "2x2 integer matrix",
    "C": "length-2 integer row",
    "x0": "length-2 integer column"
  },
  "assumptions": [
    "Known exact linear autonomous dynamics, synchronized noiseless observations.",
    "No unknown inputs act between the observations."
  ],
  "limits": "Full rank is an exact model property, not measured sensor quality or evidence that a live agent state is reconstructible."
}
```

### Exercice 1

Formez la matrice des observations.

<details><summary>Réponse 1</summary>

Les lignes sont `[1,1]` et `[1,2]`, d’où un déterminant de `1` et un rang de `2`. Deux équations indépendantes identifient les coordonnées sous les hypothèses annoncées.

</details>

### Exercice 2

Reconstruisez l’état à partir des sorties.

<details><summary>Réponse 2</summary>

Les observations sont `[7,11]`. Leur différence donne la seconde composante `4` ; la première vaut `3`. C’est une reconstruction exacte du modèle, pas une estimation mesurée d’une file.

</details>

### Exercice 3

Appliquez le contrôle à dynamiques égales.

<details><summary>Réponse 3</summary>

Son déterminant vaut `0`, son rang `1` et ses sorties `[7,7]`. La reconstruction vaut `null`, car aucune paire initiale unique ne peut être choisie.

</details>

### Exercice 4

Une arrivée inconnue préserverait-elle le calcul ?

<details><summary>Réponse 4</summary>

Non. Elle ajoute une contribution non modélisée à la sortie suivante. Enregistrez cette entrée ou revoyez le contrat d’observation avant d’interpréter les composantes reconstruites.

</details>

### Exercice 5

Qu’exige un vrai tableau de bord ?

<details><summary>Réponse 5</summary>

Une transition justifiée, des entrées connues, des dates d’observation, des preuves liées aux sources et des limites de bruit. L’observabilité d’une matrice construite n’établit ni identité ni santé d’un worker réel.

</details>

## Travail avec consultation des sources

Évaluez si un agrégat proposé pour un tableau d’agents distingue ses coordonnées cachées.

**Référence manuelle directe:** Écrivez les équations observées et résolvez-les ou donnez une paire indiscernable à la main.

**Critère de réfutation:** Des états initiaux distincts produisent toute la même séquence observée selon le modèle.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Formez la matrice des observations. — Décision indéterminée.
- Exercice 2: Reconstruisez l’état à partir des sorties. — Décision indéterminée.
- Exercice 3: Appliquez le contrôle à dynamiques égales. — Décision indéterminée.
- Exercice 4: Une arrivée inconnue préserverait-elle le calcul ? — Décision indéterminée.
- Exercice 5: Qu’exige un vrai tableau de bord ? — Décision indéterminée.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
