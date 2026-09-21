---
title: Patterns d’architecture — Mission
description: Comparer les architectures en couches, onion, clean, hexagonale et monolithe modulaire sur un même cas, avec des décisions réfutables.
sidebar:
  label: Mission
  order: 0
---

## Mission

Choisir une frontière parce qu'elle rend un changement précis plus sûr ou moins coûteux. Ce cours compare cinq patterns sans en faire un classement. Il complète le [cours d'architecture hexagonale](../hexagonal-architecture/) : quand des couches simples suffisent-elles, comment onion et clean recoupent-ils les ports et adaptateurs, et pourquoi le monolithe modulaire répond-il à une autre question ?

Notre cas fil rouge consiste à **enregistrer le plan de pratique d'un guitariste** : recevoir un plan nommé contenant trois positions d'accords, le valider contre une révision du catalogue, l'enregistrer et retourner un reçu. Les quatre leçons gardent ce même cas. C'est une conception pédagogique, pas une fonctionnalité implémentée dans un dépôt de l'écosystème.

## Prérequis et résultat attendu

Connaître les fonctions, les interfaces, une transaction de base de données et la différence entre processus et bibliothèque. Aucun compte, modèle payant ni service n'est nécessaire. Les exercices portent sur la conception et les scénarios de panne, avec corrigés ; cette première tranche ne contient ni application exécutable ni benchmark.

À la fin : une carte des dépendances, un contrat, une table de pannes et une décision d'une page qu'un autre développeur peut mettre à l'épreuve. Durée suggérée : deux heures, estimation d'étude et non mesure.

## Plan

| Leçon | Livrable |
|---|---|
| [1. Partir d'un changement](01-change-and-boundaries/) | Hypothèses, invariants et référence mesurable |
| [2. Cinq patterns, un cas](02-five-patterns/) | Comparaison des dépendances et responsabilités |
| [3. Quand la frontière traverse un processus](03-failure-and-distribution/) | Contrat de reprise, concurrence et récupération |
| [4. Évaluer une frontière dans l'écosystème](04-ecosystem-decisions/) | Expérience bornée et décision pour GA/Gaia/IX/Demerzel |
| [Journal](journal/) | Sources, preuves de validation et vérifications restantes |

## Sources primaires

- [Microsoft : architectures d'applications web](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures).
- [Cockburn : article original sur les ports et adaptateurs](https://alistair.cockburn.us/hexagonal-architecture).
- [Palermo : architecture onion, partie 1](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/).
- [Martin : clean architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html).
- [Spring Modulith : principes des modules](https://docs.spring.io/spring-modulith/reference/fundamentals.html) et [vérification structurelle](https://docs.spring.io/spring-modulith/reference/verification.html).
- [Amazon Builders' Library : API idempotentes](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).

Ces sources fixent le vocabulaire. La charge de travail, les seuils, les arbitrages et les expériences proposés ici sont des hypothèses pédagogiques, pas des résultats mesurés par ces sources.
