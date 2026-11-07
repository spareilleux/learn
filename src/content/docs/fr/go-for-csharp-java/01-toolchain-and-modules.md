---
title: "1. Chaîne d’outils et modules"
description: "Créer un module reproductible et comprendre packages, imports et points d’entrée."
sidebar:
  order: 1
---

## Objectifs

Retrouver la racine d’un module, distinguer package et module, puis lancer une commande du dépôt sans modifier ses dépendances.

## Un petit exécutable avant un framework

[Go](https://go.dev/doc/) fournit un compilateur, un formateur, un lanceur de tests et une commande qui comprend les modules. Commencez par les instructions officielles d’installation adaptées à votre système, puis utilisez les mêmes commandes sous Windows, Linux/WSL et macOS. Le cours cible Go 1.27 ; le coordinateur a identifié Go 1.27.1 sous Windows. Cette information décrit l’environnement : elle ne prouve pas que les nouveaux exemples ont réussi. Notre premier résultat sera un programme qui importe des données locales et affiche une ligne stable.

Un module rassemble des packages et possède une version. Sa racine contient [`go.mod`](https://go.dev/ref/mod#go-mod-file), dont la directive module fournit le préfixe des imports. Ici, ce préfixe est example.com/learn/go-for-csharp-java. C’est un identifiant pédagogique : importer les packages du même module ne nécessite aucune requête vers example.com. Un package correspond généralement aux fichiers Go d’un répertoire. La clause package nomme leur unité de compilation ; le chemin d’import indique son emplacement. Plusieurs répertoires d’exécutables peuvent partager le même module et ses packages internes.

## Lire le projet de l’extérieur vers l’intérieur

La première commande se trouve dans cmd/l01/main.go. Le package main et une fonction nommée main définissent un exécutable. L’import d’internal/study réunit le préfixe du module et un répertoire. Une initiale majuscule exporte un identifiant : main peut donc appeler Fixture et lire Course. Les déclarations commençant par une minuscule restent accessibles dans leur package. Le répertoire internal limite aussi les packages autorisés à l’importer ; cette frontière de visibilité est vérifiée par l’outillage.

Lancez les commandes depuis code/go-for-csharp-java, pas depuis la racine du dépôt. Le fichier go.mod existe déjà : ne lancez pas go mod init dessus. La commande go run compile et lance le package demandé ; ses artefacts de compilation ne constituent pas une distribution publiée. go build produit des artefacts de construction, tandis que go test construit puis exécute les tests. Le formatage avec [`gofmt`](https://pkg.go.dev/cmd/gofmt) est une opération déterministe distincte. Ces différences compteront quand nous testerons les entrées du CLI : une compilation réussie ne suffit pas à les valider.

## Transposer vos connaissances de compilation

Un fichier projet C# et un descripteur de compilation Java regroupent des responsabilités que Go répartit entre conventions de répertoires, go.mod et la commande go. Ne cherchez ni classe Program ni objet application. Le démarrage passe par une fonction du package main. Il n’y a pas non plus de namespace à déclarer autour de chaque élément. L’import ne signifie pas que le package sera téléchargé à chaque lancement ; il intervient dans la compilation et la résolution des modules.

Le cours utilise uniquement la bibliothèque standard : aucune dépendance tierce n’est à installer. La directive go définit la version de langage du module et son exigence minimale de chaîne d’outils ; elle ne prétend pas que le compilateur actif possède exactement cette version corrective. Selon sa configuration, la sélection de chaîne d’outils peut en obtenir une plus récente. Vérifiez votre environnement avant d’interpréter un comportement dépendant de la version. Go 1.27 modifie certaines règles du langage et des bibliothèques ; un ancien tutoriel peut donc contredire le compilateur actuel.

## Suivre la dépendance plutôt que copier les fichiers

Le programme appelle Fixture, qui renvoie deux enregistrements, puis affiche leur nombre. Suivez l’import jusqu’à internal/study/study.go et retrouvez la constante et la fonction. Ce parcours relie dès maintenant exécutable, package local, données typées et sortie visible. Les prochaines leçons remplaceront le comptage par la sélection, le décodage JSON et le rapport. Conservez cette relation entre packages pendant vos essais. Copier l’utilitaire dans chaque commande masquerait la question essentielle : le projet final utilise-t-il vraiment les comportements étudiés ?

Un piège fréquent consiste à lancer un seul fichier source alors que l’exemple dépend de plusieurs fichiers du package. Préférez le chemin de package indiqué ci-dessous. Un autre consiste à renommer le module sans adapter les imports. Ces deux écritures forment un contrat. Enfin, un import relatif écrit comme un chemin vers le répertoire parent ne convient pas ici. Utilisez le préfixe du module et conservez l’arborescence.

## Exemple détaillé

Source complète: [`cmd/l01/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l01/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	fmt.Printf("module=%s records=%d\n", study.Course, len(study.Fixture()))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l01
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
module=study-log records=2
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Pourquoi cet exemple peut-il fonctionner sans contacter example.com ?

<details>
<summary>Solution 1</summary>

L’import est résolu dans le module courant parce que son préfixe correspond à go.mod. Le nom ressemblant à un domaine identifie le module ; il ne demande pas de contacter un site à l’exécution. La dépendance est le package internal/study du dépôt. Le manifeste prévoit deux enregistrements parce que Fixture construit exactement deux valeurs.

</details>

2. Comment ajouter une deuxième commande sans dupliquer les données ?

<details>
<summary>Solution 2</summary>

Créez un autre sous-répertoire de cmd, déclarez package main, importez example.com/learn/go-for-csharp-java/internal/study et appelez study.Fixture dans main. Le programme l01 constitue un modèle complet. Conservez go.mod et le package partagé. Seul le répertoire de l’exécutable change : aucun nouveau module ni aucune dépendance ne sont nécessaires.

</details>

## Sources officielles

- [Tutoriel sur les modules Go](https://go.dev/doc/tutorial/create-module)
- [Commande go](https://pkg.go.dev/cmd/go)
- [Référence des modules](https://go.dev/ref/mod)

[Leçon suivante](../02-values-types-and-strings/) · [Journal](../journal/)
