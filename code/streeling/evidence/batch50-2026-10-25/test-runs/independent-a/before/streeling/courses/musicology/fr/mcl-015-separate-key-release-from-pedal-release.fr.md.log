---
module_id: mcl-015-separate-key-release-from-pedal-release
department: musicology
course: "Distinguer le relâchement de la touche de celui de la pédale"
level: advanced
prerequisites: ["mcl-012-merge-ties-without-merging-slurs"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer le relâchement de la touche de celui de la pédale

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un accompagnement peut maintenir une note sous pédale après le relâchement de sa touche. Assimiler celui-ci à la fin immédiate du son raccourcit la tenue prévue ; prolonger toutes les notes suivantes l’allonge trop. Pour un transfert d’accompagnement [GA](https://github.com/GuitarAlchemist/ga), nous suivons la commande de relâchement et laissons la décroissance acoustique hors du modèle.

## Lire les éléments conservés

La référence de lecture distingue le réglage de pédale forte d’un événement de note. Le relevé temporel conservé comporte des fins explicites, sans règle de pédale. Notre règle est une extension pédagogique proposée, sans modification d’importateur ni comportement de piano attribué au moteur de guitare.

[Prérequis](../../musicology/en/mcl-012-merge-ties-without-merging-slurs.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/sound/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "notes": [
      {
        "id": "a",
        "on": 0,
        "key_off": 0.5
      },
      {
        "id": "b",
        "on": 1,
        "key_off": 1.5
      }
    ],
    "pedal_down": 0.25,
    "pedal_up": 2
  },
  "formula": "release_i=pedal_up if pedal_down<=key_off_i<pedal_up else key_off_i; scheduled_hold_i=release_i-on_i",
  "expected": {
    "release_times": [
      2,
      2
    ],
    "scheduled_holds": [
      2,
      1
    ]
  },
  "negative_control": {
    "values": {
      "notes": [
        {
          "id": "a",
          "on": 0,
          "key_off": 0.5
        },
        {
          "id": "b",
          "on": 1,
          "key_off": 1.5
        }
      ],
      "pedal_down": 0.25,
      "pedal_up": 0.75
    },
    "expected": {
      "release_times": [
        0.75,
        1.5
      ],
      "scheduled_holds": [
        0.75,
        0.5
      ]
    }
  }
}
```

## Préciser la limite réellement commandée

Les fins conservées décrivent des intervalles de notes construits, sans mesurer le silence. Ajouter l’état de pédale crée un autre niveau de planification. Le relâchement de touche marque la fin de son action ; la règle choisit ensuite quand la pédale permet la libération. L’enveloppe acoustique ultérieure est encore un autre processus. Un transfert fiable nomme ces limites plutôt que de tout ranger dans une durée ambiguë.

Le cours exclut volontairement les événements simultanés et les répétitions de même hauteur. Ces cas importent dans un planificateur complet. Une pédale changeant au moment d’un relâchement exige un ordre ; une hauteur répétée exige des identités pour éviter qu’une fin coupe un autre événement. Ici, temps distincts et identifiants rendent ces données inutiles au petit calcul, sans prouver que l’implémentation future gère les exclusions.

Il ne faut pas non plus transférer silencieusement la métaphore de la pédale à la guitare physique. Relâchement, étouffement et résonance des cordes suivent d’autres mécanismes. Leur point commun utile est la conservation d’une action explicite. Une chronologie suffit à montrer la perte due à l’omission de pédale. Avant d’étendre cela en DSL multi-instrument, comparez le relevé proposé à la chronologie et listez les sémantiques supplémentaires réellement nécessaires à chaque instrument.

### Exercice 1

Repérez les événements de relâchement des notes principales. Touche relâchée et relâchement planifié coïncident-ils ?

<details><summary>Réponse 1</summary>

Ils diffèrent dans le cas principal. Les touches sont relâchées pendant que la pédale est abaissée ; la règle reporte donc leurs commandes jusqu’au relevage.

</details>

### Exercice 2

Calculez les instants de relâchement et les durées de tenue planifiée.

<details><summary>Réponse 2</summary>

Les tableaux figurent ci-dessous. Soustrayez chaque début de son relâchement ; ne prenez pas le premier début pour toutes les notes et ne remplacez pas leur identité par la hauteur.

</details>

### Exercice 3

Un relâchement planifié signifie-t-il une forme d’onde nulle à cet instant ?

<details><summary>Réponse 3</summary>

Non. C’est une limite de commande. Une enveloppe ou un instrument physique peut continuer à décroître ; aucune traîne n’a été fournie ou mesurée.

</details>

### Exercice 4

Appliquez le témoin au relevage anticipé. Pourquoi la note tardive n’est-elle pas prolongée ?

<details><summary>Réponse 4</summary>

Sa touche est relâchée après le relevage. La première note reste prolongée jusqu’à cette limite antérieure ; la suivante garde son propre relâchement de touche.

</details>

### Exercice 5

Qu’est-ce qui réfute un export annoncé fidèle au calendrier de relâchement ?

<details><summary>Réponse 5</summary>

Omettre l’intervalle de pédale ou donner les mêmes tableaux aux cas principal et témoin efface la distinction requise. La fidélité acoustique demande une autre observation.

</details>

## Travail avec consultation des sources

Dessinez les états des notes et de la pédale à la main. Examinez le sens des fins conservées, puis proposez un relevé de commandes distinct. Utilisez le témoin contre un export avant toute automatisation ; la décroissance réelle et la tenue à la guitare restent non évaluées.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
