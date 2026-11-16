---
module_id: gas-011-track-reflection-polarity-at-string-boundaries
department: guitar-acoustics
course: "Suivre la polarité des réflexions aux extrémités d’une corde"
level: intermediate
prerequisites: ["gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Suivre la polarité des réflexions aux extrémités d’une corde

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un schéma de corde indique un gain de réflexion sans nommer la variable transportée. Cette omission peut inverser le signe d'une explication pourtant soignée. Nous suivons des ondes de déplacement à une extrémité fixe idéale, vérifions l'annulation et distinguons les conventions de force. Les impulsions sont construites ; aucun chevalet réel n'a été mesuré.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gas-006-relate-pluck-position-to-string-modes](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md)

[Artefact du projet conservé](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Référence primaire](https://www.dsprelated.com/freebooks/pasp/Rigid_Terminations.html)

## 1. Exercice 1

Déclarons une amplitude incidente de .2 mm et un même axe transversal positif pour les deux composantes. À une extrémité fixe immobile idéale, leur somme doit s'annuler. Le déplacement réfléchi vaut donc -.2 mm. La contrainte porte sur la somme, sans rendre nulle l'onde incidente.

Quel coefficient satisfait cette frontière ?

> **Réponse.** Le coefficient de déplacement vaut -1 : il donne -.2 mm et un déplacement total de 0 mm.

## 2. Exercice 2

Essayons +1 comme témoin négatif en gardant la même convention de déplacement. L'amplitude réfléchie vaut .2 mm et la somme .4 mm. Cela viole l'hypothèse d'extrémité fixe. L'échec est algébrique ; il ne signifie pas qu'un tampon GA ait déplacé un chevalet réel.

Pourquoi le coefficient positif échoue-t-il ici ?

> **Réponse.** Il donne .4 mm au lieu des 0 mm requis à la frontière fixe.

## 3. Exercice 3

Une impulsion réfléchie une fois à chaque extrémité fixe reçoit `(-1)*(-1)=+1`. Son signe après aller-retour est positif malgré les inversions locales. Durée et atténuation exigent d'autres données. Le signe positif d'une boucle ne révèle donc pas à lui seul le respect des contraintes locales.

Un signe positif après aller-retour implique-t-il des extrémités sans inversion ?

> **Réponse.** Non. Deux inversions donnent le produit +1 ; conservez les deux gains locaux séparément.

## 4. Exercice 4

Le texte primaire distingue déplacement et vitesse des ondes de force : leurs signes à une frontière rigide diffèrent. Un coefficient de réflexion non qualifié est incomplet. Avant d'emprunter une formule, conservez variable, orientation, unités et type de frontière. Un signe copié sans contexte peut répondre correctement à une autre question.

Quel contexte évite une comparaison trompeuse ?

> **Réponse.** Nommez déplacement ou force, orientation commune, unités et condition de frontière avant de comparer les gains.

## 5. Exercice 5

Lisez les états de rétroaction et de corps du moteur sans appeler chaque récurrence une frontière physique. L'implémentation est un modèle de synthèse ; l'exercice vérifie une interprétation idéale. Une note doit désigner la récurrence exacte et la correspondance de modèle encore nécessaire avant une affirmation physique.

Ce calcul valide-t-il un chevalet réel ou répare-t-il le résultat de décroissance ?

> **Réponse.** Non. Il valide seulement l'algèbre stipulée ; correspondance physique et ancien critère de décroissance restent distincts.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
