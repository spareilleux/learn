---
title: "13. Dépendances, builds et sécurité"
description: "Distinguer sélection reproductible des sources, analyse de vulnérabilités et artefact déployable."
sidebar:
  order: 13
---

## Objectif pédagogique

Distinguer sélection reproductible des sources, analyse de vulnérabilités et artefact déployable.

## Mécanismes et repères C#/Java

La [référence des modules](https://go.dev/ref/mod) décrit go.mod comme un élément de sélection des dépendances et de configuration du langage. Ce module déclare go 1.27.0 et n’importe que la bibliothèque standard. L’absence de dépendance externe ne dispense pas de maintenance de sécurité : compilateur et bibliothèque doivent aussi recevoir leurs mises à jour. Une somme de contrôle compare un contenu téléchargé à une empreinte attendue ; elle ne certifie ni sûreté, ni revue, ni absence de vulnérabilité.

La [commande go](https://pkg.go.dev/cmd/go) propose inspection du graphe, tests, vet et compilation pour des buts différents. go list -m all montre les modules retenus ; go mod verify contrôle leur contenu téléchargé ; go vet recherche des constructions suspectes ; go test exerce les contrats écrits. Chaque résultat répond à une autre question. Un test réussi ne prouve ni le compilateur de l’artefact ni son déploiement effectif. Associez version et provenance au résultat pertinent.

[runtime/debug.ReadBuildInfo](https://pkg.go.dev/runtime/debug#ReadBuildInfo) expose les informations de build du binaire exécuté. Notre commande affiche le chemin du module principal, déterministe ici. Elle évite de citer une version de compilateur ou une révision variable selon la machine. Un vrai enregistrement de livraison devrait contenir révision, compilateur, options, architecture et empreinte d’artefact. Les chemins peuvent révéler la machine de build ; envisagez trimpath comme option de livraison explicite, puis vérifiez son effet sans y voir une preuve automatique de reproductibilité bit à bit.

Les utilisateurs de NuGet C# et Maven Java connaissent déjà la distinction entre sélectionner, restaurer et publier. Les règles des modules Go diffèrent des hypothèses de priorité au plus proche ou de remplacement improvisé. Examinez replacements et configuration workspace : les dérogations locales changent parfois ce qui est construit. La [gestion des vulnérabilités Go](https://go.dev/security/vuln) explique l’analyse de base d’avis et de symboles accessibles par govulncheck. Cette unité ne l’installe ni ne l’exécute. Consignez une exécution réelle avant d’annoncer une analyse, et rappelez-vous qu’un résultat propre reste limité aux avis connus et au périmètre de l’outil. Gardez les secrets hors des commandes et examinez aussi l’artefact livré.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[provenance/build.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/provenance/build.go)

```go
package provenance

import "runtime/debug"

func MainModule() (string, bool) {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "", false
	}
	return info.Main.Path, true
}
```

[cmd/l13/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l13/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/provenance"
	"fmt"
)

func main() {
	path, ok := provenance.MainModule()
	if !ok {
		panic("build info unavailable")
	}
	fmt.Println(path)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l13
```

### Contrat de sortie attendu

```text
example.com/learn/go-advanced
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Une somme de contrôle vérifiée prouve-t-elle la sécurité du module ?

<details>
<summary>Solution complète</summary>

Non. Elle établit la conformité au contenu attendu. Examinez séparément sources et avis, exécutez l’outil adapté avec autorisation et consignez son périmètre ainsi que son résultat réel.

</details>

2. Pourquoi afficher le chemin du module plutôt qu’une version fixe du compilateur ?

<details>
<summary>Solution complète</summary>

Le chemin est stable pour l’exemple versionné et permet une comparaison exacte. Compilateur et révision réels doivent provenir de l’artefact ou de la commande exécutée, pas d’une configuration supposée.

</details>

## Sources primaires

- [Référence des modules](https://go.dev/ref/mod)
- [Commande Go](https://pkg.go.dev/cmd/go)
- [Gestion des vulnérabilités Go](https://go.dev/security/vuln)
- [runtime/debug.ReadBuildInfo](https://pkg.go.dev/runtime/debug#ReadBuildInfo)

[Leçon suivante](../14-service-capstone/) · [Journal d’apprentissage](../journal/)
