---
title: "3. Génériques et itérateurs"
description: "Implémenter une transformation générique paresseuse qui s’arrête avec son consommateur."
sidebar:
  order: 3
---

## Objectif pédagogique

Implémenter une transformation générique paresseuse qui s’arrête avec son consommateur.

## Mécanismes et repères C#/Java

Le package [iter](https://pkg.go.dev/iter) donne un nom aux formes des fonctions d’itération. Seq reçoit un callback yield ; renvoyer false signifie que le consommateur s’arrête. Map transforme les valeurs une par une et revient immédiatement quand yield renvoie false. Rien n’est matérialisé avant que le consommateur demande des valeurs. Dans la commande, slices.Collect choisit explicitement de construire le résultat. Séparer ces décisions laisse le choix entre parcours, arrêt anticipé et collecte complète.

Contrairement à un pipeline Stream Java, cet itérateur est une fonction ordinaire suivant une convention documentée. Contrairement à un bloc d’itération C#, son type public est une séquence à callback plutôt qu’un objet IEnumerator. Ces analogies expliquent la paresse sans remplacer le contrat de yield. Rappeler yield après son refus viole ce contrat. Créer une goroutine par itérateur serait inutile et ajouterait des questions d’annulation et de durée de vie absentes du callback synchrone.

Map possède deux paramètres de type parce que le résultat peut avoir un autre type que l’entrée. any indique qu’aucune opération n’est nécessaire sur la valeur, hormis son passage à la fonction fournie. Une contrainte comparable imposerait une capacité d’égalité inutilisée. Les contraintes avec des termes de type sous-jacent décrivent des ensembles de types admissibles ; ce ne sont pas des sommes de valeurs ordinaires à l’exécution. Distinguez interfaces comportementales et contraintes, même lorsque leur syntaxe se ressemble.

Le cours vise Go 1.27, dont les notes de version ajoutent les méthodes génériques. Les anciennes affirmations interdisant à toute méthode d’introduire des paramètres de type sont donc obsolètes ici. Les méthodes d’interface restent soumises à cette restriction. L’exemple utilise une fonction générique de package parce que la transformation n’a pas besoin d’état de receveur. Le test d’arrêt compte les transformations et interrompt le parcours après le premier résultat : une liste collectée ne détecterait pas un travail inutile après cet arrêt.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[collection/sequence.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/collection/sequence.go)

```go
package collection

import "iter"

func Map[A, B any](input iter.Seq[A], f func(A) B) iter.Seq[B] {
	return func(yield func(B) bool) {
		for value := range input {
			if !yield(f(value)) {
				return
			}
		}
	}
}

func Reverse(s string) string {
	r := []rune(s)
	for i, j := 0, len(r)-1; i < j; i, j = i+1, j-1 {
		r[i], r[j] = r[j], r[i]
	}
	return string(r)
}
```

[cmd/l03/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l03/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/collection"
	"fmt"
	"slices"
)

func main() {
	values := collection.Map(slices.Values([]int{1, 2, 3}), func(v int) int { return v * 2 })
	fmt.Println(slices.Collect(values))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l03
```

### Contrat de sortie attendu

```text
[2 4 6]
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Pourquoi Map doit-il revenir immédiatement quand yield renvoie false ?

<details>
<summary>Solution complète</summary>

Le consommateur a terminé son parcours. Revenir propage cette décision vers l’amont et évite callbacks, travail et rétention supplémentaires. TestMapStops attend exactement une transformation après un break immédiat.

</details>

2. La contrainte comparable améliorerait-elle la signature de Map ?

<details>
<summary>Solution complète</summary>

Aucune égalité n’est nécessaire : elle exclurait des entrées utiles sans prouver une propriété requise par le corps. Gardez any ; renforcez la contrainte uniquement pour une opération qui l’exige.

</details>

## Sources primaires

- [Notes de version Go 1.27](https://go.dev/doc/go1.27)
- [iter](https://pkg.go.dev/iter)
- [slices](https://pkg.go.dev/slices)

[Leçon suivante](../04-error-contracts-and-typed-nil/) · [Journal d’apprentissage](../journal/)
