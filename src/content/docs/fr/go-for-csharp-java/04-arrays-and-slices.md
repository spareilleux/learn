---
title: "4. Tableaux et slices"
description: "Comprendre les tableaux copiés, le stockage partagé des slices, append et le clonage explicite."
sidebar:
  order: 4
---

## Objectifs

Dessiner le stockage partagé par deux slices, distinguer longueur et capacité, puis décider si une copie superficielle suffit.

## La collection n’est pas toujours son stockage

Un [tableau](https://go.dev/ref/spec#Array_types) contient un nombre fixe d’éléments, et sa longueur appartient à son type. Son affectation copie les éléments. Un [slice](https://go.dev/ref/spec#Slice_types) décrit plutôt un segment d’un tableau sous-jacent. Sa longueur donne le nombre d’éléments accessibles ; sa capacité indique jusqu’où ce segment peut s’étendre avant qu’[`append`](https://pkg.go.dev/builtin#append) nécessite une autre allocation. Copier le slice copie cette description, sans copier automatiquement les éléments qu’elle désigne.

Nos données initiales forment un nouveau slice de deux Record. L’expression qui en extrait le premier élément sous forme de slice crée une autre vue sur le même tableau. Modifier le premier enregistrement de cette vue modifie donc aussi celui qu’on lit par le slice original. study.Clone appelle au contraire [slices.Clone](https://pkg.go.dev/slices#Clone), qui alloue une séquence séparée. Le premier enregistrement détaché garde quinze minutes quand l’original partagé passe à trente. C’est une question de propriété du stockage.

## Append peut modifier le partage

append renvoie un slice : conservez son résultat. Si la capacité suffit, il peut réutiliser le tableau ; sinon il alloue et copie les éléments existants. N’appuyez pas la correction du programme sur un facteur de croissance non documenté. Deux exemples très proches peuvent partager différemment parce que leurs capacités diffèrent. Si vous exigez un stockage indépendant, clonez explicitement au lieu d’espérer qu’un prochain append alloue par hasard.

Un slice nil a une longueur et une capacité nulles ; on peut le parcourir ou lui ajouter des éléments. Un slice vide non nil possède aussi une longueur nulle, mais cette différence peut compter pour un contrat de sérialisation. Un indice doit rester dans la longueur, même s’il existe une capacité supplémentaire. Étendez une vue par découpage seulement lorsque c’est intentionnel. Passer un slice copie son descripteur : modifier les éléments partagés reste visible, réaffecter le descripteur local ne modifie pas la variable appelante.

## La profondeur de copie dépend des éléments

Record contient actuellement une chaîne et une valeur numérique Minutes. Copier les éléments suffit pour isoler les affectations ultérieures de ces champs ; les chaînes sont immuables. Si Record contenait demain une map ou un autre slice, cloner le slice externe copierait leurs descripteurs tout en conservant leur stockage partagé. Ne présentez pas Clone comme une copie profonde universelle. Sa garantie doit rester liée au modèle actuel et au contrat de la bibliothèque standard.

En C# et Java, les tableaux sont des objets référencés : une affectation de variable partage cet objet. En Go, affecter un tableau copie ses éléments, tandis qu’affecter un slice partage le stockage par copie du descripteur. Le mot tableau ne suffit donc pas à transposer une intuition. Regardez le type réellement déclaré. Un slice n’est pas non plus un objet extensible offrant toutes les méthodes des collections habituelles : fonctions ordinaires et opérations prédéfinies fournissent les mécanismes essentiels.

## Diagnostiquer le partage avant de le corriger

Suivez les trois noms de l’exemple. original et alias atteignent le même premier enregistrement ; detached en atteint un autre. La modification passe par alias, mais la sortie lit original et detached pour rendre cette relation visible. Le test écrit vérifie les deux côtés : supprimer accidentellement le partage ou partager accidentellement la copie le ferait échouer. Une expression complète de slice peut limiter la capacité et la réutilisation par append, mais n’isole pas les écritures sur les éléments existants. Clone répond précisément à ce besoin.

## Exemple détaillé

Source complète: [`cmd/l04/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l04/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	original := study.Fixture()
	alias := original[:1]
	detached := study.Clone(alias)
	alias[0].Minutes = 30
	fmt.Printf("original=%d clone=%d\n", original[0].Minutes, detached[0].Minutes)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l04
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
original=30 clone=15
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Pourquoi obtient-on trente dans original et quinze dans clone ?

<details>
<summary>Solution 1</summary>

alias vise le premier élément du même tableau qu’original. Lui affecter trente change donc ce que lit original. Clone avait copié cet élément avant l’affectation ; son tableau séparé conserve quinze. Inverser l’ordre de la copie et de l’affectation copierait trente à la place.

</details>

2. Le clonage isolerait-il un champ map ajouté à Record ?

<details>
<summary>Solution 2</summary>

Non. Le clonage superficiel copie la valeur map, qui désigne toujours le même stockage. Conservez le modèle actuel à champs immuables ou définissez et testez une copie plus profonde pour le nouveau champ. Limiter la capacité du slice n’isolerait ni les entrées de map ni les éléments déjà présents.

</details>

## Sources officielles

- [Types tableaux](https://go.dev/ref/spec#Array_types)
- [Types slices](https://go.dev/ref/spec#Slice_types)
- [slices.Clone](https://pkg.go.dev/slices#Clone)

[Leçon suivante](../05-maps-and-structs/) · [Journal](../journal/)
