---
module_id: mcl-009-preserve-pickup-offsets-in-bar-addresses
department: musicology
course: "Conserver le décalage de l’anacrouse dans les adresses de mesure"
level: intermediate
prerequisites: ["mcl-006-preserve-meter-grouping-and-tempo-units", "mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Conserver le décalage de l’anacrouse dans les adresses de mesure

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un agent situe une note par mesure et pulsation mais traite l'anacrouse comme une mesure complète. Tous les temps suivants se décalent. Ce cours sépare identité écrite et durée réelle, sur une partition construite à une voix. Il n'analyse aucun fichier et ne déduit aucune interprétation expressive de la notation.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: mcl-006-preserve-meter-grouping-and-tempo-units](../../musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Prérequis: mcl-007-integrate-a-midi-tempo-map-before-scheduling](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefact du projet conservé](../../../../streeling/courses/musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Référence primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/measure-partwise/)

## 1. Exercice 1

Utilisons les étiquettes `0`, `1`, `2`, avec durées réelles `[1,4,4]` en noires. La première est une anacrouse construite. Les étiquettes identifient ; elles ne multiplient pas une durée. Les sommes préfixes donnent `[0,1,5]` depuis l'origine de l'extrait.

À quelles positions absolues commencent les mesures ?

> **Réponse.** Elles commencent en `[0,1,5]` ; l'anacrouse contribue 1 noire, pas 4.

## 2. Exercice 2

Plaçons un événement au décalage local 1, compté depuis zéro, dans la mesure 2. Sa coordonnée absolue vaut `5+1=6`. La convention évite de confondre décalage et numéro de temps affiché. L'adresse locale reste attachée à la mesure même si l'origine d'extrait change.

Donnez la coordonnée absolue de l'événement.

> **Réponse.** Elle vaut 6 noires depuis cette origine ; conservez aussi mesure 2 et décalage local 1.

## 3. Exercice 3

À 120 noires par minute constantes, chaque noire dure .5 seconde. La coordonnée 6 correspond donc à 3 secondes. Une carte de tempo exigerait l'intégration du prérequis. Correction d'anacrouse et intégration de tempo résolvent deux problèmes distincts ; il faut garder les deux si nécessaire.

Convertissez l'événement en secondes au tempo annoncé.

> **Réponse.** `6*60/120=3` secondes ; aucune attaque expressive ni latence enregistrée n'a été mesurée.

## 4. Exercice 4

Comme témoin négatif, remplaçons la durée réelle de l'anacrouse par 4. Les débuts deviennent `[0,4,8]` ; la même adresse locale donne 9 noires. L'erreur vaut 3 noires, soit 1.5 seconde ici. Le texte de l'adresse reste identique malgré le déplacement produit par le modèle.

Quelle erreur crée ce raccourci ?

> **Réponse.** Il ajoute 3 noires, soit 1.5 seconde au tempo déclaré.

## 5. Exercice 5

MusicXML autorise des identifiants textuels et décrit la numérotation implicite liée aux anacrouses. Lisez cette définition avec le prérequis. Cela ne transforme pas notre somme en importateur général : accords, voix, déplacements et divisions variables exigent un traitement explicite. Le rapport doit conserver adresse et coordonnée cumulée.

Le numéro de mesure détermine-t-il le temps écoulé ?

> **Réponse.** Non. Durées réelles, décalage local, origine et tempo sont requis ; la numérotation ne suffit pas.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
