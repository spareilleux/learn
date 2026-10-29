---
title: Intégrer une rampe de tempo dans le repère des temps musicaux
description: Intégrer une rampe de tempo dans le repère des temps musicaux — Musicologie
sidebar:
  label: MCL-017 · Intégrer une rampe de tempo dans le repère des temps musicaux
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/fr/mcl-017-integrate-a-tempo-ramp-in-beat-coordinates.fr.md
---

:::note[Streeling University]
**MCL-017** · Intégrer une rampe de tempo dans le repère des temps musicaux · avancé · 60 minutes

Généré par le département *Musicologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/fr/mcl-017-integrate-a-tempo-ramp-in-beat-coordinates.fr.md) · [Mon journal](../../journal/)

Prérequis: [MCL-007](../../musicology/mcl-007-integrate-a-midi-tempo-map-before-scheduling/)
:::

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Une accélération dite linéaire reste incomplète sans variable indépendante. Un tempo linéaire selon la position musicale n’est généralement pas linéaire selon le temps écoulé. Pour une rampe d’exercice [GA](https://github.com/GuitarAlchemist/ga) proposée, nous intégrons les secondes par temps et comparons le résultat à la moyenne des tempos extrêmes. Le cours étend la carte par paliers avec un modèle continu distinct.

## Lire les éléments conservés

La référence définit le tempo en noires par minute, sans fixer notre interpolation continue. Le relevé de phrase conserve un tempo constant ; appliquer cette rampe serait une nouvelle proposition nécessitant des limites d’événements explicites.

[Prérequis](../../musicology/mcl-007-integrate-a-midi-tempo-map-before-scheduling/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/sound/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "start_bpm": 60,
    "end_bpm": 120,
    "quarter_beats": 4
  },
  "formula": "slope=(B1-B0)/Q; duration=60*log(B1/B0)/slope if slope!=0 else 60*Q/B0; endpoint_average_duration=60*Q/((B0+B1)/2)",
  "expected": {
    "slope_bpm_per_quarter": 15,
    "duration_s": 2.772588722239781,
    "endpoint_average_duration_s": 2.6666666666666665
  },
  "negative_control": {
    "values": {
      "start_bpm": 60,
      "end_bpm": 60,
      "quarter_beats": 4
    },
    "expected": {
      "slope_bpm_per_quarter": 0,
      "duration_s": 4,
      "endpoint_average_duration_s": 4
    }
  }
}
```

## Inclure le repère d’interpolation dans la proposition

Des tempos aux extrémités ne définissent pas le trajet intermédiaire. Un éditeur peut interpoler le tempo selon les secondes, un autre selon les temps musicaux, un autre la durée par temps. Tous peuvent respecter les extrémités tout en déplaçant les notes internes. Le relevé proposé doit nommer grandeur et repère interpolés, au lieu de conserver seulement les valeurs extrêmes et le mot linéaire.

Dans ce modèle musical, chaque petit intervalle contribue au temps écoulé selon l’inverse du tempo local. Les portions lentes prennent plus de secondes par temps que les rapides. Cette asymétrie explique l’échec général du raccourci moyen. L’intégrale exacte sert de référence à une approximation numérique future, sans prouver qu’un planificateur atteint réellement ces horodatages.

Le témoin constant est important car la singularité apparente est supprimable. Une spécification peut énoncer la limite au lieu d’imposer une formule non constante avec division indéfinie. Près de cette limite, une implémentation demanderait une évaluation stable, ce qui relève d’un autre travail de code. La déduction directe suffit à rejeter le raccourci. Le projet ne devrait envisager un nœud DSL ou un agent créant des phrases accélérées qu’après conservation des positions, du repère et de la branche constante.

### Exercice 1

Déduisez la pente sur l’étendue musicale déclarée. Quel repère utilise-t-elle ?

<details><summary>Réponse 1</summary>

La pente affichée est rapportée à la position en noires. La réutiliser comme variation par seconde définirait une autre trajectoire et généralement une autre durée.

</details>

### Exercice 2

Déduisez le temps écoulé en intégrant les secondes par temps. Pourquoi un logarithme apparaît-il ?

<details><summary>Réponse 2</summary>

Les secondes par temps sont l’inverse du tempo linéaire, avec conversion des minutes. Leur intégrale est logarithmique et donne la durée affichée pour cette rampe positive.

</details>

### Exercice 3

Comparez la moyenne des tempos extrêmes au résultat intégré.

<details><summary>Réponse 3</summary>

Le raccourci sous-estime la durée construite. Inverser la moyenne des tempos n’équivaut pas à moyenner leur inverse le long de l’intervalle musical.

</details>

### Exercice 4

Appliquez le témoin constant. Pourquoi éviter une division par une pente nulle ?

<details><summary>Réponse 4</summary>

La branche constante donne la durée indiquée et rejoint le raccourci. L’expression non constante serait indéfinie, bien que sa limite physique soit finie.

</details>

### Exercice 5

Qu’est-ce qui réfute une conversion annoncée linéaire selon la position musicale ?

<details><summary>Réponse 5</summary>

Un instant final incompatible avec la durée intégrée réfute cette conversion. Une rampe déclarée linéaire en secondes doit être jugée selon sa propre équation.

</details>

## Travail avec consultation des sources

Déduisez l’intégrale et la limite constante à la main, puis comparez-les à l’horloge fixe du relevé. Proposez un enregistrement nommant repère et interpolation. Utilisez l’écart du raccourci comme critère de réfutation avant de recommander une abstraction de planification.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
