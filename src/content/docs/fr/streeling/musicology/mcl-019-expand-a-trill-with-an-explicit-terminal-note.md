---
title: Développer un trille avec une note finale explicite
description: Développer un trille avec une note finale explicite — Musicologie
sidebar:
  label: MCL-019 · Développer un trille avec une note finale explicite
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/fr/mcl-019-expand-a-trill-with-an-explicit-terminal-note.fr.md
---

:::note[Streeling University]
**MCL-019** · Développer un trille avec une note finale explicite · avancé · 45 minutes

Généré par le département *Musicologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/fr/mcl-019-expand-a-trill-with-an-explicit-terminal-note.fr.md) · [Mon journal](../../journal/)

Prérequis: [MCL-014](../../musicology/mcl-014-declare-where-grace-notes-take-their-time/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un exercice GA demande d’alterner des hauteurs pendant une durée fixe et de finir sur la principale, alors que son compte finit sur l’auxiliaire. Les deux hauteurs sont présentes, mais la contrainte finale échoue. Nous développons une politique finie de trille et vérifions sa terminaison. Elle dépasse l’attribution de temps autour d’une note principale étudiée en prérequis.

Déclarez départ, hauteur auxiliaire, nombre d’événements et durée avant de produire la suite. Avec des durées égales, chaque attaque est un multiple entier de la durée élémentaire et le dernier événement se termine à la frontière prévue. La hauteur finale dépend de la parité. Changer le compte à durée totale constante change donc espacement et terminaison, pas seulement une étiquette.

La référence MusicXML distingue note initiale, compte de lecture et tournure finale éventuelle. Ces champs motivent la conservation des distinctions, sans imposer notre espacement égal à une pratique historique. Une tournure finale ajouterait des événements exclus du modèle. Le témoin change seulement le compte et termine sur l’autre hauteur. Conservez tableaux de hauteurs et d’attaques si l’exercice impose une terminaison. Une alternance manuelle règle cette question avant de proposer un DSL d’ornements ou un moteur audio.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../musicology/mcl-014-declare-where-grace-notes-take-their-time/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/music-phrase-2026-10-22/melody-constraints.json)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/trill-mark/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "main_pitch": 60,
    "alternate_pitch": 62,
    "note_count": 6,
    "duration_s": 1.2
  },
  "formula": "pitch[i]=main if i%2==0 else alternate; onset[i]=i*duration/count for i=0..count-1; duration_each=duration/count; terminal=pitch[count-1]",
  "expected": {
    "pitches": [
      60,
      62,
      60,
      62,
      60,
      62
    ],
    "onsets_s": [
      0,
      0.2,
      0.4,
      0.6,
      0.8,
      1
    ],
    "duration_each_s": 0.2,
    "terminal_pitch": 62
  },
  "negative_control": {
    "values": {
      "main_pitch": 60,
      "alternate_pitch": 62,
      "note_count": 5,
      "duration_s": 1.2
    },
    "expected": {
      "pitches": [
        60,
        62,
        60,
        62,
        60
      ],
      "onsets_s": [
        0,
        0.24,
        0.48,
        0.72,
        0.96
      ],
      "duration_each_s": 0.24,
      "terminal_pitch": 60
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez un compte fini positif, un départ principal, des durées égales et aucune tournure finale. Hauteurs et support sont explicites. Aucune réalisation stylistique ni exécution musicale n’est établie.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Développez la suite en comptant aussi le premier événement.

<details><summary>Réponse 1</summary>

Elle commence sur la principale et alterne exactement pendant le nombre déclaré d’événements.

</details>

### Exercice 2

Dérivez les attaques et la durée élémentaire.

<details><summary>Réponse 2</summary>

Divisez le support par le compte puis utilisez les multiples successifs ; le dernier événement finit à la frontière.

</details>

### Exercice 3

Le cas principal finit-il sur la principale ?

<details><summary>Réponse 3</summary>

Non. Son compte pair et son départ principal donnent une terminaison auxiliaire.

</details>

### Exercice 4

Que change le témoin impair ?

<details><summary>Réponse 4</summary>

Il finit sur la principale avec des événements égaux plus longs et le même support total.

</details>

### Exercice 5

Qu’est-ce qui réfute la conservation de l’ornement ?

<details><summary>Réponse 5</summary>

Une terminaison, un compte ou un support différent rejette la propriété correspondante selon cette politique.

</details>

## Travail avec consultation des sources

Développez le trille à la main et vérifiez sa terminaison. Proposez un relevé séparant compte, départ et tournure finale éventuelle.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
