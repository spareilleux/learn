---
title: "Go avancé pour les développeurs C#/Java — Mission"
description: "Quatorze leçons pratiques sur la propriété des données, la concurrence, les frontières et un service HTTP testé."
sidebar:
  label: "Mission"
  order: 0
---

## Pourquoi approfondir Go ?

Connaître la syntaxe ne suffit pas pour relire un service qui possède ses tampons, coordonne ses workers et doit s’arrêter de façon prévisible. Ce cours développe ces compétences à travers des contrats concrets et de petits packages réutilisables. Il s’adresse aux développeurs de services C# ou Java ayant terminé [Go pour les développeurs C#/Java](../go-for-csharp-java/). Maîtrisez d’abord slices, interfaces, erreurs, goroutines, canaux, HTTP et tests élémentaires.

La cible est **Go 1.27**, et le module déclare `go 1.27.0`. Le compilateur de vérification fourni est Go 1.27.1 sous Windows/amd64. Les versions comptent : Go 1.27 prend en charge les méthodes génériques et stabilise JSON v2. Consultez les [notes officielles](https://go.dev/doc/go1.27) et la [spécification](https://go.dev/ref/spec) plutôt que les restrictions d’un ancien tutoriel.

## Ce que vous saurez faire

- Choisir les frontières de packages et expliciter la propriété des données.
- Expliquer la visibilité mémoire et borner le travail concurrent.
- Préserver les contrats d’erreur et distinguer nil typé et interface nil.
- Construire des frontières HTTP et de tramage bornées, testées localement.
- Concevoir propriétés de fuzzing et expériences de performance sans inventer de résultats.
- Intégrer validation, copie à l’admission, annulation et drain dans un service complet.

## Méthode de travail

Le code se trouve dans [code/go-advanced](https://github.com/spareilleux/learn/tree/main/code/go-advanced), module indépendant utilisant uniquement la bibliothèque standard. Chaque leçon reproduit les fichiers Go versionnés et une commande de `cmd/l01` à `cmd/l14`. Depuis la racine du dépôt, entrez dans `code/go-advanced` puis lancez la commande. Aucun conteneur, base, identifiant, service externe ou framework installé séparément n’est nécessaire.

Prédisez la sortie, expliquez pourquoi chaque observation est sûre, puis résolvez les deux exercices avant d’ouvrir leurs solutions. Les contrats stdout sont dans `examples.json`. Les tests couvrent propriété, identités d’erreur, arrêt d’itération, atomiques, annulation, tramage, HTTP et drain. Le projet final est un service borné en mémoire, pas un modèle de déploiement ni une file durable.

La syntaxe de la CLI Go est commune à Windows, Linux/WSL et macOS. L’instrumentation des courses demande des plateformes et un outillage C compatibles au-delà des tests ordinaires ; consultez sa documentation. Les outils de profilage doivent écouter sur boucle locale. Benchmarks, fuzzing actif, traces et analyse d’échappement exigent leurs propres conditions consignées ; une compilation réussie ne les prouve pas.

## Plan du cours

1. [Frontières des packages et des modules](01-package-and-module-boundaries/)
2. [Mémoire, analyse d’échappement et GC](02-memory-escape-and-gc/)
3. [Génériques et itérateurs](03-generics-and-iterators/)
4. [Contrats d’erreur et nil typé](04-error-contracts-and-typed-nil/)
5. [Modèle mémoire, synchronisation et atomiques](05-memory-model-sync-and-atomics/)
6. [Pipelines à concurrence bornée](06-bounded-pipelines/)
7. [Annulation, échéances et arrêt](07-cancellation-deadlines-and-shutdown/)
8. [Frontières HTTP en production](08-production-http/)
9. [Flux et délimitation des messages](09-streaming-and-framing/)
10. [Tests de courses, fuzzing et propriétés](10-race-fuzz-and-property-tests/)
11. [Benchmarks, pprof et trace](11-benchmarks-pprof-and-trace/)
12. [Réflexion, encodage et frontières](12-reflection-and-encoding/)
13. [Dépendances, builds et sécurité](13-dependencies-builds-and-security/)
14. [Un service intégré de tâches HTTP](14-service-capstone/)

## Ressources

- [Go](https://go.dev/doc/)
- [Go 1.27](https://go.dev/doc/go1.27)
- [Spécification](https://go.dev/ref/spec)
- [Modèle mémoire](https://go.dev/ref/mem)
- [Bibliothèque standard](https://pkg.go.dev/std)

## Journal et état des vérifications

Le [journal d’apprentissage](journal/) distingue rédaction, vérifications techniques réelles, mesures à effectuer et questions pédagogiques. Compiler et rejouer les exemples ne prouve pas qu’un apprenant humain termine le parcours.
