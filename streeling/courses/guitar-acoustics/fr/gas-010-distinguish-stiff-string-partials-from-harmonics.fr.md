---
module_id: gas-010-distinguish-stiff-string-partials-from-harmonics
department: guitar-acoustics
course: "Distinguer les partiels d’une corde raide des harmoniques"
level: intermediate
prerequisites: ["gas-005-separate-a-partial-peak-from-a-period", "gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Distinguer les partiels d’une corde raide des harmoniques

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Une étiquette de spectre GA peut appeler chaque partiel « harmonique ». Ce n'est exact que pour un multiple entier d'une fondamentale de référence. Un modèle stipulé, inspiré de la raideur, change ici les rapports de fréquences, sans traiter les amplitudes. La normalisation au premier partiel garde la référence explicite.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gas-005-separate-a-partial-peak-from-a-period](../../guitar-acoustics/en/gas-005-separate-a-partial-peak-from-a-period.md)

[Prérequis: gas-006-relate-pluck-position-to-string-modes](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md)

[Artefact du projet conservé](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Référence primaire](https://www.dsprelated.com/freebooks/pasp/Stiff_String.html)

## 1. Exercice 1

Définissons `f_n=n*100*sqrt((1+B*n*n)/(1+B))` avec `B=.01`, sans dimension. Le dénominateur fixe exactement le premier partiel à 100 Hz. L'omettre changerait la référence. Ce coefficient construit n'est pas le réglage de dispersion GA.

Que donne la formule pour le premier partiel ?

> **Réponse.** À n=1, le rapport sous la racine vaut 1 ; le résultat est 100 Hz.

## 2. Exercice 2

Le deuxième partiel vaut environ 202.948561985 Hz, au-dessus de la référence harmonique 200 Hz. Son rapport au double du premier dépasse l'unité. Le terme « deuxième partiel » préserve sa position ; « deuxième harmonique exact » effacerait l'écart calculé.

Donnez la référence harmonique et le signe du résidu.

> **Réponse.** La référence vaut 200 Hz ; le résidu est positif, car le deuxième partiel modélisé est plus haut.

## 3. Exercice 3

Pour le troisième partiel, la formule donne environ 311.654797607 Hz, au lieu de 300 Hz. L'écart augmente avec l'indice dans ce modèle à coefficient positif. Cela n'établit pas un effet audible universel : amplitude, bande, durée et tâche d'écoute ne sont pas définies.

Ce calcul prouve-t-il l'audibilité ou une préférence ?

> **Réponse.** Non. Il calcule un écart de modèle ; les comptes rendus perceptifs exigent d'autres observations et une comparaison définie.

## 4. Exercice 4

Fixons B à 0 comme témoin négatif. La formule retourne `[100,200,300]`, des multiples harmoniques exacts. Ce contrôle vérifie normalisation et sens de comparaison. Une mauvaise convention pour le premier partiel pourrait sinon fabriquer un résidu jusque dans le témoin de corde souple.

Que doit retourner le témoin à coefficient nul ?

> **Réponse.** Il doit donner `[100,200,300]` Hz. Un écart non nul réfuterait l'application de la formule ou la convention de référence annoncée.

## 5. Exercice 5

La source identifie un état de dispersion ; le texte acoustique explique une propagation dépendant de la fréquence. Aucun n'étalonne notre coefficient par rapport à un réglage GA. Séparez modèle construit et spectre ajusté, en conservant identité des partiels et pics incertains. L'avertissement du prérequis sur le pic maximal reste valable.

Que manque-t-il avant de recommander un réglage GA ?

> **Réponse.** Il manque une relation exécutée et versionnée entre commande et fréquences mesurées, des estimations étalonnées et une tâche d'acceptation déclarée.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
