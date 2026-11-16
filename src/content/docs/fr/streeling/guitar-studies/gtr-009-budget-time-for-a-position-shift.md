---
title: Prévoir le temps nécessaire à un changement de position
description: Prévoir le temps nécessaire à un changement de position — Études de guitare
sidebar:
  label: GTR-009 · Prévoir le temps nécessaire à un changement de position
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-009-budget-time-for-a-position-shift.fr.md
---

:::note[Streeling University]
**GTR-009** · Prévoir le temps nécessaire à un changement de position · intermédiaire · 45 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-009-budget-time-for-a-position-shift.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-003](../../guitar-studies/gtr-003-audit-voicing-playability/), [GTR-005](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/)
:::

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un voicing peut satisfaire hauteur et occupation des cordes sans laisser le temps d'atteindre la position suivante. Une proposition de pratique GA exige donc un budget temporel en plus d'un score statique. Nous utilisons des coûts construits de déplacement, relâchement et préparation pour montrer une impossibilité limitée au modèle. Aucun coût n'est une vitesse humaine mesurée.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gtr-003-audit-voicing-playability](../../guitar-studies/gtr-003-audit-voicing-playability/)

[Prérequis: gtr-005-plan-which-string-keeps-ringing](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Paquet de données construites](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

À 120 noires par minute, une demi-noire dure 250 ms. Le créneau commence quand la note tenue peut être relâchée, pas à son attaque. Soustraire la mauvaise frontière invente du temps de préparation. Gardez les identités d'événements du prérequis.

Quel temps offre un créneau de .5 noire ?

> **Réponse.** `0.5*60000/120` donne 250 ms.

## 2. Exercice 2

Stipulons 40 ms de relâchement, 4 cases à 30 ms par case et 60 ms de préparation. Les étapes se succèdent sans chevauchement. Le total requis vaut 220 ms. Cette table pédagogique n'est ni une loi physiologique ni un service GA étalonné.

Calculez le temps requis et la marge.

> **Réponse.** Il faut `40+4*30+60=220` ms ; la marge sur 250 ms vaut 30 ms.

## 3. Exercice 3

Passons seulement le tempo à 180. Le créneau offre alors environ 166.666667 ms, sous le coût inchangé. Ce témoin réfute l'affirmation que toute transition aux hauteurs valides tient dans le temps. Il identifie l'hypothèse en défaut, sans prédire l'échec de tous les guitaristes.

Quel déficit obtient-on au tempo rapide ?

> **Réponse.** Temps requis moins disponible vaut environ 53.333333 ms ; la transition ne tient pas dans le modèle déclaré.

## 4. Exercice 4

Une correction peut réduire le trajet, avancer le relâchement ou modifier le tempo. Elle change une entrée déclarée ; la demande musicale doit en garder la trace. Raccourcir silencieusement une tenue peut rendre le planning possible en violant le sustain. Comparez d'abord un calcul manuel avant de proposer un planificateur.

Relâcher plus tôt est-il une réalisation inchangée ?

> **Réponse.** Non. La fin de l'événement change ; consignez cette modification musicale et demandez la décision de l'interprète.

## 5. Exercice 5

Le paquet d'occupation exclut explicitement géométrie de la main et timing moteur. Notre extension ajoute un calcul proposé, pas des observations musicales rétroactives. Une future tâche devra conserver écarts d'attaque observés, doigté et assistance. La réussite du planning arithmétique n'établit aucun de ces résultats.

Que permet de conclure une marge positive ?

> **Réponse.** Le modèle construit de coûts successifs tient dans le créneau ; exécution nette, confort et apprentissage restent indécidés.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
