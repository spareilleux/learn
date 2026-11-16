---
title: Vérifier la cohérence des transformations signées sur un cycle
description: Vérifier la cohérence des transformations signées sur un cycle — Science des réseaux
sidebar:
  label: NET-021 · Vérifier la cohérence des transformations signées sur un cycle
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/fr/net-021-check-signed-transform-consistency-around-a-cycle.fr.md
---

:::note[Streeling University]
**NET-021** · Vérifier la cohérence des transformations signées sur un cycle · intermédiaire · 45 minutes

Généré par le département *Science des réseaux* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/fr/net-021-check-signed-transform-consistency-around-a-cycle.fr.md) · [Mon journal](../../journal/)

Prérequis: [NET-009](../../network-science/net-009-detect-global-cycles-in-a-panel-stack/), [NET-011](../../network-science/net-011-separate-reachability-from-semantic-compatibility/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Des panneaux d’artisanat ou des conventions de coordonnées peuvent imposer des relations d’orientation par paires. Une relation conserve un signe, une autre l’inverse. Un schéma peut contenir un cycle sans contradiction : la cohérence dépend de la composition des transformations. Cela diffère d’un cycle de précédence, où l’ordre circulaire empêche un planning valide.

Attribuez un signe à chaque sommet et exigez que le produit des signes aux extrémités égale celui de l’arête. Fixez le signe racine pour éliminer l’ambiguïté d’inversion globale. Propagez les signes sur un chemin couvrant, puis vérifiez toutes les arêtes restantes. Multiplier les relations sur un cycle annule les signes des sommets : le produit des signes des arêtes doit être positif. Pour le triangle déclaré, cette condition est aussi suffisante.

Le triangle fixé contient des inversions compatibles. Changer une seule arête dans le contrôle rend le produit cyclique impossible. Inverser tous les signes de sommets ne répare rien, puisque leurs produits restent inchangés. Ce modèle ne représente pas toutes les transformations géométriques : les rotations spatiales peuvent ne pas commuter et exigent des matrices ou des quaternions. Un futur DSL devrait conserver la signification et la révision des relations.

## Sources et périmètre du projet

[Prérequis: net-009-detect-global-cycles-in-a-panel-stack](../../network-science/net-009-detect-global-cycles-in-a-panel-stack/)

[Prérequis: net-011-separate-reachability-from-semantic-compatibility](../../network-science/net-011-separate-reachability-from-semantic-compatibility/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://arxiv.org/abs/1701.07963)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "nodes": [
      "A",
      "B",
      "C"
    ],
    "edges": [
      [
        "A",
        "B",
        1
      ],
      [
        "B",
        "C",
        -1
      ],
      [
        "A",
        "C",
        -1
      ]
    ],
    "root_sign": 1
  },
  "formula": "Require label[u]*label[v]=edge_sign with root label fixed. Enumerate remaining signs in order [1,-1]; report first satisfying assignment or null. For this triangle cycle_product is product of its three edge signs.",
  "expected": {
    "cycle_product": 1,
    "consistent": true,
    "labels": [
      1,
      1,
      -1
    ]
  },
  "negative_control": {
    "values": {
      "nodes": [
        "A",
        "B",
        "C"
      ],
      "edges": [
        [
          "A",
          "B",
          1
        ],
        [
          "B",
          "C",
          -1
        ],
        [
          "A",
          "C",
          1
        ]
      ],
      "root_sign": 1
    },
    "expected": {
      "cycle_product": -1,
      "consistent": false,
      "labels": null
    },
    "why": "One changed edge makes closed-loop sign transport contradictory."
  },
  "input_types": {
    "nodes": "ordered three distinct node strings",
    "edges": "triangle undirected pairs with sign integer +1 or -1",
    "root_sign": "fixed first-node sign +1 or -1"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "Only commuting scalar sign relations are modeled; no 3D transform, social trust, knot type or physical panel is validated."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Fixer la racine, propager les relations et multiplier les signes du cycle.

**Critère de réfutation:** Le diagnostic accepte un produit cyclique négatif ou rejette tout cycle sans composer les relations.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Propagez les signes fixés.

> **Réponse:** Avec la racine `A=1`, les signes `[1,1,-1]` satisfont les arêtes ; le produit cyclique vaut `1`.

### Exercice 2

Pourquoi le contrôle échoue-t-il ?

> **Réponse:** Son produit cyclique vaut `-1`. Multiplier les équations exigerait `1=-1` ; aucune affectation n’existe.

### Exercice 3

Inverser tous les signes réparerait-il le contrôle ?

> **Réponse:** Non. L’inversion globale conserve les produits aux extrémités. Il faut examiner la relation en conflit, pas changer seulement la convention racine.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: Avec la racine `A=1`, les signes `[1,1,-1]` satisfont les arêtes ; le produit cyclique vaut `1`.
- Exercice 2: Son produit cyclique vaut `-1`. Multiplier les équations exigerait `1=-1` ; aucune affectation n’existe.
- Exercice 3: Non. L’inversion globale conserve les produits aux extrémités. Il faut examiner la relation en conflit, pas changer seulement la convention racine.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
