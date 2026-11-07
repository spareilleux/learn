---
title: "13. Tests"
description: "Vérifier les contrats observables par tables, exemples, tests HTTP et cible de fuzzing bornée."
sidebar:
  order: 13
---

## Objectifs

Choisir un comportement à vérifier, distinguer assertion et affichage démonstratif et comprendre les tests déterministes d’annulation.

## Un affichage réussi ne couvre pas tout

Le [package testing](https://pkg.go.dev/testing) découvre les fonctions de test dans les fichiers terminés par _test.go. Une fonction Test reçoit [`testing.T`](https://pkg.go.dev/testing#T) et lui signale ses échecs. La commande affiche total initial et total vide, mais les tests vérifient aussi partage, copies indépendantes, données invalides, identité des erreurs, Unicode, ordre et annulation. Il s’agit de rendre des erreurs plausibles observables, pas seulement de parcourir toutes les lignes.

TestSelectBoundaryAndOrder emploie des durées de dix-neuf et vingt minutes. Un seuil de vingt doit inclure les deux valeurs limites, exclure dix-neuf et conserver l’ordre. Le test modifie aussi un résultat sélectionné et vérifie que l’entrée reste intacte. Ce sont des contrats de comportement. Réécrire la boucle sans les modifier doit garder le test valide. Calculer l’attente avec Select elle-même supprimerait sa vérification indépendante.

## Les tables rendent les cas lisibles

Les tests de Load et du CLI utilisent des tables : chaque ligne nomme une entrée, un résultat et une catégorie. Les [sous-tests](https://pkg.go.dev/testing#hdr-Subtests_and_Sub_benchmarks) identifient le scénario en échec. Choisissez des lignes significatives. JSON malformé, journal vide et durée nulle valide sont trois contrats différents ; multiplier des noms valides équivalents n’apporte pas autant. Les messages d’échec doivent montrer les données observées utiles au diagnostic.

Un [test d’exemple](https://pkg.go.dev/testing#hdr-Examples) documente un petit comportement et vérifie sa sortie. ExampleTotal affiche quarante et zéro avec la directive comprise par le lanceur. Cette directive est une métadonnée exécutable, pas la prétention d’avoir capturé une session manuelle. Le manifeste vérifie séparément les quatorze commandes. Les exemples démontrent un format stable ; les assertions examinent comportement métier et catégories d’erreurs.

## Employer de vraies frontières simples

Les tests CLI appellent Run avec de vrais lecteurs et tampons : options, JSON, sélection et rapport sont exercés ensemble. Un fichier temporaire teste l’acquisition sans fixture permanente. Les tests HTTP appellent le véritable gestionnaire avec [`httptest`](https://pkg.go.dev/net/http/httptest). Aucun simulacre de Select ne renvoie simplement le nombre désiré ; ces tests peuvent donc révéler des défauts d’intégration entre frontière et cœur.

Le test d’annulation annule avant Count et vérifie [`context.Canceled`](https://pkg.go.dev/context#Canceled). Il n’attend pas arbitrairement en espérant une position particulière d’une goroutine. La fin du canal offre aussi un point de jonction observable. Le détecteur de courses constitue une vérification distincte : un test ordinaire réussi ne prouve pas l’absence de courses. Le coordinateur effectue les exécutions faisant autorité et indique leur environnement réel dans le journal.

## Explorer sans inventer des mesures

La [cible de fuzzing](https://go.dev/doc/security/fuzz/) part d’un exemple valide, d’un tableau vide et de null. Pour toute entrée acceptée, elle vérifie noms non vides et durées positives ou nulles. Les erreurs sont des résultats légitimes : une entrée arbitraire malformée n’est pas une défaillance du test. Une exécution normale teste les graines ; une commande bornée explore leurs mutations. N’annoncez aucun nombre de cas ni pourcentage de couverture sans mesure réelle.

Vous pouvez conserver vos habitudes C# et Java de tests observables tout en utilisant la découverte intégrée de Go. Nommez le défaut visé, écrivez une attente indépendante et gardez une préparation plus petite que le comportement testé. Les tests complets restent lisibles dans le module, à côté de l’implémentation.

## Exemple détaillé

Source complète: [`cmd/l13/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l13/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	records := study.Fixture()
	fmt.Printf("fixture-total=%d empty-total=%d\n", study.Total(records), study.Total(nil))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l13
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
fixture-total=40 empty-total=0
```

## Une assertion du comportement à la limite

[`internal/study/study_test.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/internal/study/study_test.go)

```go
func TestSelectBoundaryAndOrder(t *testing.T) {
	records := []Record{{"first", 20}, {"skip", 19}, {"last", 20}}
	selected := Select(records, 20)
	if len(selected) != 2 || selected[0].Name != "first" || selected[1].Name != "last" {
		t.Fatal(selected)
	}
	selected[0].Name = "changed"
	if records[0].Name != "first" {
		t.Fatal("selection aliases the input elements")
	}
}
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Quel test détecte une comparaison devenue stricte ?

<details>
<summary>Solution 1</summary>

TestSelectBoundaryAndOrder : ses valeurs exactement à vingt doivent être retenues par un seuil de vingt. Une comparaison stricte les exclurait et ferait échouer longueur et ordre attendus. Le test ne demande pas à l’implémentation de calculer son attente ; les enregistrements voulus sont indiqués indépendamment.

</details>

2. Le fuzzing prouve-t-il que toute entrée acceptée se somme sans limite ?

<details>
<summary>Solution 2</summary>

Non. La propriété vérifie noms et durées négatives, pas toutes les bornes arithmétiques ni les ressources. Réussir les graines n’est pas non plus une campagne prolongée. Limitez la conclusion aux assertions existantes et consignez durée et résultats réels après exécution. Un contrat plus fort demanderait les règles et tests correspondants.

</details>

## Sources officielles

- [Package testing](https://pkg.go.dev/testing)
- [Tests d’exemples](https://pkg.go.dev/testing#hdr-Examples)
- [Sous-tests](https://pkg.go.dev/testing#hdr-Subtests_and_Sub_benchmarks)
- [Tests par fuzzing](https://go.dev/doc/security/fuzz/)

[Leçon suivante](../14-cli-capstone/) · [Journal](../journal/)
