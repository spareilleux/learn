---
module_id: gaa-014-hold-out-whole-transposition-families
department: guitar-alchemist-academy
course: "Réserver des familles entières de transpositions pour l’évaluation"
level: advanced
prerequisites: ["gaa-009-test-transposition-beyond-a-memorized-fret-pattern"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Réserver des familles entières de transpositions pour l’évaluation

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un test peut contenir des identifiants inédits tout en reprenant, transposé, un motif déjà travaillé. [GA](https://github.com/GuitarAlchemist/ga) doit préciser ce qui est réservé avant d’interpréter un score comme un transfert. Nous définissons une clé de famille à partir des intervalles ordonnés et vérifions la séparation. Le résultat décrit l’exposition aux motifs ; l’apprentissage réel reste une question empirique.

## Lire les éléments conservés

La lecture sur la validation par groupes explique pourquoi des observations dépendantes ne devraient pas traverser la séparation entraînement-évaluation. Les groupes sont ici des familles construites. Le relevé conservé distingue déjà les indices permis, sans tentative réelle sur ces nouveaux exercices.

[Prérequis](../../guitar-alchemist-academy/en/gaa-009-test-transposition-beyond-a-memorized-fret-pattern.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://scikit-learn.org/stable/modules/cross_validation.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "train": [
      {
        "id": "a",
        "notes": [
          60,
          64,
          67
        ]
      },
      {
        "id": "b",
        "notes": [
          60,
          63,
          67
        ]
      }
    ],
    "test": [
      {
        "id": "c",
        "notes": [
          62,
          66,
          69
        ]
      },
      {
        "id": "d",
        "notes": [
          62,
          67,
          69
        ]
      }
    ]
  },
  "formula": "family(notes)=tuple(note-note[0]); overlap=sorted(set(train families) intersect set(test families)); family_disjoint=(overlap empty)",
  "expected": {
    "overlap": [
      [
        0,
        4,
        7
      ]
    ],
    "family_disjoint": false,
    "distinct_item_ids": 4
  },
  "negative_control": {
    "values": {
      "train": [
        {
          "id": "a",
          "notes": [
            60,
            64,
            67
          ]
        },
        {
          "id": "b",
          "notes": [
            60,
            63,
            67
          ]
        }
      ],
      "test": [
        {
          "id": "d",
          "notes": [
            62,
            67,
            69
          ]
        },
        {
          "id": "e",
          "notes": [
            65,
            70,
            72
          ]
        }
      ]
    },
    "expected": {
      "overlap": [],
      "family_disjoint": true,
      "distinct_item_ids": 4
    }
  }
}
```

## Définir l’exposition au niveau exigé par l’évaluation

Clé d’exercice et clé de famille servent des besoins différents. La première distingue une consigne ou un fichier précis ; la seconde regroupe du matériel selon la transformation choisie. Aucune n’est l’unité correcte pour toute évaluation. L’affirmation d’apprentissage détermine quelle familiarité rendrait le test trop facile, et la règle doit précéder l’examen du score.

La règle choisie garde l’ordre et les écarts à la première note. Elle regroupe les transpositions exactes, mais pas les renversements, variantes rythmiques ou déplacements d’octave isolés, sauf si les écarts ordonnés coïncident aussi. Une séparation réussie ne valide que cette définition. Élargir la règle après les réponses changerait le matériel considéré comme réservé et exigerait un nouveau rapport.

Le témoin contient des exercices apparentés dans la partie d’évaluation, ce qu’autorise la règle étroite entre partitions. Leurs réponses futures ne deviennent pas pour autant indépendantes. Un bilan pourrait nécessiter une agrégation par famille ou un modèle de dépendance. Distinguez donc prévention des fuites d’exposition et estimation de l’incertitude. Une table directe des notes, clés et appartenances suffit à vérifier la frontière actuelle. Un générateur doit la conserver au lieu de traiter des identifiants nouveaux comme preuve de nouveauté.

### Exercice 1

Calculez une clé pour chaque exercice principal. Quelle information d’ordre conserve-t-elle ?

<details><summary>Réponse 1</summary>

Soustrayez la première hauteur de toutes les hauteurs, dans leur ordre. La clé conserve les écarts dirigés et le registre, au lieu d’un ensemble non ordonné de classes de hauteur.

</details>

### Exercice 2

Croisez les clés des parties d’entraînement et d’évaluation. Des identifiants uniques suffisent-ils ?

<details><summary>Réponse 2</summary>

Le recoupement affiché réfute la séparation des familles. Chaque identifiant peut être unique alors que des motifs apparentés restent présents des deux côtés.

</details>

### Exercice 3

Le recoupement prouve-t-il une tricherie ou une absence d’apprentissage ?

<details><summary>Réponse 3</summary>

Non. Il décrit le protocole et limite l’interprétation en termes de transfert. Il n’apporte ni réponse réelle, ni intention, ni évolution de compétence.

</details>

### Exercice 4

Appliquez le témoin. Quel défaut est corrigé et que reste-t-il à vérifier ?

<details><summary>Réponse 4</summary>

Le recoupement des familles choisies disparaît. Le timbre, le rythme, l’exposition aux sources et la difficulté peuvent encore relier les conditions ou fournir d’autres indices.

</details>

### Exercice 5

Qu’est-ce qui réfute une séparation annoncée entre familles ?

<details><summary>Réponse 5</summary>

Une clé conservée dans les deux parties constitue un contre-exemple. Gardez les notes originales et la règle de regroupement pour permettre sa remise en question.

</details>

## Travail avec consultation des sources

Construisez la table des familles à la main avant toute assistance. Vérifiez les partitions et les règles d’indices du relevé, puis proposez un manifeste d’exercices. Nommez le contre-exemple et une dépendance non résolue avant de recommander une génération automatique de quiz.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
