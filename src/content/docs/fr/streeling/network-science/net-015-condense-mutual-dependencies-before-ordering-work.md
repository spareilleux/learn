---
title: Condenser les dépendances mutuelles avant d’ordonner le travail
description: Condenser les dépendances mutuelles avant d’ordonner le travail — Science des réseaux
sidebar:
  label: NET-015 · Condenser les dépendances mutuelles avant d’ordonner le travail
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/fr/net-015-condense-mutual-dependencies-before-ordering-work.fr.md
---

:::note[Streeling University]
**NET-015** · Condenser les dépendances mutuelles avant d’ordonner le travail · intermédiaire · 45 minutes

Généré par le département *Science des réseaux* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/fr/net-015-condense-mutual-dependencies-before-ordering-work.fr.md) · [Mon journal](../../journal/)

Prérequis: [NET-009](../../network-science/net-009-detect-global-cycles-in-a-panel-stack/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Une esquisse de plan Demerzel contient plusieurs cycles. En montrer un suffit à exclure un ordre topologique du graphe initial, mais ne montre pas quelles tâches appartiennent à la même région de dépendance mutuelle. Les composantes fortement connexes fournissent cette partition tout en conservant l’identité de chaque tâche.

NetworkX décrit leur contraction et précise que le graphe obtenu est acyclique. Nos étiquettes sont construites et aucune bibliothèque n’est exécutée. Vérifiez l’accessibilité dans les deux sens avant de regrouper les nœuds. Un chemin à sens unique ne suffit pas. Supprimez ensuite les arêtes internes uniquement dans la vue condensée, en gardant la table des membres.

Le DAG permet de raisonner sur l’ordre entre groupes. Il ne résout pas leurs dépendances internes, qui peuvent exiger de revoir un contrat, scinder une tâche ou définir une itération. Une arête de retour peut fusionner les groupes, comme le montre le contrôle. La contraction ne prouve pas qu’un ordonnancement exécutable a été livré.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: net-009-detect-global-cycles-in-a-panel-stack](../../network-science/net-009-detect-global-cycles-in-a-panel-stack/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.components.condensation.html)

## Modèle fixé et contrôle

```json
{
  "values": {
    "nodes": [
      "a",
      "b",
      "c",
      "d",
      "e"
    ],
    "edges": [
      [
        "a",
        "b"
      ],
      [
        "b",
        "a"
      ],
      [
        "b",
        "c"
      ],
      [
        "c",
        "d"
      ],
      [
        "d",
        "c"
      ],
      [
        "d",
        "e"
      ]
    ]
  },
  "formula": "Group nodes by mutual reachability (including zero-length self path); sort members and components lexically. Emit unique edges between distinct components. Count SCCs and condensed edges.",
  "expected": {
    "components": [
      [
        "a",
        "b"
      ],
      [
        "c",
        "d"
      ],
      [
        "e"
      ]
    ],
    "component_count": 3,
    "condensed_edges": [
      [
        "ab",
        "cd"
      ],
      [
        "cd",
        "e"
      ]
    ],
    "condensed_edge_count": 2
  },
  "negative_control": {
    "values": {
      "nodes": [
        "a",
        "b",
        "c",
        "d",
        "e"
      ],
      "edges": [
        [
          "a",
          "b"
        ],
        [
          "b",
          "a"
        ],
        [
          "b",
          "c"
        ],
        [
          "c",
          "d"
        ],
        [
          "d",
          "c"
        ],
        [
          "d",
          "e"
        ],
        [
          "e",
          "a"
        ]
      ]
    },
    "expected": {
      "components": [
        [
          "a",
          "b",
          "c",
          "d",
          "e"
        ]
      ],
      "component_count": 1,
      "condensed_edges": [],
      "condensed_edge_count": 0
    },
    "why": "One return dependency makes every node mutually reachable; hiding only the obvious local cycles would miss the larger component."
  },
  "assumptions": [
    "Exact finite directed dependency graph; condensed labels concatenate sorted unique single-letter names.",
    "An edge means a dependency relation only, not a legal execution trigger."
  ],
  "limits": "Contraction identifies coupled groups; it does not resolve a cycle, execute a fixed point or authorize simultaneous writes.",
  "input_types": {
    "nodes": "set<unique single-letter string>",
    "edges": "list<[node,node]>"
  }
}
```

### Exercice 1

Trouvez les groupes mutuellement dépendants.

<details><summary>Réponse 1</summary>

Les groupes sont `[a,b]`, `[c,d]` et `[e]`, soit `3` composantes. Chaque paire interne dispose de chemins dans les deux sens.

</details>

### Exercice 2

Écrivez les arêtes condensées.

<details><summary>Réponse 2</summary>

Ce sont `ab->cd` et `cd->e`, soit `2`. Les arêtes internes deviennent une information d’appartenance, pas des boucles de groupe.

</details>

### Exercice 3

Le DAG résout-il les cycles initiaux ?

<details><summary>Réponse 3</summary>

Non. Il ordonne les groupes seulement. Les dépendances internes et identités initiales restent à traiter et doivent rester accessibles.

</details>

### Exercice 4

Appliquez l’arête de retour du contrôle.

<details><summary>Réponse 4</summary>

Tous les nœuds forment `[a,b,c,d,e]` ; il reste `1` composante et `0` arête condensée. Le retour couple tout le graphe.

</details>

### Exercice 5

Pourquoi garder la table des membres ?

<details><summary>Réponse 5</summary>

Sans elle, une image acyclique concise masquerait les tâches encore interdépendantes. La contraction est une vue, pas une autorisation de fusionner les effets.

</details>

## Travail avec consultation des sources

Préparez une carte de régions de dépendance pour un plan Demerzel fictif.

**Référence manuelle directe:** Marquez les paires mutuellement accessibles, formez leurs classes et dessinez les arêtes entre classes.

**Critère de réfutation:** Une accessibilité à sens unique fusionne des groupes ou le DAG condensé devient un ordonnancement résolu.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
