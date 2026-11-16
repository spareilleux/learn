---
title: "6. Pointeurs et méthodes"
description: "Choisir les récepteurs selon leur contrat de modification et leur ensemble de méthodes."
sidebar:
  order: 6
---

## Objectifs

Suivre un enregistrement copié, expliquer la prise d’adresse implicite et distinguer modification et identité partagée.

## Un pointeur désigne un stockage

Un [pointeur](https://go.dev/ref/spec#Pointer_types) contient l’adresse d’une variable ou nil. Prendre une adresse et déréférencer sont des opérations du langage. Go gère la durée de vie des objets ordinaires par ramasse-miettes ; renvoyer l’adresse d’une valeur locale ne demande pas de libération manuelle. Cela ne supprime pas les questions de propriété. Un pointeur permet à plusieurs appelants d’atteindre le même objet mutable et donc d’observer les modifications des autres.

Le programme copie d’abord un Record dans copy. Comme les champs sont une chaîne et Minutes, les deux enregistrements peuvent ensuite évoluer indépendamment. copy.Add fait passer la copie de quinze à vingt. record.Add fait passer l’autre variable locale de quinze à vingt-cinq. Afficher les deux distingue la copie d’une structure du passage d’une adresse à une méthode. Aucun clonage profond caché ne se produit lors de l’appel.

## Choisir la promesse du récepteur

Une [méthode](https://go.dev/ref/spec#Method_declarations) est une fonction associée à un type récepteur. Label reçoit une valeur parce qu’elle lit seulement un champ. Add reçoit un pointeur parce qu’elle modifie le Record visé. Le récepteur passe toujours par valeur : copier un pointeur conserve l’accès à sa cible. Un récepteur valeur reçoit une copie de l’enregistrement ; affecter ses propres champs ne remplace pas ceux de l’appelant.

Pour une variable locale adressable, Go peut prendre implicitement son adresse lors d’un appel à une méthode sur pointeur. Cette commodité ne signifie pas que le type valeur possède toutes les méthodes dans tous les contextes. Les ensembles de méthodes déterminent la satisfaction des interfaces, sujet suivant. Distinguez aussi un pointeur nil d’un Record nul : ce dernier possède des champs accessibles ; déréférencer le premier est invalide, sauf méthode conçue pour traiter nil sans le déréférencer.

## Comparer les modèles connus

La copie d’un [struct C#](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct) fournit une première comparaison, tandis que les références Java aident à imaginer un stockage volontairement partagé. Aucune analogie ne définit complètement Go. Il n’existe pas de classe objet universelle, et déclarer une méthode n’impose pas de hiérarchie. Un récepteur pointeur n’oblige pas non plus le compilateur à placer l’objet sur le tas ; l’analyse d’échappement et l’implémentation déterminent son emplacement.

Ne choisissez pas un pointeur uniquement parce qu’un enregistrement paraît volumineux, sans mesure ni souci de cohérence. La modification suffit déjà à justifier Add. Mélanger les styles de récepteur doit correspondre à un contrat clair, surtout avec des interfaces. Recevoir la structure externe par valeur n’isole pas automatiquement ses éventuels champs mutables imbriqués. La règle de copie superficielle de la leçon précédente reste valable.

## Donner une frontière compréhensible

Le projet final lit des entrées immuables et produit des valeurs sélectionnées ; il n’a pas besoin de partager chaque enregistrement par pointeur. Add est un exemple ciblé, pas une raison de réorganiser tout le modèle autour de l’identité. Lors de la lecture, repérez quelle variable est adressable et quel stockage chaque appel modifie. Ce suivi concret est plus fiable que dire que Go passe les objets par référence : tout passe par valeur, et certaines valeurs désignent un stockage partagé.

## Exemple détaillé

Source complète: [`cmd/l06/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l06/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	record := study.Fixture()[0]
	copy := record
	copy.Add(5)
	record.Add(10)
	fmt.Printf("record=%d copy=%d\n", record.Minutes, copy.Minutes)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l06
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
record=25 copy=20
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Si copy.Add reçoit encore cinq, record change-t-il ?

<details>
<summary>Solution 1</summary>

Non. Après l’affectation, copy et record sont deux variables de structure distinctes. Le deuxième appel vise copy et fait passer sa durée de vingt à vingt-cinq. record garde vingt-cinq après sa propre modification. L’égalité finale des nombres ne prouverait pas une identité partagée : ce sont deux calculs indépendants.

</details>

2. Quel récepteur choisir pour Label et pourquoi Add diffère-t-elle ?

<details>
<summary>Solution 2</summary>

Label peut recevoir une valeur puisqu’elle lit un champ sans modifier le stockage appelant. Add doit recevoir un pointeur pour mettre à jour la cible. Les déclarations du dépôt réalisent exactement cette distinction. Une interface exigeant Label accepte valeurs et pointeurs selon leurs ensembles de méthodes ; la modification reste un besoin distinct.

</details>

## Sources officielles

- [Types pointeurs](https://go.dev/ref/spec#Pointer_types)
- [Déclarations de méthodes](https://go.dev/ref/spec#Method_declarations)
- [Ensembles de méthodes](https://go.dev/ref/spec#Method_sets)

[Leçon suivante](../07-interfaces-and-composition/) · [Journal](../journal/)
