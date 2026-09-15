---
title: "5. Interfaces et génériques"
description: Des interfaces qu'un type implémente sans le dire, et des génériques sans contraintes — essayés sur les 111 projets .NET de GuitarAlchemist/ga.
sidebar:
  order: 5
---

Code : [`examples/l05_interfaces.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v) et [`examples/l05_generics.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v) — `v run examples/l05_generics.v` depuis `code/v-for-csharp-java`.

## Nouvelles données : les projets d'une solution .NET

À partir de cette leçon, les exemples lisent les projets .NET de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), une application de théorie musicale, au commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893). Le [cours LadybugDB](../../ladybugdb/05-csharp/) les a extraits des fichiers `.csproj` et `.fsproj` ; [`data/ga`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/data/ga) contient une copie de ses trois fichiers CSV :

| Fichier | Lignes | Colonnes |
|---|---|---|
| `projects.csv` | 111 | `path,name,language,sdk,frameworks,in_solution` |
| `project_refs.csv` | 266 | `from,to` : une `ProjectReference`, du chemin d'un projet au chemin d'un projet |
| `package_refs.csv` | 478 | `project,package,version` : une `PackageReference` |

Aucun champ ne contient de virgule, donc `line.split(',')` suffit ici, contrairement aux titres de pages de la [leçon 3](../03-errors-option-result/).

## Interfaces

| | C# | Java | V |
|---|---|---|---|
| Un type implémente une interface | en la déclarant : `class Package : INamed` | en la déclarant : `implements Named` | en ayant ses méthodes et ses champs |
| La déclaration | obligatoire | obligatoire | facultative : `struct Package implements Named` |
| Membres | méthodes, propriétés, [implémentations par défaut](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/default-interface-methods-versions) | méthodes, [méthodes par défaut](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html) | méthodes et champs |
| Tester le type | `if (n is Project p)` | `if (n instanceof Project p)` | `if n is Project { }` |

Source : [Interfaces](https://docs.vlang.io/type-declarations.html#interfaces).

Une interface liste des méthodes, et aussi des champs. [`Project` et `Package`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L4-L38) ont tous deux un champ `name` et une méthode `kind()`, donc tous deux sont des `Named`, sans que leurs déclarations en disent un mot :

```v
interface Named {
	name string
	kind() string
}

fn (p Project) kind() string {
	return 'project'
}

fn (p Package) kind() string {
	return 'package'
}

fn describe(n Named) string {
	return '${n.kind()} ${n.name}'
}
```

Un tableau de valeurs d'interface contient des types différents, comme le ferait une `List<INamed>`. `is` teste le type et convertit la variable à l'intérieur du `if`, comme les types d'erreur de la leçon 3 :

```v
items := [Named(project), package, Language{'F#'}]
for item in items {
	println(describe(item))
	println('  ${item.label()}')
	if item is Project {
		println('  sdk: ${item.sdk}')
	}
}
```

```text
project AllProjects.AppHost
  [project] AllProjects.AppHost
  sdk: Microsoft.NET.Sdk
package Aspire.Dashboard.Sdk.win-x64
  [package] Aspire.Dashboard.Sdk.win-x64
language F#
  [language] F#
```

`Named(project)` convertit le premier élément ; V convertit ensuite les autres vers le type d'élément du tableau.

### Une méthode manquante est signalée là où la valeur est convertie

C# signale un membre manquant sur la déclaration de la classe (`error CS0535: 'Package' does not implement interface member 'INamed.Kind()'`), et javac aussi (`Package is not abstract and does not override abstract method kind() in Named`). En V, `Package` ne déclare rien, donc l'erreur apparaît là où un `Package` devient un `Named` :

```v
struct Package {
	name    string
	version string
}

fn main() {
	println(describe(Package{'Aspire.Hosting.AppHost', '9.5.1'}))
}
```

```text
e05_missing_method.v:16:19: error: `Package` doesn't implement method `kind` of interface `Named`
   14 | 
   15 | fn main() {
   16 |     println(describe(Package{'Aspire.Hosting.AppHost', '9.5.1'}))
      |                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   17 | }
```

Une struct qui n'est jamais convertie n'est jamais vérifiée. Le `implements` facultatif déplace la vérification vers la déclaration, comme en C# et en Java :

```v
struct Package implements Named {
	name    string
	version string
}
```

```text
e05_implements.v:6:1: error: `Package` doesn't implement method `kind` of interface `Named`
    4 | }
    5 | 
    6 | struct Package implements Named {
      | ~~~~~~~~~~~~~~
    7 |     name    string
    8 |     version string
```

Le [`Language`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L73-L79) de l'exemple l'utilise.

### Les méthodes sur l'interface ne sont pas des implémentations par défaut

`fn (n Named) label()` déclare une méthode sur l'interface elle-même. Toute valeur `Named` la possède, et les types ne l'implémentent pas. La documentation avertit que ce n'est « PAS une "implémentation par défaut" comme en C# » : si `Project` avait son propre `label()`, appeler `label()` sur un `Named` exécuterait quand même la méthode de l'interface, et celle de `Project` seulement après `is Project`. Elle se comporte comme une méthode d'extension C# sur `INamed`, écrite comme une méthode.

### Méthodes `mut:`

Une méthode qui modifie son receveur va dans la section `mut:` de l'interface. [`Counter` et `Distinct`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L40-L71) comptent les références de paquets de deux façons :

```v
interface Tally {
mut:
	add(key string)
	total() int
}
```

```v
lines := os.read_lines('data/ga/package_refs.csv')![1..]
mut tallies := [Tally(Counter{}), Distinct{}]
for mut t in tallies {
	for line in lines {
		t.add(line.split(',')[1])
	}
}
println('package references: ${tallies[0].total()}, distinct packages: ${tallies[1].total()}')
```

```text
package references: 478, distinct packages: 136
```

`for mut t` est nécessaire pour appeler `add`. Hors de `mut:`, une méthode d'interface est appelée sur une valeur immuable, et un type dont la méthode a un receveur `mut` ne l'implémente pas :

```v
interface Tally {
	add(key string)
}

fn (mut c Counter) add(_ string) {
	c.n++
}

fn main() {
	t := Tally(Counter{})
	t.add('Aspire.Hosting.AppHost')
}
```

```text
e05_mut_receiver.v:15:7: error: `Counter` incorrectly implements method `add` of interface `Tally`: expected `Tally` which is immutable, not `mut &Counter`
   13 | 
   14 | fn main() {
   15 |     t := Tally(Counter{})
      |          ~~~~~~~~~~~~~~~~
   16 |     t.add('Aspire.Hosting.AppHost')
   17 | }
Details: main.Tally has `fn add(x main.Tally, key string)`
         main.Counter has `fn add(mut c main.Counter, _ string)`
e05_mut_receiver.v:15:7: error: `Counter` does not implement interface `Tally`, cannot cast `Counter` to interface `Tally`
   13 | 
   14 | fn main() {
   15 |     t := Tally(Counter{})
      |          ~~~~~~~~~~~~~~~~
   16 |     t.add('Aspire.Hosting.AppHost')
   17 | }
```

L'inverse est accepté : `total()` est dans la section `mut:`, et `Counter` l'implémente avec un receveur immuable. La documentation de la 0.5.2 dit le contraire (un type avec `fn (s MyStruct) write` « implémente l'interface Foo, mais *pas* l'interface Bar », dont le `write` est dans `mut:`) ; le compilateur ne rejette qu'un receveur `mut` pour une méthode hors de `mut:` (voir le [journal](../journal/)).

### Une struct est copiée dans une interface

```v
mut counter := Counter{}
mut copied := Tally(counter)
copied.add('Aspire.Hosting.AppHost')
println('copied: counter.n = ${counter.n}, copied.total() = ${copied.total()}')
mut shared_counter := &Counter{}
mut through_ref := Tally(shared_counter)
through_ref.add('Aspire.Hosting.AppHost')
println('reference: shared_counter.n = ${shared_counter.n}')
```

```text
copied: counter.n = 0, copied.total() = 1
reference: shared_counter.n = 1
```

Convertir une valeur struct en interface la copie, comme le [boxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing) d'une `struct` C# : avec `struct Counter : ITally`, `ITally copied = counter;` laisse aussi `counter.N` à 0, ce que j'ai vérifié avec .NET 11. Convertir une référence (`&Counter`) partage la struct, comme convertir une classe C# ou n'importe quel objet Java.

Les interfaces peuvent aussi incorporer d'autres interfaces, comme les structs incorporent des structs : `interface ReaderWriter { Reader Writer }` ([Embedded interface](https://docs.vlang.io/type-declarations.html#embedded-interface)).

## Génériques

| | C# | Java | V |
|---|---|---|---|
| Fonction générique | `Dictionary<string, int> CountBy<T>(…)` | `<T> Map<String, Integer> countBy(…)` | `fn count_by[T](…) map[string]int` |
| Arguments de type | inférés, ou `CountBy<Project>(…)` | inférés, ou `Util.<Project>countBy(…)` | inférés, ou `count_by[Project](…)` |
| Contraintes | [`where T : IComparable<T>`](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters) | [`<T extends Comparable<T>>`](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html) | aucune : chaque usage est vérifié avec le type concret |
| À l'exécution | une version par type valeur, du code partagé pour les références | [effacés](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html) en `Object` ou en la borne | une copie de la fonction par type utilisé |

Source : [Generics](https://docs.vlang.io/type-declarations.html#generics).

### Fonctions génériques

[`count_by`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L35-L47) regroupe des éléments par clé, comme `GroupBy(key).ToDictionary(g => g.Key, g => g.Count())` en LINQ ou `Collectors.groupingBy(key, Collectors.counting())` en Java :

```v
fn count_by[T](items []T, key fn (T) string) map[string]int {
	mut counts := map[string]int{}
	for item in items {
		counts[key(item)]++
	}
	return counts
}

// Aucune contrainte : il suffit que T ait un champ `name` à chaque appel
fn names[T](items []T) []string {
	return items.map(it.name)
}
```

```v
println(count_by(projects, fn (p Project) string {
	return p.language
}))
println(count_by[Project](projects, fn (p Project) string {
	return p.sdk
}))
println(names(projects[..2]))
println(names(packages[..2]))
```

```text
{'C#': 105, 'F#': 6}
{'Microsoft.NET.Sdk': 95, 'Microsoft.NET.Sdk.Web': 16}
['AllProjects.AppHost', 'AllProjects.ServiceDefaults']
['Aspire.Dashboard.Sdk.win-x64', 'Aspire.Hosting.AppHost']
```

ga a 105 projets C# et 6 projets F#, dont 16 projets web. V infère `T` à partir des arguments. Quand aucun argument n'est de type `T`, il faut le donner :

```v
fn parse[T](field string) T {
	return field.int()
}

fn main() {
	println(parse('111'))
}
```

```text
e05_infer.v:6:10: error: could not infer generic type `T` in call to `parse`
    4 | 
    5 | fn main() {
    6 |     println(parse('111'))
      |             ~~~~~~~~~~~~
    7 | }
```

`names` lit `it.name` sur un `T` que rien ne contraint. C# refuserait de compiler la fonction elle-même ; V vérifie à nouveau le corps pour chaque type avec lequel elle est appelée, comme un template C++. `Project` et `Package` ont tous deux un `name`. Un type qui n'en a pas échoue, et l'erreur pointe dans la fonction générique, pas sur l'appel :

```v
struct Package {
	id      string
	version string
}

fn names[T](items []T) []string {
	return items.map(it.name)
}

fn main() {
	println(names([Package{'Aspire.Hosting.AppHost', '9.5.1'}]))
}
```

```text
e05_generic_field.v:7:22: error: type `Package` has no field named `name`.
2 possibilities: `id`, `version`.
    5 | 
    6 | fn names[T](items []T) []string {
    7 |     return items.map(it.name)
      |                         ~~~~
    8 | }
    9 |
e05_generic_field.v:7:15: error: cannot use `[]void` as type `[]string` in return argument
    5 | 
    6 | fn names[T](items []T) []string {
    7 |     return items.map(it.name)
      |                  ~~~~~~~~~~~~
    8 | }
    9 |
```

### Structs génériques

[`Index[T]`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L49-L61) est une map d'une clé vers un `T`, avec des méthodes. `get` renvoie une option, là où C# aurait `TryGetValue` et Java `Optional<T>` :

```v
struct Index[T] {
mut:
	by_key map[string]T
}

fn (mut ix Index[T]) add(key string, value T) {
	ix.by_key[key] = value
}

fn (ix Index[T]) get(key string) ?T {
	return ix.by_key[key] or { return none }
}
```

```v
mut ix := Index[Project]{}
for p in projects {
	ix.add(p.name, p)
}
println(ix.get('GaApi') or { Project{} }.path)
if p := ix.get('GaServer') {
	println(p.path)
} else {
	println('GaServer: not found')
}
println(typeof(ix).name)
```

```text
Apps/ga-server/GaApi/GaApi.csproj
GaServer: not found
Index[Project]
```

Le nom est une mauvaise clé pour ga : deux projets s'appellent `GaApi.Tests`, dans `Tests/Apps/GaApi.Tests` et `Tests/GaApi.Tests`, donc le second `add` remplace le premier, et l'index contient 110 projets. Le chemin, lui, est unique.

### Opérateurs dans une fonction générique

[`largest`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L63-L84) compare avec `>`. C# le rejette dans la méthode générique elle-même (`error CS0019: Operator '>' cannot be applied to operands of type 'T' and 'T'`) sauf si `T` a une contrainte. V l'accepte pour les nombres et les chaînes, et pour une struct qui définit `<` : V en génère `>`, `<=` et `>=` ([surcharge d'opérateurs](https://docs.vlang.io/limited-operator-overloading.html#implicitly-generated-overloads)).

```v
fn largest[T](items []T) ?T {
	if items.len == 0 {
		return none
	}
	mut best := items[0]
	for x in items[1..] {
		if x > best {
			best = x
		}
	}
	return best
}

struct Usage {
	package  string
	projects int
}

fn (a Usage) < (b Usage) bool {
	return a.projects < b.projects
}
```

```v
println(largest(usages) or { Usage{} })
println(largest(by_package.values()) or { 0 })
println(largest(by_package.keys()) or { '' })
println(largest([]int{}) or { -1 })
```

```text
Usage{
    package: 'Spectre.Console'
    projects: 20
}
20
xunit.runner.visualstudio
-1
```

[Spectre.Console](https://spectreconsole.net/) est le paquet que référencent le plus de projets de ga, 20 d'entre eux. Sans `<`, l'erreur est de nouveau dans la fonction, et sa formulation est curieuse :

```v
fn main() {
	println(largest([20, 12, 9]))
	println(largest([Usage{'Spectre.Console', 20}, Usage{'xunit', 12}]))
}
```

```text
e05_generic_operator.v:9:6: error: cannot use `>` as `<=` operator method is not defined
    7 |     mut best := items[0]
    8 |     for x in items[1..] {
    9 |         if x > best {
      |            ~~~~~~~~
   10 |             best = x
   11 |         }
```

Le message ne nomme pas `Usage`, et ne mentionne pas la ligne 18, l'appel qui le demande. Il ne nomme pas non plus `<`, l'opérateur à définir : `>` est généré à partir de `<`. Dans un programme avec plusieurs appels à `largest`, c'est à toi de trouver celui qui passe une struct.

### Un test à la compilation au lieu d'une contrainte

Sans contraintes, une fonction générique peut tester son argument de type à la compilation avec `$if T is …` ([types à la compilation](https://docs.vlang.io/conditional-compilation.html#compile-time-types)), et `T.name` donne le nom du type :

```v
interface Named {
	name string
}

fn label[T](x T) string {
	$if T is Named {
		return '${T.name} named ${x.name}'
	} $else {
		return 'a ${T.name}'
	}
}
```

```v
println(label(projects[0]))
println(label(usages[0]))
println(label(42))
```

```text
Project named AllProjects.AppHost
a Usage
a int
```

Seule la branche qui correspond à `T` est compilée, donc `x.name` n'est pas vérifié pour `int`. Contrairement à un `where` C#, le test ne rejette pas d'appel : il choisit le code pour chaque type.

## À retenir

- Un type implémente une interface en ayant ses méthodes et ses champs ; la vérification a lieu là où une valeur est convertie, ou à la déclaration avec le `implements` facultatif.
- Les interfaces peuvent exiger des champs. Les méthodes déclarées sur l'interface ne sont pas des implémentations par défaut.
- Une méthode de la section `mut:` exige une valeur d'interface mutable ; un receveur `mut` ne peut pas implémenter une méthode hors de cette section.
- Convertir une valeur struct en interface copie la struct, comme le boxing en C# ; convertir une référence la partage.
- Les génériques n'ont pas de contraintes : le corps est vérifié pour chaque type utilisé, et les erreurs pointent dans la fonction générique plutôt que sur l'appel. `$if T is` choisit le code à la compilation.

## Exercices

1. Écris `fn group_by[T](items []T, key fn (T) string) map[string][]T`, et affiche les noms des projets F# de ga.

<details>
<summary>Solution</summary>

[`examples/s05_group_by.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s05_group_by.v#L10-L16) :

```v
fn group_by[T](items []T, key fn (T) string) map[string][]T {
	mut groups := map[string][]T{}
	for item in items {
		groups[key(item)] << item
	}
	return groups
}
```

```v
groups := group_by(projects, fn (p Project) string {
	return p.language
})
println(groups.keys())
println(groups['F#'].map(it.name))
```

```text
['C#', 'F#']
['GaCli', 'GaMusicTheoryLsp', 'GA.Business.Config', 'GA.Business.Core.Generated', 'GA.Business.DSL', 'GA.Business.ProbabilisticGrammar']
```

`groups[key(item)] << item` fonctionne sur une clé absente : indexer une map pour la modifier crée le tableau vide, comme `counts[key]++` crée le 0 dans `count_by`.

</details>

2. Appelle `largest` sur les projets F# de l'exercice 1, de sorte qu'il renvoie le dernier par nom.

<details>
<summary>Solution</summary>

`Project` a besoin de `<` ([`s05_group_by.v`, lignes 31-34](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s05_group_by.v#L31-L34)) :

```v
fn (a Project) < (b Project) bool {
	return a.name < b.name
}
```

```v
println(largest(groups['F#']) or { Project{} }.name)
```

```text
GaMusicTheoryLsp
```

La comparaison de chaînes est ordinale, comme `string.CompareOrdinal` en C# et `compareTo` en Java : `'a'` vient après `'A'`, donc `GaMusicTheoryLsp` vient après `GA.Business.ProbabilisticGrammar`.

</details>

3. Dans l'exemple de copie, `copied.total()` vaut 1 et `counter.n` vaut 0. Qu'est-ce qui afficherait `copied: counter.n = 1`, et quel est l'équivalent en C# ?

<details>
<summary>Solution</summary>

Convertir une référence au lieu d'une valeur : `mut counter := &Counter{}`, puis `Tally(counter)`, comme le fait l'exemple avec `shared_counter`. En C#, l'interface devrait désigner le même objet : fais de `Counter` une `class` au lieu d'une `struct`. Avec une `struct`, `ITally copied = counter;` met en boîte (boxing) une copie.

</details>

## Sources

- [Documentation V — Interfaces](https://docs.vlang.io/type-declarations.html#interfaces), [Generics](https://docs.vlang.io/type-declarations.html#generics), [Limited operator overloading](https://docs.vlang.io/limited-operator-overloading.html), [Compile-time types](https://docs.vlang.io/conditional-compilation.html#compile-time-types) ; la documentation de la 0.5.2 : [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [C# — Interfaces](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces), [Constraints on type parameters](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Boxing and unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing)
- [Java — Default methods](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html), [Bounded type parameters](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html), [Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html)
- [GuitarAlchemist/ga au commit `a26a7893`](https://github.com/GuitarAlchemist/ga/tree/a26a7893), extraits par le [cours LadybugDB](../../ladybugdb/05-csharp/)
