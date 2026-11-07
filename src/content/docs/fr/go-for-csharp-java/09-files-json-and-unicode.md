---
title: "9. Fichiers, JSON et Unicode"
description: "Séparer acquisition des fichiers, validité des octets, décodage JSON et validation métier."
sidebar:
  order: 9
---

## Objectifs

Lire par une abstraction de système de fichiers, décoder des valeurs typées et distinguer encodage, syntaxe et règles métier.

## Quatre frontières, quatre questions

Un chemin, des octets, une valeur JSON et un enregistrement valide sont quatre objets différents. [fs.ReadFile](https://pkg.go.dev/io/fs#ReadFile) obtient les octets d’un système de fichiers. [utf8.Valid](https://pkg.go.dev/unicode/utf8#Valid) vérifie leur encodage. [json.Unmarshal](https://pkg.go.dev/encoding/json#Unmarshal) les décode vers une destination typée. Notre boucle finale impose les règles métier. Confondre ces étapes rend l’échec difficile à expliquer : un fichier lisible peut contenir du JSON invalide, et du JSON valide peut décrire une séance invalide.

La commande utilise [fstest.MapFS](https://pkg.go.dev/testing/fstest#MapFS), un système de fichiers en mémoire de la bibliothèque standard. Elle évite ainsi de dépendre d’un répertoire courant ou des séparateurs du système d’exploitation. records.json est interprété dans ce système. La même opération fs.ReadFile accepte d’autres implémentations de fs.FS. Le CLI ouvrira un vrai fichier choisi par l’utilisateur ; il partage le décodeur sans prétendre que cet exemple prouve les permissions disque et chemins sur toutes les plateformes.

## Définir la forme décodée

Load décode un tableau de Record avec les tags name et minutes. Il rejette null parce que le cours exige un tableau, mais accepte le tableau vide. Un nom absent ou vide et une durée négative échouent à la validation métier. Des minutes absentes deviennent zéro dans ce modèle, et zéro est autorisé. La gestion des champs inconnus n’est pas ici une garantie de schéma strict. Un contrat d’échange l’exigeant demanderait une politique explicite du décodeur et des tests.

Le lecteur charge toute l’entrée avant décodage. C’est simple pour un petit journal local ; ce n’est pas un parseur borné en flux pour de grands téléversements non fiables. Ne le présentez pas ainsi. Le cours avancé traite séparément flux et délimitation. Additionner des entiers arbitrairement grands peut aussi déborder : les petits exemples et le CLI ne définissent pas un contrat comptable ou financier.

## Validité Unicode et largeur d’affichage

Le contrôle UTF-8 rejette les encodages invalides avant l’analyse. Il ne normalise pas le texte et ne détermine pas les caractères visibles. café occupe toujours cinq octets et quatre runes. Un accent décomposé peut modifier le nombre de runes tout en donnant un affichage proche. Le cours conserve les noms reçus parce que son contrat ne prévoit pas de normalisation linguistique. Validez exactement la promesse de l’application et séparez la présentation.

En C#, on reconnaîtra [System.Text.Json](https://learn.microsoft.com/dotnet/standard/serialization/system-text-json/overview) ; Java possède plusieurs bibliothèques JSON d’écosystème plutôt qu’une fonctionnalité équivalente du langage. Go fournit encodeur et décodeur dans sa bibliothèque standard, mais leur comportement reste versionné. Go 1.27 change les implémentations JSON par défaut. Nous utilisons les API encoding/json précises indiquées ici et testons les entrées du cours, sans transformer d’anciennes hypothèses en garantie universelle de compatibilité.

## Suivre tout l’exemple

L’exemple lit Sample par le système de fichiers, crée un [`io.Reader`](https://pkg.go.dev/io#Reader) sur ses octets et appelle le même Load que le CLI. Il affiche ensuite deux enregistrements et une mesure Unicode indépendante. Les erreurs de syntaxe restent des erreurs ; les tests écrits couvrent texte malformé, contenu supplémentaire et UTF-8 invalide. La seule sortie du chemin réussi ne démontrerait pas ces règles de rejet.

## Exemple détaillé

Source complète: [`cmd/l09/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l09/main.go).

```go
package main

import (
	"bytes"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"io/fs"
	"testing/fstest"
	"unicode/utf8"
)

func main() {
	disk := fstest.MapFS{"records.json": {Data: []byte(study.Sample)}}
	data, err := fs.ReadFile(disk, "records.json")
	if err != nil {
		panic(err)
	}
	records, err := study.Load(bytes.NewReader(data))
	if err != nil {
		panic(err)
	}
	fmt.Printf("records=%d bytes=%d runes=%d\n", len(records), len("café"), utf8.RuneCountInString("café"))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l09
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
records=2 bytes=5 runes=4
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Faut-il assimiler null et un tableau JSON vide ici ?

<details>
<summary>Solution 1</summary>

Non. Le cours exige un tableau JSON : null donne un slice nil que Load rejette avec ErrInvalid. Un tableau vide est valide et totalise zéro. C’est une politique applicative, pas l’affirmation que null serait du JSON invalide. Le test du lecteur couvre explicitement les deux entrées.

</details>

2. Où ajouter le contrôle d’un nom de séance vide ?

<details>
<summary>Solution 2</summary>

Après le décodage en Record, dans la boucle de validation métier existante. Le décodeur établit le type du champ sans prouver que son contenu a du sens. La condition actuelle vérifie Name vide et Minutes négatif, puis enveloppe ErrInvalid avec l’indice, en préservant la distinction avec lecture et syntaxe.

</details>

## Sources officielles

- [fs.ReadFile](https://pkg.go.dev/io/fs#ReadFile)
- [json.Unmarshal](https://pkg.go.dev/encoding/json#Unmarshal)
- [utf8.Valid](https://pkg.go.dev/unicode/utf8#Valid)
- [Évolutions des bibliothèques en Go 1.27](https://go.dev/doc/go1.27#library)

[Leçon suivante](../10-generics-and-collections/) · [Journal](../journal/)
