---
module_id: "net-016-find-mandatory-gates-with-dominators"
department: "network-science"
course: "Repérer les passages obligés avec les dominateurs"
title: "Repérer les passages obligés avec les dominateurs"
level: "intermediate"
prerequisites: ["net-004-semantic-backpressure-and-evidence-dependencies"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Repérer les passages obligés avec les dominateurs

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un schéma Learn place une case de revue avant la publication. Il peut pourtant autoriser un autre chemin qui l’évite. Pour vérifier si la revue est structurellement incontournable, fixez l’entrée et la cible de publication, puis examinez tous les chemins autorisés entre elles. Position dans le dessin et fréquence d’usage ne prouvent pas la nécessité.

Ici, une arête signifie une prochaine étape autorisée. Elle n’exige pas la fin de tous les prédécesseurs comme le ferait une jointure de preuves. Un sommet domine la cible lorsque tous les chemins depuis l’entrée le contiennent. Incluez entrée et cible dans l’intersection, puis repérez la garde intermédiaire proposée. S’il existe un contournement, conservez le chemin : il explique l’échec mieux qu’un pourcentage.

Le graphe fixé a deux branches réunies à la revue. Les deux chemins traversent la garde. Le contrôle ajoute une branche directe vers la publication ; l’ancienne garde n’est plus obligatoire, bien que les chemins initiaux restent présents. Garder son nom ou ajouter un badge vert ne supprime pas la nouvelle route. L’audit structurel exige l’inventaire complet et sa version.

La documentation NetworkX présente une dominance dirigée relative à l’entrée. Notre énumération manuelle ne crée pas de moteur de graphe. Le prérequis vérifie si des preuves satisfont une règle ; ici, on demande si tous les chemins rencontrent cette règle. Une garde peut dominer tout en vérifiant la mauvaise chose. À l’inverse, une arête absente du dessin ne prouve pas un contournement réel. Il faut consulter le code et des parcours liés aux révisions avant toute affirmation opérationnelle.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: net-004-semantic-backpressure-and-evidence-dependencies](../../network-science/en/net-004-semantic-backpressure-and-evidence-dependencies.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.dominance.immediate_dominators.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "nodes": [
      "S",
      "A",
      "B",
      "R",
      "P"
    ],
    "edges": [
      [
        "S",
        "A"
      ],
      [
        "S",
        "B"
      ],
      [
        "A",
        "R"
      ],
      [
        "B",
        "R"
      ],
      [
        "R",
        "P"
      ]
    ],
    "start": "S",
    "target": "P",
    "candidate": "R"
  },
  "formula": "Enumerate all simple directed start-to-target paths. Dominators are their vertex-set intersection ordered by nodes. Candidate mandatory iff it belongs to that intersection; bypass is lexicographically first path omitting candidate or null. Require at least one target path.",
  "expected": {
    "dominators": [
      "S",
      "R",
      "P"
    ],
    "candidate_mandatory": true,
    "bypass": null
  },
  "negative_control": {
    "values": {
      "nodes": [
        "S",
        "A",
        "B",
        "R",
        "P"
      ],
      "edges": [
        [
          "S",
          "A"
        ],
        [
          "S",
          "B"
        ],
        [
          "A",
          "R"
        ],
        [
          "B",
          "R"
        ],
        [
          "R",
          "P"
        ],
        [
          "B",
          "P"
        ]
      ],
      "start": "S",
      "target": "P",
      "candidate": "R"
    },
    "expected": {
      "dominators": [
        "S",
        "P"
      ],
      "candidate_mandatory": false,
      "bypass": [
        "S",
        "B",
        "P"
      ]
    },
    "why": "An added publication route avoids the declared review gate."
  },
  "input_types": {
    "nodes": "ordered list of unique strings",
    "edges": "directed pairs of listed nodes",
    "start": "listed node",
    "target": "reachable listed node",
    "candidate": "listed node"
  },
  "assumptions": [
    "Graph edges mean allowed traversal, not AND-required evidence joins.",
    "Graph includes every allowed route for the stated entry and target."
  ],
  "limits": "Dominance is relative to the graph and entry. It is not authorization, successful review, runtime enforcement or security certification."
}
```

### Exercice 1

Trouvez les dominateurs de la cible fixée.

<details><summary>Réponse 1</summary>

Dans l’ordre déclaré, ce sont `[S,R,P]`. Tous les chemins passent par la revue ; entrée et cible appartiennent aussi à l’ensemble par définition.

</details>

### Exercice 2

Donnez le contournement du contrôle.

<details><summary>Réponse 2</summary>

Le chemin `[S,B,P]` omet `R`. Les dominateurs deviennent `[S,P]` et l’affirmation de garde obligatoire vaut `false`.

</details>

### Exercice 3

La dominance prouve-t-elle une revue réussie ?

<details><summary>Réponse 3</summary>

Non. Elle prouve une présence sur les chemins selon le graphe. Le prédicat réel, l’identité des preuves et l’autorité exigent encore une validation séparée.

</details>

### Exercice 4

Le même graphe peut-il représenter une jointure obligatoire ?

<details><summary>Réponse 4</summary>

Seulement en redéfinissant son sens. Chemins de choix et prérequis conjonctifs répondent à des questions différentes ; un contournement n’est pas automatiquement une condition AND manquante.

</details>

### Exercice 5

Et si la publication est inaccessible ?

<details><summary>Réponse 5</summary>

N’annoncez pas une garde satisfaite à partir d’une intersection vide de chemins. Signalez la cible inaccessible ; le modèle exige une cible accessible avant de juger la nécessité.

</details>

## Travail avec consultation des sources

Vérifiez si une route de publication Learn doit rencontrer sa garde de revue.

**Référence manuelle directe:** Dessinez tous les chemins autorisés depuis l’entrée et prenez l’intersection de leurs sommets.

**Critère de réfutation:** Un chemin autorisé vers la publication omet la garde annoncée obligatoire.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Trouvez les dominateurs de la cible fixée. — Décision indéterminée.
- Exercice 2: Donnez le contournement du contrôle. — Décision indéterminée.
- Exercice 3: La dominance prouve-t-elle une revue réussie ? — Décision indéterminée.
- Exercice 4: Le même graphe peut-il représenter une jointure obligatoire ? — Décision indéterminée.
- Exercice 5: Et si la publication est inaccessible ? — Décision indéterminée.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
