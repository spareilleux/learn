---
title: "10. Génériques et collections"
description: "Construire une transformation typée immédiate et comprendre les contraintes actuelles."
sidebar:
  order: 10
---

## Objectifs

Lire les paramètres de types, déduire entrée et sortie d’une fonction de conversion et distinguer génériques et interfaces.

## Réutiliser un algorithme en gardant les types

Les [paramètres de types](https://go.dev/ref/spec#Type_parameter_declarations) décrivent une famille d’opérations concrètes. Map reçoit un slice de T et une conversion de T vers U, puis renvoie un slice de U. Le compilateur vérifie le type d’entrée du rappel et chacune de ses valeurs de retour. Aucun passage de chaque élément par une interface any n’est nécessaire ; l’appelant reçoit un résultat typé statiquement.

Dans la commande, T est Record et U est string. L’[inférence](https://go.dev/ref/spec#Type_inference) s’appuie sur le slice et la signature du rappel, ce qui évite d’écrire les deux arguments de types. Map alloue la longueur finale, affecte un résultat par indice et conserve l’ordre. L’exécution est immédiate : tous les rappels se terminent avant le retour. Ce n’est ni une requête différée ni une parallélisation automatique.

## Les contraintes déterminent les opérations

Les deux paramètres utilisent any parce que Map ne compare ni n’additionne leurs valeurs. Elle transmet T au rappel et stocke U. Une fonction utilisant l’égalité demanderait une contrainte comparable adaptée ; un algorithme numérique exigerait les opérateurs nécessaires. Une contrainte plus large n’est pas automatiquement plus utile si elle interdit les opérations indispensables à l’implémentation. Décrivez les besoins réels de l’algorithme.

Les types nommés et leurs types sous-jacents comptent dans les contraintes réutilisables. Ne ramenez pas Minutes à int uniquement pour satisfaire un utilitaire. La conversion reste explicite dans le rappel de Map, ce qui autorise diverses sorties sans perdre le type métier ailleurs. Le typage ne prouve pas la justesse métier du rappel : les tests doivent encore vérifier ordre, valeurs et entrée vide.

## Un utilitaire générique ne fait pas tout

Le résultat possède son stockage de slice, mais les valeurs produites peuvent conserver des références. Transformer Record en Record ne promet pas un clonage profond. Le rappel n’a pas non plus de retour d’erreur dans ce contrat précis. Une conversion pouvant échouer demanderait une autre fonction avec résultat et erreur, ainsi qu’une politique de résultats partiels. Ne supprimez pas silencieusement des échecs pour conserver cette signature pratique.

[C# Enumerable.Select](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.select) et [Java Stream.map](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Stream.html#map(java.util.function.Function)) aident à comparer la transformation d’éléments. Leurs modèles d’exécution diffèrent toutefois de cet utilitaire immédiat. Ne lui attribuez pas sans raison exécution différée, invalidation d’itérateur ou flux parallèles : son implémentation complète est une courte boucle.

## Enseigner le langage actuel

Go 1.27 autorise les méthodes concrètes avec leurs propres paramètres de types. Les textes interdisant universellement les méthodes génériques sont dépassés. Les méthodes d’interface ne peuvent toujours pas déclarer leurs propres paramètres et ne sont pas implémentées par ces méthodes génériques. Ici, une fonction générique convient naturellement à l’opération sur des slices arbitraires ; ce n’est pas une interdiction du langage qui impose ce choix.

Utilisez les génériques lorsque le même algorithme typé sert à plusieurs types. Select reste spécifique au domaine et plus claire pour filtrer des durées d’étude. Il n’est pas nécessaire de transformer chaque utilitaire en framework de collections. L’objectif est une transformation courte dont allocation, ordre et moment d’évaluation restent visibles.

## Exemple détaillé

Source complète: [`cmd/l10/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l10/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	labels := study.Map(study.Fixture(), func(record study.Record) string { return record.Label() })
	fmt.Printf("labels=%v\n", labels)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l10
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
labels=[types go]
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Quels sont T et U, et quand le rappel s’exécute-t-il ?

<details>
<summary>Solution 1</summary>

T est study.Record et U est string. Le rappel s’exécute une fois pour chacun des deux enregistrements dans Map, avant l’affichage. L’ordre reste types puis go, car chaque résultat garde l’indice de son entrée. Aucune énumération différée ne subsiste après le retour.

</details>

2. any permet-il d’additionner deux valeurs T ?

<details>
<summary>Solution 2</summary>

Non. Cette contrainte ne garantit pas l’addition. L’implémentation n’en a pas besoin : elle transmet les valeurs au rappel et stocke les résultats. Un algorithme numérique demanderait une contrainte adaptée. Gardez cette fonction ciblée plutôt que d’affaiblir les types avec des assertions ou d’inventer une politique arithmétique universelle.

</details>

## Sources officielles

- [Paramètres de types](https://go.dev/ref/spec#Type_parameter_declarations)
- [Inférence de types](https://go.dev/ref/spec#Type_inference)
- [Méthodes génériques de Go 1.27](https://go.dev/doc/go1.27#language)

[Leçon suivante](../11-goroutines-and-channels/) · [Journal](../journal/)
