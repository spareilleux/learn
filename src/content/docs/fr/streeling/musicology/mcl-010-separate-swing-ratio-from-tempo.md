---
title: Distinguer le rapport de swing du tempo
description: Distinguer le rapport de swing du tempo — Musicologie
sidebar:
  label: MCL-010 · Distinguer le rapport de swing du tempo
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/fr/mcl-010-separate-swing-ratio-from-tempo.fr.md
---

:::note[Streeling University]
**MCL-010** · Distinguer le rapport de swing du tempo · intermédiaire · 45 minutes

Généré par le département *Musicologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/fr/mcl-010-separate-swing-ratio-from-tempo.fr.md) · [Mon journal](../../journal/)

Prérequis: [MCL-004](../../musicology/mcl-004-model-timing-without-inventing-a-style/), [MCL-006](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/)
:::

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un agent change un rapport de swing en ralentissant toute la phrase. Il modifie alors la durée totale du temps, alors que la demande concernait sa répartition interne. Nous séparons les commandes dans un modèle construit de deux notes. Ce modèle ne définit aucun genre et ne prédit aucun choix réel d'interprète.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: mcl-004-model-timing-without-inventing-a-style](../../musicology/mcl-004-model-timing-without-inventing-a-style/)

[Prérequis: mcl-006-preserve-meter-grouping-and-tempo-units](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/)

[Artefact du projet conservé](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/)

[Paquet de données construites](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)

[Référence primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/swing/)

## 1. Exercice 1

Stipulons 120 noires par minute et deux événements nominaux par noire. Le temps dure .5 seconde. Le rapport 2:1 attribue deux parts au premier événement et une au second. Le dénominateur de répartition est la somme des parts.

Quelle est la durée du temps et combien de parts contient-il ?

> **Réponse.** Il dure .5 seconde et contient 3 parts de rapport.

## 2. Exercice 2

Les durées sont `(.5)*2/3=1/3` et `(.5)*1/3=1/6` seconde. Leur somme reste .5 : c'est le contrôle de conservation du temps. Arrondir chaque durée avant d'accumuler plusieurs temps peut ajouter une erreur ; conservez les fractions exactes pour vérifier l'exemple.

Calculez les durées et leur somme.

> **Réponse.** Elles valent `1/3` et `1/6` seconde, pour une somme de `.5` seconde.

## 3. Exercice 3

Gardons le tempo mais passons au rapport 1:1. Les deux événements durent .25 seconde. Le temps total ne change pas, mais la frontière interne bouge. Cela distingue redistribution et ralentissement. Inversement, un changement global de tempo redimensionne les deux durées sans changer leur rapport dans ce modèle.

Quelle quantité change entre les rapports au même tempo ?

> **Réponse.** La division interne change ; la durée totale reste .5 seconde.

## 4. Exercice 4

Comme témoin négatif, ralentissons le rythme égal à 60 noires par minute. Les événements durent chacun .5 seconde, pour 1 seconde au total. Ni durées ni somme ne correspondent au cas 2:1 initial. Une impression de ralentissement ne réalise pas un changement de rapport à tempo fixe.

Le rythme égal ralenti reproduit-il la paire originale ?

> **Réponse.** Non. `[.5,.5]` diffère de `[1/3,1/6]` et fait passer le total de .5 à 1 seconde.

## 5. Exercice 5

La référence MusicXML définit des rapports nominaux et leurs limites. Le cours conservé apporte l'exigence distincte d'unité de tempo nommée. Une proposition GA doit identifier événements admissibles et interaction avec liaisons et changements de tempo. Un mot de style générique ne fournit pas ces politiques.

Que faut-il joindre au rapport dans une transmission ?

> **Réponse.** Unité de temps, tempo, type d'événement admissible, rapport et cas non pris en charge ; aucun style joué ni identité culturelle n'en découle.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
