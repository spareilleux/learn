---
title: 4. Tableaux, maps, slices et mémoire
description: Les tableaux et les maps comparés à List, Dictionary, ArrayList et HashMap, ce qu'une affectation partage, et les quatre façons de gérer la mémoire en V, mesurées sur trois OS.
sidebar:
  order: 4
---

Code : [`examples/l04_arrays.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_arrays.v), [`examples/l04_maps.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_maps.v), [`examples/l04_references.v`](https://github.com/spareilleux/learn/blob/391a0c46439cb27c820aae4238475d9f3bec5a10/code/v-for-csharp-java/examples/l04_references.v) et [`examples/l04_memory.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_memory.v) — `v run examples/l04_maps.v` depuis `code/v-for-csharp-java`.

## Tableaux

Un tableau V, `[]int`, grandit comme une `List<int>` ou une `ArrayList<Integer>` ; il n'y a pas de type de tableau à taille fixe distinct dans le code de tous les jours (`[3]int` existe, pour les buffers).

```v
mut lines := [474, 341, 326]
lines << 394
lines << [120, 88]
println('${lines} len=${lines.len}')

squares := []int{len: 5, init: index * index}
println(squares)
```

```text
[474, 341, 326, 394, 120, 88] len=6
[0, 1, 4, 9, 16]
```

| | C# | Java | V |
|---|---|---|---|
| Type | `List<int>` | `ArrayList<Integer>` | `[]int` |
| Littéral | `[474, 341]` (C# 12) | `List.of(474, 341)` (immuable) | `[474, 341]` |
| Vide, avec capacité | `new List<int>(100)` | `new ArrayList<>(100)` | `[]int{cap: 100}` |
| Ajouter | `Add(x)`, `AddRange(xs)` | `add(x)`, `addAll(xs)` | `a << x`, `a << xs` |
| Nombre d'éléments | `Count` | `size()` | `len` |
| Contient | `Contains(x)` | `contains(x)` | `x in a` |
| Index hors limites | `ArgumentOutOfRangeException` | `IndexOutOfBoundsException` | panic, ou `a[i] or { }` |

Sources : [tableaux de V](https://docs.vlang.io/v-types.html#arrays), [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [`ArrayList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html).

`init` est évalué pour chaque élément, avec `index` comme position. Les éléments sont toujours initialisés : `[]int{len: 5}` donne cinq zéros.

### `filter`, `map` et tri

```v
long := lines.filter(it > 300)
println(long)
println(lines.map(it / 10))
println(lines.filter(fn (n int) bool {
	return n < 100
}))
println('${lines.any(it > 400)} ${lines.all(it > 100)}')
println('${326 in lines} ${lines.index(394)}')
```

```text
[474, 341, 326, 394]
[47, 34, 32, 39, 12, 8]
[88]
true false
true 3
```

`filter`, `map`, `any` et `all` prennent une expression dans laquelle `it` est l'élément, ou une fonction. Ils renvoient immédiatement un nouveau tableau : ils ne sont pas paresseux comme LINQ ou les streams.

| LINQ | Streams | V |
|---|---|---|
| `Where(n => n > 300)` | `filter(n -> n > 300)` | `filter(it > 300)` |
| `Select(n => n / 10)` | `map(n -> n / 10)` | `map(it / 10)` |
| `Any(…)`, `All(…)` | `anyMatch(…)`, `allMatch(…)` | `any(…)`, `all(…)` |
| `OrderBy(n => n)` | `sorted()` | `sorted()` |
| `OrderByDescending(n => n)` | `sorted(Comparator.reverseOrder())` | `sorted(a > b)` |

```v
mut sorted := lines.sorted()
println(sorted)
sorted.sort(a > b)
println(sorted)
titles := ['Mission', 'Journal', '1. Install']
println(titles.sorted(a.len < b.len))
```

```text
[88, 120, 326, 341, 394, 474]
[474, 394, 341, 326, 120, 88]
['Mission', 'Journal', '1. Install']
```

`sort` trie sur place, `sorted` renvoie une copie. L'expression de tri nomme les deux éléments `a` et `b`, et ne peut rien utiliser d'autre : une variable de la fonction englobante est hors de portée.

```v
fn main() {
	lines := {
		'duckdb':         3177
		'github-actions': 2785
	}
	mut courses := lines.keys()
	courses.sort(lines[a] > lines[b])
	println(courses)
}
```

```text
e04_sort_capture.v:7:15: error: can not access external variable `lines`
    5 |     }
    6 |     mut courses := lines.keys()
    7 |     courses.sort(lines[a] > lines[b])
      |                  ~~~~~~~~~~~~~~~~
    8 |     println(courses)
    9 | }
e04_sort_capture.v:7:10: error: `.sort()` can only use `a` or `b` as argument, e.g. `arr.sort(a < b)`
    5 |     }
    6 |     mut courses := lines.keys()
    7 |     courses.sort(lines[a] > lines[b])
      |             ~~~~~~~~~~~~~~~~~~~~~~~~~
    8 |     println(courses)
    9 | }
e04_sort_capture.v:7:20: error: invalid key: expected `string`, not `&string`; did you mean `lines[*a]`?
    5 |     }
    6 |     mut courses := lines.keys()
    7 |     courses.sort(lines[a] > lines[b])
      |                       ~~~
    8 |     println(courses)
    9 | }
e04_sort_capture.v:7:31: error: invalid key: expected `string`, not `&string`; did you mean `lines[*b]`?
    5 |     }
    6 |     mut courses := lines.keys()
    7 |     courses.sort(lines[a] > lines[b])
      |                                  ~~~
    8 |     println(courses)
    9 | }
```

Les troisième et quatrième erreurs montrent comment fonctionne `sort` : `a` et `b` sont des références (`&string`) vers les éléments. [`sort_with_compare`](https://modules.vlang.io/builtin.html#array.sort_with_compare) prend plutôt une fonction de comparaison ; la [section sur les maps](#maps) plus bas trie un tableau de structs par un champ.

## Slices

```v
counts := [474, 341, 326, 394, 120, 88]
first := counts[..2]
println('${first} ${counts[4..]} ${counts#[-2..]}')
```

```text
[474, 341] [120, 88] [120, 88]
```

`a[start..end]` exclut `end`, comme les plages C# `a[..2]`. Un index négatif compte depuis la fin, mais seulement avec `#[…]` : `counts#[-2..]` correspond à `counts[^2..]` en C#. En V, une slice est un tableau ordinaire (`[]int`), pas un type distinct comme `Span<int>` ou une vue `subList`.

Le fait qu'une slice partage la mémoire de son tableau dépend de la mutabilité ([array slices](https://docs.vlang.io/v-types.html#array-slices)) :

- Si le tableau et la slice sont tous deux immuables, la slice partage la mémoire du tableau : aucun des deux ne peut la modifier.
- Si l'un des deux est `mut`, V clone la slice, et le signale par une notice :

```text
w04_implicit_clone.v:3:16: notice: an implicit clone of the slice was done here
    1 | fn main() {
    2 |     mut lines := [474, 341, 326]
    3 |     first := lines[..2]
      |                   ~~~~~
    4 |     lines[0] = 0
    5 |     println('${lines} ${first}')
Details: w04_implicit_clone.v:3:16: details: To silence this notice, use either an explicit `a[..].clone()`,
or use an explicit `unsafe{ a[..] }`, if you do not want a copy of the slice.
    1 | fn main() {
    2 |     mut lines := [474, 341, 326]
    3 |     first := lines[..2]
      |                   ~~~~~
    4 |     lines[0] = 0
    5 |     println('${lines} ${first}')
[0, 341, 326] [474, 341]
```

`first` a gardé `[474, 341]` après `lines[0] = 0` : c'est une copie.

## Ce qu'une affectation partage

Une struct est copiée à l'affectation ([leçon 2](../02-types-structs-methods/#les-structs-sont-des-valeurs)). Un tableau, non. Le checker dans [`assign.v`, lignes 845-855](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/assign.v#L845-L855) ne clone que les *slices* (`a[..]`) ; un tableau entier affecté à une autre variable partage sa mémoire :

```v
mut original := [1, 2, 3]
alias := original
original[0] = 100
println('original ${original}, alias ${alias}')
println('cap ${original.cap}')
original << 4
original[1] = 200
println('original ${original}, alias ${alias}')

mut copy := original.clone()
copy[0] = -1
println('original ${original}, copy ${copy}')
```

```text
original [100, 2, 3], alias [100, 2, 3]
cap 3
original [100, 200, 3, 4], alias [100, 2, 3]
original [100, 200, 3, 4], copy [-1, 200, 3, 4]
```

1. `alias := original` partage la mémoire : l'`alias` immuable voit `original[0] = 100`, sans notice.
2. `original << 4` dépasse la capacité de 3 : V déplace `original` vers un bloc plus grand. `alias` pointe toujours vers l'ancien, et ne voit plus `original[1] = 200`.
3. `clone()` fait une copie indépendante, comme `new List<int>(list)` ou `new ArrayList<>(list)`.

Une `List<int>` C# ou une `ArrayList` Java affectée à une autre variable reste le même objet pour de bon ; un tableau V est partagé jusqu'à ce qu'il grandisse, comme une slice en Go. Tout immuable qu'il est, `alias` ne protège rien : le tableau qu'il lit peut toujours changer via `original`.

V refuse le sens inverse, une variable mutable qui partagerait un tableau immuable :

```v
fn main() {
	lines := [474, 341, 326]
	mut copy := lines
	copy[0] = 0
	println(copy)
}
```

```text
e04_mut_alias.v:3:14: notice: left-side of assignment expects a mutable reference, but variable `lines` is immutable, declare it with `mut` to make it mutable or clone it
    1 | fn main() {
    2 |     lines := [474, 341, 326]
    3 |     mut copy := lines
      |                 ~~~~~
    4 |     copy[0] = 0
    5 |     println(copy)
e04_mut_alias.v:3:11: error: use `mut array2 := array1.clone()` instead of `mut array2 := array1` (or use `unsafe`)
    1 | fn main() {
    2 |     lines := [474, 341, 326]
    3 |     mut copy := lines
      |              ~~
    4 |     copy[0] = 0
    5 |     println(copy)
e04_mut_alias.v:4:2: error: `copy` aliases mutable data from an immutable value, clone it first (or use `unsafe`)
    2 |     lines := [474, 341, 326]
    3 |     mut copy := lines
    4 |     copy[0] = 0
      |     ~~~~
    5 |     println(copy)
    6 | }
```

## Maps

`data/pages.csv` contient une ligne par page de ce site. [`encoding.csv`](https://modules.vlang.io/encoding.csv.html) le lit ([leçon 3](../03-errors-option-result/#types-derreur-personnalisés)), et deux maps comptent les pages par locale et les lignes anglaises par cours :

```v
mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
reader.read()! // l'en-tête : url,locale,course,title,lines
mut pages_per_locale := map[string]int{}
mut lines_per_course := map[string]int{}
for {
	row := reader.read() or { break }
	pages_per_locale[row[1]]++
	if row[1] == 'en' {
		lines_per_course[row[2]] += row[4].int()
	}
}
println(pages_per_locale)
```

```text
{'en': 117, 'es': 101, 'fr': 101}
```

`pages_per_locale[row[1]]++` fonctionne la première fois qu'une locale apparaît : une clé absente se lit comme la valeur zéro du type. C'est la principale différence avec C# et Java :

```v
println(pages_per_locale['de'])
println('de' in pages_per_locale)
println(pages_per_locale['de'] or { -1 })
if n := pages_per_locale['fr'] {
	println('fr: ${n} pages')
}
```

```text
0
false
-1
fr: 101 pages
```

| | C# `Dictionary` | Java `HashMap` | V `map` |
|---|---|---|---|
| Type | `Dictionary<string, int>` | `HashMap<String, Integer>` | `map[string]int` |
| Clé absente, `m[k]` | `KeyNotFoundException` | `get` renvoie `null` | la valeur zéro, `0` |
| Clé absente, explicitement | `TryGetValue`, `GetValueOrDefault` | `getOrDefault` | `m[k] or { … }`, `if v := m[k] { }` |
| Contient la clé | `ContainsKey(k)` | `containsKey(k)` | `k in m` |
| Supprimer | `Remove(k)` | `remove(k)` | `m.delete(k)` |
| Ordre d'itération | non défini | non défini (`LinkedHashMap` : insertion) | insertion |

Sources : [maps de V](https://docs.vlang.io/v-types.html#maps), [`Dictionary<TKey,TValue>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2), [`HashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/HashMap.html).

La valeur zéro masque les fautes de frappe : `m['fr ']` renvoie discrètement 0. Un module peut y renoncer avec `@[strict_map_index]`, qui fait de chaque index sans `or { }` une erreur :

```v
@[strict_map_index]
module main

fn main() {
	pages := {
		'en': 117
	}
	println(pages['de'])
}
```

```text
e04_strict_map_index.v:8:15: error: `@[strict_map_index]` requires handling missing map keys with `or {}` or `if value := map[key] {}`
    6 |         'en': 117
    7 |     }
    8 |     println(pages['de'])
      |                  ~~~~~~
    9 | }
```

Pour trier les entrées, l'exemple les copie dans un tableau de structs, puisqu'une expression de tri ne voit que `a` et `b` :

```v
struct CourseLines {
	course string
	lines  int
}

mut totals := []CourseLines{}
for course, lines in lines_per_course {
	totals << CourseLines{course, lines}
}
totals.sort(a.lines > b.lines)
println('English lines per course:')
for t in totals[..5] {
	println('  ${t.course:-22} ${t.lines:5}')
}
```

```text
English lines per course:
  streeling               9225
  java-for-csharp         6251
  rust-for-csharp-java    5652
  duckdb                  3177
  github-actions          2785
```

`${t.course:-22}` complète à 22 caractères à droite, `${t.lines:5}` à 5 à gauche, comme `{t.Course,-22}` et `{t.Lines,5}` en C#.

Contrairement à un tableau, une map ne peut pas être affectée à une autre variable, mutable ou non :

```v
fn main() {
	mut status := {
		'ladybugdb': 'lesson 8'
	}
	next := status
	status['ladybugdb'] = 'done'
	println(next)
}
```

```text
e04_map_copy.v:5:10: error: cannot copy map: call `move` or `clone` method (or use a reference)
    3 |         'ladybugdb': 'lesson 8'
    4 |     }
    5 |     next := status
      |             ~~~~~~
    6 |     status['ladybugdb'] = 'done'
    7 |     println(next)
```

`clone()` rend la copie explicite :

```v
mut status := {
	'duckdb':            'done'
	'ladybugdb':         'lesson 8'
	'v-for-csharp-java': 'lesson 4'
}
status.delete('duckdb')
mut next := status.clone()
next['v-for-csharp-java'] = 'lesson 5'
println(status)
println(next)
```

```text
{'ladybugdb': 'lesson 8', 'v-for-csharp-java': 'lesson 4'}
{'ladybugdb': 'lesson 8', 'v-for-csharp-java': 'lesson 5'}
```

## Mémoire

### La pile, le tas et les références

V place les structs sur la pile quand il le peut, et sur le tas quand leur adresse s'échappe ([stack and heap](https://docs.vlang.io/memory-management.html#stack-and-heap)). Les tableaux et les maps gardent leurs éléments sur le tas. Tu ne choisis pas avec un mot-clé comme `class` et `struct` en C# : le compilateur décide d'après ce que le code fait de l'adresse.

```v
struct Page {
	title string
}

fn newest() &Page {
	p := Page{'Journal'}
	return &p
}
```

`&Page` est une référence vers une `Page`, et `&p` prend l'adresse de `p`. La renvoyer est permis : V voit l'adresse quitter `newest` et alloue `p` sur le tas. `&Page{…}` alloue directement sur le tas, comme `new` en C# et en Java :

```v
lesson := &Page{'4. Arrays, maps, slices and memory'}
println(typeof(lesson).name)
println(lesson.title)
```

```text
&Page
4. Arrays, maps, slices and memory
```

Dans une fonction qui reçoit une référence, le compilateur ne peut pas savoir où vit la struct. Il refuse de stocker la référence, car la struct est peut-être sur la pile de l'appelant :

```v
struct Page {
	title string
}

struct History {
mut:
	last &Page = unsafe { nil }
}

fn (mut h History) visit(p &Page) {
	h.last = p
}
```

```text
e04_stack_reference.v:11:11: error: `p` cannot be assigned outside `unsafe` blocks as it might refer to an object stored on stack. Consider declaring `Page` as `@[heap]`.
    9 | 
   10 | fn (mut h History) visit(p &Page) {
   11 |     h.last = p
      |              ^
   12 | }
   13 | 
```

Comme le dit le message, `@[heap]` sur la struct alloue chaque instance sur le tas, et le même code compile ([`l04_references.v`, lignes 13-26](https://github.com/spareilleux/learn/blob/391a0c46439cb27c820aae4238475d9f3bec5a10/code/v-for-csharp-java/examples/l04_references.v#L13-L26)). Une référence nulle s'écrit `unsafe { nil }` : hors d'`unsafe`, une référence ne peut pas être nulle.

### Par défaut : un ramasse-miettes

La [documentation](https://docs.vlang.io/memory-management.html) liste quatre façons de gérer la mémoire :

| Mode | Option | Ce qui libère la mémoire |
|---|---|---|
| Ramasse-miettes | le comportement par défaut | le ramasse-miettes conservatif [Boehm-Demers-Weiser](https://github.com/bdwgc/bdwgc), livré dans `thirdparty/libgc` |
| *Autofree* | `-autofree` | des appels à `free()` insérés par le compilateur ; la documentation le qualifie de travail en cours et le déconseille |
| Manuel | `-gc none` | rien : tu appelles `free()` dans du code `unsafe`, ou tu as une fuite |
| Arène | `-prealloc` | un allocateur à arène, pour des programmes courts, mono-thread, de type traitement par lots |

[`l04_memory.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_memory.v#L5-L24) construit 50 tableaux de 100 000 chaînes, l'un après l'autre, et n'en garde aucun. [`runtime.used_memory`](https://modules.vlang.io/runtime.html#used_memory) donne la mémoire résidente du processus, sur les trois OS :

```v
for round in 1 .. 51 {
	lines := make_lines(100_000)
	total += lines.len
	if round % 25 == 0 {
		println('round ${round}: ${runtime.used_memory()! / 1024 / 1024} MB resident')
	}
}
```

Mémoire résidente après le tour 50, telle qu'affichée par la CI du cours et sur ma machine :

| Build | Windows (ma machine) | Runner Windows | Runner Linux | Runner macOS |
|---|---|---|---|---|
| `v run` (GC) | 20 Mo | 20 Mo | 18 Mo | 36 Mo |
| `v -gc none run` | 540 Mo | 540 Mo | 383 Mo | 384 Mo |
| `v -autofree run` | 10 Mo | 9 Mo | 6 Mo | 6 Mo |
| `v -prod run` | 542 Mo (MSVC) | | | |
| `v -prod -gc boehm run` | 30 Mo (MSVC) | | | |

- Avec le GC, la mémoire reste stable, comme dans un programme .NET ou Java : les tableaux des tours précédents sont collectés.
- Avec `-gc none`, rien n'est libéré : la mémoire augmente de 8 à 11 Mo par tour.
- `-autofree` libère chaque tableau à la fin de son tour, et utilise ici le moins de mémoire. Il *désactive* aussi le GC : `-autofree` fixe `gc_mode = .no_gc` dans [`pref.v`, lignes 807-811](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/pref.v#L807-L811), donc tout ce qu'*autofree* manque fuit, là où la documentation dit que le GC le libère.
- Sous Windows, un build `-prod` compilé par MSVC désactive le GC sans un mot : [`default.v`, lignes 369-381](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/default.v#L369-L381) passe à `no_gc` quand le compilateur C est MSVC et qu'aucune option `-gc` n'est donnée. Le même programme qui reste à 20 Mo en développement monte à 542 Mo en production. `-gc boehm` rétablit le GC.

`gc_is_enabled()` indique dans quel cas tu te trouves : l'exemple l'affiche sur sa première ligne, `GC enabled: false` avec `-gc none`, `-autofree`, et `-prod` compilé par MSVC.

## À retenir

- `[]T` est un tableau extensible avec `<<`, `filter`, `map`, `sort` ; les méthodes fonctionnelles sont immédiates (non paresseuses), et une expression de tri ne voit que `a` et `b`.
- Une slice d'un tableau immuable partage sa mémoire ; avec `mut` d'un côté ou de l'autre, V la clone et affiche une notice.
- Affecter un tableau entier le partage jusqu'à ce qu'il dépasse sa capacité ; `clone()` fait une vraie copie. Une map ne peut pas être affectée sans `clone()`.
- Une clé de map absente renvoie la valeur zéro ; utilise `or { }`, `if v := m[k]`, `in`, ou `@[strict_map_index]`.
- Le compilateur choisit la pile ou le tas ; `&T{}` et `@[heap]` imposent le tas.
- Le GC est le mode par défaut, `-gc none` laisse fuir ce que tu ne libères pas, et `-autofree` désactive le GC. Sous Windows, `-prod` avec MSVC le désactive aussi.

## Exercices

1. Compte les leçons françaises de chaque cours dans `data/pages.csv` (les titres qui commencent par un chiffre), et affiche les cours triés par nom.

<details>
<summary>Solution</summary>

[`examples/s04_lessons_per_course.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s04_lessons_per_course.v#L5-L20) :

```v
mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
reader.read()!
mut lessons := map[string]int{}
for {
	row := reader.read() or { break }
	if row[1] == 'fr' && row[3].len > 0 && row[3][0].is_digit() {
		lessons[row[2]]++
	}
}
mut courses := lessons.keys()
courses.sort()
for course in courses {
	println('${course}: ${lessons[course]}')
}
```

```text
duckdb: 8
github-actions: 10
java-for-csharp: 12
rust-for-csharp-java: 15
wsl-containers: 5
```

La map conserve l'ordre dans lequel les cours apparaissent pour la première fois dans le fichier ; `keys()` et `sort()` donnent l'ordre alphabétique. J'ai vérifié les nombres avec `awk` sur le même fichier.

</details>

2. Qu'affiche ce code ?

```v
mut a := [1, 2, 3]
b := a
a << 4
a[0] = 9
println('a ${a}, b ${b}')
```

<details>
<summary>Solution</summary>

```text
a [9, 2, 3, 4], b [1, 2, 3]
```

`b := a` partage le tableau, mais `a << 4` dépasse sa capacité de 3 et déplace `a` vers un nouveau bloc avant `a[0] = 9`. Inverse les deux lignes, `a[0] = 9` puis `a << 4`, et `b` affiche `[9, 2, 3]`.

</details>

3. Un service V qui tourne longtemps est construit avec `v -prod` sur une machine Windows équipée des Visual Studio Build Tools, et sa mémoire augmente régulièrement. Que vérifies-tu en premier ?

<details>
<summary>Solution</summary>

Si le GC est actif : affiche `gc_is_enabled()`, ou construis avec `v -showcc -prod` et cherche le `cl.exe` de MSVC. Avec MSVC et sans option `-gc`, V 0.5.2 construit sans GC, et chaque allocation fuit. Construis avec `-prod -gc boehm`, ou avec un autre compilateur C (`-cc gcc`, *à vérifier* sur une machine qui a les deux).

</details>

## Sources

- [Documentation de V — Arrays, Maps](https://docs.vlang.io/v-types.html), [Memory management](https://docs.vlang.io/memory-management.html), [References](https://docs.vlang.io/references.html)
- [Bibliothèque standard de V — `array` et `map`](https://modules.vlang.io/builtin.html), [`runtime`](https://modules.vlang.io/runtime.html), [`encoding.csv`](https://modules.vlang.io/encoding.csv.html)
- [C# — `List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [`Dictionary<TKey,TValue>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2), [Principes fondamentaux du ramasse-miettes](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals)
- [Java — `ArrayList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html), [`HashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/HashMap.html), [Réglage du ramasse-miettes](https://docs.oracle.com/en/java/javase/25/gctuning/)
- [Ramasse-miettes Boehm-Demers-Weiser](https://github.com/bdwgc/bdwgc)
