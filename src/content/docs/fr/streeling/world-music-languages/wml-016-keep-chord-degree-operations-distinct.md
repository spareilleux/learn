---
title: Distinguer les opérations sur les degrés d’un accord
description: Distinguer les opérations sur les degrés d’un accord — Musiques et langues du monde
sidebar:
  label: WML-016 · Distinguer les opérations sur les degrés d’un accord
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-016-keep-chord-degree-operations-distinct.fr.md
---

:::note[Streeling University]
**WML-016** · Distinguer les opérations sur les degrés d’un accord · avancé · 60 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-016-keep-chord-degree-operations-distinct.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-011](../../world-music-languages/wml-011-preserve-the-kind-of-a-seventh-chord/)
:::

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un symbole d’accord peut garder sa fondamentale et sa famille tout en perdant l’ajout, l’altération ou la suppression d’un degré. Transformer toute consigne en classe de hauteur supplémentaire peut conserver une note à retirer. Pour une explication harmonique [GA](https://github.com/GuitarAlchemist/ga), nous exécutons un petit programme de modifications avant la projection en classes de hauteur.

## Lire les éléments conservés

La référence distingue ajout, altération et suppression par rapport à la famille d’accord. Nos contrôles stricts de collision sont une règle construite supplémentaire, sans promesse de conformité. L’acceptation ciblée du relevé conservé justifie de garder davantage qu’une famille générale.

[Prérequis](../../world-music-languages/wml-011-preserve-the-kind-of-a-seventh-chord/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.w3.org/2021/06/musicxml40/musicxml-reference/data-types/degree-type-value/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "degrees": {
      "1": 0,
      "3": 4,
      "5": 7,
      "7": 10
    },
    "operations": [
      {
        "op": "add",
        "degree": 9,
        "semitones": 14
      },
      {
        "op": "alter",
        "degree": 5,
        "delta": -1
      },
      {
        "op": "subtract",
        "degree": 3
      }
    ]
  },
  "formula": "add requires absent degree and inserts declared offset; alter requires present degree and adds delta; subtract requires present degree and removes it; pcs=sorted(set(offset%12))",
  "expected": {
    "degrees": {
      "1": 0,
      "5": 6,
      "7": 10,
      "9": 14
    },
    "pitch_classes": [
      0,
      2,
      6,
      10
    ],
    "valid": true
  },
  "negative_control": {
    "values": {
      "degrees": {
        "1": 0,
        "3": 4,
        "5": 7,
        "7": 10
      },
      "operations": [
        {
          "op": "add",
          "degree": 9,
          "semitones": 14
        },
        {
          "op": "add",
          "degree": 5,
          "semitones": 6
        },
        {
          "op": "subtract",
          "degree": 3
        }
      ]
    },
    "expected": {
      "valid": false,
      "rejected_operation_index": 1,
      "reason": "duplicate_degree",
      "degree": 5
    }
  }
}
```

## Conserver la modification avant de projeter son résultat

La table des degrés garde une relation à la famille d’accord initiale. L’ensemble final répond aux classes restantes après modifications, sans permettre de reconstruire leur histoire de façon unique. Des degrés écrits ou programmes différents peuvent aboutir au même ensemble. Pour expliquer ou transférer fidèlement une notation, l’historique fait donc partie du sens voulu et n’est pas un simple détail de calcul.

Le rejet d’un ajout de degré existant est volontairement strict. Une autre interface pourrait remplacer ou autoriser des doublons, mais devrait le déclarer. Ici, le rejet révèle l’instruction ambiguë avant qu’un récepteur invente sa résolution. Le témoin ne prouve pas que la spécification impose notre erreur exacte ; il vérifie la règle supplémentaire promise par ce programme pédagogique.

Les tables intermédiaires évitent aussi de collecter toutes les hauteurs rencontrées au lieu de celles qui restent. Cette collecte annulerait la suppression en donnant un accord apparemment plus riche. Un relevé manuel suffit à révéler l’erreur. Avant une grammaire composable ou une explication d’agent, gardez fondamentale, famille, opérations ordonnées et texte original avec le résultat projeté. Analyse réelle, terminologie acceptée par des musiciens et réalisation utile à la guitare exigeraient chacune d’autres preuves que ce petit programme symbolique.

### Exercice 1

Partez de la table des degrés et appliquez l’ajout. Pourquoi garder la clé du degré composé ?

<details><summary>Réponse 1</summary>

Le degré ajouté conserve son écart tenant compte de l’octave. Sa classe pourra coïncider avec un autre degré ; projeter trop tôt effacerait l’identité de la modification.

</details>

### Exercice 2

Appliquez l’altération au degré existant. Ajoute-t-elle une copie du degré ?

<details><summary>Réponse 2</summary>

Non. Elle modifie l’écart du degré existant dans ce programme. Garder les écarts ancien et nouveau effectuerait une autre opération musicale.

</details>

### Exercice 3

Appliquez la suppression, puis calculez l’ensemble des classes de hauteur.

<details><summary>Réponse 3</summary>

La table et l’ensemble finaux figurent ci-dessus. Le degré supprimé est absent ; l’union de toutes les hauteurs intermédiaires le conserverait à tort.

</details>

### Exercice 4

Appliquez le témoin avec ajout au lieu d’altération. Pourquoi le rejeter ?

<details><summary>Réponse 4</summary>

Le degré cible existe déjà. La règle stricte rejette cette opération indexée au lieu de deviner un remplacement ou de produire silencieusement un autre accord.

</details>

### Exercice 5

Qu’est-ce qui réfute un export annoncé fidèle au programme ?

<details><summary>Réponse 5</summary>

Traiter les programmes principal et témoin comme une même opération valide perd la distinction. Conservez symbole original, famille et modifications avant d’annoncer une interprétation réussie.

</details>

## Travail avec consultation des sources

Exécutez les programmes à la main en conservant les tables intermédiaires. Comparez leur acceptation aux règles d’accord ciblées existantes. Proposez un transfert compact gardant opérations et provenance, avec la collision comme critère de réfutation avant une grammaire ou un agent.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
