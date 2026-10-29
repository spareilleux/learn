---
module_id: "net-014-bound-throughput-with-a-capacity-cut"
department: "network-science"
course: "Borner le débit par une coupe de capacité"
level: "intermediate"
prerequisites: ["net-010-compute-critical-paths-with-resource-assumptions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Borner le débit par une coupe de capacité

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un coordinateur ajoute des routes entre étapes de preuve fictives et annonce un débit supérieur parce qu’il existe plus de chemins. Plusieurs chemins peuvent partager leur dernier lien. Accessibilité et nombre de routes ne tiennent pas compte de la conservation des capacités. Le prérequis étudie une durée d’ordonnancement finie ; ici on borne un débit stationnaire idéalisé.

La documentation officielle NetworkX définit les capacités et la valeur d’un flot. Nous utilisons ce concept sans exécuter la bibliothèque. Donnez un flot réalisable et une coupe de capacité égale : le premier témoigne d’une borne inférieure, la seconde d’une borne supérieure. Leur égalité établit l’optimum de ce graphe construit. Compter les chemins ne fournit aucun de ces témoins.

La coupe du puits est simple à lire : toute unité livrée doit emprunter une arête entrante. Le contrôle réduit une capacité sans supprimer d’arête. Les routes restent présentes, mais la borne baisse. Appliquer cela à un pipeline réel demanderait des unités compatibles, des capacités observées et des hypothèses de charge.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: net-010-compute-critical-paths-with-resource-assumptions](../../network-science/en/net-010-compute-critical-paths-with-resource-assumptions.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.flow.maximum_flow.html)

## Modèle fixé et contrôle

```json
{
  "values": {
    "nodes": [
      "s",
      "a",
      "b",
      "t"
    ],
    "edges": [
      [
        "s",
        "a",
        3
      ],
      [
        "s",
        "b",
        2
      ],
      [
        "a",
        "t",
        2
      ],
      [
        "b",
        "t",
        2
      ],
      [
        "a",
        "b",
        1
      ]
    ],
    "source": "s",
    "sink": "t"
  },
  "formula": "Nonnegative flow obeys capacities and conservation at a,b. Maximize source outflow; minimum cut is minimum sum of directed capacities from source-side set to its complement.",
  "expected": {
    "maximum_flow": 4,
    "minimum_cut_capacity": 4,
    "sink_cut_capacity": 4,
    "simple_path_count": 3
  },
  "negative_control": {
    "values": {
      "nodes": [
        "s",
        "a",
        "b",
        "t"
      ],
      "edges": [
        [
          "s",
          "a",
          3
        ],
        [
          "s",
          "b",
          2
        ],
        [
          "a",
          "t",
          2
        ],
        [
          "b",
          "t",
          1
        ],
        [
          "a",
          "b",
          1
        ]
      ],
      "source": "s",
      "sink": "t"
    },
    "expected": {
      "maximum_flow": 3,
      "minimum_cut_capacity": 3,
      "sink_cut_capacity": 3,
      "simple_path_count": 3
    },
    "why": "One sink capacity falls while reachability and path count remain unchanged."
  },
  "assumptions": [
    "Directed capacities use common hypothetical items per tick; divisible steady flow.",
    "No latency, node capacity, semantic mismatch or queue storage limit."
  ],
  "limits": "Flow bounds are not an observed worker rate, a finite nonpreemptive schedule or delivery guarantee.",
  "input_types": {
    "nodes": "set<string>",
    "edges": "list<[from,to,nonnegative capacity]>",
    "source": "node",
    "sink": "different node"
  }
}
```

### Exercice 1

Donnez un flot réalisable.

<details><summary>Réponse 1</summary>

Envoyez `2` unités par `s-a-t` et `2` par `s-b-t`, avec `0` sur `a-b`. Le total vaut `4` et respecte la conservation.

</details>

### Exercice 2

Donnez une borne supérieure égale.

<details><summary>Réponse 2</summary>

Les arêtes entrantes de `t` totalisent `4`. Tout flot livré les traverse ; `4` est donc aussi une borne supérieure.

</details>

### Exercice 3

Comptez les routes simples.

<details><summary>Réponse 3</summary>

Il y en a `3` : `s-a-t`, `s-b-t` et `s-a-b-t`. Leur nombre n’est pas une capacité.

</details>

### Exercice 4

Appliquez le contrôle réduit.

<details><summary>Réponse 4</summary>

Le flot maximal et la coupe du puits valent `3` ; le nombre de routes reste `3`. Réduire la capacité ne supprime pas l’accessibilité.

</details>

### Exercice 5

L’optimum garantit-il un débit réel ?

<details><summary>Réponse 5</summary>

Non. Le flot stationnaire divisible omet granularité, pannes, durées et compatibilité sémantique. L’optimum dépend de ce modèle.

</details>

## Travail avec consultation des sources

Préparez une note de coupe de capacité pour un pipeline de preuves Learn construit.

**Référence manuelle directe:** Dessinez les bilans de conservation, un flot réalisable et une coupe séparatrice.

**Critère de réfutation:** Un débit annoncé dépasse une coupe séparatrice ou le nombre de routes devient une capacité.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
