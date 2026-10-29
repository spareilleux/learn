---
module_id: mcl-016-reconstruct-polyphonic-score-cursors
department: musicology
course: "Reconstruire les curseurs d’une partition polyphonique"
level: advanced
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Reconstruire les curseurs d’une partition polyphonique

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Une partition sérialisée peut décrire toute une voix avant de revenir au début pour la suivante. Additionner les durées comme une suite de sons transforme la simultanéité en succession. Un transfert de phrase [GA](https://github.com/GuitarAlchemist/ga) exige donc une interprétation du curseur avant la conversion de tempo. Nous reconstruisons les intervalles à partir d’une courte suite d’opérations.

## Lire les éléments conservés

La référence utilise retour et avance pour coordonner les voix et interdit au retour de franchir une mesure ou un changement de divisions. Le relevé conservé emploie déjà des intervalles absolus. Le cours explique une conversion possible, sans affirmer qu’un analyseur l’exécute.

[Prérequis](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/backup/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "measure_units": 4,
    "operations": [
      {
        "op": "note",
        "id": "a",
        "duration": 4
      },
      {
        "op": "backup",
        "duration": 4
      },
      {
        "op": "note",
        "id": "b",
        "duration": 2
      },
      {
        "op": "forward",
        "duration": 2
      }
    ]
  },
  "formula": "cursor=0; note records [cursor,cursor+duration) then advances; backup subtracts duration; forward adds duration; valid=all cursor states within [0,measure_units]",
  "expected": {
    "note_intervals": {
      "a": [
        0,
        4
      ],
      "b": [
        0,
        2
      ]
    },
    "cursor_states": [
      0,
      4,
      0,
      2,
      4
    ],
    "final_cursor": 4,
    "valid": true
  },
  "negative_control": {
    "values": {
      "measure_units": 4,
      "operations": [
        {
          "op": "note",
          "id": "a",
          "duration": 4
        },
        {
          "op": "backup",
          "duration": 2
        },
        {
          "op": "note",
          "id": "b",
          "duration": 2
        },
        {
          "op": "forward",
          "duration": 2
        }
      ]
    },
    "expected": {
      "note_intervals": {
        "a": [
          0,
          4
        ],
        "b": [
          2,
          4
        ]
      },
      "cursor_states": [
        0,
        4,
        2,
        4,
        6
      ],
      "final_cursor": 6,
      "valid": false
    }
  }
}
```

## Séparer parcours du document et temps musical

Le curseur de sérialisation sert à placer les événements pendant la lecture du document. Ce n’est pas forcément une horloge de lecture monotone. Le retour le démontre : le lecteur recule sans que la musique s’inverse. Convertir le curseur en intervalles absolus avant la lecture permet ensuite une chronologie monotone, sans perdre le placement des voix.

L’unité de division fixe doit accompagner chaque durée. Un changement de divisions en cours de mesure exigerait une autre conversion ; soustraire une ancienne durée d’un curseur exprimé dans la nouvelle unité serait incorrect. Les restrictions de la référence ont donc un sens musical et ne sont pas une simple validation de forme. Notre modèle évite ces changements pour rendre le calcul directement lisible.

Un curseur final correct ne garantit pas toute la partition. Une suite invalide pourrait finir au bon endroit après une excursion interdite ; des fins correctes ne préservent pas forcément voix et articulation. Le contrôle conserve donc chaque état et pas seulement le dernier. Le relevé manuel détecte déjà chevauchement modifié et dépassement du témoin. Un importateur futur devrait garder ces contre-exemples avant tempo, conduite des voix ou affectation à la guitare, qui dépendent tous d’une reconstruction exacte.

### Exercice 1

Parcourez la suite principale et relevez chaque état du curseur. Le retour est-il une durée musicale négative ?

<details><summary>Réponse 1</summary>

Les états figurent ci-dessus. Le retour repositionne le curseur de sérialisation ; il ne crée pas une note de durée sonore négative.

</details>

### Exercice 2

Déduisez les intervalles des notes. Sont-elles successives ou superposées ?

<details><summary>Réponse 2</summary>

Elles commencent ensemble et se superposent pendant la durée de la plus courte. L’ordre documentaire ne définit pas à lui seul l’ordre de lecture.

</details>

### Exercice 3

Que fait l’opération d’avance ?

<details><summary>Réponse 3</summary>

Elle déplace le curseur sans ajouter d’événement sonore dans cette suite construite. Distinguez le temps silencieux d’une nouvelle note et de la durée de la note précédente.

</details>

### Exercice 4

Appliquez le témoin au retour réduit. Où changent le placement et le respect des limites ?

<details><summary>Réponse 4</summary>

La voix suivante commence plus tard et le curseur final dépasse la mesure déclarée. Gardez ces faits plutôt que de borner artificiellement le curseur pour masquer l’entrée invalide.

</details>

### Exercice 5

Qu’est-ce qui réfute un export annoncé fidèle à la polyphonie ?

<details><summary>Réponse 5</summary>

Une liste qui joue les notes principales à la suite ou garde les mêmes débuts pour le témoin perd la chronologie requise. Un curseur hors limites invalide l’entrée avant planification.

</details>

## Travail avec consultation des sources

Reconstruisez les tables à la main avant les réponses. Comparez leurs intervalles absolus au relevé conservé. Proposez un transfert gardant les unités de division et les voix, avec le dépassement de mesure comme critère de réfutation avant tout analyseur ou DSL.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
