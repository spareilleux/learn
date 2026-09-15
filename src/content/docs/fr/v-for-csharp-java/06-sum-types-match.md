---
title: "6. Enums, types somme et match"
description: Des enums sans arithmétique, des types somme au lieu de hiérarchies scellées, et un match qui doit couvrir tous les cas — essayés sur les versions de paquets de GuitarAlchemist/ga.
sidebar:
  order: 6
---

Code : [`examples/l06_enums.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v) et [`examples/l06_versions.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v) — `v run examples/l06_versions.v` depuis `code/v-for-csharp-java`. Les données sont les projets de ga de la [leçon 5](../05-interfaces-generics/#nouvelles-données--les-projets-dune-solution-net).

## Enums

| | C# | Java | V |
|---|---|---|---|
| Déclaration | `enum Sdk { Library, Web }` | `enum Sdk { LIBRARY, WEB }` | `enum Sdk { library web }` |
| Valeur sous-jacente | `int`, converti par un cast | un objet, avec `ordinal()` | `int` par défaut, `enum Sdk as u8` |
| Méthodes | méthodes d'extension | oui | oui |
| `<`, `+ 1` | autorisés | `compareTo`, pas de `+` | refusés : `int(sdk)` d'abord |
| Depuis une chaîne | `Enum.Parse<Sdk>("Web")` | `Sdk.valueOf("WEB")` | `Sdk.from('web')!` |
| Ensemble de drapeaux | [`[Flags]`](https://learn.microsoft.com/dotnet/api/system.flagsattribute) | [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html) | `@[flag]` |

Source : [Enums](https://docs.vlang.io/type-declarations.html#enums).

Dans ga, la colonne `sdk` a deux valeurs. [`Sdk`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L4-L23) les nomme, avec une méthode, et une fonction qui lit le nom MSBuild :

```v
enum Sdk {
	library
	web
}

// Un enum peut avoir des méthodes
fn (s Sdk) msbuild_name() string {
	return match s {
		.library { 'Microsoft.NET.Sdk' }
		.web { 'Microsoft.NET.Sdk.Web' }
	}
}

fn parse_sdk(name string) !Sdk {
	return match name {
		'Microsoft.NET.Sdk' { .library }
		'Microsoft.NET.Sdk.Web' { .web }
		else { error('unknown SDK: ${name}') }
	}
}
```

Là où le type est connu, `.web` suffit : `Sdk.web` en entier ailleurs. `match` est une expression, comme une [switch expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) C# ou un `switch` Java avec `->`.

```v
sdk := parse_sdk('Microsoft.NET.Sdk.Web')!
println('${sdk} ${int(sdk)} ${sdk.msbuild_name()}')
println(Sdk.from('library')!)
println(Sdk.from(1)!)
parse_sdk('Microsoft.NET.Sdk.Razor') or { println(err.msg()) }
```

```text
web 1 Microsoft.NET.Sdk.Web
library
web
unknown SDK: Microsoft.NET.Sdk.Razor
```

Un enum s'affiche par son nom, et `int(sdk)` donne sa valeur. Un enum n'est pas pour autant un nombre :

```v
fn main() {
	sdk := Sdk.library
	if sdk < Sdk.web {
		println('library')
	}
	println(sdk + 1)
}
```

```text
e06_enum_operators.v:8:9: error: only `==` and `!=` are defined on `enum`, use an explicit cast to `int` if needed
    6 | fn main() {
    7 |     sdk := Sdk.library
    8 |     if sdk < Sdk.web {
      |            ^
    9 |         println('library')
   10 |     }
e06_enum_operators.v:11:10: error: infix expr: cannot use `int literal` (right expression) as `Sdk`
    9 |         println('library')
   10 |     }
   11 |     println(sdk + 1)
      |             ~~~~~~~
   12 | }
```

C# accepte les deux lignes. Le second message est moins utile que le premier : il dit que `1` n'est pas un `Sdk`, pas que `+` est refusé.

### `match` doit couvrir toutes les valeurs

`msbuild_name` n'a pas de `else` : il nomme les deux valeurs. Ajoute une troisième valeur à l'enum, et chaque `match` de ce genre cesse de compiler :

```v
enum Sdk {
	library
	web
	worker
}

fn default_port(sdk Sdk) int {
	return match sdk {
		.library { 0 }
		.web { 8080 }
	}
}
```

```text
e06_match_enum.v:8:9: error: match must be exhaustive (add match branches for: `.worker` or `else {}` at the end)
    6 | 
    7 | fn default_port(sdk Sdk) int {
    8 |     return match sdk {
      |            ~~~~~~~~~~~
    9 |         .library { 0 }
   10 |         .web { 8080 }
```

C# ne fait qu'avertir : avec .NET 11, une switch expression sur un enum sans `Worker` donne `warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern 'Sdk.Worker' is not covered.`, et lève une [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception) à l'exécution si la valeur arrive. Un `match` sur des chaînes ou des nombres ne peut pas lister toutes les valeurs, donc il lui faut toujours un `else` :

```v
fn sdk_kind(name string) string {
	return match name {
		'Microsoft.NET.Sdk' { 'library' }
		'Microsoft.NET.Sdk.Web' { 'web' }
	}
}
```

```text
e06_match_string.v:2:9: error: match must be exhaustive (add `else {}` at the end)
    1 | fn sdk_kind(name string) string {
    2 |     return match name {
      |            ~~~~~~~~~~~~
    3 |         'Microsoft.NET.Sdk' { 'library' }
    4 |         'Microsoft.NET.Sdk.Web' { 'web' }
```

Une branche peut lister plusieurs valeurs, ou un intervalle inclusif avec trois points ([`size`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L47-L54)) ; les slices de la leçon 4 utilisent deux points, et excluent la fin :

```v
fn size(references int) string {
	return match references {
		0 { 'none' }
		1...3 { 'few' }
		4, 5, 6 { 'some' }
		else { 'many' }
	}
}
```

```text
0: none
2: few
5: some
23: many
```

### Drapeaux

Un enum `@[flag]` donne un bit à chaque valeur, comme `[Flags]` en C#. [`traits`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L25-L45) positionne les drapeaux d'un projet à partir de ses champs CSV :

```v
@[flag]
enum Traits {
	web
	fsharp
	in_solution
}

fn traits(fields []string) Traits {
	mut t := Traits.zero()
	if fields[3] == 'Microsoft.NET.Sdk.Web' {
		t.set(.web)
	}
	if fields[2] == 'F#' {
		t.set(.fsharp)
	}
	if fields[5] == 'true' {
		t.set(.in_solution)
	}
	return t
}
```

```v
mut by_sdk := map[Sdk]int{}
mut web_outside := []string{}
for line in os.read_lines('data/ga/projects.csv')![1..] {
	f := line.split(',')
	by_sdk[parse_sdk(f[3])!]++
	t := traits(f)
	if t.has(.web) && !t.has(.in_solution) {
		web_outside << f[1]
	}
}
println(by_sdk)
println('web projects outside the solution: ${web_outside}')
println(Traits.web | Traits.in_solution)
```

```text
{library: 95, web: 16}
web projects outside the solution: ['FloorManager', 'GA.DocumentProcessing.Service', 'ScenesService', 'GA.Business.AI', 'FretboardExplorer', 'GA.WebBlazorApp']
Traits{.web | .in_solution}
```

Six des 16 projets web de ga ne sont pas listés dans `AllProjects.slnx`, le fichier de solution.

## Types somme

Une version NuGet n'est pas toujours faite de trois nombres. Le `package_refs.csv` de ga contient des versions finales (`9.5.1`), des préversions (`1.0.0-beta.24164.1`) et des [versions flottantes](https://learn.microsoft.com/nuget/concepts/dependency-resolution#floating-versions) (`8.*-*`, la dernière 8.x, préversions comprises). Chaque forme a ses propres données. C# et Java modélisent cela par une hiérarchie de classes ou de records ; V a un type pour ça :

| | C# | Java 21+ | V |
|---|---|---|---|
| Déclaration | un `record Version` abstrait, et `record Release(…) : Version` | [`sealed interface Version permits …`](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) et des records | `type Version = Floating \| Prerelease \| Release` |
| Fermé | non : n'importe quel assembly peut dériver | oui | oui |
| Tester et convertir | `if (v is Release r)` | `if (v instanceof Release r)` | `if v is Release { }` |
| Un cas oublié dans un `switch` | avertissement CS8509, puis une exception à l'exécution | une erreur de compilation | une erreur de compilation |

Source : [Sum types](https://docs.vlang.io/type-declarations.html#sum-types).

[`Version`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v#L5-L53) est l'une de trois structs. Une fonction qui renvoie `!Version` renvoie n'importe laquelle d'entre elles :

```v
struct Release {
	parts []int
}

struct Prerelease {
	release Release
	label   string
}

struct Floating {
	pattern string
}

type Version = Floating | Prerelease | Release

fn parse_version(s string) !Version {
	if s.contains('*') {
		return Floating{s}
	}
	if dash := s.index('-') {
		return Prerelease{parse_release(s[..dash])!, s[dash + 1..]}
	}
	return parse_release(s)!
}
```

Un `match` sur un type somme a une branche par variante ; dans chaque branche, `v` a le type de la variante, comme avec `is` :

```v
fn (v Version) describe() string {
	return match v {
		Release { 'release ${v}' }
		Prerelease { 'prerelease ${v.label} of ${v.release}' }
		Floating { 'floating ${v.pattern}' }
	}
}

fn (v Version) is_stable() bool {
	return v is Release
}
```

```v
for s in ['9.5.1', '1.0.0-beta.24164.1', '8.*-*', '1.x'] {
	v := parse_version(s) or {
		println('${s}: ${err.msg()}')
		continue
	}
	println('${s}: ${v.describe()}, stable: ${v.is_stable()}, type: ${v.type_name()}')
}
```

```text
9.5.1: release 9.5.1, stable: true, type: Release
1.0.0-beta.24164.1: prerelease beta.24164.1 of 1.0.0, stable: false, type: Prerelease
8.*-*: floating 8.*-*, stable: false, type: Floating
1.x: strconv.atoi: parsing "x": invalid radix 10 character
```

`${v}` dans la branche `Release` utilise `Release.str()`, qui joint les parties par des points. `type_name()` donne la variante à l'exécution.

Une variante oubliée est une erreur, comme une valeur d'enum oubliée :

```v
fn describe(v Version) string {
	return match v {
		Release { 'release' }
		Prerelease { 'prerelease ${v.label}' }
	}
}
```

```text
e06_match_variant.v:16:9: error: match must be exhaustive (add match branches for: `Floating` or `else {}` at the end)
   14 | 
   15 | fn describe(v Version) string {
   16 |     return match v {
      |            ~~~~~~~~~
   17 |         Release { 'release' }
   18 |         Prerelease { 'prerelease ${v.label}' }
```

Le même code en Java 25, avec une `sealed interface` et trois records, donne `error: the switch expression does not cover all possible input values`. Une branche `else {}` fait taire la vérification, et avec elle le rappel quand une variante est ajoutée.

### Les versions de ga

```v
mut kinds := map[string]int{}
for line in os.read_lines('data/ga/package_refs.csv')![1..] {
	f := line.split(',')
	v := parse_version(f[2])!
	kinds[v.type_name()]++
	match v {
		Floating {
			println('${f[1]} ${v.pattern} in ${short(f[0])}')
		}
		Release {
			if v.parts.len != 3 {
				println('${f[1]} ${v} has ${v.parts.len} parts, in ${short(f[0])}')
			}
		}
		else {}
	}
}
println(kinds)
```

```text
ModelContextProtocol 0.* in DemerzelBridge
Microsoft.AspNetCore.SpaProxy 8.*-* in ReactApp1.Server
Microsoft.KernelMemory.Core 0.91.241101.1 has 4 parts, in GaCLI
{'Release': 443, 'Prerelease': 33, 'Floating': 2}
```

Les 478 versions s'analysent toutes. Deux sont flottantes : chaque restauration de `DemerzelBridge` et de `ReactApp1.Server` peut choisir un paquet plus récent, donc deux builds du même commit peuvent différer, sauf si le projet utilise un [fichier de verrouillage](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies). `0.91.241101.1` a quatre parties, ce que NuGet accepte ([numéros de version normalisés](https://learn.microsoft.com/nuget/concepts/package-versioning#normalized-version-numbers)).

### `as`, et un champ qu'une seule variante possède

`as` convertit vers une variante, et fait un panic sur la mauvaise :

```v
fn main() {
	v := Version(Floating{'0.*'})
	r := v as Release
	println(r.parts)
}
```

```text
V panic: as cast: cannot cast `main.Floating` to `main.Release`
```

Préfère `is` ou `match`, qui ne peuvent pas échouer. Un piège : V 0.5.2 accepte aussi `v.parts` directement sur une `Version`, sans `as`, parce que seule `Release` a un champ nommé `parts`. Ça compile, et fait un panic avec le même message :

```v
fn main() {
	v := Version(Floating{'0.*'})
	println(v.parts)
}
```

```text
V panic: as cast: cannot cast `main.Floating` to `main.Release`
```

Le checker réécrit un champ qui existe dans exactement une variante en un cast `as` ([`checker.v`, lignes 3180-3201](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/checker.v#L3180-L3201)). La documentation n'en parle pas. Un champ que toutes les variantes possèdent, avec le même type, peut être lu sans cast ([`table.v`, lignes 878-925](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/ast/table.v#L878-L925)).

### Un type somme récursif

Une variante peut contenir le type somme lui-même. [`Tree`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v#L55-L106) est un projet et les projets qu'il référence, jusqu'aux projets qui ne référencent rien :

```v
struct Leaf {
	name string
}

struct Branch {
	name     string
	children []Tree
}

type Tree = Branch | Leaf

fn (t Tree) count() int {
	return match t {
		Leaf {
			1
		}
		Branch {
			mut n := 1
			for c in t.children {
				n += c.count()
			}
			n
		}
	}
}
```

Une branche d'une expression `match` peut contenir des instructions ; sa dernière expression, `n`, est sa valeur. `print` parcourt l'arbre de la même façon :

```text
GaCli (1)
  GA.Business.DSL (3)
    GA.Core
    GA.Domain.Core (2)
      GA.Business.Config
      GA.Core
    GA.Domain.Services (5)
      GA.Business.Config
      GA.Business.Core (1)
        GA.Domain.Core (2)
          GA.Business.Config
          GA.Core
      GA.Core
      GA.Domain.Core (2)
        GA.Business.Config
        GA.Core
      GA.Domain.Repositories (1)
        GA.Domain.Core (2)
          GA.Business.Config
          GA.Core
20 nodes
```

L'arbre a 20 nœuds pour 8 projets : `GA.Domain.Core` apparaît quatre fois, une fois sous chacun des quatre projets qui le référencent. Les références forment un graphe, pas un arbre ; la [leçon 7](../07-concurrency/) compte chaque projet une seule fois.

## À retenir

- Un enum a des méthodes et s'affiche par son nom ; seuls `==` et `!=` fonctionnent dessus, `int(e)` donne le nombre, `Sdk.from` lit un nom ou une valeur, `@[flag]` en fait un ensemble de bits.
- Un type somme liste ses variantes : il est fermé, comme une sealed interface Java, et n'a pas besoin de classe de base.
- `match` doit couvrir toutes les valeurs d'enum ou toutes les variantes, ou avoir un `else` ; sur les chaînes et les nombres, `else` est obligatoire. Un `else` cache aussi les variantes ajoutées plus tard.
- `is` et `match` convertissent sans risque ; `as` fait un panic sur la mauvaise variante, tout comme un champ qu'une seule variante possède, que V 0.5.2 accepte sans `as`.

## Exercices

1. Ajoute `fn (v Version) major() ?int`, qui renvoie le premier nombre d'une version finale ou d'une préversion, et d'une version flottante quand elle commence par un nombre (`8.*-*` donne 8, `*` donne `none`).

<details>
<summary>Solution</summary>

[`examples/s06_major.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s06_major.v#L19-L25) :

```v
fn (v Version) major() ?int {
	return match v {
		Release { v.parts[0] }
		Prerelease { v.release.parts[0] }
		Floating { strconv.atoi(v.pattern.all_before('.')) or { return none } }
	}
}
```

```text
Release: 9
Prerelease: 1
Floating: 8
Floating: no major version
```

La branche `Floating` sort de la fonction avec `none` quand le motif ne commence pas par un nombre ; les autres branches donnent un `int`, qui devient l'option.

</details>

2. ga ajoute un service worker, et `Sdk` reçoit une troisième valeur, `worker`, pour `Microsoft.NET.Sdk.Worker`. Quelles fonctions de `l06_enums.v` le compilateur te fait-il modifier, et qu'arrive-t-il aux autres ?

<details>
<summary>Solution</summary>

`msbuild_name` cesse de compiler, avec l'erreur de `e06_match_enum.v` : son `match` sur l'enum n'a pas de `else`. `parse_sdk` compile toujours : il fait un match sur des chaînes, avec un `else` qui renvoie une erreur, donc un projet `Microsoft.NET.Sdk.Worker` échouerait à l'exécution, dans `by_sdk[parse_sdk(f[3])!]++`, avec `unknown SDK: Microsoft.NET.Sdk.Worker`. `traits` ne change pas, et compterait un worker comme n'étant ni `web` ni quoi que ce soit d'autre.

</details>

3. Pourquoi `if v is Release { v.parts }` est-il sûr, alors que `v.parts` seul peut faire un panic, bien que les deux compilent ?

<details>
<summary>Solution</summary>

Dans `if v is Release`, le compilateur connaît la variante et lit le champ directement. `v.parts` seul est réécrit en `(v as Release).parts`, un cast vérifié à l'exécution, qui fait un panic quand `v` contient une autre variante. En termes C#, le premier est `if (v is Release r) { r.Parts }`, le second est `((Release)v).Parts`, qui lève une `InvalidCastException`, sauf qu'en V rien dans le source ne montre le cast.

</details>

## Sources

- [Documentation V — Enums](https://docs.vlang.io/type-declarations.html#enums), [Sum types](https://docs.vlang.io/type-declarations.html#sum-types), [Smart casting](https://docs.vlang.io/type-declarations.html#smart-casting), [Matching sum types](https://docs.vlang.io/type-declarations.html#matching-sum-types) ; la documentation de la 0.5.2 : [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [C# — Switch expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [Enumeration types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/enum), [`FlagsAttribute`](https://learn.microsoft.com/dotnet/api/system.flagsattribute)
- [Java — Sealed classes and interfaces](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), [Pattern matching for switch](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html), [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html)
- [NuGet — Package versioning](https://learn.microsoft.com/nuget/concepts/package-versioning), [Floating versions](https://learn.microsoft.com/nuget/concepts/dependency-resolution#floating-versions)
