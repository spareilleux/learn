---
title: "6. Pipelines à concurrence bornée"
description: "Borner le travail concurrent et rendre annulable chaque opération susceptible de bloquer."
sidebar:
  order: 6
---

## Objectif pédagogique

Borner le travail concurrent et rendre annulable chaque opération susceptible de bloquer.

## Mécanismes et repères C#/Java

Un [pipeline](https://go.dev/blog/pipelines) exige une règle de propriété et une règle de terminaison à chaque étape. Squares possède un producteur, un nombre fixe de workers et un collecteur. Seul le producteur ferme jobs. Une autre goroutine attend tous les workers puis ferme results. Le collecteur parcourt results jusqu’à cette fermeture. Les workers ne ferment jamais un canal partagé dont ils n’ont pas la propriété exclusive. Ces décisions comptent davantage qu’un joli diagramme de flèches.

Le nombre de workers est ramené à au moins un et au plus le nombre d’entrées. Une entrée vide n’en crée donc aucun. Les canaux sans tampon imposent un transfert entre étapes sans accumuler de file illimitée. La fonction alloue néanmoins une sortie proportionnelle à l’entrée : borner la concurrence ne rend pas toute la mémoire constante. Pour un flux sans fin, l’API devrait fournir des résultats en flux ou limiter explicitement l’entrée. Ici, une slice finie produit une sortie dans le même ordre d’index.

Chaque envoi du producteur et des workers sélectionne aussi l’annulation du [context](https://pkg.go.dev/context). Un consommateur qui abandonne un flux sans annuler peut bloquer un émetteur amont ; cette fonction évite ce risque public en collectant jusqu’à la fin des workers. L’annulation est coopérative. Si une communication et l’annulation sont prêtes, select peut choisir l’une ou l’autre : quelques étapes bornées supplémentaires restent possibles. La vérification finale du contexte empêche de présenter une sortie partielle comme complète.

Les requêtes parallèles C# et les streams parallèles Java cachent l’ordonnancement derrière des opérateurs. Une transposition lançant une goroutine par entrée ne préserve pourtant aucun budget de concurrence. Définissez ce budget indépendamment de la taille d’entrée. Distinguez aussi ordre des résultats et ordre de fin : les index permettent un ordonnancement quelconque et reconstruisent une sortie déterministe. Testez plusieurs nombres de workers, l’entrée vide et l’entrée déjà annulée. Les entiers machine peuvent déborder : le calcul illustre les durées de vie, pas une arithmétique financière vérifiée.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[pipeline/pipeline.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/pipeline/pipeline.go)

```go
package pipeline

import (
	"context"
	"sync"
	"sync/atomic"
)

type Counter struct{ value atomic.Int64 }

func (c *Counter) Add()         { c.value.Add(1) }
func (c *Counter) Value() int64 { return c.value.Load() }

func Squares(ctx context.Context, input []int, workers int) ([]int, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if workers < 1 {
		workers = 1
	}
	if workers > len(input) {
		workers = len(input)
	}
	type item struct{ index, value int }
	jobs := make(chan item)
	results := make(chan item)
	var group sync.WaitGroup
	group.Add(workers)
	for range workers {
		go func() {
			defer group.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case job, ok := <-jobs:
					if !ok {
						return
					}
					job.value *= job.value
					select {
					case results <- job:
					case <-ctx.Done():
						return
					}
				}
			}
		}()
	}
	go func() {
		defer close(jobs)
		for i, v := range input {
			select {
			case jobs <- item{i, v}:
			case <-ctx.Done():
				return
			}
		}
	}()
	go func() { group.Wait(); close(results) }()
	output := make([]int, len(input))
	for result := range results {
		output[result.index] = result.value
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	return output, nil
}

func Wait(ctx context.Context, started chan<- struct{}) error {
	close(started)
	<-ctx.Done()
	return context.Cause(ctx)
}
```

[cmd/l06/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l06/main.go)

```go
package main

import (
	"context"
	"example.com/learn/go-advanced/pipeline"
	"fmt"
)

func main() {
	values, err := pipeline.Squares(context.Background(), []int{1, 2, 3}, 2)
	if err != nil {
		panic(err)
	}
	fmt.Println(values)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l06
```

### Contrat de sortie attendu

```text
[1 4 9]
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Qui peut fermer results, et à quel moment ?

<details>
<summary>Solution complète</summary>

Le coordinateur le ferme après confirmation par WaitGroup que tous les workers ont cessé d’émettre. Une fermeture par un worker pourrait faire envoyer un autre sur un canal fermé. Le producteur ne possède que jobs.

</details>

2. Un nombre fixe de workers garantit-il une mémoire constante ?

<details>
<summary>Solution complète</summary>

Non. Les slices d’entrée et de sortie augmentent avec le nombre de valeurs. Pour une source illimitée, exposez une consommation en flux avec annulation ou une limite documentée au lieu de tout collecter.

</details>

## Sources primaires

- [Pipelines et annulation](https://go.dev/blog/pipelines)
- [context](https://pkg.go.dev/context)

[Leçon suivante](../07-cancellation-deadlines-and-shutdown/) · [Journal d’apprentissage](../journal/)
