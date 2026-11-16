---
title: "1. Frontières des packages et des modules"
description: "Concevoir un petit package métier dont la propriété des données et les erreurs restent compréhensibles sans son adaptateur HTTP."
sidebar:
  order: 1
---

## Objectif pédagogique

Concevoir un petit package métier dont la propriété des données et les erreurs restent compréhensibles sans son adaptateur HTTP.

## Mécanismes et repères C#/Java

Un [module](https://go.dev/ref/mod) est un ensemble versionné de packages ; le package est l'unité de compilation, de visibilité et de dépendance. Un répertoire de fichiers Go ordinaires fournit généralement un seul package. Le chemin du module préfixe les chemins d'importation ; il ne crée pas un assembly réunissant tous les symboles exportés. Partez d'une responsabilité que l'appelant peut nommer : valeurs métier, tramage ou admission des tâches. Un package nommé helpers cache souvent le choix de dépendance au lieu de le résoudre.

Le package métier construit une tâche en vérifiant son nom et en copiant la slice reçue. Le type Job exporté permet aux adaptateurs d'échanger une valeur utile ; NewJob offre un chemin de construction validé. Comme les champs exportés permettent aussi une construction directe, le service valide de nouveau à sa véritable frontière d'admission. C'est voulu : une convention de constructeur ne garantit pas seule les invariants d'une struct exportée. Une bibliothèque plus stricte pourrait masquer les champs et fournir des accesseurs ; ici, la frontière du transport reste visible.

Un namespace C# et un package Java donnent des analogies de nommage utiles, sans correspondre exactement à un module Go. Une majuscule initiale exporte un identificateur ; aucun mot clé public n'accompagne chaque déclaration. La convention du répertoire internal limite les importateurs à l'arbre parent, et les cycles d'importation sont interdits. Préférez une petite interface chez son consommateur lorsqu'un remplacement est réellement nécessaire. Transformer tout type concret en interface transpose une habitude d'injection de dépendances sans réduire les dépendances.

Suivez le futur service vers l'intérieur : HTTP importe jobs, jobs importe domain, et domain n'importe que la bibliothèque standard. Le package métier ne doit pas importer HTTP pour choisir un code de statut. Une erreur métier imposerait alors une décision de transport à tous les appelants. Le versionnage relève du module : une rupture d'API publique après la version un demande normalement un nouveau chemin majeur. Ce module pédagogique ne promet aucune publication dans un registre.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[domain/job.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/domain/job.go)

```go
package domain

import (
	"errors"
	"fmt"
	"strings"
)

var ErrInvalid = errors.New("invalid job")

type Job struct {
	Name   string
	Values []int
}

func NewJob(name string, values []int) (Job, error) {
	if strings.TrimSpace(name) == "" {
		return Job{}, fmt.Errorf("name: %w", ErrInvalid)
	}
	return Job{Name: name, Values: append([]int(nil), values...)}, nil
}

func (j Job) Total() int {
	var total int
	for _, v := range j.Values {
		total += v
	}
	return total
}

func Clone(data []byte) []byte { return append([]byte(nil), data...) }

type ValidationError struct{ Field string }

func (e *ValidationError) Error() string {
	if e == nil {
		return "nil validation"
	}
	return "invalid " + e.Field
}
func Validate(name string) error {
	if name == "" {
		return &ValidationError{Field: "name"}
	}
	return nil
}
func TypedNil() error { var e *ValidationError; return e }
```

[cmd/l01/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l01/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	job, err := domain.NewJob("sum", []int{2, 3})
	if err != nil {
		panic(err)
	}
	fmt.Println(job.Name, job.Total())
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l01
```

### Contrat de sortie attendu

```text
sum 5
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. L’appelant modifie la slice originale après NewJob. Quelle propriété doit rester vraie, et pourquoi ?

<details>
<summary>Solution complète</summary>

Le total reste égal à cinq, car le tableau sous-jacent a été copié. TestOwnership modifie l’entrée puis vérifie le total observable ; copier seulement le descripteur de slice conserverait l’alias.

</details>

2. Où placer la règle qui traduit une tâche invalide en HTTP 400 ?

<details>
<summary>Solution complète</summary>

Dans l’adaptateur HTTP. La construction métier renvoie une identité d’erreur ; l’adaptateur choisit le statut, tandis qu’un autre consommateur pourrait choisir un code de sortie. Gardez les imports orientés vers le domaine.

</details>

## Sources primaires

- [Référence des modules Go](https://go.dev/ref/mod)
- [Noms des packages](https://go.dev/blog/package-names)

[Leçon suivante](../02-memory-escape-and-gc/) · [Journal d’apprentissage](../journal/)
