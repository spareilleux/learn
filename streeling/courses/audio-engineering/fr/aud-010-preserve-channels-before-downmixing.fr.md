---
module_id: aud-010-preserve-channels-before-downmixing
department: audio-engineering
course: "Préserver les canaux avant de réduire en mono"
level: intermediate
prerequisites: ["aud-005-pcm-guards-and-format-boundaries", "aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Préserver les canaux avant de réduire en mono

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Une personne qui révise GA reçoit une référence de guitare stéréo et une synthèse mono. Faire la moyenne avant de vérifier les canaux peut effacer le signal à comparer. Ce cours explicite la matrice de réduction, conserve le support original et précise ce qui devient irrécupérable. Il s'agit de préserver les données, sans nouvel enregistrement ni jugement d'écoute.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: aud-005-pcm-guards-and-format-boundaries](../../audio-engineering/en/aud-005-pcm-guards-and-format-boundaries.md)

[Prérequis: aud-009-declare-alignment-before-a-null-test](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Artefact du projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Référence primaire](https://www.w3.org/TR/webaudio-1.0/#channel-up-mixing-and-down-mixing)

## 1. Exercice 1

Prenons les échantillons gauches `[1,-1,1,-1]` et droits `[-1,1,-1,1]`, sur le même support de quatre trames. La somme des carrés vaut 4 dans chaque canal. Une trame réunit les échantillons simultanés des canaux : quatre trames stéréo contiennent huit valeurs scalaires. Confondre ces quantités fausse le raisonnement sur la durée et la taille.

Combien compte-t-on de trames et de valeurs scalaires, et quelle énergie a chaque canal ?

> **Réponse.** Il y a 4 trames et 8 valeurs scalaires. La somme des carrés de chaque canal vaut 4 ; ce n'est pas une énergie étalonnée en joules.

## 2. Exercice 2

Appliquons la réduction déclarée `m[n]=(L[n]+R[n])/2`. Tous les échantillons de sortie sont nuls, car les valeurs des canaux sont opposées. L'entrée multicanal n'est pas nulle. Un tampon réduit silencieux ne prouve donc pas que les canaux d'origine étaient silencieux ; un test d'annulation mono ne certifie pas leur égalité.

Calculez le vecteur mono et expliquez pourquoi l'étiquette « silence » serait trompeuse.

> **Réponse.** Le vecteur mono est `[0,0,0,0]`, de somme des carrés 0. Ce résultat s'explique par l'annulation dans la matrice choisie ; les canaux d'origine restent non nuls.

## 3. Exercice 3

Conservons un autre témoin, aux canaux identiques : `L=R=[1,-1,1,-1]`. La moyenne préserve cette fois le vecteur et sa somme des carrés. La comparaison isole le signe relatif des canaux. Elle ne décrit pas toutes les prises de son et ne permet pas de diagnostiquer un câblage défectueux sans contexte d'acquisition.

Que produit le témoin aux canaux identiques, et quelle variable isole-t-il ?

> **Réponse.** Le mono vaut `[1,-1,1,-1]`, de somme des carrés 4. Le témoin change la relation entre canaux ; il ne diagnostique pas une installation réelle.

## 4. Exercice 4

La sortie mono ne distingue pas des canaux non nuls opposés de deux canaux nuls. Cette application associe plusieurs entrées à la même sortie. Conservez l'ordre des canaux, la fréquence d'échantillonnage, les octets originaux et la matrice. Une correction de gain ultérieure ne restaure pas la différence supprimée ; ces traces permettent de refaire la transformation.

Peut-on retrouver de façon unique les deux entrées à partir du mono nul ?

> **Réponse.** Non. Des canaux opposés et deux canaux nuls donnent la même sortie. Conservez les originaux et la matrice déclarée ; le tampon réduit ne suffit pas.

## 5. Exercice 5

Lisez le contrat mono du lanceur conservé avant de proposer la stéréo. Ses nombres d'échantillons concernent ce contrat, pas cet exemple nouveau. La référence W3C sur le mélange des haut-parleurs définit une moyenne pour la réduction stéréo ; il faut encore préciser l'interprétation des canaux. Le rapport proposé doit distinguer lecture de source et exécution d'un décodeur.

Qu'est-ce qui réfuterait un rapport affirmant que le mono nul prouve une entrée nulle ?

> **Réponse.** Le cas construit de canaux opposés le réfute déjà. Le rapport doit conserver les valeurs par canal et préciser que le lanceur a été lu, sans réexécution ni extension.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
