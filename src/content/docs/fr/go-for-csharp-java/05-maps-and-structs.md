---
title: "5. Maps et structures"
description: "Modéliser les enregistrements comme valeurs et distinguer absence et zéro."
sidebar:
  order: 5
---

## Objectifs

Utiliser des littéraux de structure nommés, agréger dans une map et distinguer clé absente et zéro enregistré.

## Nommer les données avant la collection

Une [structure](https://go.dev/ref/spec#Struct_types) regroupe des champs nommés. Record contient Name et Minutes : son littéral décrit donc une séance plutôt qu’une paire anonyme. Nommer les champs dans les littéraux rend leur relation lisible et résiste mieux à leur réorganisation. Les champs commençant par une majuscule sont exportés ; les tags JSON définissent leurs noms externes. Un tag reste une métadonnée, pas une règle de validité. Load appliquera les règles métier après décodage.

Affecter une structure copie ses champs. Ce comportement ressemble davantage à un type valeur C# qu’à l’hypothèse selon laquelle tout objet de données Java possède une identité référencée. Une copie peut néanmoins conserver des références partagées si ses champs sont des maps, pointeurs ou slices. Nos champs actuels évitent ce stockage mutable imbriqué. Choisir une structure ne crée ni héritage, ni constructeur, ni accesseurs automatiques : fonctions et méthodes fournissent le comportement nécessaire.

## Agréger avec une règle d’absence explicite

Une [map](https://go.dev/ref/spec#Map_types) associe des clés et des valeurs. La commande alloue une map de string vers Minutes et ajoute chaque durée au total de son nom. Lire une clé absente donne la valeur nulle du type associé. La première occurrence part donc de zéro ; une occurrence suivante ajoute au total existant. Une lecture avec deux variables renvoie aussi un booléen de présence, qui distingue un zéro enregistré d’un nom absent.

L’exemple lit une clé connue et une clé absente. Il n’affiche pas toute la map, car l’ordre de parcours n’est pas spécifié. Un rapport stable doit conserver l’ordre d’entrée ou trier explicitement les clés. Le projet final conserve celui du slice. Le formatage déterministe relève d’une décision de comportement ; la map seule ne le garantit pas.

## Modification et propriété

On peut lire une map nil et demander sa longueur, mais pas y ajouter d’entrées. Allouez-la avec [`make`](https://pkg.go.dev/builtin#make) avant d’écrire. Affecter une map partage son stockage ; cela ne clone pas ses entrées. [`delete`](https://pkg.go.dev/builtin#delete) supprime une clé et ne pose pas de problème si elle est absente. Les modifications concurrentes non synchronisées constituent un autre sujet : une map n’est pas automatiquement sûre entre goroutines.

Une entrée contenant une structure est récupérée comme valeur. Pour la modifier, on lit une copie locale, on la change, puis on la réaffecte à l’entrée. Une map de pointeurs partage au contraire volontairement des enregistrements mutables, avec un autre contrat de propriété. Ne choisissez pas des pointeurs uniquement pour faciliter l’appel d’une méthode. Décidez d’abord si deux lecteurs doivent voir la même modification.

## Comparer les contrats de lecture

[C# Dictionary.TryGetValue](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.trygetvalue) expose explicitement la présence, comme la lecture Go à deux résultats. [Java Map.get](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#get(java.lang.Object)) emploie souvent null pour l’absence, avec des distinctions supplémentaires si la map autorise les valeurs nulles. En Go, zéro est une valeur Minutes légitime. Examiner seulement le nombre fait perdre l’information de présence. Le booléen indique si la clé existe, indépendamment de sa valeur numérique.

## Exemple détaillé

Source complète: [`cmd/l05/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l05/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	totals := make(map[string]study.Minutes)
	for _, record := range study.Fixture() {
		totals[record.Name] += record.Minutes
	}
	minutes, present := totals["missing"]
	fmt.Printf("go=%d missing=%d present=%t\n", totals["go"], minutes, present)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l05
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
go=25 missing=0 present=false
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Comment distinguer go enregistré à zéro d’une clé absente ?

<details>
<summary>Solution 1</summary>

Récupérez les deux résultats. La clé go donne zéro et true ; une clé absente donne zéro et false. Le nombre seul ne suffit pas. L’exemple affiche donc le booléen avec la valeur absente, plutôt que de traiter automatiquement zéro comme une erreur.

</details>

2. Deux séances go durent dix et quinze minutes : quel total obtenir ?

<details>
<summary>Solution 2</summary>

La map doit contenir vingt-cinq pour go. Le premier ajout part de zéro ; le second ajoute quinze aux dix déjà présents. Conservez la map allouée et le += de main. Pour afficher plusieurs noms agrégés de manière reproductible, triez les clés ou conservez une liste ordonnée distincte.

</details>

## Sources officielles

- [Types maps](https://go.dev/ref/spec#Map_types)
- [Types structures](https://go.dev/ref/spec#Struct_types)
- [Indexation des maps](https://go.dev/ref/spec#Index_expressions)

[Leçon suivante](../06-pointers-and-methods/) · [Journal](../journal/)
