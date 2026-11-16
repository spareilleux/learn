---
title: "8. Erreurs, defer et ressources"
description: "Préserver l’identité des erreurs, ajouter du contexte et libérer les ressources possédées."
sidebar:
  order: 8
---

## Objectifs

Distinguer erreurs d’entrée et défaillances de programmation, reconnaître les causes enveloppées et placer le nettoyage après l’acquisition.

## L’échec fait partie du résultat

L’[interface error](https://pkg.go.dev/builtin#error) décrit une valeur possédant une méthode Error. Une fonction renvoie souvent une valeur utile et une erreur ; l’appelant vérifie l’erreur avant d’utiliser la valeur. Load ne renvoie les enregistrements qu’après lecture, décodage et validation réussis. Une donnée utilisateur malformée est un échec ordinaire. Elle doit être signalée à l’appelant sans arrêter le processus au fond d’un package réutilisable.

La commande charge les données connues, puis soumet volontairement un nom vide. La première opération doit produire quarante minutes au total. La seconde doit produire une erreur liée à ErrInvalid. Le panic sur un échec inattendu des données fixes reste limité à l’hypothèse de démarrage de cette commande pédagogique ; Load ne panique pas pour une entrée utilisateur invalide. Le CLI transformera la même erreur en diagnostic et code de sortie non nul.

## Conserver la cause en ajoutant du contexte

[fmt.Errorf](https://pkg.go.dev/fmt#Errorf), avec le format d’enveloppement, ajoute un emplacement utile tout en conservant l’erreur sous-jacente. Load indique l’indice du record et enveloppe ErrInvalid. [errors.Is](https://pkg.go.dev/errors#Is) retrouve cette cause malgré le contexte. Comparer le message complet transformerait une simple reformulation en rupture de compatibilité. Comparer seulement l’erreur externe par égalité manquerait la sentinelle enveloppée.

Toutes les erreurs ne sont pas ErrInvalid. Un échec de lecture conserve sa cause ; les erreurs de syntaxe et de type JSON gardent les informations du décodeur. Décidez quelles distinctions servent vraiment l’appelant. Une sentinelle identifie une catégorie ; un type concret et [`errors.As`](https://pkg.go.dev/errors#As) peuvent exposer des détails structurés si un consommateur les exige. Inutile de reproduire une hiérarchie d’exceptions. Les tests vérifient l’identité de validation et la préservation d’une vraie erreur de lecture.

## Nettoyer après une acquisition réussie

Une [instruction defer](https://go.dev/ref/spec#Defer_statements) programme un appel au retour de la fonction courante. Enregistrez le nettoyage après réussite de l’acquisition. Dans le CLI, [`os.Open`](https://pkg.go.dev/os#Open) renvoie fichier et erreur ; seule la branche réussie diffère [File.Close](https://pkg.go.dev/os#File.Close). Les arguments sont évalués au passage sur defer ; les appels différés s’exécutent dans l’ordre inverse. Un defer dans une longue boucle attend le retour de la fonction : réduisez la portée de vie par une fonction plus petite si nécessaire.

Fermer un fichier d’entrée libère une ressource ; cela ne donne pas la propriété de l’entrée standard fournie par l’appelant. Le CLI ferme donc les fichiers qu’il ouvre et laisse le lecteur fourni à son propriétaire. Pour un fichier de sortie, Close peut signaler un échec important et fait partie de la réussite de l’écriture. Notre projet ouvre seulement des fichiers d’entrée et vérifie ses écritures : il ne prétend pas réaliser un remplacement durable de fichier.

## Transposer le contrôle, pas la syntaxe

[C# using](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/using) et [Java try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html) lient le nettoyage à une construction lexicale. Go defer le lie au retour d’une fonction. Les erreurs ordinaires sont aussi renvoyées explicitement plutôt que propagées automatiquement par déroulement de pile. Chaque choix devient visible, mais chaque résultat pertinent doit être vérifié. Ignorer une erreur avec l’identifiant vide supprime volontairement de l’information ; ce n’est pas une réussite.

## Exemple détaillé

Source complète: [`cmd/l08/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l08/main.go).

```go
package main

import (
	"errors"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"strings"
)

func main() {
	records, err := study.Load(strings.NewReader(study.Sample))
	if err != nil {
		panic(err)
	}
	_, invalid := study.Load(strings.NewReader(`[{"name":"","minutes":1}]`))
	fmt.Printf("total=%d invalid=%t\n", study.Total(records), errors.Is(invalid, study.ErrInvalid))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l08
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
total=40 invalid=true
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Pourquoi utiliser errors.Is plutôt que comparer le texte ?

<details>
<summary>Solution 1</summary>

Load ajoute notamment l’indice de l’enregistrement : l’erreur externe n’est donc pas directement la sentinelle. errors.Is suit l’enveloppement et reconnaît ErrInvalid. Comparer le texte dépendrait de sa formulation et de sa ponctuation. Le test de validation exprime ce contrat sans promettre un diagnostic utilisateur exact.

</details>

2. Qui ferme un fichier fourni à Load, et où placer defer ?

<details>
<summary>Solution 2</summary>

L’appelant qui ouvre correctement le fichier doit le fermer. Load accepte io.Reader et ne peut supposer qu’il s’agit d’un fichier ni qu’il possède sa durée de vie. Dans cli.Run, defer suit la branche os.Open réussie. Un retour anticipé après une erreur de décodage exécute quand même cette fermeture.

</details>

## Sources officielles

- [errors.Is](https://pkg.go.dev/errors#Is)
- [fmt.Errorf](https://pkg.go.dev/fmt#Errorf)
- [Instructions defer](https://go.dev/ref/spec#Defer_statements)
- [File.Close](https://pkg.go.dev/os#File.Close)

[Leçon suivante](../09-files-json-and-unicode/) · [Journal](../journal/)
