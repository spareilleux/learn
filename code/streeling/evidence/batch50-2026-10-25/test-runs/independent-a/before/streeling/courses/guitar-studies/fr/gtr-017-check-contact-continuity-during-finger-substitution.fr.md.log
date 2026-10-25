---
module_id: gtr-017-check-contact-continuity-during-finger-substitution
department: guitar-studies
course: "Vérifier la continuité du contact lors d’une substitution de doigt"
level: advanced
prerequisites: ["gtr-011-test-barre-coverage-before-calling-a-shape-playable"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Vérifier la continuité du contact lors d’une substitution de doigt

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Une note tenue peut garder sa corde et sa case alors que le doigt qui la maintient change. Un relevé des seules hauteurs masque l’arrivée éventuellement tardive du remplaçant. Pour une consigne [GA](https://github.com/GuitarAlchemist/ga), nous vérifions la chronologie des contacts avant de qualifier la substitution de continue. Une condition temporelle complète ainsi la géométrie statique.

## Lire les éléments conservés

Le relevé d’occupation conservé suit les événements musicaux sur les cordes, sans décrire chaque contact de doigt. Ses limites explicites invitent à conserver un relevé de contacts séparé. Ce relevé proposé reste pédagogique et ne modifie aucun schéma du projet.

[Prérequis](../../guitar-studies/en/gtr-011-test-barre-coverage-before-calling-a-shape-playable.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "required_interval_s": [
      0,
      1
    ],
    "contacts": [
      {
        "finger": "index",
        "interval_s": [
          0,
          0.6
        ]
      },
      {
        "finger": "ring",
        "interval_s": [
          0.5,
          1
        ]
      }
    ]
  },
  "formula": "merge half-open contact intervals at the same string/fret; gaps=required_interval minus union; overlap=max(0,min(ends)-max(starts)); continuous=(gaps empty)",
  "expected": {
    "union_s": [
      [
        0,
        1
      ]
    ],
    "gaps_s": [],
    "overlap_s": 0.1,
    "continuous": true
  },
  "negative_control": {
    "values": {
      "required_interval_s": [
        0,
        1
      ],
      "contacts": [
        {
          "finger": "index",
          "interval_s": [
            0,
            0.6
          ]
        },
        {
          "finger": "ring",
          "interval_s": [
            0.7,
            1
          ]
        }
      ]
    },
    "expected": {
      "union_s": [
        [
          0,
          0.6
        ],
        [
          0.7,
          1
        ]
      ],
      "gaps_s": [
        [
          0.6,
          0.7
        ]
      ],
      "overlap_s": 0,
      "continuous": false
    }
  }
}
```

## Traiter la substitution comme un relais de contact

L’événement musical et l’événement de doigt n’ont pas la même identité. Maintenir le premier ne garantit pas la continuité du second. Inversement, changer de doigt ne demande pas nécessairement une nouvelle attaque. La distinction compte lorsqu’une consigne libère un doigt pour l’accord suivant tout en maintenant la note actuelle. La chronologie doit expliquer le chevauchement, sans le déduire de la seule hauteur inchangée.

Les intervalles semi-ouverts rendent explicite le traitement des limites. Un remplacement au moment exact où le premier contact finit n’aurait pas de trou dans le modèle, mais aucune marge de chevauchement positive. Sa fiabilité pour le joueur est une autre question. L’incertitude temporelle peut transformer ce relais exact en trou ; un travail réel conserverait des temps estimés ou une marge voulue, sans présenter le calendrier idéal comme une technique mesurée.

L’union ignore les autres sollicitations des doigts. Un doigt peut devoir quitter une autre position avant d’assurer le contact prévu ; une position peut aussi friser malgré une couverture nominale continue. Ces contraintes absentes limitent le résultat à une condition nécessaire de planification. Le relevé manuel suffit à rejeter le témoin retardé. Après ce contrôle seulement, un planificateur proposé pourrait combiner disponibilité, portée et tenue propre observée ; aucun planificateur ni jeu réel n’est livré ici.

### Exercice 1

Qu’est-ce qui reste fixe et qu’est-ce qui change dans le relevé principal ?

<details><summary>Réponse 1</summary>

La corde, la case et l’intervalle de tenue prévus restent fixes ; l’identité du doigt change. Une liste de hauteurs ne possède pas de champ décrivant ce relais.

</details>

### Exercice 2

Fusionnez les intervalles de contact. Chaque instant requis est-il couvert ?

<details><summary>Réponse 2</summary>

L’union principale couvre l’intervalle semi-ouvert requis. Le chevauchement représente des contacts simultanés pendant la substitution, sans nouvelle attaque musicale.

</details>

### Exercice 3

Calculez le chevauchement. Garantit-il un son propre ?

<details><summary>Réponse 3</summary>

Sa durée figure ci-dessous. Elle établit seulement une coexistence planifiée des contacts ; ni leur pression ni leur qualité ne sont données ou mesurées.

</details>

### Exercice 4

Appliquez le témoin retardé et localisez l’intervalle découvert.

<details><summary>Réponse 4</summary>

Le trou affiché rompt la continuité malgré des hauteurs inchangées. Un contrôle des seules notes cibles ne détecte pas cet échec.

</details>

### Exercice 5

Qu’est-ce qui réfute un plan de contact annoncé continu ?

<details><summary>Réponse 5</summary>

Toute portion découverte de l’intervalle requis réfute le plan. Une frise ou une interruption observée pourrait aussi réfuter la réussite physique malgré le respect de cette condition nécessaire.

</details>

## Travail avec consultation des sources

Dessinez les chronologies avant de consulter les réponses. Comparez occupation musicale et contact des doigts, puis proposez le relevé supplémentaire minimal. Conservez le témoin avec trou et distinguez un défaut du plan d’un échec d’exécution ; aucun essai de jeu n’a eu lieu.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
