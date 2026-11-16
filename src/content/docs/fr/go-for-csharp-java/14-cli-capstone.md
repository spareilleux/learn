---
title: "14. Projet final en ligne de commande"
description: "Assembler modules, données typées, entrée JSON, filtrage et rapport testé dans une commande utilisable."
sidebar:
  order: 14
---

## Objectifs

Suivre toute la commande, séparer diagnostics et rapport et vérifier de vraies frontières d’entrée et de sortie.

## La plus petite application complète

Le projet final produit un rapport de séances d’étude. Sans argument, il utilise les données du cours. min sélectionne les séances atteignant un seuil inclusif. file accepte un nom de fichier JSON, tandis qu’un tiret seul désigne l’entrée standard. Le rapport conserve l’ordre reçu, affiche noms et durées sélectionnés, puis leur total. C’est une véritable commande locale, pas quatorze démonstrations réunies seulement par leur texte.

Le petit main délègue à cli.Run avec arguments et flux du processus. [os.Exit](https://pkg.go.dev/os#Exit) appartient à cette frontière. Il termine sans exécuter les appels différés de main ; le nettoyage reste donc dans Run, dont le retour normal exécute d’abord ses defers. Cette séparation permet aussi de tester l’application sans arrêter le processus de test. Run n’est pas un point d’entrée réservé aux tests : main utilise exactement cette fonction.

## Suivre les dépendances dans l’ordre

Le [package flag](https://pkg.go.dev/flag) analyse min et file avec un [`FlagSet`](https://pkg.go.dev/flag#FlagSet) dédié. Syntaxe invalide, minimum négatif et arguments positionnels inattendus donnent le résultat d’erreur d’utilisation. L’aide réussit. L’acquisition choisit ensuite les données intégrées, le [io.Reader](https://pkg.go.dev/io#Reader) fourni ou un fichier ouvert avec [os.Open](https://pkg.go.dev/os#Open). Seuls les fichiers ouverts par la fonction sont fermés ; l’entrée standard ne lui appartient pas.

study.Load établit encodage, forme JSON et validité métier. study.Select matérialise les valeurs retenues et study.Total les additionne. Le rapport va dans out, les diagnostics dans errOut. Chaque écriture de sortie est contrôlée : un destinataire défaillant ne produit pas une fausse réussite. Run renvoie un pour un échec d’entrée ou de sortie, deux pour les arguments et zéro en cas de succès. Avec go run, distinguez le statut du lanceur Go de celui renvoyé par l’application.

## Une frontière testée couvrant l’application

Les tests fournissent du vrai JSON et capturent les deux flux. Ils couvrent données intégrées, filtre, entrée standard, tableau vide, JSON malformé, records invalides, options invalides et arguments inattendus. Un fichier temporaire vérifie l’acquisition par chemin réel. Un écrivain défaillant vérifie le résultat d’une erreur de sortie. Le manifeste exerce aussi l’exécutable et sa sortie exacte par défaut. Ces contrôles traversent analyse, fonctions métier et formatage sans service extérieur.

En C# ou Java, on pourrait attendre un conteneur d’injection, un framework de commandes ou une classe de service. Cette application n’en a pas besoin pour avoir une frontière nette : ses dépendances sont des flux et fonctions typées, ses effets restent dans un package. Introduisez un framework si une exigence concrète le justifie. Une application petite peut être testée rigoureusement ; sa composition est précisément ce qu’observent les tests d’intégration.

## Limiter honnêtement la promesse

La commande charge complètement un petit journal en mémoire. Elle ne modifie pas de fichiers, ne fusionne pas les noms identiques et ne normalise pas Unicode. Elle ne définit ni format comptable durable ni politique de dépassement pour des totaux arbitraires. Ce sont des limites délibérées de l’application pédagogique. Le gestionnaire HTTP est un autre adaptateur du même cœur ; ajouter un appel réseau au CLI n’améliorerait pas son contrat actuel.

Retrouvez le parcours : imports du module, durées typées, ordre des slices, causes d’erreurs, defer pour les fichiers, validation JSON et tests de composition. Les goroutines servent lorsqu’une durée de vie l’exige, mais l’addition locale reste séquentielle. Le cours avancé peut maintenant s’appuyer sur ces choix concrets plutôt que sur une liste de syntaxe mémorisée.

## Exemple détaillé

Source complète: [`cmd/l14/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l14/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/cli"
	"os"
)

func main() { os.Exit(cli.Run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr)) }
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l14
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
types: 15 min
go: 25 min
total: 40 min
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Comment garder uniquement la séance atteignant vingt minutes ?

<details>
<summary>Solution 1</summary>

Lancez go run ./cmd/l14 -min 20 depuis le module. Select conserve go, dont la durée vaut vingt-cinq ; le rapport contient cette séance et un total de vingt-cinq minutes. Le cas d’intégration du filtre vérifie ce comportement. Il n’est pas nécessaire de dupliquer lecture ou filtrage dans main.

</details>

2. Un fichier JSON contient une durée négative : que se passe-t-il ?

<details>
<summary>Solution 2</summary>

Run ouvre le fichier et programme sa fermeture ; Load rejette ensuite le record et enveloppe ErrInvalid. Run écrit un diagnostic dans errOut, renvoie un et ferme le fichier au passage des defers. out ne reçoit aucun rapport. Le test du record invalide vérifie ce chemin sans imposer la formulation exacte du diagnostic.

</details>

## Sources officielles

- [flag package](https://pkg.go.dev/flag)
- [io.Reader](https://pkg.go.dev/io#Reader)
- [os.Open](https://pkg.go.dev/os#Open)
- [os.Exit](https://pkg.go.dev/os#Exit)

[Poursuivre avec Go avancé](../../go-advanced/) · [Journal](../journal/)
