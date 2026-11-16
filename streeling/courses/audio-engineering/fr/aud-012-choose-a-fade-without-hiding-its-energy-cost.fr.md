---
module_id: aud-012-choose-a-fade-without-hiding-its-energy-cost
department: audio-engineering
course: "Choisir un fondu en explicitant son coût énergétique"
level: intermediate
prerequisites: ["aud-006-calibrate-spectral-amplitudes", "aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Choisir un fondu en explicitant son coût énergétique

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un fondu peut atténuer une discontinuité tout en modifiant les données d'une comparaison d'amplitude. Un rapport GA qui décrit seulement l'extrémité adoucie omet ce coût. Nous comparons deux enveloppes finies sur les mêmes échantillons construits, en conservant support et sommes des carrés. Il s'agit de préparation des mesures, pas d'un classement auditif.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: aud-006-calibrate-spectral-amplitudes](../../audio-engineering/en/aud-006-calibrate-spectral-amplitudes.md)

[Prérequis: aud-009-declare-alignment-before-a-null-test](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Artefact du projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

Prenons `[1,1,1]` sur trois trames, de somme des carrés 3. Définissons l'enveloppe d'amplitude linéaire `[1,.5,0]`. Les gains initial et final sont explicites, tout comme la valeur centrale de cette définition discrète. Une durée de fondu décrite vaguement ne déterminerait pas ces valeurs.

Appliquez l'enveloppe linéaire et calculez la somme des carrés.

> **Réponse.** Le résultat est `[1,.5,0]`, de somme des carrés 1.25. Les extrémités et le gain central discret font partie de la définition construite.

## 2. Exercice 2

Une autre enveloppe vaut `[1,sqrt(.5),0]`. Ses gains au carré sont `[1,.5,0]` ; l'entrée unitaire donne donc une énergie de 1.5. Le gain central vaut environ .707106781. Malgré des extrémités et un support identiques, les sommes des carrés diffèrent. Le seul mot « fondu » masque ce choix.

Calculez la seconde énergie et comparez-la au résultat linéaire.

> **Réponse.** La seconde énergie vaut 1.5 contre 1.25. Des extrémités et une durée identiques n'impliquent pas une énergie identique selon la mesure déclarée.

## 3. Exercice 3

Par rapport à l'énergie initiale 3, les fractions conservées valent `1.25/3=5/12` et `1.5/3=.5`. Elles concernent cette entrée. Multiplier ensuite l'audio pour retrouver un RMS choisi ajoute une transformation et peut changer les crêtes. Consignez ce gain séparément ; il ne prouve pas que le fondu initial préservait l'énergie.

Donnez les fractions conservées et ce qu'ajoute une normalisation RMS ultérieure.

> **Réponse.** Elles valent `5/12` et `.5`. La normalisation ajoute un gain distinct ; elle ne rend pas l'enveloppe initiale conservatrice d'énergie.

## 4. Exercice 4

Pour le témoin négatif, plaçons toute l'énergie dans la dernière trame : `[0,0,1]`. Les deux enveloppes donnent alors `[0,0,0]`, donc une conservation nulle. Ce cas réfute un facteur universel déduit d'échantillons constants. La position de l'énergie dans l'enveloppe compte autant que la courbe de gain.

Le résultat constant établit-il un pourcentage universel de conservation ?

> **Réponse.** Non. Le témoin limité à la dernière trame donne `[0,0,0]` dans les deux cas, sans énergie conservée. Une fraction doit préciser son entrée et son support.

## 5. Exercice 5

Examinez le choix des fenêtres et la conservation des tampons bruts dans le lanceur. Une comparaison future doit conserver copie originale, enveloppe, support, gain éventuel et critère. Un agent peut aider aux calculs, mais le choix de préparation doit répondre à une tâche définie pour le guitariste. Ni extrémité adoucie ni baisse d'énergie ne suffit à établir une préférence.

Que doit conserver une note de revue avant de comparer les résultats ?

> **Réponse.** Conservez échantillons originaux, enveloppe, support, définition de l'énergie, gain ultérieur et critère. Aucun nouveau rendu ni préférence d'écoute n'a été observé ici.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
