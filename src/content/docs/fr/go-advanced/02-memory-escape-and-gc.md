---
title: "2. Mémoire, analyse d’échappement et GC"
description: "Distinguer les garanties d’aliasing des choix d’allocation du compilateur et préparer une mesure honnête."
sidebar:
  order: 2
---

## Objectif pédagogique

Distinguer les garanties d’aliasing des choix d’allocation du compilateur et préparer une mesure honnête.

## Mécanismes et repères C#/Java

Le [guide du GC](https://go.dev/doc/gc-guide) décrit un collecteur traçant les objets accessibles. Un pointeur n’implique pas une allocation sur le tas, et une déclaration locale n’implique pas une allocation sur la pile. L’analyse d’échappement décide si le stockage peut rester dans sa durée de vie actuelle ; l’inlining et la version du compilateur peuvent modifier ce choix. Renvoyer un pointeur vers une valeur locale est sûr : Go en préserve la durée de vie. Un rapport d’échappement explique une compilation précise, pas une propriété éternelle d’une ligne.

Une slice est un descripteur de tableau. Copier ce descripteur partage le stockage ; refaire une slice change la fenêtre visible sans libérer un grand tableau encore référencé. Clone crée un stockage indépendant pour les octets visibles. Modifier source ensuite ne change que source. NewJob prend la même décision de propriété pour les entiers. Cette garantie sémantique se teste sans savoir où le compilateur place chaque objet. Copier une slice de slices exige une décision distincte pour chaque couche référencée.

Avec les tableaux C# ou Java en tête, distinguez une valeur tableau Go d’une slice référençant un tableau. Affecter un tableau Go copie ses éléments. Affecter une slice copie uniquement son descripteur. Ni le ramasse-miettes ni la synchronisation ne rendent indépendants des éléments mutables partagés. Évitez de conserver durablement une petite fenêtre d’un énorme tampon dans un cache ; copiez la partie dont vous avez réellement besoin. Cette copie peut réduire la mémoire retenue tout en augmentant les allocations : la mesure utile dépend du scénario.

Préparez le diagnostic avec go build -gcflags=-m=2 ./domain et notez version du compilateur, options et révision. Cette commande reste une expérience proposée : aucune transcription n’a été recueillie. Mesurez aussi les allocations avant d’introduire un pool. Un pool peut abandonner ses entrées et ne garantit plus de propriété exclusive après restitution. Régler le GC modifie un compromis entre CPU et mémoire ; cela ne répare pas un graphe d’objets conservé par erreur. Clarifiez d’abord les durées de vie.

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

[cmd/l02/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l02/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	source := []byte{1, 2}
	copy := domain.Clone(source)
	source[0] = 9
	fmt.Println(source, copy)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l02
```

### Contrat de sortie attendu

```text
[9 2] [1 2]
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Renvoyer un pointeur local le rend-il pendant ?

<details>
<summary>Solution complète</summary>

Non. Go maintient le stockage référencé en vie. L’emplacement dépend de l’implémentation ; la sûreté mémoire vient des règles de durée de vie, pas d’une hypothèse sur les frames de pile.

</details>

2. Un cache conserve 20 octets d’un tampon de 20 Mo. Quel changement et quelle mesure proposer ?

<details>
<summary>Solution complète</summary>

Copiez les octets visibles avant de les conserver. Comparez mémoire retenue et allocations avec la même charge et les mêmes conditions de GC. Le test de propriété et le rapport de tailles ne prouvent aucun gain de vitesse.

</details>

## Sources primaires

- [Guide du GC](https://go.dev/doc/gc-guide)
- [Options du compilateur](https://pkg.go.dev/cmd/compile)

[Leçon suivante](../03-generics-and-iterators/) · [Journal d’apprentissage](../journal/)
