---
title: "Go pour développeurs C# et Java — Mission"
description: "Une introduction complète à Go 1.27 autour d’un CLI de journal d’étude testé."
sidebar:
  label: Mission
  order: 0
---

## Pourquoi apprendre Go

Vous savez déjà modéliser des données, traiter les échecs et construire des applications en C# ou Java. Go conserve ces objectifs mais change les mécanismes : valeurs copiées, descripteurs de slices, interfaces implicites, erreurs explicites, goroutines et petit outillage standard. Ce cours relie concrètement vos compétences à ces choix. Son objectif est de prévoir correctement le comportement d’un programme Go et de livrer une commande compréhensible, plutôt que de traduire mécaniquement la syntaxe des classes.

## Prérequis

Soyez à l’aise avec fonctions, collections, interfaces, génériques, JSON élémentaire et tests unitaires en C# ou Java. Il faut un terminal, un éditeur et la [chaîne d’outils Go](https://go.dev/doc/install). Le langage cible est Go 1.27 ; le coordinateur dispose de Go 1.27.1 sous Windows/amd64. Les exemples utilisent uniquement la bibliothèque standard : aucun framework, compte ou service externe n’est à configurer.

## Ce que vous construirez

Le CLI lit un tableau JSON de séances, valide noms et durées, filtre selon un minimum de minutes et affiche un rapport ordonné. Au dernier chapitre, l’exécutable assemble le même package study utilisé pendant le cours. Un petit gestionnaire HTTP offre un second adaptateur du cœur. Les exercices réseau se déroulent en mémoire, sans service public. Vous apprendrez les limites de la copie, la propriété des ressources, la conservation des causes d’erreurs et les tests de la frontière applicative.

## Plan du cours

| # | Leçon | Étape vers le projet |
|---|---|---|
| 1 | [Chaîne d’outils et modules](01-toolchain-and-modules/) | Un package local partagé |
| 2 | [Valeurs, types et chaînes](02-values-types-and-strings/) | Des durées et noms typés |
| 3 | [Contrôle de flux et fonctions](03-control-flow-and-functions/) | Sélection et totaux |
| 4 | [Tableaux et slices](04-arrays-and-slices/) | Propriété explicite des collections |
| 5 | [Maps et structures](05-maps-and-structs/) | Enregistrements nommés et agrégation |
| 6 | [Pointeurs et méthodes](06-pointers-and-methods/) | Modification contrôlée |
| 7 | [Interfaces et composition](07-interfaces-and-composition/) | Petits contrats de comportement |
| 8 | [Erreurs, defer et ressources](08-errors-defer-and-resources/) | Diagnostics d’entrée utiles |
| 9 | [Fichiers, JSON et Unicode](09-files-json-and-unicode/) | Enregistrements JSON validés |
| 10 | [Génériques et collections](10-generics-and-collections/) | Transformations typées |
| 11 | [Goroutines et canaux](11-goroutines-and-channels/) | Durées de travail bornées |
| 12 | [HTTP et context](12-http-and-context/) | Frontière HTTP testable |
| 13 | [Tests](13-testing/) | Vérifications métier et intégration |
| 14 | [Projet final en ligne de commande](14-cli-capstone/) | Commande de rapport fonctionnelle |

## Comment travailler

Suivez les leçons dans l’ordre. Prévoyez la sortie avant chaque exécution et séparez vos expériences des données fixes. Chaque chapitre contient deux exercices corrigés ; essayez avant d’ouvrir les solutions. Code, commandes et sorties sont identiques dans les trois langues. Les commandes communes aux plateformes partent de la racine du dépôt puis entrent dans code/go-for-csharp-java. Les sources complètes figurent dans [code/go-for-csharp-java](https://github.com/spareilleux/learn/tree/main/code/go-for-csharp-java).

## Vérification et limites

Le module comprend quatorze commandes, un manifeste de sorties exactes examples.json, des tests sémantiques, des tests d’intégration CLI, des tests HTTP et une cible de fuzzing du lecteur. Les tests, vet, le formatage, les quatorze sorties exactes et un essai borné de fuzzing du lecteur ont réussi avec Go 1.27.1 sous Windows/amd64. Les extraits et les traductions ont été contrôlés contre le module terminé. Le [journal](journal/) conserve les conditions, les corrections et les preuves distinctes concernant la CI hébergée, la publication et les essais par des apprenants. Le projet final lit un journal local ; il ne fournit pas de garanties comptables ni de flux durables.

Poursuivez avec [Go avancé](../go-advanced/) après le projet final.

## Sources primaires

- [Go 1.27](https://go.dev/doc/go1.27)
- [Spécification du langage](https://go.dev/ref/spec)
- [Bibliothèque standard](https://pkg.go.dev/std)
- [Tutoriel sur les modules](https://go.dev/doc/tutorial/create-module)
