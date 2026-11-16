---
title: Tester l’atteignabilité sur un horizon fini
description: Tester l’atteignabilité sur un horizon fini — Cybernétique
sidebar:
  label: CYB-021 · Tester l’atteignabilité sur un horizon fini
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-021-test-finite-horizon-control-reachability.fr.md
---

:::note[Streeling University]
**CYB-021** · Tester l’atteignabilité sur un horizon fini · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-021-test-finite-horizon-control-reachability.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-018](../../cybernetics/cyb-018-reconstruct-hidden-state-from-distinct-dynamics/), [CYB-019](../../cybernetics/cyb-019-test-coupled-feedback-eigenmodes/), [MAT-024](../../mathematics/mat-024-dynamical-systems-stability-feedback/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un coordinateur agentique peut observer une file sans disposer d’actions qui atteignent la cible avant une échéance. Même un rang de commandabilité complet ne règle pas la question lorsque les commandes sont bornées ou discrètes. Le cours de mathématiques enseigne déjà ce test pour le double intégrateur. On ajoute ici une autre opération : énumérer les séquences permises, vérifier une cible précise et minimiser une énergie de commande déclarée.

Développez la récurrence dans l’ordre temporel des entrées. Les premières commandes subissent davantage de transitions ; leurs colonnes diffèrent de celles des commandes tardives. Gardez cette matrice comme diagnostic, mais imposez l’alphabet d’actions pendant l’énumération. Propagez chaque candidat, conservez les arrivées exactes sur la cible et comparez les sommes des carrés des commandes. Cette recherche finie fournit un optimum reproductible pour l’alphabet déclaré, pas une solution de commande continue.

L’horizon fixé laisse à une commande précoce le temps d’accumuler le déplacement sans dépasser sa magnitude permise. Le contrôle raccourcit l’horizon : le rang reste complet, mais la solution sans borne exige une commande interdite. Aucune séquence admissible ne réussit. Plus de télémétrie ne crée pas l’action manquante, et le rang ne doit pas annuler ce refus. Un futur DSL devrait conserver horizon, domaine d’action et ensemble admissible vide avant de déclarer la cible exécutable.

## Sources et périmètre du projet

[Prérequis: cyb-018-reconstruct-hidden-state-from-distinct-dynamics](../../cybernetics/cyb-018-reconstruct-hidden-state-from-distinct-dynamics/)

[Prérequis: cyb-019-test-coupled-feedback-eigenmodes](../../cybernetics/cyb-019-test-coupled-feedback-eigenmodes/)

[Prérequis: mat-024-dynamical-systems-stability-feedback](../../mathematics/mat-024-dynamical-systems-stability-feedback/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://hankyang.seas.harvard.edu/OptimalControlEstimation/app-lti-system-theory.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "A": [
      [
        1,
        1
      ],
      [
        0,
        1
      ]
    ],
    "B": [
      0,
      1
    ],
    "initial": [
      0,
      0
    ],
    "target": [
      2,
      1
    ],
    "horizon": 3,
    "allowed_controls": [
      -1,
      0,
      1
    ]
  },
  "formula": "For x_next=A*x+B*u, enumerate every allowed_controls sequence of length horizon in lexicographic order. Propagate from initial; retain sequences whose final state equals target. Report reachability_matrix=[A^(horizon-1)*B,...,B] and its exact rank separately. Minimize sum(u*u) over feasible sequences, retaining all ties. Empty feasible set has null minimum_energy and null final_state.",
  "expected": {
    "reachability_matrix": [
      [
        2,
        1,
        0
      ],
      [
        1,
        1,
        1
      ]
    ],
    "rank": 2,
    "feasible_sequences": [
      [
        1,
        0,
        0
      ]
    ],
    "minimum_energy": 1,
    "optimal_controls": [
      [
        1,
        0,
        0
      ]
    ],
    "final_state": [
      2,
      1
    ]
  },
  "negative_control": {
    "values": {
      "A": [
        [
          1,
          1
        ],
        [
          0,
          1
        ]
      ],
      "B": [
        0,
        1
      ],
      "initial": [
        0,
        0
      ],
      "target": [
        2,
        1
      ],
      "horizon": 2,
      "allowed_controls": [
        -1,
        0,
        1
      ]
    },
    "expected": {
      "reachability_matrix": [
        [
          1,
          0
        ],
        [
          1,
          1
        ]
      ],
      "rank": 2,
      "feasible_sequences": [],
      "minimum_energy": null,
      "optimal_controls": [],
      "final_state": null
    },
    "why": "The shorter horizon retains full linear controllability rank but cannot reach the target with the declared bounded discrete action alphabet."
  },
  "input_types": {
    "A": "rational two-by-two transition matrix",
    "B": "rational two-vector for scalar input",
    "initial": "rational initial two-vector",
    "target": "rational target two-vector",
    "horizon": "positive integer",
    "allowed_controls": "ordered distinct finite rational scalar actions"
  },
  "assumptions": [
    "Every action sequence uses only the declared finite action alphabet.",
    "Energy is the stipulated sum of squared commands, not measured electricity or human effort."
  ],
  "limits": "Finite exhaustive bounded-command feasibility and energy are new here; unrestricted linear rank is baseline knowledge. No actual queue, continuous-input optimum, physical controller or execution permission is established."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Énumérer les séquences permises, propager les états et comparer les énergies quadratiques des arrivées exactes.

**Critère de réfutation:** La cible dite exécutable par le rang n’a aucune séquence respectant horizon et alphabet d’action.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Pourquoi conserver l’ordre temporel des commandes ?

> **Réponse:** La matrice fixée est `[A*A*B,A*B,B]` pour `[u0,u1,u2]`. Les premières commandes se propagent plus longtemps et ont des effets finaux différents.

### Exercice 2

Trouvez l’optimum borné fixé.

> **Réponse:** La matrice `[[2,1,0],[1,1,1]]` a le rang `2`. La seule séquence admissible `[1,0,0]` atteint `[2,1]` avec une énergie quadratique de `1`.

### Exercice 3

Pourquoi le rang complet ne sauve-t-il pas le contrôle raccourci ?

> **Réponse:** À l’horizon `2`, la matrice garde le rang `2`, mais la solution sans borne `[2,-1]` utilise l’action interdite `2`. L’ensemble admissible est vide ; l’énergie minimale est `null`.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: La matrice fixée est `[A*A*B,A*B,B]` pour `[u0,u1,u2]`. Les premières commandes se propagent plus longtemps et ont des effets finaux différents.
- Exercice 2: La matrice `[[2,1,0],[1,1,1]]` a le rang `2`. La seule séquence admissible `[1,0,0]` atteint `[2,1]` avec une énergie quadratique de `1`.
- Exercice 3: À l’horizon `2`, la matrice garde le rang `2`, mais la solution sans borne `[2,-1]` utilise l’action interdite `2`. L’ensemble admissible est vide ; l’énergie minimale est `null`.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
