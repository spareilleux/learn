---
title: "4. Contrats d’erreur et nil typé"
description: "Préserver l’identité des erreurs entre couches et renvoyer une interface réellement nil en cas de succès."
sidebar:
  order: 4
---

## Objectif pédagogique

Préserver l’identité des erreurs entre couches et renvoyer une interface réellement nil en cas de succès.

## Mécanismes et repères C#/Java

Le package [errors](https://pkg.go.dev/errors) distingue la reconnaissance d’une erreur de l’affichage de son message. NewJob enveloppe ErrInvalid avec la directive de format prévue à cet effet. Un appelant ajoute ainsi du contexte sans perdre l’identité reconnue par errors.Is. errors.As recherche une erreur typée compatible dans l’arbre et renseigne le pointeur cible. Utilisez identités et types pour décider ; réservez les chaînes lisibles à l’explication. Une modification de ponctuation ne doit pas changer le contrôle de flux.

Une interface contient un type dynamique et une valeur dynamique. TypedNil renvoie une interface error contenant un pointeur nil de type ValidationError : cette interface n’est pas nil. Validate renvoie au contraire le littéral nil en cas de succès. La commande montre la différence sans déréférencer de pointeur nil. ValidationError.Error accepte un receveur nil, ce qui autorise l’affichage de cette valeur précise ; d’autres types peuvent paniquer. La leçon porte sur la représentation d’une interface, pas sur une prétendue sûreté universelle des receveurs nil.

Les annotations de références nullables C# décrivent un contrat statique ; null en Java est une valeur de référence. Aucun ne prédit directement l’égalité à nil d’une interface Go. Considérez les deux composantes de l’interface. Une fonction renvoyant un pointeur concret peut renvoyer sa valeur zéro, mais convertir ce pointeur en error change le contrat. Préférez un résultat déclaré error lorsque les appelants doivent suivre la convention habituelle, et écrivez explicitement le retour nil du succès.

Envelopper une erreur d’implémentation expose aussi une information aux consommateurs. S’ils commencent à reconnaître l’erreur d’un pilote précis, remplacer ce pilote peut devenir une rupture publique. Définissez les erreurs significatives à la frontière du package. Le cours expose invalid, full et closed pour distinguer validation, surcharge et arrêt. Il ne promet pas chaque représentation interne. Une panique convient à une hypothèse de programmation violée à une frontière système, pas à une entrée utilisateur invalide ordinaire. Plusieurs erreurs peuvent être jointes sans promettre la présentation textuelle de leur arbre.

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

[cmd/l04/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l04/main.go)

```go
package main

import (
	"errors"
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	fmt.Println(domain.TypedNil() == nil, domain.Validate("ok") == nil)
	var detail *domain.ValidationError
	fmt.Println(errors.As(domain.Validate(""), &detail), detail.Field)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l04
```

### Contrat de sortie attendu

```text
false true
true name
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Pourquoi TypedNil() == nil vaut-il false ?

<details>
<summary>Solution complète</summary>

L’interface conserve le type dynamique du pointeur, même lorsque sa valeur est nil. Renvoyez le littéral nil dans le chemin de succès, comme Validate ; ne corrigez pas les appelants avec une comparaison de chaînes.

</details>

2. Comment un adaptateur HTTP reconnaît-il une tâche invalide enveloppée ?

<details>
<summary>Solution complète</summary>

Utilisez errors.Is(err, domain.ErrInvalid). Pour les détails de ValidationError, utilisez errors.As avec une cible pointeur. Les deux parcourent les enveloppes ; l’égalité directe ne reconnaît que la sentinelle elle-même.

</details>

## Sources primaires

- [errors](https://pkg.go.dev/errors)
- [FAQ : erreur nil](https://go.dev/doc/faq#nil_error)

[Leçon suivante](../05-memory-model-sync-and-atomics/) · [Journal d’apprentissage](../journal/)
