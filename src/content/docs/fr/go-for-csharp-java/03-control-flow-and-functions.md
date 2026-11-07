---
title: "3. Contrôle de flux et fonctions"
description: "Écrire des transformations explicites avec boucles, retours multiples et petites fonctions."
sidebar:
  order: 3
---

## Objectifs

Suivre une boucle de sélection, distinguer déclaration et affectation, puis choisir une frontière de fonction claire.

## Rendre la transformation visible

Les [instructions de contrôle](https://go.dev/ref/spec#Statements) de Go expriment directement la règle du journal : conserver les séances atteignant une durée minimale, puis additionner leurs minutes. Commencez par une boucle simple avant d’inventer un pipeline fluide. La commande délègue sélection et somme à deux petites fonctions. Leurs noms répondent à deux questions différentes, et le slice sélectionné reste une valeur intermédiaire ordinaire, facile à examiner et à tester séparément.

Il existe un seul mot-clé de boucle : for. Il accepte une condition, une initialisation et une mise à jour, une boucle sans condition ou un range sur une valeur compatible. Sur notre slice, range fournit un indice et une valeur d’élément. L’identifiant vide ignore l’indice inutilisé. L’élément reçu est une copie de Record. Lire Minutes est simple ; modifier cette copie ne réécrit pas l’élément du slice original. La leçon suivante précisera l’effet du stockage partagé.

## Suivre les branches et les retours

Select alloue un résultat vide et y ajoute chaque enregistrement satisfaisant une comparaison inclusive. Avec quinze et vingt-cinq minutes dans les données, un minimum de vingt ne garde que le deuxième. L’ordre d’entrée est préservé parce que la boucle ajoute les éléments dans l’ordre rencontré. Total initialise son accumulateur à la valeur nulle de Minutes et additionne les valeurs retenues. Une entrée vide produit donc zéro sans branche particulière. Ce sont ces décisions observables que les tests doivent vérifier.

Les conditions Go n’exigent pas de parenthèses, mais leurs corps utilisent des accolades. Un if peut introduire une variable avant sa condition ; nous utiliserons cette forme pour les erreurs. Limitez sa portée pour rendre évidente l’opération dont elle provient. Une déclaration courte doit introduire au moins une nouvelle variable non vide dans la portée courante. Dans un bloc interne, elle peut créer une autre variable au lieu de modifier celle que vous aviez en tête.

Les [fonctions](https://go.dev/ref/spec#Function_declarations) peuvent renvoyer plusieurs valeurs. Nous emploierons une valeur et une erreur pour les échecs ordinaires. Les paramètres passent par valeur ; copier un pointeur ou un descripteur de slice conserve toutefois l’accès à des données partagées. Le passage par valeur ne promet donc pas une isolation profonde. Une fonction peut aussi être conservée dans une variable ou transmise à une autre fonction. La leçon dix utilisera cette possibilité sans créer de hiérarchie de classes.

## Transposer les idiomes connus

En C#, on pense à [Enumerable.Where](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.where) ; en Java, à [Stream.filter](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Stream.html#filter(java.util.function.Predicate)). Notre boucle est immédiate et renvoie un slice matérialisé. Elle ne crée pas une requête différée ; parcourir à nouveau le résultat ne réexécute aucun prédicat. Cette différence compte si les données changent ou si le prédicat produit des effets. Ici, la comparaison est pure et son résultat réutilisable.

Un switch sans expression peut organiser des conditions successives, et ses cas ne s’enchaînent pas automatiquement. Utilisez-le lorsqu’il clarifie un vrai choix, sans remplacer systématiquement les if. Deux fonctions n’exigent pas de reproduire un framework d’entreprise. La frontière actuelle suffit : Select filtre, Total additionne. Aucune n’affiche, ne lit les arguments ou n’ouvre de fichier. Elles pourront ainsi servir aux frontières HTTP et CLI.

## Interpréter le résultat

L’exemple sélectionne un élément, mais totalise vingt-cinq minutes. Un nombre d’éléments et une somme sont deux mesures différentes. Sur papier, remplacez le seuil par quinze et suivez les deux valeurs : elles seraient retenues et totaliseraient quarante. À vingt-cinq, la comparaison garde encore le deuxième élément. Cette limite est précisément l’endroit où une comparaison stricte accidentelle donnerait un rapport plausible mais faux.

## Exemple détaillé

Source complète: [`cmd/l03/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l03/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	records := study.Select(study.Fixture(), 20)
	fmt.Printf("selected=%d total=%d\n", len(records), study.Total(records))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l03
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
selected=1 total=25
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Que se passe-t-il avec un minimum de vingt-cinq, puis de vingt-six ?

<details>
<summary>Solution 1</summary>

La comparaison inclusive conserve la séance de vingt-cinq minutes au premier seuil : un élément, pour vingt-cinq minutes. Au seuil de vingt-six, aucune séance ne convient ; le résultat est vide et Total renvoie son accumulateur nul. Il n’est pas nécessaire d’ajouter une branche réservée aux entrées vides.

</details>

2. Où placer la lecture des arguments et le formatage ?

<details>
<summary>Solution 2</summary>

En dehors de Select et Total. Le package CLI transforme les options en seuil Minutes, appelle Select, puis met en forme les enregistrements et leur Total. La fonction Select complète ci-dessous illustre ce cœur réutilisable : elle reçoit et renvoie des données typées, ce qui permet de tester une limite sans terminal.

</details>

## Sources officielles

- [Instructions for](https://go.dev/ref/spec#For_statements)
- [Déclarations de fonctions](https://go.dev/ref/spec#Function_declarations)
- [Instructions if](https://go.dev/ref/spec#If_statements)

[Leçon suivante](../04-arrays-and-slices/) · [Journal](../journal/)
