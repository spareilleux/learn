---
module_id: mcl-020-reset-an-accidental-state-at-the-bar-boundary
department: musicology
course: "Réinitialiser l’état des altérations à la barre de mesure"
level: advanced
prerequisites: ["mcl-005-preserve-written-and-sounding-pitch"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Réinitialiser l’état des altérations à la barre de mesure

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un générateur lit un bécarre, le conserve dans la mesure puis le prolonge par erreur après la barre suivante. La lettre reste identique, mais l’altération voulue change. Nous construisons une politique étroite d’état notationnel pour préciser l’effet de la réinitialisation. Elle concerne la portée de l’état, au-delà de la distinction entre hauteur écrite et entendue.

Dans cet exercice, une instruction explicite remplace l’armure pour cette lettre et cette octave dans la mesure courante. Une instruction absente consulte ce remplacement puis l’armure. L’autre octave reste indépendante. À la mesure suivante, les remplacements sont effacés avant de résoudre l’événement. C’est une politique stipulée, pas une règle universelle de gravure. Liaisons prolongées et portées croisées sont exclues.

Le témoin désactive seulement l’effacement. Les événements antérieurs restent identiques et le premier événement concerné de la nouvelle mesure révèle la fuite. La barre devient ainsi un critère de réfutation concret. L’élément accidental de MusicXML décrit le symbole affiché ; alter précise la hauteur. Le destinataire ne doit pas appliquer ce raccourci aux hauteurs explicites ni ajouter une altération depuis un signe de précaution. Une table manuelle indique les contextes à conserver. Aucun analyseur, rendu de partition ou avis de musicien n’a été observé.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../musicology/en/mcl-005-preserve-written-and-sounding-pitch.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/pitch-context-2026-10-22/transposition-arithmetic.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/accidental/)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/alter/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "key_F_alter": 1,
    "reset_at_bar": true,
    "events": [
      {
        "measure": 1,
        "octave": 4,
        "explicit_alter": 0
      },
      {
        "measure": 1,
        "octave": 4,
        "explicit_alter": null
      },
      {
        "measure": 1,
        "octave": 5,
        "explicit_alter": null
      },
      {
        "measure": 2,
        "octave": 4,
        "explicit_alter": null
      }
    ]
  },
  "formula": "state keyed by letter and octave; clear overrides at each new measure iff reset_at_bar; explicit_alter updates state; missing alter uses override else key; F4_base=65; F5_base=77; pitch=base+effective_alter",
  "expected": {
    "effective_alters": [
      0,
      0,
      1,
      1
    ],
    "pitches": [
      65,
      65,
      78,
      66
    ]
  },
  "negative_control": {
    "values": {
      "key_F_alter": 1,
      "reset_at_bar": false,
      "events": [
        {
          "measure": 1,
          "octave": 4,
          "explicit_alter": 0
        },
        {
          "measure": 1,
          "octave": 4,
          "explicit_alter": null
        },
        {
          "measure": 1,
          "octave": 5,
          "explicit_alter": null
        },
        {
          "measure": 2,
          "octave": 4,
          "explicit_alter": null
        }
      ]
    },
    "expected": {
      "effective_alters": [
        0,
        0,
        1,
        0
      ],
      "pitches": [
        65,
        65,
        78,
        65
      ]
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez seulement la lettre fournie, des remplacements propres à l’octave et aucune liaison entre mesures. Les champs pédagogiques ne sont pas du MusicXML brut. La hauteur encodée explicite commande le décodage indépendamment du symbole affiché.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Résolvez l’instruction explicite et sa continuation dans la même octave.

<details><summary>Réponse 1</summary>

Les événements utilisent le bécarre explicite dans la mesure selon la politique déclarée.

</details>

### Exercice 2

Pourquoi l’autre octave conserve-t-elle l’armure ?

<details><summary>Réponse 2</summary>

Les remplacements dépendent de la lettre et de l’octave ; celui d’une autre octave ne correspond pas.

</details>

### Exercice 3

Résolvez le premier événement après la barre.

<details><summary>Réponse 3</summary>

Effacez le remplacement précédent puis utilisez l’armure, sans nouvelle instruction explicite.

</details>

### Exercice 4

Où le témoin sans réinitialisation diffère-t-il ?

<details><summary>Réponse 4</summary>

À la nouvelle mesure, où il conserve le bécarre précédent contrairement à la politique voulue.

</details>

### Exercice 5

L’état du symbole peut-il remplacer la hauteur MusicXML explicite ?

<details><summary>Réponse 5</summary>

Non. Symbole et hauteur encodée sont distincts ; le raccourci ne doit pas écraser l’information explicite.

</details>

## Travail avec consultation des sources

Préparez la trace et repérez le premier événement contaminé. Gardez une colonne de hauteur explicite avant de proposer un changement GA.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
