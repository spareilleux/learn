---
module_id: gaa-008-schedule-retrieval-with-an-explicit-due-rule
department: guitar-alchemist-academy
course: "Programmer le rappel avec une règle d’échéance explicite"
level: intermediate
prerequisites: ["gaa-007-turn-a-voicing-result-into-a-practice-item"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Programmer le rappel avec une règle d’échéance explicite

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Un exercice GA existe, mais cela ne dit pas quand la file doit le représenter. Ce cours définit une petite règle de planification dont entrées et résultats manquants restent visibles. C'est une politique construite, sans prétention d'optimiser la mémoire. Les échéances calculées et le rappel différé réel doivent garder des traces distinctes.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gaa-007-turn-a-voicing-result-into-a-practice-item](../../guitar-alchemist-academy/en/gaa-007-turn-a-voicing-result-into-a-practice-item.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Paquet de données construites](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

Utilisons des jours entiers. Un item revu au jour 10, avec un intervalle de 4 jours, arrive à échéance au jour 14. La comparaison est inclusive : l'item est dû dès ce jour. On résout ainsi l'ambiguïté de frontière avant d'évaluer la file.

L'item est-il dû au jour 14, puis au jour 13 ?

> **Réponse.** Il est dû au jour 14 et ne l'est pas au jour 13 selon la règle inclusive.

## 2. Exercice 2

Stipulons une tentative réelle réussie au jour 14. La règle proposée double l'intervalle, plafonné à 16 jours. Le nouvel intervalle vaut 8 et la prochaine échéance 22. Ces nombres découlent de la politique choisie ; ils n'estiment pas la probabilité de mémoriser un accord.

Calculez la branche de réussite.

> **Réponse.** L'intervalle vaut 8 jours et l'échéance est au jour 22. Aucun des nombres ne fournit une probabilité de rappel.

## 3. Exercice 3

Pour la branche d'échec, gardons le jour mais stipulons une réponse incorrecte. L'intervalle revient à 1 jour ; l'échéance devient 15. Conservez réponse et assistance autorisée ayant produit ce résultat. Une solution copiée après révélation n'est pas automatiquement un rappel sans aide.

Calculez la branche d'échec et nommez les traces nécessaires.

> **Réponse.** L'échéance est au jour 15 ; conservez réponse avant révélation, assistance et règle de notation.

## 4. Exercice 4

Une tentative absente n'est ni réussie ni échouée dans cette règle binaire. Gardez l'item en retard ou indéterminé selon une politique distincte, sans inventer un résultat. Ce témoin sépare temps écoulé et rappel observé. Ouvrir une page ne fournit pas la réponse manquante.

Quelle nouvelle échéance déduit-on d'un résultat absent ?

> **Réponse.** Aucune nouvelle échéance n'est déterminée. Conservez l'absence de résultat sans choisir une branche.

## 5. Exercice 5

Le paquet conservé vérifie coordonnées et indices des items ; il ne contient aucune réussite observée pour notre exemple. Comparez une table manuelle d'échéances à toute file automatique avant d'introduire une abstraction. Une évaluation future exige des réponses différées et une comparaison justifiée, au-delà du respect de la règle.

Que prouve une arithmétique correcte des échéances ?

> **Réponse.** Seulement la conformité à la politique. Bénéfice pédagogique, intervalles optimaux et acceptation restent non observés.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
