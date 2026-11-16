---
title: Réduire les arêtes de précédence sans effacer les preuves
description: Réduire les arêtes de précédence sans effacer les preuves — Science des réseaux
sidebar:
  label: NET-018 · Réduire les arêtes de précédence sans effacer les preuves
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/fr/net-018-reduce-precedence-edges-without-erasing-evidence.fr.md
---

:::note[Streeling University]
**NET-018** · Réduire les arêtes de précédence sans effacer les preuves · intermédiaire · 45 minutes

Généré par le département *Science des réseaux* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/fr/net-018-reduce-precedence-edges-without-erasing-evidence.fr.md) · [Mon journal](../../journal/)

Prérequis: [NET-015](../../network-science/net-015-condense-mutual-dependencies-before-ordering-work/)
:::

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un schéma de pipeline IX accumule des flèches directes entre tâches déjà ordonnées par d’autres tâches. Le dessin devient difficile à lire. On peut le simplifier, mais seulement après avoir choisi le sens des flèches. Lorsqu’une arête porte un artefact précis ou une autorisation, un autre chemin ne remplace pas automatiquement l’obligation directe.

Ici, chaque arête signifie uniquement une précédence. Dans un graphe acyclique, elle est redondante si ses extrémités restent reliées dans le même sens sans elle. Vérifiez ce chemin avant de retirer la flèche de la vue simplifiée. Comparez toute la relation d’accessibilité avant et après, pas seulement le nombre de sommets ni l’existence d’un ordre topologique.

Le graphe fixé contient une chaîne complète et plusieurs raccourcis. La chaîne préserve toutes les paires ordonnées accessibles. Le contrôle enlève une arête centrale de la chaîne. Un ancien raccourci devient alors nécessaire, faute d’autre chemin. Une réduction appartient donc à une révision précise : une arête redondante hier peut devenir essentielle après une autre modification.

La documentation NetworkX exige un DAG et précise que la réduction ne recopie pas automatiquement les données des arêtes ou sommets. C’est un rappel concret de la perte de représentation, sans exécution de bibliothèque. Le prérequis traite les cycles en regroupant leurs composantes ; la réduction est une autre opération sur un graphe déjà acyclique. Gardez graphe source et preuves. Une vue DSL peut masquer des flèches de précédence redondantes, sans effacer provenance, données requises ou approbations absentes du modèle.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: net-015-condense-mutual-dependencies-before-ordering-work](../../network-science/net-015-condense-mutual-dependencies-before-ordering-work/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.dag.transitive_reduction.html)

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
        "A",
        "C"
      ],
      [
        "C",
        "D"
      ],
      [
        "A",
        "D"
      ],
      [
        "B",
        "D"
      ]
    ]
  },
  "formula": "For a DAG retain edge [u,v] iff deleting that edge leaves no directed u-to-v path. Sort edge lists lexicographically. Count ordered distinct reachable node pairs before and after. Never apply this DAG rule to a cyclic graph.",
  "expected": {
    "retained_edges": [
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
      ]
    ],
    "removed_edges": [
      [
        "A",
        "C"
      ],
      [
        "A",
        "D"
      ],
      [
        "B",
        "D"
      ]
    ],
    "reachable_pairs_before": 6,
    "reachable_pairs_after": 6
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
          "A",
          "C"
        ],
        [
          "C",
          "D"
        ],
        [
          "A",
          "D"
        ],
        [
          "B",
          "D"
        ]
      ]
    },
    "expected": {
      "retained_edges": [
        [
          "A",
          "B"
        ],
        [
          "A",
          "C"
        ],
        [
          "B",
          "D"
        ],
        [
          "C",
          "D"
        ]
      ],
      "removed_edges": [
        [
          "A",
          "D"
        ]
      ],
      "reachable_pairs_before": 5,
      "reachable_pairs_after": 5
    },
    "why": "Removing the middle chain edge makes the former shortcut necessary to preserve reachability."
  },
  "input_types": {
    "nodes": "ordered finite unique strings",
    "edges": "unique directed node pairs forming a DAG"
  },
  "assumptions": [
    "Edges mean precedence only, without latency, required payload, direct authorization or evidence semantics.",
    "Every reachability relation of the supplied DAG is the preservation target."
  ],
  "limits": "Do not delete production dependencies or receipts from this drawing exercise. Equivalent reachability need not preserve data or authority contracts."
}
```

### Exercice 1

Donnez les arêtes réduites du cas fixé.

<details><summary>Réponse 1</summary>

Ce sont `[[A,B],[B,C],[C,D]]`. Les raccourcis retirés sont `[[A,C],[A,D],[B,D]]` ; chacun possède un chemin dirigé alternatif.

</details>

### Exercice 2

Vérifiez la propriété préservée.

<details><summary>Réponse 2</summary>

Il y a `6` paires ordonnées accessibles avant et `6` après. L’égalité des comptes ne suffit pas en général : les ensembles réels doivent aussi concorder.

</details>

### Exercice 3

Quelles arêtes du contrôle restent nécessaires ?

<details><summary>Réponse 3</summary>

La réduction vaut `[[A,B],[A,C],[B,D],[C,D]]` ; seul `[[A,D]]` disparaît. Les comptes accessibles restent `5` avant et `5` après.

</details>

### Exercice 4

Peut-on supprimer la preuve d’une flèche redondante ?

<details><summary>Réponse 4</summary>

Non. L’accessibilité de précédence n’encode ni identité des preuves, ni données directes, ni autorité. Gardez ces enregistrements séparément et le graphe original disponible.

</details>

### Exercice 5

Pourquoi refuser une entrée cyclique ?

<details><summary>Réponse 5</summary>

La règle déclarée suppose un DAG. Condensez ou résolvez les cycles avec un modèle justifié avant de l’appliquer ; ne réutilisez pas silencieusement sa garantie d’unicité.

</details>

## Travail avec consultation des sources

Simplifiez un schéma fictif de précédence IX en gardant ses preuves sources.

**Référence manuelle directe:** Pour chaque arête, tracez un autre chemin ou marquez-la nécessaire, puis comparez les paires accessibles.

**Critère de réfutation:** Le schéma perd une paire accessible ou prétend préserver des données d’arête non représentées.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Donnez les arêtes réduites du cas fixé. — Décision indéterminée.
- Exercice 2: Vérifiez la propriété préservée. — Décision indéterminée.
- Exercice 3: Quelles arêtes du contrôle restent nécessaires ? — Décision indéterminée.
- Exercice 4: Peut-on supprimer la preuve d’une flèche redondante ? — Décision indéterminée.
- Exercice 5: Pourquoi refuser une entrée cyclique ? — Décision indéterminée.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
