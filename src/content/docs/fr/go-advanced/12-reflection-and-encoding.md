---
title: "12. Réflexion, encodage et frontières"
description: "Intégrer les choix d’encodage au contrat de frontière et limiter la réflexion aux types attendus."
sidebar:
  order: 12
---

## Objectif pédagogique

Intégrer les choix d’encodage au contrat de frontière et limiter la réflexion aux types attendus.

## Mécanismes et repères C#/Java

[encoding/json/v2](https://pkg.go.dev/encoding/json/v2) et [encoding/json/jsontext](https://pkg.go.dev/encoding/json/jsontext) deviennent stables avec Go 1.27. Le premier traduit les valeurs Go ; jsontext traite la couche syntaxique de JSON. L’ancien encoding/json utilise désormais la nouvelle implémentation tout en conservant ses comportements v1. Une implémentation commune ne rend pas tous les comportements par défaut interchangeables. Choisissez API et options comme un contrat de données explicite, puis testez les champs et cas limites dont les clients dépendent réellement.

Record nomme ses champs JSON et Decode demande le rejet des membres inconnus. Encode et Decode utilisent des octets et un type de destination concret. Cela évite une map générique de valeurs dynamiques où interprétation des nombres et champs absents deviennent implicites. Refuser les membres inconnus est une politique parmi d’autres : un protocole public tolérant les versions peut permettre volontairement de nouveaux champs. Le cours choisit une entrée stricte pour rendre la décision visible, sans la déclarer compatible avec toute stratégie d’évolution.

L’auxiliaire [reflect](https://pkg.go.dev/reflect) examine le type après vérification de nil et du genre. NumField s’applique à une struct, pas à toute valeur. Fields renvoie zéro pour nil et les autres genres, puis deux pour Record. Compter les champs ne les sérialise pas et ne prouve ni exportation ni modification possible. Une réflexion sur le mauvais genre peut paniquer ; modifier une valeur exige qu’elle soit adressable et modifiable. Un petit switch de types ou une interface explicite reste souvent plus simple lorsque les variantes sont connues.

Attributs C# et annotations Java ressemblent aux tags de struct, mais ces tags sont des chaînes interprétées par une bibliothèque, pas un mécanisme général d’annotation exécutable. La réflexion ne remplace pas non plus les contraintes génériques statiques. Conservez une frontière typée pour les opérations ordinaires et isolez l’inspection dynamique aux entrées réellement ouvertes. unsafe et cgo restent hors des exemples : leurs frontières mémoire et runtimes étrangers ajoutent des règles de propriété et de portabilité. Leur existence ne justifie pas des suppositions sur la disposition mémoire. Vérifiez le comportement avec Go 1.27 plutôt qu’avec d’anciennes notes expérimentales.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[encodingx/record.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/encodingx/record.go)

```go
package encodingx

import (
	"encoding/json/v2"
	"reflect"
)

type Record struct {
	Name   string `json:"name"`
	Values []int  `json:"values"`
}

func Encode(value Record) ([]byte, error) { return json.Marshal(value) }
func Decode(data []byte) (Record, error) {
	var value Record
	err := json.Unmarshal(data, &value, json.RejectUnknownMembers(true))
	return value, err
}
func Fields(value any) int {
	t := reflect.TypeOf(value)
	if t == nil || t.Kind() != reflect.Struct {
		return 0
	}
	return t.NumField()
}
```

[cmd/l12/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l12/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/encodingx"
	"fmt"
)

func main() {
	value := encodingx.Record{Name: "sum", Values: []int{2, 3}}
	data, err := encodingx.Encode(value)
	if err != nil {
		panic(err)
	}
	decoded, err := encodingx.Decode(data)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(data))
	fmt.Println(decoded.Name, encodingx.Fields(decoded))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l12
```

### Contrat de sortie attendu

```text
{"name":"sum","values":[2,3]}
sum 2
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Un aller-retour réussi prouve-t-il la compatibilité JSON publique ?

<details>
<summary>Solution complète</summary>

Non. Encodeur et décodeur peuvent partager un comportement inattendu. Ajoutez des attentes exactes sur le format et des entrées d’anciens clients ; décidez des politiques de champs inconnus, null, nombres et nommage avant une modification publique.

</details>

2. Pourquoi examiner Kind avant NumField ?

<details>
<summary>Solution complète</summary>

NumField exige un type struct. Vérifier nil et le genre établit cette précondition et donne un résultat zéro prévisible hors du domaine pris en charge, sans récupération de panique comme contrôle ordinaire.

</details>

## Sources primaires

- [encoding/json/v2](https://pkg.go.dev/encoding/json/v2)
- [encoding/json/jsontext](https://pkg.go.dev/encoding/json/jsontext)
- [reflect](https://pkg.go.dev/reflect)
- [Go 1.27](https://go.dev/doc/go1.27)

[Leçon suivante](../13-dependencies-builds-and-security/) · [Journal d’apprentissage](../journal/)
