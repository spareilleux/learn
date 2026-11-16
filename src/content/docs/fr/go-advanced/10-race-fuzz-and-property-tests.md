---
title: "10. Tests de courses, fuzzing et propriétés"
description: "Transformer une loi comportementale en cible de fuzzing exécutant ses graines sans exagérer sa couverture."
sidebar:
  order: 10
---

## Objectif pédagogique

Transformer une loi comportementale en cible de fuzzing exécutant ses graines sans exagérer sa couverture.

## Mécanismes et repères C#/Java

Le [détecteur de courses](https://go.dev/doc/articles/race_detector) instrumente les accès du programme réellement exécuté. Une exécution réussie signifie qu’aucune course n’a été observée sur ces chemins ; elle ne prouve pas statiquement tous les ordonnancements. Exercez les chemins concurrents pertinents, annulation et drain compris, plutôt qu’un seul succès séquentiel. Lancez go test -race ./... dans un environnement compatible et consignez le résultat réel. Une course qui affiche par chance la valeur attendue reste incorrecte.

Le [tutoriel de fuzzing](https://go.dev/doc/tutorial/fuzz) distingue l’exécution des graines de la génération active. go test ordinaire exécute le corpus initial. Une commande avec -fuzz cherche d’autres entrées et peut conserver des échecs minimisés. FuzzReverse fournit vide, ASCII, accents et emoji. Sa loi dit qu’inverser deux fois une chaîne UTF-8 valide restitue l’original. Toute suite d’octets n’est pas UTF-8 valide ; la conversion d’octets invalides en runes les normalise. Restreindre le domaine fait donc partie du contrat.

Le test de propriété utilise testing/quick pour générer des valeurs de la même loi. La cible de tramage vérifie l’aller-retour d’octets arbitraires bornés, tandis que la table des trames malformées couvre les rejets connus. Un aller-retour peut masquer deux erreurs compatibles, comme encodeur et décodeur utilisant ensemble le mauvais ordre d’octets. Le protocole demande donc aussi des attentes explicites sur l’en-tête et les longueurs incorrectes. Combinez lois et exemples concrets : aucun ne remplace la compréhension du contrat.

Les frameworks C# et Java expriment les mêmes propriétés, mais l’outillage standard Go reconnaît directement les cibles de fuzzing et leur signature obligatoire. Gardez une cible déterministe pour son entrée et indépendante du réseau externe. Un échec n’est utile que si l’entrée est conservée et rejouable. Graines, recherche active, instrumentation de courses et systèmes d’exploitation apportent des preuves distinctes. Le journal marque initialement recherche active et courses à vérifier ; aucun nombre de cas générés ni bug découvert n’est inventé.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[collection/sequence_test.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/collection/sequence_test.go)

```go
package collection

import (
	"slices"
	"testing"
	"testing/quick"
	"unicode/utf8"
)

func TestMapStops(t *testing.T) {
	calls := 0
	for v := range Map(slices.Values([]int{1, 2, 3}), func(v int) int { calls++; return v * 2 }) {
		if v != 2 {
			t.Fatal(v)
		}
		break
	}
	if calls != 1 {
		t.Fatalf("iterator ignored stop: %d", calls)
	}
}
func TestReverseProperty(t *testing.T) {
	property := func(s string) bool { return !utf8.ValidString(s) || Reverse(Reverse(s)) == s }
	if err := quick.Check(property, nil); err != nil {
		t.Fatal(err)
	}
}
func FuzzReverse(f *testing.F) {
	for _, seed := range []string{"", "abc", "été", "🙂x"} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, s string) {
		if !utf8.ValidString(s) {
			t.Skip()
		}
		if Reverse(Reverse(s)) != s {
			t.Fatal("involution")
		}
	})
}
```

[cmd/l10/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l10/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/collection"
	"fmt"
)

func main() {
	text := "été Go"
	fmt.Println(collection.Reverse(text))
	fmt.Println(collection.Reverse(collection.Reverse(text)) == text)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l10
```

### Contrat de sortie attendu

```text
oG été
true
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Pourquoi exclure l’UTF-8 invalide du test d’involution ?

<details>
<summary>Solution complète</summary>

L’implémentation inverse des runes, pas les octets bruts. Le décodage remplace les encodages invalides, qui ne sont donc pas toujours reconstructibles. Limitez cette propriété au texte valide et utilisez le tramage pour les octets arbitraires.

</details>

2. Un go test réussi prouve-t-il une recherche fuzz active ?

<details>
<summary>Solution complète</summary>

Non. Il exécute les graines. La recherche active exige une commande dédiée et un résultat avec durée consignés séparément. Distinguez aussi les résultats de courses et de tests ordinaires.

</details>

## Sources primaires

- [Détecteur de courses](https://go.dev/doc/articles/race_detector)
- [Tutoriel de fuzzing](https://go.dev/doc/tutorial/fuzz)
- [testing/quick](https://pkg.go.dev/testing/quick)

[Leçon suivante](../11-benchmarks-pprof-and-trace/) · [Journal d’apprentissage](../journal/)
