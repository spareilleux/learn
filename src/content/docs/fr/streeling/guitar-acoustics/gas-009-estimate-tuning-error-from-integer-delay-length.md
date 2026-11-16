---
title: Estimer l’erreur d’accordage due à une longueur de retard entière
description: Estimer l’erreur d’accordage due à une longueur de retard entière — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-009 · Estimer l’erreur d’accordage due à une longueur de retard entière
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-009-estimate-tuning-error-from-integer-delay-length.fr.md
---

:::note[Streeling University]
**GAS-009** · Estimer l’erreur d’accordage due à une longueur de retard entière · intermédiaire · 45 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-009-estimate-tuning-error-from-integer-delay-length.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-005](../../guitar-acoustics/gas-005-separate-a-partial-peak-from-a-period/)
:::

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Une fréquence demandée ne correspond pas toujours à un retard entier. GAS005 présentait un rapport ; ici, on compare les arrondis selon une tolérance déclarée. Horloge et cibles sont des constantes construites. Le moteur GA possède aussi retard fractionnaire et filtres : ce modèle simplifié ne prédit donc pas sa hauteur rendue.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gas-005-separate-a-partial-peak-from-a-period](../../guitar-acoustics/gas-005-separate-a-partial-peak-from-a-period/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/vendor/lib.rs)

[Paquet de données construites](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

À 44100 Hz pour une cible de 1000 Hz, le retard idéal vaut 44.1 échantillons. La troncature et l'arrondi au plus proche choisissent ici 44. Cette longueur est un nombre d'échantillons ; sa durée s'obtient en divisant par l'horloge.

Quelle fréquence donne la longueur 44 ?

> **Réponse.** `44100/44` donne environ 1002.272727273 Hz, au-dessus de la cible.

## 2. Exercice 2

Utilisez les cents signés `1200*log2(f/target)`. La longueur 44 donne environ 3.930158439 cents ; 45 donne environ -34.975614791 cents. Le signe indique la direction. Une tolérance symétrique porte sur la valeur absolue ; il faut évaluer le rapport produit, pas seulement la distance en échantillons.

Quelle longueur satisfait la tolérance stipulée de 5 cents ?

> **Réponse.** La longueur 44 réussit ; 45 échoue. C'est un critère construit, pas un seuil auditif mesuré.

## 3. Exercice 3

L'écart entre longueurs voisines dépend de leur position : `1200*log2((N+1)/N)` donne sa grandeur positive. Pour les retards courts, un échantillon peut déplacer davantage le rapport. Une politique suffisante à une cible ne certifie donc pas toute une plage.

La réussite à 1000 Hz certifie-t-elle toutes les cibles ?

> **Réponse.** Non. Il faut vérifier l'écart local et la position de chaque cible entre les entiers.

## 4. Exercice 4

Pour un témoin négatif, changez la cible en 1100 Hz en conservant l'horloge. La longueur proche est 40, donnant 1102.5 Hz. Il faut calculer l'erreur plutôt que conclure d'après l'étiquette d'arrondi. Elle vaut encore environ 3.930158439 cents : ce témoin réussit donc.

Quel contre-exemple plus fort doit remplacer ce témoin inefficace ?

> **Réponse.** Prenez 1090 Hz : la longueur proche 40 donne 1102.5 Hz et dépasse 5 cents.

## 5. Exercice 5

La source du moteur conservé distingue longueur entière et état fractionnaire. Gardez cette distinction dans toute recommandation. Un échec du modèle simple motive l'examen de la phase et de l'interpolation ; il n'identifie pas un défaut de la boucle complète. L'ancien échec du critère de décroissance reste distinct.

Quel résultat peut-on affirmer ?

> **Réponse.** Seulement les résultats calculés du modèle entier, avec horloge, cible et politique. Accordage réel et jugement musical restent non observés.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
