---
module_id: mcl-011-keep-repeats-separate-from-written-bar-identity
department: musicology
course: "Distinguer les reprises de l’identité des mesures écrites"
level: intermediate
prerequisites: ["mcl-002-musical-form", "mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Distinguer les reprises de l’identité des mesures écrites

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un élève demande de revoir le deuxième passage d'une mesure. Son identifiant écrit ne distingue pas deux visites pendant la lecture. Nous développons un plan de reprise limité tout en préservant l'identité écrite. Parcours, temps écoulé et notation restent séparés ; aucun interpréteur général ni résultat d'exécution musicale n'est produit.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: mcl-002-musical-form](../../musicology/en/mcl-002-musical-form.md)

[Prérequis: mcl-007-integrate-a-midi-tempo-map-before-scheduling](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefact du projet conservé](../../../../streeling/courses/musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Référence primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/repeat/)

## 1. Exercice 1

Déclarons A, B et C, de quatre noires chacune. Le parcours construit est `[A,B,A,B,C]`. L'identité écrite ne change pas au retour. Une visite exige sa propre occurrence, sinon les annotations ultérieures risquent d'écraser celles du premier passage.

Combien de mesures écrites et de visites y a-t-il ?

> **Réponse.** Il y a 3 mesures écrites et 5 visites ; B est visitée 2 fois.

## 2. Exercice 2

En cumulant les durées des visites, on obtient `[0,4,8,12,16]` en noires. Le deuxième B commence à 12, le premier à 4. Une adresse B plus décalage local ne suffit donc pas à désigner un passage précis.

Où commence le deuxième B ?

> **Réponse.** À la coordonnée 12 ; conservez séparément identité écrite B et deuxième occurrence.

## 3. Exercice 3

Le parcours dure 20 noires. Dédupliquer en `[A,B,C]` ne donne que 12. Ce témoin montre qu'un ensemble égal de mesures ne préserve ni visites ordonnées ni durée. Inversement, représenter une nouvelle visite n'exige pas de copier la mesure sous une nouvelle identité écrite.

Quelle erreur de durée cause la déduplication ?

> **Réponse.** Le total passe de 20 à 12 noires, soit 8 noires perdues.

## 4. Exercice 4

La définition MusicXML distingue sens de reprise et nombre de passages dans son contexte. Notre parcours est fourni explicitement, sans être déduit d'une syntaxe quelconque. Fins alternatives, imbrications et renvois sortent du modèle. Une notation non prise en charge doit rester indéterminée plutôt que recevoir un parcours plausible non testé.

L'exemple certifie-t-il toute interprétation des reprises ?

> **Réponse.** Non. Seul le parcours fourni de cinq visites est vérifié ; les autres cas exigent règles et tests supplémentaires.

## 5. Exercice 5

Le cours conservé explique le passage d'une coordonnée au temps écoulé selon une carte de tempo. Appliquez-le après sélection de la visite et de l'origine. Une annotation future doit identifier partition versionnée, mesure, visite, position locale et tempo. Ces champs aident la revue sans créer de schéma obligatoire.

Qu'est-ce qui distingue une annotation du deuxième passage ?

> **Réponse.** Une identité de visite et le contexte de parcours ; B seule n'identifie pas la deuxième occurrence.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
