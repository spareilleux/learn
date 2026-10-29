---
title: Déduire les attaques d’un accord d’un balayage
description: Déduire les attaques d’un accord d’un balayage — Études de guitare
sidebar:
  label: GTR-020 · Déduire les attaques d’un accord d’un balayage
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-020-derive-strum-onsets-from-a-sweep.fr.md
---

:::note[Streeling University]
**GTR-020** · Déduire les attaques d’un accord d’un balayage · avancé · 45 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-020-derive-strum-onsets-from-a-sweep.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-010](../../guitar-studies/gtr-010-separate-muting-from-releasing-a-fretted-note/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un accord contient plusieurs notes, mais le médiator atteint leurs cordes à des instants différents. Un exercice GA peut conserver les hauteurs tout en perdant le balayage demandé s’il programme tout simultanément. Nous convertissons un déplacement déclaré en instants d’attaque. Le trajet à travers les cordes étouffées reste conservé, au lieu de comprimer la liste des cordes sonores.

Prenez une vitesse constante et une origine à la corde extrême dans le sens choisi. Calculez chaque instant par distance divisée par vitesse, puis gardez seulement les événements des cordes sonores. Étouffer supprime un événement de hauteur, pas une coordonnée de l’instrument. Reconstruire un espacement égal à partir de la liste réduite raccourcirait discrètement le trajet.

Le témoin inverse parcourt la même géométrie et conserve l’étalement total, mais la note intérieure arrive à un autre instant relatif. Un relevé limité à cet étalement perd donc ordre et espacement des attaques. Conservez la liste ordonnée si l’exercice en dépend. Le support d’occupation distingue son et technique sans mesurer ce mouvement. Contact du médiator, déformation, espacement réel et réponse acoustique peuvent déplacer les attaques observées. Notre carte fournit une référence manuelle pour un transfert d’articulation proposé, sans démontrer lecture synchronisée, enregistrement ou exécution réelle.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-studies/gtr-010-separate-muting-from-releasing-a-fretted-note/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "positions_mm": [
      0,
      10,
      20,
      30,
      40,
      50
    ],
    "sounding_indices": [
      0,
      2,
      5
    ],
    "speed_mm_s": 1000,
    "direction": 1
  },
  "formula": "origin=min(positions) if direction=1 else max(positions); t[i]=abs(position[i]-origin)/speed; events=sort((t[i],i) for sounding i); spread=max(t)-min(t)",
  "expected": {
    "events_time_s_and_index": [
      [
        0,
        0
      ],
      [
        0.02,
        2
      ],
      [
        0.05,
        5
      ]
    ],
    "spread_s": 0.05
  },
  "negative_control": {
    "values": {
      "positions_mm": [
        0,
        10,
        20,
        30,
        40,
        50
      ],
      "sounding_indices": [
        0,
        2,
        5
      ],
      "speed_mm_s": 1000,
      "direction": -1
    },
    "expected": {
      "events_time_s_and_index": [
        [
          0,
          5
        ],
        [
          0.03,
          2
        ],
        [
          0.05,
          0
        ]
      ],
      "spread_s": 0.05
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez des cordes parallèles fixes, une vitesse constante positive et une excitation instantanée à chaque croisement. Les cordes étouffées n’ont pas d’événement de hauteur. Souplesse du médiator et latence acoustique restent non mesurées.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Calculez les attaques dans le sens principal.

<details><summary>Réponse 1</summary>

Utilisez les coordonnées initiales et la vitesse ; les cordes étouffées contribuent encore à la distance.

</details>

### Exercice 2

Pourquoi garder une corde étouffée dans la géométrie ?

<details><summary>Réponse 2</summary>

Elle supprime une excitation sans rapprocher les autres cordes.

</details>

### Exercice 3

Que conserve l’inversion du balayage ?

<details><summary>Réponse 3</summary>

Elle conserve la durée entre extrêmes et l’étalement total dans cette convention d’origine.

</details>

### Exercice 4

Que change le témoin inversé ?

<details><summary>Réponse 4</summary>

Il inverse l’ordre et modifie le retard de l’événement intérieur par rapport à la première attaque.

</details>

### Exercice 5

Qu’est-ce qui réfute un transfert fondé sur le seul étalement ?

<details><summary>Réponse 5</summary>

Le témoin conserve l’étalement mais change les attaques ordonnées ; ce seul scalaire ne reconstruit donc pas l’articulation.

</details>

## Travail avec consultation des sources

Dessinez toutes les cordes, y compris étouffées, avant de calculer les événements ordonnés. Comparez les sens dans un relevé GA proposé.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
