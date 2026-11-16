---
title: Vérifier la couverture d’un barré avant de déclarer une forme jouable
description: Vérifier la couverture d’un barré avant de déclarer une forme jouable — Études de guitare
sidebar:
  label: GTR-011 · Vérifier la couverture d’un barré avant de déclarer une forme jouable
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-011-test-barre-coverage-before-calling-a-shape-playable.fr.md
---

:::note[Streeling University]
**GTR-011** · Vérifier la couverture d’un barré avant de déclarer une forme jouable · intermédiaire · 45 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-011-test-barre-coverage-before-calling-a-shape-playable.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-003](../../guitar-studies/gtr-003-audit-voicing-playability/)
:::

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Le prérequis montrait que deux heuristiques GA répondent à des questions différentes. Nous ajoutons ici l'intervalle explicite d'un doigt proposé et vérifions si son contact contredit une corde demandée à vide. L'opération dépasse le comptage de cases répétées. Elle ne certifie toujours ni portée, ni pression, ni son, et ne remplace aucune heuristique.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gtr-003-audit-voicing-playability](../../guitar-studies/gtr-003-audit-voicing-playability/)

[Artefact du projet conservé](../../guitar-studies/gtr-003-audit-voicing-playability/)

[Paquet de données construites](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

Utilisons les numéros conventionnels : 1 aiguë, 6 grave. Proposons un contact continu à la case 2 sur les cordes 1 à 3. Les cases demandées sont `[2,0,2]`. La corde centrale appartient à l'intervalle du doigt, même si elle ne partage pas la case positive répétée.

Quelles cordes ce contact couvre-t-il ?

> **Réponse.** Il couvre `[1,2,3]`, y compris la corde centrale demandée à vide.

## 2. Exercice 2

Dans le modèle de contact continu, une corde couverte ne peut conserver une case sonore inférieure au barré. La corde 2 demande 0 alors que le contact est à 2 : contradiction. Cela concerne le doigté proposé, pas l'existence de la forme avec toute technique imaginable.

Identifiez le conflit et son hypothèse.

> **Réponse.** La corde 2 est en conflit car `0<2` ; le résultat suppose un contact continu sans doigt sélectivement arqué.

## 3. Exercice 3

Pour le témoin négatif, remplaçons la demande centrale par la case 3. Un autre contact plus haut peut dominer le barré inférieur dans cette géométrie idéale. La contradiction disparaît, mais l'affectation complète des doigts manque encore. Réussir ce contrôle ne prouve donc pas le doigté pratique.

Que change la demande `[2,3,2]` ?

> **Réponse.** Aucune case demandée n'est inférieure à la case couverte 2. Le contrôle réussit ; l'affectation réelle des doigts reste indéterminée.

## 4. Exercice 4

Un détecteur booléen de cases répétées ne fournit ni extrémités, ni doigt, ni politique de contact. On ne peut donc transformer silencieusement son étiquette en barré continu. Conservez forme et contact proposé séparément : une personne peut rejeter le doigté tout en gardant le voicing utile.

Une heuristique de barré fausse garantit-elle l'absence de barré nécessaire ?

> **Réponse.** Non. Elle annonce seulement son prédicat ; doigté explicite et observations musicales répondent à d'autres questions.

## 5. Exercice 5

Le prérequis conservé est une archive transférée, dont la revue musicale reste ouverte. Ce calcul ne réécrit pas son histoire. Pour un futur essai, gardez ordre des cordes, intervalle du doigt, cordes à vide voulues, notes nettes observées et assistance. Vérifiez d'abord la petite table avant d'étendre le classement GA.

Que reste-t-il après le calcul de couverture ?

> **Réponse.** Contact réel, son net, réussite des transitions et acceptation musicale restent à vérifier ; aucun interprète n'a été testé.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
