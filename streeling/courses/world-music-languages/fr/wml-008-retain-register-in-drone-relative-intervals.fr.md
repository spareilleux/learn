---
module_id: wml-008-retain-register-in-drone-relative-intervals
department: world-music-languages
course: "Conserver le registre dans les intervalles relatifs à un bourdon"
level: intermediate
prerequisites: ["wml-007-resolve-scale-degrees-against-tonic-and-mode"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Conserver le registre dans les intervalles relatifs à un bourdon

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un agent décrit les notes par rapport à un bourdon mais réduit les intervalles à l'octave. Les étiquettes peuvent alors cacher si la note est au-dessus ou au-dessous. Nous conservons séparément distance signée en demi-tons et classe réduite. Cet exemple inventé n'attribue aucun système, gamme ou convention à une communauté.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: wml-007-resolve-scale-degrees-against-tonic-and-mode](../../world-music-languages/en/wml-007-resolve-scale-degrees-against-tonic-and-mode.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/capo-spelling-2026-10-22/degree-context.json)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

Stipulons un bourdon absolu 60 et les notes `[55,67,79]`. Soustrayez la même référence avant toute réduction. Les intervalles signés valent `[-5,7,19]` demi-tons. Le signe négatif compte : la première note est plus grave, les autres plus aiguës.

Donnez les distances et identifiez la note inférieure.

> **Réponse.** Les distances sont `[-5,7,19]` ; la note 55 est sous le bourdon 60.

## 2. Exercice 2

Réduisons chaque intervalle modulo 12 en classe positive ou nulle. Tous deviennent 7. Cette équivalence d'octave efface direction et registre. L'affichage peut servir une tâche, sans affirmer que les notes occupent la même position absolue ou partagent la même provenance.

Quelles classes obtient-on, et que perd-on ?

> **Réponse.** Les classes sont `[7,7,7]` ; direction et déplacement d'octave disparaissent.

## 3. Exercice 3

Avec la distance signée, retrouvez la note par `note=drone+delta`. Ajouter seulement la classe réduite donnerait partout 67, remplaçant incorrectement 55 et 79. Ce témoin réfute un adaptateur réversible limité à la classe. Ni étiquette séduisante ni score de confiance ne rétablit l'octave perdue.

Reconstruisez les notes depuis les distances complètes.

> **Réponse.** Elles valent `[55,67,79]` ; la reconstruction par classe seule donnerait à tort `[67,67,67]`.

## 4. Exercice 4

Le paquet de degrés exige déjà un registre de tonique pour résoudre des notes absolues. Une interface relative au bourdon doit aussi garder référence et politique d'étendue, surtout quand la mélodie le traverse. Ces demi-tons excluent délibérément rapports d'intonation, hauteurs continues et conventions non déclarées.

Le modèle établit-il un vocabulaire universel du bourdon ?

> **Réponse.** Non. Il établit seulement coordonnées signées et réduites de l'exemple tempéré déclaré.

## 5. Exercice 5

Une tâche localisée doit conserver terme original et référence avec toute coordonnée dérivée. Les sources aident à vérifier la soustraction ; une personne maîtrisant la langue et un musicien évaluent terminologie et réalisation séparément. La table n'autorise aucune équivalence culturelle ni affirmation de chant ou d'écoute.

Que faut-il garder pour préserver la réversibilité ?

> **Réponse.** Référence60, distances signées, convention et étiquettes originales ; la classe7 seule ne suffit pas.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
