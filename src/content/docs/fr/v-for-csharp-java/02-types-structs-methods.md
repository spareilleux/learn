---
title: 2. Types, variables immuables, structs et méthodes
description: Des variables immuables par défaut, les types primitifs de V, et des structs avec des méthodes au lieu de classes — comparés à C# et Java, avec les vraies erreurs du compilateur.
sidebar:
  order: 2
---

Code : [`examples/l02_variables.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l02_variables.v) et [`examples/l02_structs.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l02_structs.v) — `v run examples/l02_structs.v` depuis `code/v-for-csharp-java`.

## Variables

```v
course := 'V for C#/Java developers'
lessons := 4
mut done := 0
done = 2
println('${course}: ${done}/${lessons} lessons')
```

```text
V for C#/Java developers: 2/4 lessons
```

| | C# | Java | V |
|---|---|---|---|
| Déclarer, type inféré | `var lessons = 4;` | `var lessons = 4;` | `lessons := 4` |
| Déclarer, type donné | `long big = 3_000_000_000;` | `long big = 3_000_000_000L;` | `big := i64(3_000_000_000)` |
| Non réassignable | `const`, champ `readonly` | `final var` | le comportement par défaut |
| Réassignable | le comportement par défaut | le comportement par défaut | `mut done := 0` |
| Affecter | `done = 2;` | `done = 2;` | `done = 2` |

[`:=`](https://docs.vlang.io/variables.html) est la seule façon de déclarer une variable, donc une variable a toujours une valeur. `=` ne fait qu'affecter, et seulement à une variable `mut` :

```v
fn main() {
	done := 0
	done = 2
	println(done)
}
```

```text
e02_immutable.v:3:2: error: `done` is immutable, declare it with `mut` to make it mutable
    1 | fn main() {
    2 |     done := 0
    3 |     done = 2
      |     ~~~~
    4 |     println(done)
    5 | }
```

Une variable ne peut pas reprendre le nom d'une variable d'un bloc englobant. C# ([CS0136](https://learn.microsoft.com/dotnet/csharp/misc/cs0136)) et Java le rejettent aussi :

```v
fn main() {
	total := 10
	if total > 5 {
		total := 20
		println(total)
	}
}
```

```text
e02_shadowing.v:4:3: error: redefinition of `total`
    2 |     total := 10
    3 |     if total > 5 {
    4 |         total := 20
      |         ~~~~~
    5 |         println(total)
    6 |     }
```

Une variable inutilisée est un avertissement, comme le [CS0219](https://learn.microsoft.com/dotnet/csharp/misc/cs0219) de C#, là où `javac` ne dit rien :

```text
w02_unused.v:2:2: warning: unused variable: `count`
    1 | fn main() {
    2 |     count := 3
      |     ~~~~~
    3 |     println('done')
    4 | }
done
```

Le même fichier avec `v -prod` ne compile pas : les [avertissements deviennent des erreurs](https://docs.vlang.io/variables.html#warnings-and-declaration-errors) dans les builds de production.

```text
e02_unused_prod.v:3:2: error: unused variable: `count`
    1 | // flags: -prod
    2 | fn main() {
    3 |     count := 3
      |     ~~~~~
    4 |     println('done')
    5 | }
```

## Types primitifs

| V | C# | Java | Notes |
|---|---|---|---|
| `bool` | `bool` | `boolean` | |
| `i8`, `i16`, `int`, `i64` | `sbyte`, `short`, `int`, `long` | `byte`, `short`, `int`, `long` | `int` fait toujours 32 bits |
| `u8`, `u16`, `u32`, `u64` | `byte`, `ushort`, `uint`, `ulong` | — | Java n'a pas de types non signés |
| `f32`, `f64` | `float`, `double` | `float`, `double` | |
| `isize`, `usize` | `nint`, `nuint` | — | la taille d'un pointeur |
| `rune` | `int` contenant un point de code, [`Rune`](https://learn.microsoft.com/dotnet/api/system.text.rune) | `int` contenant un point de code | un point de code Unicode ; `char` en C# et en Java est une unité UTF-16 |
| `string` | `string` (UTF-16) | `String` (UTF-16) | UTF-8, immuable |

Source : [types de V](https://docs.vlang.io/v-types.html). Un littéral entier est un `int`, un littéral flottant un `f64`, et une conversion s'écrit comme un appel : `i64(3_000_000_000)`.

```v
big := i64(3_000_000_000)
println('${typeof(lessons).name} ${typeof(big).name}')
total := big + lessons
println('${typeof(total).name} ${total}')
```

```text
int i64
i64 3000000004
```

V promeut un type plus petit vers un type plus grand quand aucune valeur ne peut être perdue : `int` vers `i64` ou `f64`, `u8` vers `int`. Il ne mélange jamais signé et non signé, là où C# convertirait silencieusement `uint + int` en `long` :

```v
fn main() {
	offset := -1
	size := u32(5)
	println(size + offset)
}
```

```text
e02_mixed_signs.v:4:10: error: mismatched types `u32` and `int`
    2 |     offset := -1
    3 |     size := u32(5)
    4 |     println(size + offset)
      |             ~~~~~~~~~~~~~
    5 | }
e02_mixed_signs.v:4:2: error: `println` can not print void expressions
    2 |     offset := -1
    3 |     size := u32(5)
    4 |     println(size + offset)
      |     ~~~~~~~~~~~~~~~~~~~~~~
    5 | }
```

La seconde erreur est une conséquence de la première : une fois que l'addition n'a pas de type, `println` n'a rien à afficher. Lis d'abord la première erreur.

V ne convertit pas non plus un nombre en chaîne. `"lessons: " + 4` est valide en C# et en Java ; en V, utilise l'interpolation :

```v
fn main() {
	lessons := 4
	println('lessons: ' + lessons)
}
```

```text
e02_string_plus_int.v:3:10: error: infix expr: cannot use `int` (right expression) as `string`
    1 | fn main() {
    2 |     lessons := 4
    3 |     println('lessons: ' + lessons)
      |             ~~~~~~~~~~~~~~~~~~~~~
    4 | }
```

L'arithmétique se comporte comme en C# dans un contexte `unchecked` et comme en Java : les entiers reviennent au début de leur plage en cas de dépassement, et la division entière tronque vers zéro.

```v
max := 2147483647
println(max + 1)
println(i8(127) + 1)
println('${7 / 2} ${-7 / 2} ${-7 % 2}')
```

```text
-2147483648
-128
3 -3 -1
```

### Les chaînes sont des octets UTF-8

```v
word := 'journée'
println('${word.len} bytes, ${word.runes().len} runes')
println('${word[0]} ${typeof(word[0]).name} ${`é`} ${typeof(`é`).name}')
```

```text
8 bytes, 7 runes
106 u8 é rune
```

En C# et en Java, `"journée".Length` et `"journée".length()` valent 7 : ils comptent des unités UTF-16. En V, [`len`](https://modules.vlang.io/builtin.html#string) compte les octets de l'encodage UTF-8, et `é` en prend deux. Indexer une chaîne donne un octet (`u8`), pas un caractère : `word[0]` vaut 106, le code de `j`. [`runes()`](https://modules.vlang.io/builtin.html#string.runes) décode les points de code ; un littéral de rune utilise des accents graves.

### `if` et `match` sont des expressions

V n'a pas d'opérateur ternaire : `if` renvoie une valeur. [`match`](https://docs.vlang.io/statements-&-expressions.html#match) est l'équivalent d'une expression `switch` en C# ou d'un `switch` avec flèches en Java, et doit couvrir tous les cas, ici avec `else` :

```v
status := if done == lessons { 'finished' } else { 'in progress' }
label := match done {
	0 { 'not started' }
	1, 2, 3 { 'started' }
	else { 'done' }
}
```

```text
in progress
started
```

## Des structs au lieu de classes

V n'a ni classes, ni héritage, ni constructeurs. Une [struct](https://docs.vlang.io/structs.html) contient les données, et les méthodes sont déclarées à côté :

```v
struct Page {
	url    string
	locale string = 'en'
	title  string
	lines  int
}
```

```v
mission := Page{
	url:   '/v-for-csharp-java/'
	title: 'Mission'
	lines: 80
}
lesson :=
	Page{'/v-for-csharp-java/02-types-structs-methods/', 'en', '2. Types, structs and methods', 300}
```

- Un littéral de struct nomme les champs, ou les donne tous dans l'ordre.
- Un champ qui n'est pas donné prend sa valeur par défaut : `locale` vaut `'en'`, et sinon la valeur zéro (`0`, `''`, un tableau vide).
- Il n'y a pas de `null` : un champ `string` n'est jamais absent, seulement vide.

`@[required]` rend un champ obligatoire dans chaque littéral, comme le modificateur [`required`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/required) de C# 11 :

```v
struct Page {
	url   string @[required]
	title string
}

fn main() {
	p := Page{
		title: 'Mission'
	}
	println(p)
}
```

```text
e02_required_field.v:7:7: error: field `Page.url` must be initialized
    5 | 
    6 | fn main() {
    7 |     p := Page{
      |          ~~~~~
    8 |         title: 'Mission'
    9 |     }
```

### Les champs sont privés et immuables par défaut

```v
struct Page {
	title string
	lines int
}

fn main() {
	mut p := Page{'Mission', 80}
	p.lines = 81
	println(p)
}
```

```text
e02_immutable_field.v:8:4: error: field `lines` of struct `Page` is immutable
    6 | fn main() {
    7 |     mut p := Page{'Mission', 80}
    8 |     p.lines = 81
      |       ~~~~~
    9 |     println(p)
   10 | }
```

`mut p` rend la variable mutable, pas ses champs. Les [modificateurs d'accès](https://docs.vlang.io/structs.html#access-modifiers) sont des sections de la struct :

| Section V | Lecture depuis un autre module | Écriture dans le module | Écriture depuis un autre module | Équivalent C# le plus proche | Équivalent Java le plus proche |
|---|---|---|---|---|---|
| (aucune) | non | non | non | `private readonly` | `private final` |
| `mut:` | non | oui | non | `private` | `private` |
| `pub:` | oui | non | non | `public` + `init` | `public final` |
| `pub mut:` | oui | oui | non | `public` + `private set` | getter public, setter privé |
| `__global:` | oui | oui | oui | `public` | `public` |

Le code du cours utilise un seul module, il n'a donc besoin que de `mut:` :

```v
struct Progress {
mut:
	done int
pub:
	total int
}
```

## Méthodes

```v
fn (p Page) is_lesson() bool {
	return p.title.len > 0 && p.title[0].is_digit()
}

fn (mut p Progress) complete() {
	p.done++
}
```

Une [méthode](https://docs.vlang.io/structs.html#methods) est une fonction avec un **receveur** entre `fn` et son nom. Il n'y a pas de `this` : le receveur a un nom, par convention une lettre. Le receveur est immuable sauf s'il est déclaré `mut`, et une méthode `mut` ne peut être appelée que sur une variable mutable :

```v
fn main() {
	p := Progress{}
	p.complete()
	println(p.done)
}
```

```text
e02_mut_receiver.v:12:2: error: `p` is immutable, declare it with `mut` to make it mutable
   10 | fn main() {
   11 |     p := Progress{}
   12 |     p.complete()
      |     ^
   13 |     println(p.done)
   14 | }
```

La même règle s'applique aux paramètres : `fn f(mut pages []Page)` s'appelle `f(mut pages)`, si bien que le site d'appel montre ce qui peut changer. Mais V refuse `mut` pour un nombre, là où C# a `ref int` :

```v
fn double(mut n int) {
	n *= 2
}
```

```text
e02_mut_int_param.v:1:17: error: mutable arguments are only allowed for arrays, interfaces, maps, pointers, structs or their aliases
return values instead: `fn foo(mut n int) {` => `fn foo(n int) int {`
    1 | fn double(mut n int) {
      |                 ~~~
    2 |     n *= 2
    3 | }
```

### `str()`, méthodes statiques et mise à jour de struct

```v
fn (p Page) str() string {
	return '${p.title} (${p.locale}, ${p.lines} lines)'
}

fn Page.translation(p Page, locale string, title string) Page {
	return Page{
		...p
		url:    '/${locale}${p.url}'
		locale: locale
		title:  title
	}
}
```

- `str()` joue le rôle de `ToString()` et de `toString()` : `println` et `${…}` l'appellent.
- `fn Page.translation` est une [méthode statique](https://docs.vlang.io/structs.html#static-type-methods), appelée `Page.translation(…)`. C'est la façon V d'écrire une fabrique, puisqu'il n'y a pas de constructeurs.
- `...p` copie les champs de `p` et remplace ceux qui sont listés, comme une [expression `with`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/with-expression) C# sur un record.

```v
println(mission)
println(lesson.is_lesson())
french := Page.translation(lesson, 'fr', '2. Types, structs et méthodes')
println(french.url)
```

```text
Mission (en, 80 lines)
true
/fr/v-for-csharp-java/02-types-structs-methods/
```

### Arguments nommés et optionnels

V n'a ni surcharge, ni arguments par défaut, ni arguments nommés. Deux fonctions du même nom sont rejetées, quels que soient leurs paramètres :

```v
fn describe(lines int) string {
	return '${lines} lines'
}

fn describe(title string) string {
	return 'title: ${title}'
}
```

```text
builder error: redefinition of function `describe`
e02_overload.v:1:1: conflicting declaration: fn describe(lines int) string
    1 | fn describe(lines int) string {
      | ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    2 |     return '${lines} lines'
    3 | }
e02_overload.v:5:1: conflicting declaration: fn describe(title string) string
    3 | }
    4 | 
    5 | fn describe(title string) string {
      | ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    6 |     return 'title: ${title}'
    7 | }
```

Une struct marquée [`@[params]`](https://docs.vlang.io/structs.html#trailing-struct-literal-arguments), en dernier paramètre, offre le même confort que les arguments nommés et optionnels de C#, ou qu'un builder en Java :

```v
@[params]
struct ListOptions {
	only_lessons bool
	max          int = 10
}

fn list(pages []Page, opts ListOptions) {
	// …
}

list(pages, max: 2)
list(pages, only_lessons: true)
list(pages)
```

L'appel liste les champs sans accolades ; ceux qui sont omis gardent leur valeur par défaut.

## Les structs sont des valeurs

```v
copy := lesson
println(copy == lesson)
mut p1 := Progress{
	total: 4
}
mut p2 := p1
p2.complete()
p1.complete()
p1.complete()
println('p1 ${p1.done}/${p1.total}, p2 ${p2.done}/${p2.total}')
println(p1)
```

```text
true
p1 2/4, p2 1/4
Progress{
    done: 2
    total: 4
}
```

Une struct V se comporte comme une `struct` ou un `record struct` C#, pas comme une classe : l'affectation la copie, et `==` compare les champs, comme l'égalité d'un record C# ou d'un record Java. `mut p2 := p1` crée un second `Progress`. Une struct sans `str()` affiche tous ses champs.

En coulisses, V passe un argument struct immuable par valeur ou par référence, comme bon lui semble ([références](https://docs.vlang.io/references.html)) ; comme l'appelé ne peut pas le modifier, la différence ne se voit pas. La leçon 4 revient sur les références, `&Page`, et sur ce qui est partagé : les tableaux et les maps ne suivent pas la même règle que les structs.

## À retenir

- `x := 1` déclare une variable immuable ; `mut` est nécessaire pour la réassigner, pour modifier un champ, ou pour appeler une méthode `mut`.
- `int` fait 32 bits partout ; V ne mélange jamais types signés et non signés, et ne convertit jamais implicitement un nombre en chaîne.
- Une chaîne est en UTF-8 : `len` compte des octets, l'indexation donne un `u8`, `runes()` donne les points de code.
- Une struct a des champs privés et immuables par défaut, des méthodes avec un receveur explicite, et pas de constructeur : les méthodes statiques et `...p` les remplacent.
- Ni surcharge, ni arguments par défaut ou nommés : une struct `@[params]` les remplace.
- Les structs sont des valeurs, copiées à l'affectation et comparées champ par champ.

## Exercices

1. Écris une struct `Course` avec un nom, un nombre de leçons et un compteur mutable `done`, une méthode `finish_lesson()` qui ne dépasse jamais le nombre de leçons, et un `str()` qui affiche `V: 2/2`. Appelle `finish_lesson()` trois fois sur un cours de deux leçons.

<details>
<summary>Solution</summary>

[`examples/s02_course.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s02_course.v#L1-L28) :

```v
struct Course {
	name    string
	lessons int
mut:
	done int
}

fn (mut c Course) finish_lesson() {
	if c.done < c.lessons {
		c.done++
	}
}

fn (c Course) str() string {
	return '${c.name}: ${c.done}/${c.lessons}'
}

fn main() {
	mut v := Course{
		name:    'V'
		lessons: 2
	}
	for _ in 0 .. 3 {
		v.finish_lesson()
	}
	println(v)
}
```

```text
V: 2/2
```

`for _ in 0 .. 3` répète trois fois ; `_` ignore le compteur, et `0 .. 3` exclut 3.

</details>

2. Qu'affiche ce code ? Une `class Course` C# afficherait-elle la même chose ?

```v
mut a := Course{
	name:    'Rust'
	lessons: 15
}
mut b := a
b.finish_lesson()
println('${a} | ${b}')
```

<details>
<summary>Solution</summary>

```text
Rust: 0/15 | Rust: 1/15
```

`mut b := a` copie la struct : `a` ne change pas. Avec une classe C#, `b` et `a` seraient le même objet et afficheraient tous deux `Rust: 1/15` ; avec une `struct` C#, la sortie serait la même qu'en V.

</details>

3. `fn double(mut n int)` ne compile pas. Écris la fonction que V attend à la place, et appelle-la.

<details>
<summary>Solution</summary>

Renvoie la nouvelle valeur, comme le suggère le message d'erreur :

```v
fn double(n int) int {
	return n * 2
}

x := double(2)
```

V n'autorise les paramètres `mut` que pour les tableaux, les maps, les structs, les interfaces et les pointeurs. La [documentation](https://docs.vlang.io/functions-2.html#mutable-arguments) préfère même renvoyer des valeurs pour ceux-là, et réserve la modification d'un argument sur place aux parties d'un programme où les copies coûtent trop cher.

</details>

## Sources

- [Documentation de V — Variables](https://docs.vlang.io/variables.html), [V Types](https://docs.vlang.io/v-types.html), [Structs](https://docs.vlang.io/structs.html), [Functions 2](https://docs.vlang.io/functions-2.html), [References](https://docs.vlang.io/references.html)
- [Bibliothèque standard de V — `string`](https://modules.vlang.io/builtin.html#string)
- [C# — Types intégrés](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/built-in-types), [Records](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record), [Types de structures](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct)
- [Java Language Specification — Types, values and variables](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html), [Record classes](https://docs.oracle.com/en/java/javase/25/language/records.html)
