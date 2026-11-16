---
title: "7. Interfaces et composition"
description: "Utiliser la satisfaction implicite et reconnaître un pointeur nil contenu dans une interface."
sidebar:
  order: 7
---

## Objectifs

Distinguer pointeur nil et interface nil, raisonner sur les méthodes et définir de petites interfaces côté consommateur.

## Décrire le comportement nécessaire

Une [interface](https://go.dev/ref/spec#Interface_types) décrit un comportement. Named exige Label renvoyant string ; Record satisfait ce contrat sans déclarer implements. Son type pointeur possède aussi la méthode à récepteur valeur. Le consommateur exprime ainsi un besoin limité sans imposer au producteur une classe de base. Cela fonctionne entre packages : une interface locale peut accepter un type existant que vous n’avez pas conçu.

Notre lecteur utilisera [io.Reader](https://pkg.go.dev/io#Reader), qui représente la lecture d’octets sans distinguer fichiers, terminal et chaînes. Cette interface est utile parce que le lecteur a besoin de l’opération de lecture ; les tests peuvent lui fournir de véritables lecteurs en mémoire. Évitez une interface reproduisant chaque méthode d’un seul type concret simplement pour ressembler à une déclaration de service C#. Partez des appels réellement effectués par le consommateur.

## Une interface contient plus qu’un pointeur

Une valeur interface possède un type dynamique et une valeur dynamique. Elle n’est nil que si les deux sont absents. Dans l’exemple, pointer est un *Record nil. Son affectation à Named installe ce type pointeur comme type dynamique, même si la valeur pointeur reste nil. pointer est donc égal à nil, mais named ne l’est pas. Cette distinction concerne notamment les retours d’erreurs et les dépendances facultatives.

L’exemple n’appelle volontairement pas named.Label. Label possède un récepteur valeur ; atteindre cette valeur via le pointeur nil demanderait un déréférencement. Une interface non nil ne garantit donc pas qu’un appel soit sûr. Pour renvoyer une interface absente, renvoyez nil directement à la frontière, sans y convertir un pointeur nil typé. Les tests rendent la différence observable sans inventer d’erreur de compilation ni citer un diagnostic d’exécution instable.

## Composer sans hériter de l’état

L’incorporation d’une structure peut promouvoir les méthodes d’un champ incorporé ; celle d’interfaces réunit des exigences de méthodes. Cela ne crée pas la même relation de sous-type que l’héritage de classes. La structure conteneuse conserve son identité et ses champs. Incorporez si cette promotion correspond au comportement public souhaité ; utilisez un champ nommé si l’accès doit rester explicite. La composition fonctionne aussi sans aucune incorporation.

Les interfaces C# et Java sont des contrats familiers, mais leurs implémentations déclarent généralement cette relation. En Go, elle est implicite et dépend des [ensembles de méthodes](https://go.dev/ref/spec#Method_sets). Une méthode à récepteur pointeur peut faire satisfaire une interface par *T sans la faire satisfaire par T. La prise d’adresse pratique d’une variable locale lors d’un appel direct ne change pas ces règles. Le choix du récepteur appartient donc à la conception de l’API.

## Tenir compte de la version

Distinguez les interfaces de comportement des contraintes pour paramètres de types. any est l’alias de l’interface vide : il stocke des valeurs sans donner accès aux opérations de leur type caché. Il faut une assertion ou un switch de type pour retrouver ce comportement. En Go 1.27, les méthodes concrètes peuvent déclarer leurs paramètres de types, mais les méthodes d’interface ne le peuvent toujours pas et ne sont pas implémentées par des méthodes génériques. Cela précise une frontière d’interface ; cela ne nie pas les méthodes génériques.

## Exemple détaillé

Source complète: [`cmd/l07/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l07/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

type Named interface{ Label() string }

func main() {
	var pointer *study.Record
	var named Named = pointer
	value := study.Fixture()[0]
	fmt.Printf("pointer-nil=%t interface-nil=%t label=%s\n", pointer == nil, named == nil, value.Label())
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l07
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
pointer-nil=true interface-nil=false label=types
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Pourquoi pointer-nil et interface-nil diffèrent-ils ?

<details>
<summary>Solution 1</summary>

pointer est un *Record nil, mais son affectation à Named conserve *Record comme type dynamique. L’interface n’est donc pas l’interface nil vide. Le programme compare les deux sans appeler de méthode sur la cible nil. Pour représenter l’absence totale de Named, initialisez ou renvoyez l’interface elle-même à nil.

</details>

2. Que doit accepter Load pour lire fichiers et chaînes ?

<details>
<summary>Solution 2</summary>

io.Reader, comme dans le code du dépôt. Un fichier et strings.NewReader fournissent tous deux l’opération de lecture. Le décodage reste dans Load et l’acquisition reste chez l’appelant. Inutile de doubler le lecteur ou de créer une vaste interface applicative : le petit contrat de lecture exprime la dépendance réelle.

</details>

## Sources officielles

- [Types interfaces](https://go.dev/ref/spec#Interface_types)
- [Ensembles de méthodes](https://go.dev/ref/spec#Method_sets)
- [io.Reader](https://pkg.go.dev/io#Reader)
- [Évolutions du langage en Go 1.27](https://go.dev/doc/go1.27#language)

[Leçon suivante](../08-errors-defer-and-resources/) · [Journal](../journal/)
