---
module_id: wml-010-keep-unicode-note-labels-reversible
department: world-music-languages
course: "Préserver la réversibilité des étiquettes de notes Unicode"
level: intermediate
prerequisites: ["wml-005-declare-note-name-conventions", "wml-007-resolve-scale-degrees-against-tonic-and-mode"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Préserver la réversibilité des étiquettes de notes Unicode

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Une transmission GA remplace le dièse musical par un croisillon ASCII, puis prétend reproduire le texte original. Même si la hauteur voulue reste identique dans un vocabulaire déclaré, les octets d'origine ont disparu. Nous construisons une fiche réversible limitée, en distinguant alias sémantique, normalisation Unicode et syntaxe acceptée par un analyseur.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: wml-005-declare-note-name-conventions](../../world-music-languages/en/wml-005-declare-note-name-conventions.md)

[Prérequis: wml-007-resolve-scale-degrees-against-tonic-and-mode](../../world-music-languages/en/wml-007-resolve-scale-degrees-against-tonic-and-mode.md)

[Artefact du projet conservé](../../../../streeling/courses/world-music-languages/en/wml-005-declare-note-name-conventions.md)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Référence primaire](https://www.unicode.org/reports/tr15/tr15-58.html)

## 1. Exercice 1

Déclarons `C♯4` et `C#4`. Le signe musical est `U+266F` ; le signe ASCII est `U+0023`. Ce sont des caractères distincts, même si une interface les interprète comme le même dièse. Ressemblance visuelle ou hauteur identique ne signifie pas texte source identique.

Combien de jetons originaux distincts a-t-on ?

> **Réponse.** Il y a 2 originaux distincts, différenciés par leur caractère d'altération.

## 2. Exercice 2

Stipulons une table affichant les deux sous `C#4`. Elle a deux entrées et une seule sortie distincte. C'est une politique applicative, pas l'affirmation qu'une normalisation Unicode effectue cette substitution. L'annexe distingue équivalences formelles et réécriture sémantique arbitraire.

La table seule est-elle inversible de façon unique ?

> **Réponse.** Non. Sa seule valeur affichée ne permet pas de retrouver le jeton d'origine.

## 3. Exercice 3

Conservez original et affichage dérivé ensemble. Restaurer depuis le champ original retrouve exactement chaque graphie. L'affichage reste disponible pour la syntaxe du destinataire. Gardez version de table et convention ; stocker un original ne suffit pas à le rendre accepté par un analyseur.

Quelles données rendent ces lignes réversibles ?

> **Réponse.** Gardez chaque original avec son affichage ; la restauration retourne respectivement `C♯4` et `C#4`.

## 4. Exercice 4

Supprimons l'original comme témoin négatif. Les deux fiches ne contiennent plus que `C#4` ; rien ne permet de choisir l'origine. Une inversion qui impose le signe musical modifie la ligne initialement ASCII. La correction sémantique d'un alias ne certifie pas la restitution exacte du texte.

Qu'est-ce qui échoue si l'inversion impose le dièse musical ?

> **Réponse.** La ligne initialement ASCII n'est pas restaurée exactement ; l'affichage seul ne distingue pas les cas.

## 5. Exercice 5

Lisez le prérequis sur les conventions avant de considérer ces alias comme un vocabulaire complet. Octave, système de noms et symboles non pris en charge exigent encore des règles. L'annexe Unicode explique la normalisation ; elle ne prouve pas le comportement GA. Un futur test doit conserver version et résultats réels.

Que peut établir cet exercice avec sources ?

> **Réponse.** Seulement le comptage et la restitution exacte des deux jetons ; acceptation d'analyseur et revue linguistique restent non observées.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
