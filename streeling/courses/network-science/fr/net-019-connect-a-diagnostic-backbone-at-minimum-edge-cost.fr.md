---
module_id: "net-019-connect-a-diagnostic-backbone-at-minimum-edge-cost"
department: "network-science"
course: "Relier une ossature de diagnostic au coût minimal"
title: "Relier une ossature de diagnostic au coût minimal"
level: "intermediate"
prerequisites: ["net-014-bound-throughput-with-a-capacity-cut", "mat-019-graphs-centrality-spectral"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Relier une ossature de diagnostic au coût minimal

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Une esquisse d’observatoire cherche une petite ossature de diagnostic reliant plusieurs composants. Les liens candidats ont des coûts de mise en place imposés. Choisir séparément le lien le moins cher de chaque composant peut créer des cycles ou laisser des groupes isolés. Un arbre couvrant exprime la connectivité globale sans liens redondants pour cet objectif précis.

Énumérez les sous-ensembles ayant le nombre d’arêtes requis, rejetez ceux qui sont déconnectés et comparez les sommes de coûts. Dans un graphe non orienté, un sous-ensemble connecté de cette taille est un arbre. Le petit exemple permet une comparaison exhaustive vérifiable. Si plusieurs arbres minimisent le coût, conservez-les tous ; le nom des sommets n’autorise pas à choisir arbitrairement.

Le contrôle augmente le coût d’un lien jusqu’à rendre une autre ossature préférable. L’ancien arbre reste connecté, mais n’est plus optimal avec les nouveaux coûts. Ce n’est pas un déploiement réseau mesuré. Un arbre n’offre aucune route de secours si une arête tombe : coût minimal ne signifie pas résilience. La documentation distingue aussi les entrées déconnectées, qui donnent une forêt. Un futur DSL de topologie devrait conserver ces hypothèses de coût et de connectivité.

## Sources et périmètre du projet

[Prérequis: net-014-bound-throughput-with-a-capacity-cut](../../network-science/en/net-014-bound-throughput-with-a-capacity-cut.md)

[Prérequis: mat-019-graphs-centrality-spectral](../../mathematics/en/mat-019-graphs-centrality-spectral.md)

[Artefact du projet conservé](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.tree.mst.minimum_spanning_tree.html)

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
        "B",
        1
      ],
      [
        "A",
        "C",
        4
      ],
      [
        "A",
        "D",
        6
      ],
      [
        "B",
        "C",
        2
      ],
      [
        "B",
        "D",
        5
      ],
      [
        "C",
        "D",
        3
      ]
    ]
  },
  "formula": "Enumerate subsets of len(nodes)-1 undirected edges, retain connected subsets, sum weights and keep all minimum-cost trees. Sort each tree edge label and the list of optimal trees lexicographically.",
  "expected": {
    "minimum_cost": 6,
    "optimal_trees": [
      [
        "AB",
        "BC",
        "CD"
      ]
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
          "B",
          1
        ],
        [
          "A",
          "C",
          4
        ],
        [
          "A",
          "D",
          6
        ],
        [
          "B",
          "C",
          2
        ],
        [
          "B",
          "D",
          5
        ],
        [
          "C",
          "D",
          8
        ]
      ]
    },
    "expected": {
      "minimum_cost": 8,
      "optimal_trees": [
        [
          "AB",
          "BC",
          "BD"
        ]
      ]
    },
    "why": "The changed edge cost changes the minimum-cost connected subset."
  },
  "input_types": {
    "nodes": "ordered distinct node strings",
    "edges": "simple undirected [endpoint,endpoint,nonnegative cost] records on connected input"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No deployed topology, redundant connectivity, throughput optimum, failure probability or actual link cost is measured."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Énumérer les sous-ensembles connectés et comparer leurs coûts totaux.

**Critère de réfutation:** L’ossature est déconnectée ou un arbre moins coûteux existe avec les mêmes données.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Trouvez l’ossature minimale fixée.

> **Réponse:** Les arêtes `[AB,BC,CD]` relient tous les sommets au coût `6`. Le sous-ensemble est connecté sans cycle.

### Exercice 2

Appliquez le contrôle du lien coûteux.

> **Réponse:** L’optimum devient `[AB,BC,BD]`, au coût `8`. Garder l’ancien arbre coûterait `11`.

### Exercice 3

Le coût minimal implique-t-il une route de secours ?

> **Réponse:** Non. Retirer une arête de l’arbre le déconnecte. La résilience demande un autre objectif ou une autre contrainte.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: Les arêtes `[AB,BC,CD]` relient tous les sommets au coût `6`. Le sous-ensemble est connecté sans cycle.
- Exercice 2: L’optimum devient `[AB,BC,BD]`, au coût `8`. Garder l’ancien arbre coûterait `11`.
- Exercice 3: Non. Retirer une arête de l’arbre le déconnecte. La résilience demande un autre objectif ou une autre contrainte.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
