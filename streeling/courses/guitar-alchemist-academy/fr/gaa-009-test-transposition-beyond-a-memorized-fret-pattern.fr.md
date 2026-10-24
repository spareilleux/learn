---
module_id: gaa-009-test-transposition-beyond-a-memorized-fret-pattern
department: guitar-alchemist-academy
course: "Tester la transposition au-delà d’un dessin de cases mémorisé"
level: intermediate
prerequisites: ["gaa-006-separate-capo-shapes-from-sounding-pitches", "gaa-007-turn-a-voicing-result-into-a-practice-item"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Tester la transposition au-delà d’un dessin de cases mémorisé

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Reproduire un diagramme familier ne démontre pas nécessairement l'opération de transposition. Nous préparons une tâche avec sources dont le corrigé conserve intervalles absolus, registre et accordage. Les listes sont construites, sans réponses d'élèves réelles. Plusieurs réalisations sont possibles, mais la transformation des hauteurs doit être vérifiable ; les conclusions pédagogiques restent ouvertes.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gaa-006-separate-capo-shapes-from-sounding-pitches](../../guitar-alchemist-academy/en/gaa-006-separate-capo-shapes-from-sounding-pitches.md)

[Prérequis: gaa-007-turn-a-voicing-result-into-a-practice-item](../../guitar-alchemist-academy/en/gaa-007-turn-a-voicing-result-into-a-practice-item.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/capo-spelling-2026-10-22/degree-context.json)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

Partons des notes absolues `[60,64,67]` et demandons une hausse de 2 demi-tons pour chacune. On obtient `[62,66,69]`. Le corrigé vérifie toutes les notes et l'ordre. Vérifier seulement la fondamentale ne suffit pas, même si la première hauteur est juste.

Donnez la cible et ses intervalles depuis la première note.

> **Réponse.** La cible est `[62,66,69]` ; les intervalles sont `[0,4,7]`.

## 2. Exercice 2

Prenons `[62,65,69]` comme témoin négatif. La première note est correcte, mais l'intervalle central passe de 4 à 3 demi-tons. Une forme mineure mémorisée pourrait réussir un contrôle de tonique tout en échouant à la demande. Le corrigé doit vérifier la transformation, pas seulement une étiquette familière.

Pourquoi cette proposition échoue-t-elle ?

> **Réponse.** Ses intervalles sont `[0,3,7]` ; la note centrale devrait être 66 au lieu de 65.

## 3. Exercice 3

Autre témoin : `[74,78,81]`. Ses classes de hauteur concordent, mais chaque note est une octave au-dessus de la cible absolue. Accepter l'équivalence d'octave dépend de la consigne. Ici le registre est requis ; l'égalité des classes ne peut élargir silencieusement les réponses acceptées.

Le témoin décalé d'octave est-il correct ici ?

> **Réponse.** Non. Il ajoute 12 à la cible et viole l'exigence de registre absolu.

## 4. Exercice 4

Pour sonder le transfert, cachez la liste cible avant la réponse et changez l'item initial par rapport à l'exemple répété. Conservez sources et calculatrice autorisées. Résoudre avec le corrigé visible vise un autre résultat. Cette distinction de conception ne valide aucun transfert réel.

Que faut-il conserver avant de révéler le corrigé ?

> **Réponse.** La réponse réelle, l'item d'entrée, l'assistance et la règle de notation, avant révélation.

## 5. Exercice 5

La table de degrés conservée distingue majeur et mineur naturel à tonique et registre fixes. Elle aide à expliquer la tierce modifiée, sans prouver qu'un élève ait commis l'erreur. Une réalisation sur manche exige ordre des cordes, accordage, positions autorisées et revue musicale.

La liste juste prouve-t-elle un doigté jouable ou un transfert acquis ?

> **Réponse.** Non. Elle vérifie seulement le corrigé arithmétique construit ; ni jeu ni tentative d'élève n'ont eu lieu.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
