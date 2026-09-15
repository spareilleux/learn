---
title: "8. Tests, v fmt, v vet et v doc"
description: Des fonctions de test trouvées par leur nom, assert au lieu de Assert.Equal, et le formateur, le linter et le générateur de documentation livrés avec le compilateur — sur un module qui analyse les dépendances de GuitarAlchemist/ga.
sidebar:
  order: 8
---

Code : [`l08-testing`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing), un module et ses tests, et [`l08-failing`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-failing), des tests qui échouent exprès — `v test .` depuis `code/v-for-csharp-java/l08-testing`.

## Tests

| | C# avec xUnit | Java avec JUnit 5 | V |
|---|---|---|---|
| Framework | un paquet : [xUnit](https://xunit.net/), NUnit, MSTest | une dépendance : [JUnit](https://docs.junit.org/current/user-guide/) | intégré |
| Un test | une méthode avec `[Fact]` | une méthode avec `@Test` | une fonction nommée `test_…` dans un fichier nommé `…_test.v` |
| Vérifier | `Assert.Equal(expected, actual)` | `assertEquals(expected, actual)` | `assert actual == expected` |
| Avant et après tous les tests | une fixture, `IClassFixture<T>` | `@BeforeAll`, `@AfterAll` | `testsuite_begin()`, `testsuite_end()` |
| Tester du code privé | [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) | un test dans le même package | un test dans le même module |
| Exécuter | [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) | `mvn test`, `gradle test` | `v test .`, ou `v file_test.v` |

Source : [Testing](https://docs.vlang.io/testing.html).

### Un module et ses tests

`l08-testing` est un projet avec un seul module, `deps`, qui regroupe l'analyseur de versions de la leçon 6 et un graphe de références entre projets :

```text
l08-testing/
├── v.mod
├── deps/
│   ├── version.v          module deps: Version, parse_version
│   ├── graph.v            module deps: Graph, Graph.parse, reachable
│   ├── version_test.v     internal tests
│   ├── graph_test.v       internal tests
│   └── s08_cycle_test.v   the solution of exercise 1
└── tests/
    └── ga_test.v          external tests, on the ga CSV files
```

Un fichier de test dont la première ligne est `module deps` est un test **interne** : il appartient au module, et peut appeler ses fonctions privées, comme `parse_release` ([`version_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/version_test.v)) :

```v
// Un test interne : même module, donc il peut appeler la fonction privée parse_release
module deps

fn test_parse_release() {
	r := parse_release('9.5.1')!
	assert r.parts == [9, 5, 1]
}

fn test_parse_release_rejects_letters() {
	parse_release('1.x') or {
		assert err.msg() == 'strconv.atoi: parsing "x": invalid radix 10 character'
		return
	}
	assert false, 'expected an error'
}

fn test_prerelease() ! {
	v := parse_version('1.0.0-beta.24164.1')!
	assert v is Prerelease
	if v is Prerelease {
		assert v.label == 'beta.24164.1'
		assert v.release.parts == [1, 0, 0]
	}
	assert !v.is_stable()
}
```

Il n'y a pas de bibliothèque d'assertions : `assert` prend n'importe quelle expression booléenne, et en cas d'échec affiche les deux côtés de la comparaison. Une fonction de test peut renvoyer `!`, et un `!` après un appel fait alors échouer le test avec l'erreur, là où un test xUnit laisserait l'exception s'échapper. Une erreur attendue se vérifie avec `or`, là où xUnit a `Assert.Throws` et JUnit `assertThrows`.

Un fichier de test qui importe au contraire le module est un test **externe**, et ne voit que ce que `deps` rend `pub`. [`tests/ga_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/tests/ga_test.v) exécute le module sur les vrais fichiers de ga :

```v
// Un test externe : il importe le module, et ne voit que son API publique
import deps
import os

const data = os.join_path(@VMODROOT, '..', 'data', 'ga')

fn testsuite_begin() {
	assert os.exists(data)
}

fn test_every_version_parses() ! {
	lines := os.read_lines(os.join_path(data, 'package_refs.csv'))!
	mut floating := []string{}
	for line in lines[1..] {
		f := line.split(',')
		v := deps.parse_version(f[2])!
		if v is deps.Floating {
			floating << f[1]
		}
	}
	assert floating == ['ModelContextProtocol', 'Microsoft.AspNetCore.SpaProxy']
}

fn test_gacli_references() ! {
	g := deps.Graph.parse(os.read_lines(os.join_path(data, 'project_refs.csv'))!)!
	reachable := g.reachable('Apps/GaCli/GaCli.fsproj')
	assert reachable.len == 7
	assert 'Common/GA.Core/GA.Core.csproj' in reachable
}
```

`@VMODROOT` est le dossier du `v.mod` le plus proche, connu à la compilation : le test trouve ses données d'où qu'on le lance.

### `v test`

`v test .` trouve tous les fichiers `_test.v` sous le dossier, compile chacun comme un programme séparé, et les exécute en parallèle :

```text
---- Testing... ----------------------------------------------------------------
OK    [1/4] C:   594.6 ms, R:    83.349 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/graph_test.v
OK    [2/4] C:   593.6 ms, R:    84.106 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/s08_cycle_test.v
OK    [3/4] C:   594.1 ms, R:    84.014 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/tests/ga_test.v
OK    [4/4] C:   593.8 ms, R:    84.440 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/version_test.v
--------------------------------------------------------------------------------
Summary for all V _test.v files: 4 passed, 4 total. Elapsed time: 787 ms, on 4 parallel jobs. Comptime: 2376 ms. Runtime: 335 ms.
```

`C:` est le temps de compilation et `R:` le temps d'exécution de chaque fichier : 0,6 s de compilation pour 0,08 s de tests. Le résumé compte des fichiers, pas des tests. L'ordre des fichiers, les temps et les chemins changent d'une exécution à l'autre et d'un OS à l'autre, donc [`check.sh`](https://github.com/spareilleux/learn/blob/f6c34f637df430c031060cb89fb903e7c15be266/code/v-for-csharp-java/check.sh#L99-L108) trie les lignes `OK` et ne garde que le chemin à l'intérieur du projet avant de comparer.

Une différence de plus en CI : quand la variable d'environnement `CI` ou `GITHUB_JOB` est définie, `v test` masque les lignes `OK`, et n'affiche que les échecs et le résumé ([`common.v`, lignes 37-43](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/cmd/tools/modules/testing/common.v#L37-L43)). La première exécution en CI de cette leçon a échoué à cause de ça ; `VTEST_HIDE_OK=0` les fait réapparaître.

### Quand un test échoue

[`l08-failing/failing_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-failing/failing_test.v) échoue de quatre façons :

```v
import strconv

fn testsuite_begin() {
	println('testsuite_begin')
}

fn testsuite_end() {
	println('testsuite_end')
}

fn test_values() {
	parts := '9.5'.split('.').map(strconv.atoi(it) or { -1 })
	assert parts == [9, 5, 1]
	println('not printed: the test stops at the first failed assert')
}

fn test_message() {
	for s in ['9.5.1', '9.5', '1.0.0-beta.1'] {
		assert s.split('.').len == 3, 'version ${s}'
	}
}

fn test_propagated_error() ! {
	lines := strconv.atoi('n/a')!
	assert lines > 0
}

@[assert_continues]
fn test_continues() {
	for s in ['9.5.1', '0.*', '8.*-*'] {
		assert !s.contains('*'), s
	}
	println('printed: assert_continues goes on after a failure')
}

fn test_passes() {
	assert '9.5.1'.split('.').len == 3
}
```

`v failing_test.v`, depuis son dossier, exécute un seul fichier :

```text
testsuite_begin
failing_test.v:14: fn test_values
   > assert parts == [9, 5, 1]
     Left value (len: 6): `[9, 5]`
    Right value (len: 9): `[9, 5, 1]`

failing_test.v:20: fn test_message
   > assert s.split('.').len == 3, 'version ${s}'
     Left value (len: 1): `2`
    Right value (len: 1): `3`
        Message: version 9.5

failing_test.v:25: fn test_propagated_error failed propagation with error: strconv.atoi: parsing "n/a": invalid radix 10 character
   25 | 	lines := strconv.atoi('n/a')!
failing_test.v:32: fn test_continues
    assert !s.contains('*'), s
        Message: 0.*

failing_test.v:32: fn test_continues
    assert !s.contains('*'), s
        Message: 8.*-*

printed: assert_continues goes on after a failure
testsuite_end
```

Le code de sortie est 1. Ce que montre le rapport :

- `assert` affiche l'expression et la valeur de chaque côté, comme `Assert.Equal` affiche *Expected* et *Actual*. Le `len` entre parenthèses est la longueur du texte affiché, pas du tableau : `[9, 5]` fait 6 caractères.
- Un `assert` qui échoue termine sa fonction de test, comme un `Assert` qui échoue dans xUnit ou JUnit : `not printed` n'est pas affiché. Les autres tests s'exécutent quand même.
- Le message après la virgule est le seul moyen de savoir quelle itération d'une boucle a échoué. V n'a ni `[Theory]` ni `@ParameterizedTest` : une boucle sur des cas avec un message fait ce travail.
- Une erreur propagée avec `!` fait échouer le test, avec la ligne de l'appel.
- `@[assert_continues]` signale chaque échec et continue, comme le `assertAll` de JUnit. `-assert continues` en ligne de commande le fait pour toutes les fonctions.

`-stats` liste chaque fonction de test :

```text
     OK    [1/7] ms    NO asserts | main.testsuite_begin()
     FAIL  [2/7] ms     1 assert  | main.test_values()
     FAIL  [3/7] ms     2 asserts | main.test_message()
     FAIL  [4/7] ms     0 asserts | main.test_propagated_error()
     OK    [5/7] ms     1 assert  | main.test_continues()
     OK    [6/7] ms     1 assert  | main.test_passes()
     OK    [7/7] ms    NO asserts | main.testsuite_end()
     Summary for running V tests in "failing_test.v": 3 failed, 3 passed, 6 total. Elapsed time: ms.
```

(`check.sh` retire les temps, qui changent à chaque exécution.) Deux choses ne collent pas. `test_continues` est `OK`, avec `1 assert`, alors que deux de ses trois asserts ont échoué : le fichier échoue quand même, mais cette ligne le cache. Et le résumé compte des asserts, pas des tests : `test_message` compte pour 1 réussi et 1 échoué.

`assert` fonctionne aussi hors des tests, dans n'importe quelle fonction : un échec y est un panic, `V panic: Assertion failed...`. Avec `-prod`, les asserts sont supprimés, comme le dit la documentation : sur ma machine, `v -prod run` d'un programme dont le `assert 1 + 1 == 3` échoue sans `-prod` affiche la ligne suivante et sort avec 0. `Debug.Assert` en C# disparaît de la même façon d'un build Release.

## `v fmt`

`v fmt` est le formateur, l'équivalent de [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format) ; Java n'en a pas dans le JDK. Il n'a aucune option de style : tabulations, espacement et retours à la ligne sont ceux de V. [`vet/v08_vet.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/vet/v08_vet.v) est mal formaté exprès :

```v
module main

// Compte les références d'un projet
pub fn count(refs []string) int {
    return refs.len
}

fn main() {
	println(count( ['GA.Core','GA.Domain.Core'] ))
}
```

`v fmt -verify` vérifie sans écrire, pour la CI, comme `dotnet format --verify-no-changes` :

```text
v08_vet.v is not vfmt'ed
Encountered a total of: 1 formatting errors.
```

Le code de sortie est 1, et le vrai message commence par le chemin absolu du fichier. `v fmt v08_vet.v` affiche le fichier formaté, et `v fmt -w` le réécrit :

```v
module main

// Compte les références d'un projet
pub fn count(refs []string) int {
	return refs.len
}

fn main() {
	println(count(['GA.Core', 'GA.Domain.Core']))
}
```

Le `check.sh` du cours exécute `v fmt -verify` sur tous ses dossiers sauf les snippets rejetés, que `v fmt` vérifie au niveau des types et refuse ([journal](../journal/)).

## `v vet`

`v vet` signale le code suspect, un petit équivalent des [analyseurs .NET](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview) :

```text
v08_vet.v:4: warning: A function name is missing from the documentation of "pub fn count(refs []string) int".
v08_vet.v:5: error: Looks like you are using spaces for indentation.
Note: You can run `v fmt -w v08_vet.v` to fix these errors automatically
```

Le code de sortie est 1, à cause de l'erreur ; `-W` transforme aussi les avertissements en erreurs. L'avertissement concerne le commentaire : V attend que la documentation d'une fonction publique commence par son nom, `// count renvoie …`, comme le fait Go. `v fmt -w` corrige l'indentation, pas le commentaire.

## `v doc`

`v doc` construit la documentation d'un module à partir des commentaires placés au-dessus de ses déclarations publiques, comme `javadoc` ou les [commentaires de documentation XML](https://learn.microsoft.com/dotnet/csharp/language-reference/xmldoc/) de C#, sans balises. [`version.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/version.v) et [`graph.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/graph.v) suivent la règle de `v vet`. Depuis `l08-testing`, `v doc -comments deps` affiche :

```text
module deps
    Package versions, as written in the project files of GuitarAlchemist/ga.

fn parse_version(s string) !Version
    parse_version reads a version, or returns an error when a part isn't a number.
fn Graph.parse(lines []string) !Graph
    Graph.parse reads the lines of project_refs.csv, header included.
type Version = Floating | Prerelease | Release
    Version is one of the three forms.
fn (v Version) is_stable() bool
    is_stable tells whether a version is a release.
struct Floating {
pub:
	pattern string
}
    Floating is a version with a wildcard, such as 8.*-*, that NuGet resolves at restore time.
struct Graph {
mut:
	refs map[string][]string
}
    Graph holds the project references, from a project to the projects it references.
fn (g Graph) reachable(from string) []string
    reachable returns the projects that a project references, directly or not, sorted.
struct Prerelease {
pub:
	release Release
	label   string
}
    Prerelease is a release followed by a label, such as 1.0.0-beta.1.
struct Release {
pub:
	parts []int
}
    Release is a version made of numbers only, such as 9.5.1.
```

Les fonctions privées, comme `parse_release`, sont omises, mais le champ privé `refs` de `Graph` est affiché. `-f html` ou `-f md` écrivent d'autres formats.

## À retenir

- Un test est une fonction `test_` dans un fichier `_test.v` ; `module x` le rend interne, `import x` externe. `v test .` compile chaque fichier comme un programme séparé et les exécute en parallèle.
- `assert` affiche les deux côtés d'une comparaison qui échoue, plus un message facultatif ; il termine le test sauf avec `@[assert_continues]`, et disparaît avec `-prod`.
- Les fonctions de test peuvent renvoyer `!` ; une erreur attendue se vérifie avec `or`.
- `-stats` et les résumés comptent des asserts, et rapportent comme `OK` un test dont les échecs ont continué : lis les lignes d'échec, et le code de sortie.
- En CI, `v test` masque les fichiers qui réussissent, sauf avec `VTEST_HIDE_OK=0`.
- `v fmt -verify`, `v vet` et `v doc` sont livrés avec le compilateur ; `v vet` veut des commentaires de documentation qui commencent par le nom.

## Exercices

1. `Graph.reachable` ne doit pas boucler sur un cycle de références. Écris un test pour `A → B → A` : que doit renvoyer `reachable('A')` ?

<details>
<summary>Solution</summary>

[`l08-testing/deps/s08_cycle_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/s08_cycle_test.v) :

```v
// Leçon 8, exercice 1 : un cycle de références
module deps

fn test_cycle() ! {
	g := Graph.parse(['from,to', 'A,B', 'B,A'])!
	assert g.reachable('A') == ['A', 'B']
	assert g.reachable('B') == ['A', 'B']
}
```

`v deps/s08_cycle_test.v` n'affiche rien et sort avec 0. L'ensemble `seen` arrête le parcours. `A` fait partie de son propre résultat, parce que `B` le référence : `reachable` renvoie tous les projets atteints depuis `A`, et `A` en fait partie. Savoir si c'est juste est une décision que le test enregistre désormais. `v test .` trouve le fichier avec les autres : le résumé plus haut compte 4 fichiers.

</details>

2. Dans `failing_test.v`, `test_message` s'arrête à `9.5` et ne vérifie jamais `1.0.0-beta.1`, qui a 4 parties une fois découpé sur les points. Comment voir les deux échecs sans modifier la boucle ?

<details>
<summary>Solution</summary>

Mets `@[assert_continues]` au-dessus de `fn test_message()`, ou exécute `v -assert continues failing_test.v` pour toutes les fonctions du fichier. Le rapport a alors un bloc pour `9.5`, avec `` Left value (len: 1): `2` ``, et un pour `1.0.0-beta.1`, avec `` `4` `` : `'1.0.0-beta.1'.split('.')` donne `['1', '0', '0-beta', '1']`. Avec `@[assert_continues]`, `-stats` rapporte alors `test_message` comme `OK`, comme `test_continues`.

</details>

3. Corrige `vet/v08_vet.v` pour que `v vet` ne signale rien.

<details>
<summary>Solution</summary>

`v fmt -w v08_vet.v` corrige l'indentation. L'avertissement demande un commentaire qui commence par le nom de la fonction :

```v
// count renvoie le nombre de références d'un projet.
pub fn count(refs []string) int {
	return refs.len
}
```

Les fichiers de `l08-testing` suivent cette règle : `v vet .` n'y signale rien.

</details>

## Sources

- [Documentation V — Testing](https://docs.vlang.io/testing.html) : [Asserts](https://docs.vlang.io/testing.html#asserts), [Asserts that do not abort your program](https://docs.vlang.io/testing.html#asserts-that-do-not-abort-your-program), [Test files](https://docs.vlang.io/testing.html#test-files), [Running tests](https://docs.vlang.io/testing.html#running-tests) ; [Tools — v fmt](https://docs.vlang.io/tools.html#v-fmt) ; [Writing documentation](https://docs.vlang.io/writing-documentation.html) ; la documentation de la 0.5.2 : [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- `v help test`, `v help vet`, `v help doc` et `v help fmt`, affichés par V 0.5.2
- [xUnit](https://xunit.net/), [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test), [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format), [Code analysis in .NET](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview)
- [JUnit 5 User Guide](https://docs.junit.org/current/user-guide/)
