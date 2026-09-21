---
title: 4 — Évaluer une frontière dans l'écosystème
description: Transformer les idées architecturales en expériences bornées et fixées à une révision pour GA, Gaia, IX et Demerzel, sans prétendre à leur adoption.
sidebar:
  order: 4
---

## Des preuves avant une migration

Le plan de pratique est fictif. Les dépôts ci-dessous existent, mais leur description architecturale ne prouve pas que chaque dépendance la respecte. Les instantanés des README liés ont été consultés ; aucune application de l'écosystème n'a été compilée, migrée ni benchmarkée ici.

| Dépôt et contexte documenté | Frontière candidate à étudier | Preuves nécessaires avant adoption |
|---|---|---|
| [GA](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/README.md) : cinq couches, domaine musical et hôtes applicatifs | Une opération indépendante de l'hôte partagée par deux points d'entrée existants | Appelants exacts, cas de parité entrée/sortie, références entre couches et routes de déploiement |
| [Gaia](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/README.md) : coordination et workflows de preuves | Séparer décision de transition et adaptateur d'effet externe | Cas de replay, propriété des claims, doublons et vérification de l'autorité à la frontière d'effet |
| [IX](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/README.md) : algorithmes et outils Rust | Entrées/résultats stables ; analyse spécifique à l'outil à l'extérieur | Équivalence numérique, cas versionnés, allocations et latence sur une charge fixe |
| [Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/c72fb746116346ce1991a4f108cd12f5e012e3fb/README.md) : gouvernance | Séparer validation des preuves et évaluation des politiques de la publication | Compatibilité de schéma, provenance, tests de refus de permission et autorité explicite de publication |

Ce sont des **expériences candidates**, pas des refactorings vérifiés ni l'affirmation qu'un dépôt a adopté clean ou hexagonal. Les révisions viennent des cours existants et du fichier de verrouillage Streeling ; ce sont des références d'étude, pas des affirmations sur la production actuelle.

## Une décision GA bornée, corrigée

**Problème :** deux points d'entrée pourraient coder différemment la même règle. **Hypothèse :** ils visent la même sémantique ; le vérifier avant de les unifier. **Candidate :** exposer une opération applicative commune en préservant les règles de couches. Le comportement IA reste dans sa couche autorisée ; « tout mettre dans le cœur » n'est pas un plan de migration.

**Meilleur contre-argument :** les clients diffèrent intentionnellement pour le streaming, l'historique ou les erreurs. **Coûts cachés :** conversion des modèles, annulation, diagnostics, responsabilité du déploiement et compatibilité. **Alternative simple :** partager la règle pure et garder les orchestrations distinctes.

**Sonde :** fixer un commit, choisir dix entrées explicites couvrant succès, entrée invalide, refus de permission et annulation, puis exercer les deux chemins existants. Dix est un budget proposé, pas un nombre de tests réussis. Extraire ensuite la plus petite opération commune dans une candidate isolée et rejouer les mêmes cas.

**Acceptation :** aucun changement observable inexpliqué, aucune nouvelle référence interdite et exécution de la règle commune sans hôte web. **Réfutation :** une entrée supposée commune exige des sémantiques métier incompatibles. **Rejet :** abandonner l'unification si leur préservation ajoute plus de branches conditionnelles que le partage de règle existant. **Réexamen :** un nouvel appelant ou un défaut de parité reproduit change les preuves.

## Distinguer autorité et architecture

Pour Gaia ou Demerzel, une interface propre n'autorise ni push, ni merge, ni publication. Séparer résultat de décision et effet, puis revérifier l'autorité là où l'effet se produit. Un adaptateur factice prouve seulement comment l'appelant traite sa réponse simulée ; il ne prouve ni permissions ni concurrence ni pannes du fournisseur réel.

Les contrats d'artefacts entre dépôts portent aussi des obligations de version, d'identité et de provenance. Avant de changer un champ, identifier producteur et consommateurs, puis fixer leurs versions de schéma. Un nom d'interface commun ne prouve pas l'équivalence de ces contrats.

## Exercice — Écrire une décision qu'on peut rejeter

Choisir une ligne. Écrire six phrases : problème observé, hypothèse, candidate, objection principale, acceptation mesurable, déclencheur de rejet/réexamen. Préciser les preuves manquantes.

<details>
<summary>Corrigé : IX</summary>

« Nous soupçonnons que l'analyse de l'outil et le calcul numérique changent ensemble ; ce n'est pas encore mesuré. Nous supposons une frontière entrée/résultat déterministe et stable. Nous exposerons un calcul existant derrière cette frontière en gardant l'analyse côté outil. L'objection est une copie supplémentaire sur un chemin critique. Accepter uniquement si les cas à graine fixe restent dans la tolérance existante et si allocations/latence mesurées respectent un budget fixé avant exécution. Rejeter si la conversion domine ou si les sémantiques divergent ; réexaminer quand un second appelant apparaît. » Il manque l'implémentation exacte, la charge de référence, la tolérance, les mesures et l'inventaire des appelants. C'est une proposition testable, pas une conception adoptée par IX.

</details>

Le [journal](../journal/) distingue la validation du cours terminée des expériences restant à exécuter.
