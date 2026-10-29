---
title: Colorier les tâches agentiques incompatibles par recherche exacte
description: Colorier les tâches agentiques incompatibles par recherche exacte — Science des réseaux
sidebar:
  label: NET-020 · Colorier les tâches agentiques incompatibles par recherche exacte
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/fr/net-020-color-conflicting-agent-tasks-with-an-exact-small-search.fr.md
---

:::note[Streeling University]
**NET-020** · Colorier les tâches agentiques incompatibles par recherche exacte · intermédiaire · 45 minutes

Généré par le département *Science des réseaux* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/fr/net-020-color-conflicting-agent-tasks-with-an-exact-small-search.fr.md) · [Mon journal](../../journal/)

Prérequis: [NET-017](../../network-science/net-017-match-simultaneous-roles-without-double-booking/), [NET-007](../../network-science/net-007-separate-dag-readiness-from-admission/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Plusieurs tâches agentiques prêtes peuvent rester incompatibles dans un même créneau parce qu’elles modifient la même ressource. Un DAG de précédence ne décrit pas toutes ces incompatibilités. Un graphe de conflits non orienté relie les tâches qui ne peuvent partager un créneau. Une couleur désigne un créneau, pas un agent ni une preuve de compétence.

Cherchez les affectations en augmentant le nombre de couleurs. Acceptez une affectation seulement si les extrémités de chaque arête ont des couleurs distinctes. Le premier nombre réalisable prouve l’optimalité pour ce petit graphe entièrement énuméré. L’affectation affichée est le premier vecteur lexicographique dans l’ordre déclaré des sommets. Renommer les couleurs ne change pas le nombre minimal de créneaux.

Le cycle fixé demande moins de créneaux que le contrôle, qui ajoute une diagonale et forme un triangle. Ce triangle fournit une borne inférieure immédiate : tous ses sommets sont mutuellement incompatibles. La documentation présente la coloration gloutonne comme une tentative d’utiliser peu de couleurs, sans garantie d’optimum exact. Durées, disponibilités, mémoire et dépendances entre créneaux sont absentes. Un futur DSL ne devrait pas prendre cette coloration pour un plan d’exécution complet.

## Sources et périmètre du projet

[Prérequis: net-017-match-simultaneous-roles-without-double-booking](../../network-science/net-017-match-simultaneous-roles-without-double-booking/)

[Prérequis: net-007-separate-dag-readiness-from-admission](../../network-science/net-007-separate-dag-readiness-from-admission/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.coloring.greedy_color.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "nodes": [
      "A",
      "B",
      "C",
      "D"
    ],
    "edges": [
      [
        "A",
        "B"
      ],
      [
        "B",
        "C"
      ],
      [
        "C",
        "D"
      ],
      [
        "D",
        "A"
      ]
    ]
  },
  "formula": "For k from 1 to len(nodes), enumerate color vectors in lexicographic order from range(k)^len(nodes); valid iff every undirected edge has different endpoint colors. Return first feasible k and first valid vector.",
  "expected": {
    "chromatic_number": 2,
    "colors": [
      0,
      1,
      0,
      1
    ]
  },
  "negative_control": {
    "values": {
      "nodes": [
        "A",
        "B",
        "C",
        "D"
      ],
      "edges": [
        [
          "A",
          "B"
        ],
        [
          "B",
          "C"
        ],
        [
          "C",
          "D"
        ],
        [
          "D",
          "A"
        ],
        [
          "A",
          "C"
        ]
      ]
    },
    "expected": {
      "chromatic_number": 3,
      "colors": [
        0,
        1,
        2,
        1
      ]
    },
    "why": "A new conflict closes a triangle and raises the required slot count."
  },
  "input_types": {
    "nodes": "ordered distinct node strings",
    "edges": "simple undirected pairs; edge means simultaneous-slot incompatibility"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No actual schedule, capability assignment, equal-duration guarantee, worker availability or greedy-optimality theorem is claimed."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Dessiner les conflits et énumérer les affectations en vérifiant chaque arête.

**Critère de réfutation:** Un créneau contient deux extrémités incompatibles, ou l’optimalité gloutonne est affirmée sans preuve.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Coloriez le cycle de conflits fixé.

> **Réponse:** La première coloration minimale est `[0,1,0,1]`, avec `2` créneaux. Chaque arête sépare deux couleurs.

### Exercice 2

Expliquez le contrôle avec diagonale.

> **Réponse:** Ajouter `[A,C]` crée un triangle. Le minimum vaut `3`, avec la première coloration `[0,1,2,1]`.

### Exercice 3

Un résultat glouton certifie-t-il le minimum ici ?

> **Réponse:** Pas à lui seul. Recherche exacte et bornes du graphe justifient le minimum ; une affectation gloutonne démontre seulement la faisabilité.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: La première coloration minimale est `[0,1,0,1]`, avec `2` créneaux. Chaque arête sépare deux couleurs.
- Exercice 2: Ajouter `[A,C]` crée un triangle. Le minimum vaut `3`, avec la première coloration `[0,1,2,1]`.
- Exercice 3: Pas à lui seul. Recherche exacte et bornes du graphe justifient le minimum ; une affectation gloutonne démontre seulement la faisabilité.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
