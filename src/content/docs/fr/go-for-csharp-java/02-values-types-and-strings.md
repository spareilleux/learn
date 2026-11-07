---
title: "2. Valeurs, types et chaînes"
description: "Distinguer octets, points de code Unicode et types numériques nommés."
sidebar:
  order: 2
---

## Objectifs

Prévoir valeurs nulles et conversions, expliquer les comptes d’octets et de runes, puis donner un type distinct aux minutes.

## Des valeurs avec une représentation précise

Le [système de types](https://go.dev/ref/spec#Types) de Go distingue la représentation d’une valeur des opérations autorisées sur son type. Une variable déclarée sans initialisation reçoit la valeur nulle de son type : zéro pour les nombres, false pour les booléens et une chaîne vide pour les chaînes. Ce sont bien des valeurs initialisées. Une valeur nulle utile réduit le code de préparation, mais ne remplace pas une règle métier. Un nom d’étude vide reste invalide dans notre journal même s’il constitue une chaîne Go parfaitement valide.

Un int est un entier signé dont la taille dépend de l’architecture cible. Utilisez-le pour les indices et comptes ordinaires ; choisissez une taille explicite lorsqu’un format binaire l’impose. Les types numériques ne se mélangent généralement pas par élargissement automatique. Une conversion explicite marque la frontière voulue sans garantir que la valeur tient dans le type cible. Les constantes non typées suivent des règles particulières de représentabilité : un littéral peut initialiser Minutes sans que toute variable int puisse lui être affectée directement.

## Un nom peut exprimer une distinction métier

La déclaration de Minutes crée un type nommé dont le type sous-jacent est int. Ce n’est pas un alias. Nous pouvons lui attacher Double et éviter de mélanger accidentellement des minutes avec un autre type numérique nommé. Les opérations restent numériques : nommer le type n’interdit pas automatiquement les nombres négatifs ni les dépassements. Load imposera ensuite la règle des entrées positives ou nulles. La distinction statique et la validation traitent deux familles différentes d’erreurs.

La déclaration courte déduit le type d’une variable de son initialiseur. Elle ne crée pas une valeur dynamiquement typée. Les réaffectations respectent toujours les règles de types. Dans une portée interne, une déclaration courte peut aussi masquer une variable externe, ce qui passe facilement inaperçu lors du traitement d’une erreur. Regardez l’endroit où la variable est déclarée, pas seulement son nom. Afficher un entier avec un format décimal ne modifie ni son type ni sa validation.

## Une chaîne compte des octets

Une [chaîne](https://go.dev/ref/spec#String_types) est une suite immuable d’octets, pas un tableau de caractères. Notre littéral café occupe cinq octets UTF-8 et quatre points de code Unicode. [`len`](https://pkg.go.dev/builtin#len) compte les octets ; [utf8.RuneCountInString](https://pkg.go.dev/unicode/utf8#RuneCountInString) compte les points de code. rune est un alias d’int32 employé pour représenter un point de code. Aucun de ces comptes ne mesure nécessairement les caractères perçus par l’utilisateur : marques combinatoires et emoji composés demandent un modèle plus riche.

Indexer une chaîne renvoie un octet. Une boucle range décode l’UTF-8 et fournit des positions en octets et des runes. Découper à une position arbitraire peut séparer les octets d’un caractère. Les chaînes Go peuvent contenir de l’UTF-8 invalide : sa validité est donc un contrat d’entrée. Notre lecteur JSON le vérifie explicitement. Ne normalisez ni ne nettoyez les noms silencieusement sans règle applicative : octets, points de code et identités métier répondent à des questions différentes.

## Venir de C# ou Java

Les API de [string en C#](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/reference-types#the-string-type) et de [String en Java](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html) s’appuient sur UTF-16. Transposer une hypothèse de comptage change donc sa signification. L’égalité des chaînes Go compare les octets : deux écritures visuellement identiques, composée et décomposée, peuvent rester différentes. L’exemple démontre trois propriétés séparées : cinq octets, quatre runes et vingt minutes doublées. Retrouvez ensuite la déclaration du type dans le package partagé.

## Exemple détaillé

Source complète: [`cmd/l02/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l02/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"unicode/utf8"
)

func main() {
	name := "café"
	minutes := study.Minutes(20)
	fmt.Printf("bytes=%d runes=%d double=%d\n", len(name), utf8.RuneCountInString(name), minutes.Double())
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l02
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
bytes=5 runes=4 double=40
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Que change le remplacement du nom par la chaîne ASCII go ?

<details>
<summary>Solution 1</summary>

La longueur en octets et le nombre de runes valent tous deux deux, car chaque point de code ASCII occupe un octet UTF-8. Le résultat numérique reste quarante : la chaîne ne participe pas au calcul. Ce remplacement ne modifie ni le type de minutes ni le récepteur de Double.

</details>

2. Convertir un int négatif en Minutes valide-t-il la durée ?

<details>
<summary>Solution 2</summary>

Non. La conversion exprime un changement de type numérique ; elle n’impose pas la règle du journal. Load rejette les durées négatives après décodage. Double multiplie simplement son récepteur par deux. Un constructeur pourrait imposer un invariant plus fort, mais ce cours enseigne volontairement la validation à la frontière existante.

</details>

## Sources officielles

- [Types du langage](https://go.dev/ref/spec#Types)
- [Longueur des chaînes](https://go.dev/ref/spec#Length_and_capacity)
- [Comptage des runes UTF-8](https://pkg.go.dev/unicode/utf8#RuneCountInString)

[Leçon suivante](../03-control-flow-and-functions/) · [Journal](../journal/)
