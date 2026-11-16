---
title: "5. Modèle mémoire, synchronisation et atomiques"
description: "Expliquer la relation de synchronisation qui rend un résultat concurrent observable."
sidebar:
  order: 5
---

## Objectif pédagogique

Expliquer la relation de synchronisation qui rend un résultat concurrent observable.

## Mécanismes et repères C#/Java

Le [modèle mémoire Go](https://go.dev/ref/mem) précise quand une goroutine peut s’appuyer sur les écritures d’une autre. Un programme correct exige une relation de synchronisation, pas un récit plausible sur l’ordonnancement. Communication par canal, protocole de mutex, attente de fin et opération atomique peuvent établir la relation pertinente. Attendre une durée ne prouve ni qu’une écriture a eu lieu ni qu’elle est visible. Un programme sans course de données bénéficie de la cohérence séquentielle décrite par le modèle.

Counter conserve sa valeur dans un atomic.Int64. Add et Load opèrent sur le même emplacement atomique. La commande lance quatre goroutines de vingt-cinq incréments, puis attend leur fin avant d’afficher. Le total est stable parce que chaque incrément est atomique et que tous les producteurs ont terminé avant l’observation. Un incrément ordinaire combine lecture, calcul et écriture ; des mises à jour concurrentes peuvent s’écraser. Aucun programme volontairement racy avec un total inventé n’est fourni.

Le package [sync](https://pkg.go.dev/sync) propose plusieurs coordinations distinctes. WaitGroup suit la fin des tâches ; il ne protège pas automatiquement une map partagée par ces tâches. Mutex protège un invariant entre plusieurs valeurs si tous les accès pertinents respectent le même verrouillage. Les champs atomiques conviennent à des opérations précises sur des valeurs individuelles. Remplacer le mutex d’un solde et de son registre par deux atomiques indépendantes ne préserverait pas leur relation. Ne copiez jamais une valeur de synchronisation après utilisation.

Le lock C# et synchronized en Java permettent déjà de protéger des invariants. Ils ne permettent pas d’assimiler les atomiques Go à un champ ordinaire annoté volatile. Consultez le modèle Go pour la garantie exacte. Le pipeline montre une autre stratégie : les workers envoient des résultats indexés et une seule goroutine écrit la slice de sortie. Cela supprime les écritures concurrentes. Choisissez l’argument le plus simple que vous puissiez expliquer précisément, puis vérifiez que tous les accès y participent. Le détecteur de courses complète cet argument sur les chemins exécutés, sans prouver tous les chemins possibles.

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

[cmd/l05/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l05/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/pipeline"
	"fmt"
	"sync"
)

func main() {
	var c pipeline.Counter
	var group sync.WaitGroup
	for range 4 {
		group.Go(func() {
			for range 25 {
				c.Add()
			}
		})
	}
	group.Wait()
	fmt.Println(c.Value())
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l05
```

### Contrat de sortie attendu

```text
100
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. WaitGroup suffit-il à protéger un incrément partagé ?

<details>
<summary>Solution complète</summary>

Non. Il coordonne la fin, pas la lecture et l’écriture de l’incrément. Utilisez Counter atomique ou un mutex couvrant chaque accès, puis attendez avant d’interpréter le total final.

</details>

2. Deux atomiques préservent-elles automatiquement un invariant entre champs ?

<details>
<summary>Solution complète</summary>

Non. Un lecteur peut observer une combinaison de mises à jour distinctes. Protégez l’état lié par un même mutex ou publiez un instantané immuable via un point de synchronisation ; partez de l’invariant réel.

</details>

## Sources primaires

- [Modèle mémoire Go](https://go.dev/ref/mem)
- [sync](https://pkg.go.dev/sync)
- [sync/atomic](https://pkg.go.dev/sync/atomic)

[Leçon suivante](../06-bounded-pipelines/) · [Journal d’apprentissage](../journal/)
