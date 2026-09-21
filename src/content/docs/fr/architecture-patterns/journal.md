---
title: Patterns d’architecture — Journal
description: Preuves, provenance des sources et expériences non vérifiées du cours sur les patterns d'architecture.
sidebar:
  label: Journal
  order: 5
---

## Progression

- [x] Définir un cas unique et quatre leçons ciblées.
- [x] Comparer les cinq patterns, leurs hypothèses et critères de rejet.
- [x] Fournir les exercices corrigés en anglais, français et espagnol.
- [x] Fixer les lectures de l'écosystème sans prétendre à une adoption.
- [ ] Exécuter une expérience de changement de dépendance dans un dépôt de l'écosystème.
- [ ] Exécuter les cas de concurrence et de récupération sur un vrai adaptateur de persistance.

## 2026-09-21 — Une comparaison aux preuves bornées

Révision de référence du site : `c05b01f35c2a407e8b637db6f6c1bb5015c518d3`. La navigation Architecture et conception existante a été réutilisée. Aucun autre cours n'a été modifié.

Sources primaires consultées : [couches](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures), [onion](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/), [clean](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html), [hexagonal](https://alistair.cockburn.us/hexagonal-architecture), [principes des modules](https://docs.spring.io/spring-modulith/reference/fundamentals.html), [vérification des modules](https://docs.spring.io/spring-modulith/reference/verification.html) et [idempotence](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). La page Microsoft a été accessible via son URL anglaise. Les README de la [leçon 4](../04-ecosystem-decisions/) étaient accessibles aux révisions fixées.

Le catalogue, la règle des trois positions, le budget de cas et les seuils sont des hypothèses pédagogiques de l'auteur. Les corrigés sont des raisonnements, pas des sorties capturées. Aucune mesure de débit, allocation, concurrence ou conformité architecturale n'est revendiquée. Pas encore de table QA ou Expériences : aucun défaut logiciel ni expérience architecturale mesurée n'a été produit.

Validation du site sous Windows, Node.js v24.12.0 et npm 11.7.0 :

- `npm ci --no-audit --no-fund` : dépendances verrouillées installées avec succès.
- `npm run build` : réussi ; 1 138 pages générées. Les leçons de musique existantes ont signalé une coloration `play` non prise en charge ; ces fichiers n'ont pas été modifiés.
- Vérifications du cours : 18 pages, six noms identiques par langue, mêmes ordres de navigation et URL, 12 corrigés repliables aux balises équilibrées.
- Les 11 URL externes uniques ont retourné HTTP 200 ; les liens relatifs pointent vers des sources et du HTML généré existants.
- Le HTML contient les liens du cours sur les trois accueils et menus latéraux ; les 18 routes existent.
- `git diff --check` : réussi.

Ce sont des vérifications du site et du contenu, pas des expériences architecturales. Le rendu documentaire ne valide pas les conceptions applicatives proposées.

## À vérifier

- Rendu dans le navigateur et navigation dans les trois langues.
- Compilations Linux/macOS ; aucune exécution multiplateforme dans cette tranche.
- Dépendances réelles, parité des appelants et permissions avant tout changement de l'écosystème.
- Idempotence, unicité concurrente, fraîcheur du catalogue et récupération après crash dans une implémentation exécutable.

## Questions ouvertes

- Quelle règle réellement dupliquée justifie la première extraction ?
- Quelle garantie métier de fraîcheur doit porter la révision enregistrée ?
- Un module nécessite-t-il aujourd'hui une livraison ou une mise à l'échelle indépendante ?
