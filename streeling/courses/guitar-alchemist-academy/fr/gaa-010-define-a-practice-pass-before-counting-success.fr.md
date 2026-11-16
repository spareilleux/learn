---
module_id: gaa-010-define-a-practice-pass-before-counting-success
department: guitar-alchemist-academy
course: "Définir une réussite de pratique avant de compter les succès"
level: intermediate
prerequisites: ["gaa-007-turn-a-voicing-result-into-a-practice-item"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Définir une réussite de pratique avant de compter les succès

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un tableau de pratique compte des prises réussies sans définir la réussite. Nous posons une règle conjointe sur quatre tentatives construites : notes justes, timing dans une tolérance déclarée et absence d'aide interdite. Cette règle est locale. Compter ses résultats vérifie le barème ; prouver un progrès musical exige d'autres observations réelles.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gaa-007-turn-a-voicing-result-into-a-practice-item](../../guitar-alchemist-academy/en/gaa-007-turn-a-voicing-result-into-a-practice-item.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

Définissons une réussite : notes justes, erreur absolue d'attaque au plus 50 ms et aucune aide interdite. Toutes les conditions sont nécessaires. La tolérance n'est pas universelle ; elle rend une tâche évaluable. Changer une condition après lecture des résultats définirait un autre résultat à rapporter.

La justesse des hauteurs suffit-elle ?

> **Réponse.** Non. Les conditions de timing et d'assistance doivent aussi être satisfaites.

## 2. Exercice 2

A présente des notes justes, une erreur de 20 ms et aucune aide. B a des notes justes, 60 ms et aucune aide. Seule A satisfait le timing. Gardez la justesse de B même si sa réussite globale est fausse ; les composantes expliquent le résultat.

Laquelle de A ou B réussit ?

> **Réponse.** A réussit. B échoue car 60 dépasse la tolérance déclarée de 50 ms.

## 3. Exercice 3

C présente des notes incorrectes et 10 ms d'erreur. D a des notes justes, 20 ms et une aide interdite. Les deux échouent pour des raisons différentes. Ne les réduisez pas à une mauvaise prise indifférenciée ; ne retirez pas D du dénominateur après l'avoir vue.

Pourquoi C et D échouent-elles ?

> **Réponse.** C échoue sur les notes ; D sur l'assistance. Les raisons restent distinctes.

## 4. Exercice 4

Sur les quatre tentatives conservées, une réussit : `1/4=.25`. Le score limité aux notes en compterait trois : `3/4=.75`. Ce témoin montre l'effet d'un remplacement du critère par une composante plus facile. Ces fractions n'estiment aucune population : le registre est construit.

Quel taux répond à la question de réussite définie ?

> **Réponse.** `.25` y répond ; `.75` décrit seulement la justesse des notes et doit garder cette étiquette.

## 5. Exercice 5

Examinez les indices et réponses acceptées du paquet avant de définir le barème de jeu. Une observation future exige aussi une définition de mesure temporelle, l'aide autorisée et les prises conservées. Un agent peut vérifier la conjonction ; acceptation musicale et apprentissage différé restent des décisions distinctes.

Peut-on présenter ce compte construit comme un progrès observé ?

> **Réponse.** Non. Il n'y a ici ni prises réelles ni observations d'élèves, ni comparaison avant-après.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
