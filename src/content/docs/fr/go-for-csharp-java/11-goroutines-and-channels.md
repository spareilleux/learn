---
title: "11. Goroutines et canaux"
description: "Transmettre des enregistrements avec fermeture possédée et envois annulables."
sidebar:
  order: 11
---

## Objectifs

Suivre un échange sans tampon, attribuer la fermeture du canal et permettre l’annulation d’un émetteur bloqué.

## La concurrence a besoin d’une durée de vie

Une [instruction go](https://go.dev/ref/spec#Go_statements) lance une fonction dans une goroutine. Elle ne renvoie pas un futur qui se rejoindrait automatiquement. L’appelant doit décider comment le travail se termine, comment signaler ses erreurs et comment l’annulation arrête un travail abandonné. Stream lance un producteur et renvoie un canal de réception. La commande consomme jusqu’à sa fermeture : l’achèvement est explicite, sans pause arbitraire ni hypothèse sur la vitesse d’exécution.

Un [canal](https://go.dev/ref/spec#Channel_types) transmet des valeurs entre goroutines. Celui de Stream n’a pas de tampon : chaque envoi réussi rencontre un récepteur. Il ne conserve pas une accumulation arbitraire. Un canal avec tampon autorise au contraire un nombre borné de valeurs en attente. La capacité change l’ordonnancement et la contre-pression, mais ne remplace pas une politique de terminaison. Choisissez un tampon pour exprimer une borne réelle, pas pour cacher un producteur jamais consommé.

## Posséder l’opération de fermeture

Le producteur crée le canal et programme close avant ses envois. Lui seul sait quand il n’a plus de valeurs. Le consommateur parcourt le canal et s’arrête lorsqu’il est fermé et vidé. Un récepteur ne doit pas fermer simplement parce qu’il veut arrêter de lire : l’émetteur peut encore écrire. Fermer deux fois ou envoyer après fermeture est une erreur de programmation ; la propriété doit donc être visible dans la structure.

Stream renvoie un canal limité à la réception. L’appelant ne peut ni envoyer ni fermer par cette valeur. Le type documente le sens de circulation et permet au compilateur de vérifier une partie du contrat. Les Record transmis sont copiés. Leurs champs actuels se lisent indépendamment après le transfert, mais un record contenant pointeurs ou maps ne serait pas automatiquement copié en profondeur.

## Annuler les opérations bloquées

Le [select](https://go.dev/ref/spec#Select_statements) de Stream attend un récepteur ou l’annulation du contexte. Un envoi simple pourrait rester bloqué si l’appelant arrêtait la lecture. Le canal d’annulation fournit une sortie. La commande possède cancel et le diffère : un retour normal abandonnant l’opération peut donc libérer le producteur. Un contexte n’interrompt pas brutalement un code quelconque ; ce code doit l’observer.

Si plusieurs cas sont prêts, l’annulation ne gagne pas nécessairement chaque sélection. Ne promettez pas qu’elle supprime toute dernière valeur proche de son observation. Count vérifie l’annulation avant le démarrage et après la fin du flux ; ce contrat diffère de l’affirmation qu’aucune valeur ne peut circuler près de l’annulation. Les tests utilisent annulation explicite et achèvement des canaux plutôt que des pauses pour établir l’ordre.

## Comparer tâches et threads

[C# Task](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task) et les [threads virtuels Java](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) aident à imaginer le travail indépendant, mais goroutines et canaux ont leurs propres règles d’achèvement. Le [modèle mémoire Go](https://go.dev/ref/mem) définit la synchronisation des opérations de canal. Démarrer une goroutine ne sécurise pas les écritures partagées. L’exemple évite un accumulateur partagé : seul le consommateur additionne. Le total attendu de quarante ne dépend pas de l’entrelacement choisi par l’ordonnanceur.

## Exemple détaillé

Source complète: [`cmd/l11/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l11/main.go).

```go
package main

import (
	"context"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var total study.Minutes
	for record := range study.Stream(ctx, study.Fixture()) {
		total += record.Minutes
	}
	fmt.Printf("stream-total=%d\n", total)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l11
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
stream-total=40
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Le consommateur peut-il fermer le canal après un seul record ?

<details>
<summary>Solution 1</summary>

Non. Le producteur peut encore envoyer le second ; la fermeture violerait son contrat de propriété. Pour abandonner le flux, le consommateur annule le contexte qu’il possède puis retourne. Le producteur observe l’annulation dans select et ferme lui-même son canal en sortant.

</details>

2. Pourquoi un tampon de deux ne règle-t-il pas toute fuite ?

<details>
<summary>Solution 2</summary>

Il permet seulement aux deux envois de cet exemple de finir sans récepteur immédiat. Une source plus grande peut remplir le tampon puis bloquer. La solution durable borne la durée de vie : le cas d’annulation libère le producteur bloqué, tandis que consommation et fermeture décrivent l’achèvement normal. Capacité et annulation répondent à deux besoins différents.

</details>

## Sources officielles

- [Instructions go](https://go.dev/ref/spec#Go_statements)
- [Types canaux](https://go.dev/ref/spec#Channel_types)
- [Instructions select](https://go.dev/ref/spec#Select_statements)
- [Modèle mémoire Go](https://go.dev/ref/mem)

[Leçon suivante](../12-http-and-context/) · [Journal](../journal/)
