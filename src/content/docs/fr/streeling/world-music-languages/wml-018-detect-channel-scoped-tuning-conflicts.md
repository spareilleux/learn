---
title: Détecter les conflits d’accordage à l’échelle du canal
description: Détecter les conflits d’accordage à l’échelle du canal — Musiques et langues du monde
sidebar:
  label: WML-018 · Détecter les conflits d’accordage à l’échelle du canal
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-018-detect-channel-scoped-tuning-conflicts.fr.md
---

:::note[Streeling University]
**WML-018** · Détecter les conflits d’accordage à l’échelle du canal · avancé · 45 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-018-detect-channel-scoped-tuning-conflicts.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-004](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un transfert conserve les décalages en cents mais envoie des notes simultanées sur un canal de variation de hauteur commun. Chaque valeur peut être correcte et leur réalisation incompatible. Nous encodons une conversion déclarée et vérifions la concurrence à la frontière du canal. L’opération dépasse la conservation d’un rapport : elle examine si la portée du transport peut porter les demandes simultanées.

Le résumé officiel décrit le message de variation par canal, l’ordre des octets et la sensibilité du récepteur. Déclarez cette sensibilité avant de convertir les cents en entier. Gardez octets faible puis fort dans l’ordre prévu ; les inverser change la valeur. Notre arrondi symétrique est construit et évite les extrémités où une implémentation complète exigerait une politique de plage.

Le canal possède ici un seul réglage à un instant donné. Des notes superposées demandant des valeurs différentes sur ce canal sont donc en conflit. Le témoin à canaux distincts garde décalages et octets, tout en supprimant la collision d’état partagé. Il ne certifie ni indépendance réelle des canaux ni réglage du récepteur. Le support semi-ouvert précise les frontières ; les queues de relâchement sont exclues. Une table manuelle suffit avant un allocateur ou un DSL d’accordage. Aucun message n’a été envoyé et aucune intonation culturelle ou jouée n’est revendiquée.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lecture primaire](https://midi.org/summary-of-midi-1-0-messages)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "sensitivity_cents": 200,
    "notes": [
      {
        "id": "A",
        "channel": 0,
        "start": 0,
        "end": 1,
        "offset_cents": 0
      },
      {
        "id": "B",
        "channel": 0,
        "start": 0,
        "end": 1,
        "offset_cents": 25
      }
    ]
  },
  "formula": "bend=8192+floor(8192*cents/sensitivity+0.5); LSB=bend%128; MSB=bend//128; conflict iff same channel and max(starts)<min(ends) and unequal bend; note support is half-open",
  "expected": {
    "bend_values": [
      8192,
      9216
    ],
    "lsb_msb": [
      [
        0,
        64
      ],
      [
        0,
        72
      ]
    ],
    "conflict_pairs": [
      [
        "A",
        "B"
      ]
    ]
  },
  "negative_control": {
    "values": {
      "sensitivity_cents": 200,
      "notes": [
        {
          "id": "A",
          "channel": 0,
          "start": 0,
          "end": 1,
          "offset_cents": 0
        },
        {
          "id": "B",
          "channel": 1,
          "start": 0,
          "end": 1,
          "offset_cents": 25
        }
      ]
    },
    "expected": {
      "bend_values": [
        8192,
        9216
      ],
      "lsb_msb": [
        [
          0,
          64
        ],
        [
          0,
          72
        ]
      ],
      "conflict_pairs": []
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez la sensibilité déclarée, des valeurs encodées intérieures et des réglages identiques du récepteur. Les supports sont semi-ouverts ; les queues sont exclues. Des canaux distincts suppriment le conflit modélisé sans certifier leur indépendance réelle.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Encodez les décalages avec la sensibilité déclarée.

<details><summary>Réponse 1</summary>

Les entiers affichés conservent le centre neutre et le décalage positif selon cette conversion.

</details>

### Exercice 2

Séparez chaque entier en octets ordonnés.

<details><summary>Réponse 2</summary>

L’octet faible porte le reste et l’octet fort le quotient entier dans la base déclarée, comme affiché.

</details>

### Exercice 3

Pourquoi les notes principales sont-elles en conflit ?

<details><summary>Réponse 3</summary>

Leurs supports semi-ouverts se superposent sur un canal avec des valeurs de variation différentes.

</details>

### Exercice 4

Que démontre le témoin à canaux distincts ?

<details><summary>Réponse 4</summary>

Il supprime ce conflit de portée sans changer valeurs ou octets ; la configuration du récepteur reste non testée.

</details>

### Exercice 5

Qu’est-ce qui réfute la réalisation sur canal partagé ?

<details><summary>Réponse 5</summary>

Des demandes simultanées de variations différentes sur un canal conventionnel rejettent leur réalisation indépendante selon le modèle.

</details>

## Travail avec consultation des sources

Construisez la table sans aide, puis rédigez une note GA avec sensibilité et ordre des octets. Laissez récepteur et allocation des canaux ouverts.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
