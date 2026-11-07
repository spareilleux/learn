---
title: "11. Benchmarks, pprof et trace"
description: "Choisir une mesure répondant à une question de performance sans inventer de chronométrage."
sidebar:
  order: 11
---

## Objectif pédagogique

Choisir une mesure répondant à une question de performance sans inventer de chronométrage.

## Mécanismes et repères C#/Java

Un [benchmark](https://pkg.go.dev/testing#hdr-Benchmarks) est une expérience sur une opération et une distribution d’entrées précises. BenchmarkSum construit une slice fixe avant la boucle chronométrée, demande les allocations et conserve le résultat dans une variable de package. Cette variable rend le résultat observable. La boucle mesure la somme plutôt que la construction répétée de son entrée. Ce microbenchmark ne mesure ni débit HTTP, ni latence d’annulation, ni capacité globale du service.

La commande go test -run=^$ -bench=BenchmarkSum -benchmem ./metrics demande une mesure. Consignez compilateur, système, CPU, révision, options et taille d’entrée avec le résultat. Comparez plusieurs exécutions plutôt qu’un nombre flatteur. Aucun ns/op, bytes/op ou allocations/op n’est cité ici : aucune mesure de cette unité n’a été effectuée par son auteur. Une modification peut réduire les allocations tout en retenant davantage de mémoire. Reliez donc chaque compteur à la question étudiée.

Le guide [Diagnostics](https://go.dev/doc/diagnostics) distingue profils et traces. Un profil CPU échantillonne où passe le temps ; un profil mémoire aide à étudier allocations ou rétention ; une trace expose ordonnancement, blocages et événements du runtime dans le temps. Créez un fichier local avec go test -run=^$ -bench=BenchmarkSum -cpuprofile=cpu.out ./metrics, puis ouvrez go tool pprof -http=127.0.0.1:0 cpu.out. Gardez l’écoute sur boucle locale. Les profils peuvent contenir chemins et données de charge sensibles : appliquez la politique de données de l’application.

Les habitudes de profilage C# et Java se transfèrent au niveau de la démarche : établir une base, localiser le coût, changer une hypothèse, mesurer de nouveau. Les signaux et commandes du runtime Go diffèrent. Go 1.27 ajoute le profil goroutineleak à runtime/pprof ; il ne détecte pas toute fuite logique ou tout worker bloqué. Signaux de fin et tests de drain restent nécessaires. Traces, profils et détection de courses ajoutent aussi un surcoût : ne comparez pas une exécution instrumentée à une base sans instrumentation en attribuant tout écart au code.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[metrics/sum_test.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/metrics/sum_test.go)

```go
package metrics

import "testing"

var sink int

func TestSum(t *testing.T) {
	if Sum([]int{2, 3, 4}) != 9 {
		t.Fatal("sum")
	}
}
func BenchmarkSum(b *testing.B) {
	values := make([]int, 1024)
	for i := range values {
		values[i] = i
	}
	b.ReportAllocs()
	for b.Loop() {
		sink = Sum(values)
	}
}
```

[cmd/l11/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l11/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/metrics"
	"fmt"
)

func main() { fmt.Println(metrics.Sum([]int{1, 2, 3})) }
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l11
```

### Contrat de sortie attendu

```text
6
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Pourquoi préparer l’entrée hors de la boucle chronométrée ?

<details>
<summary>Solution complète</summary>

La question porte sur la somme d’une slice existante. Inclure sa construction mesurerait une autre opération. Si elle appartient à la charge réelle, écrivez un benchmark distinct qui l’inclut délibérément.

</details>

2. Un profil goroutineleak sans anomalie remplace-t-il les tests d’arrêt ?

<details>
<summary>Solution complète</summary>

Non. Le profil a un périmètre de détection propre au runtime ; les tests affirment les contrats applicatifs de fin. Gardez attentes et tests d’annulation, puis utilisez les profils sur une charge représentative.

</details>

## Sources primaires

- [Benchmarks avec testing](https://pkg.go.dev/testing#hdr-Benchmarks)
- [Diagnostics](https://go.dev/doc/diagnostics)
- [runtime/pprof](https://pkg.go.dev/runtime/pprof)
- [runtime/trace](https://pkg.go.dev/runtime/trace)

[Leçon suivante](../12-reflection-and-encoding/) · [Journal d’apprentissage](../journal/)
