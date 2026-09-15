---
title: "3. Erreurs : ?, ! et or { }"
description: Ni null ni exceptions — options, results, blocs or, panics et types d'erreur personnalisés, essayés sur le fichier CSV des pages de ce site.
sidebar:
  order: 3
---

Code : [`examples/l03_errors.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l03_errors.v) et [`examples/l03_pages.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l03_pages.v) — `v run examples/l03_pages.v` depuis `code/v-for-csharp-java`.

## Deux choses que V n'a pas

V n'a ni `null` ni exceptions. Une fonction qui peut ne pas avoir de valeur renvoie une **option**, `?T` ; une fonction qui peut échouer renvoie un **result**, `!T`. Les deux font partie du type de retour, et le compilateur refuse que tu utilises la valeur sans décider de ce qui se passe dans l'autre cas.

| Situation | C# | Java | V |
|---|---|---|---|
| Une valeur peut être absente | `null`, [types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references) (avertissements) | `null`, [`Optional<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html) | `?T`, `return none` |
| Une opération peut échouer | [exceptions](https://learn.microsoft.com/dotnet/csharp/fundamentals/exceptions/), toutes non vérifiées | [exceptions vérifiées et non vérifiées](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html) | `!T`, `return error('…')` |
| La traiter | `??`, `try`/`catch` | `orElse`, `try`/`catch` | `or { }`, `if x := f() { }` |
| La transmettre à l'appelant | rien à écrire | `throws` dans la signature | `!` ou `?` après l'appel |
| Un bug, le programme s'arrête | exception non gérée, [`Environment.FailFast`](https://learn.microsoft.com/dotnet/api/system.environment.failfast) | exception non gérée, [`Error`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Error.html) | `panic()` |

Source : [Option/Result types and error handling](https://docs.vlang.io/type-declarations.html#optionresult-types-and-error-handling).

## Options : `?T` et `none`

```v
const courses = ['duckdb', 'ladybugdb', 'rust-for-csharp-java', 'v-for-csharp-java']

fn find_course(prefix string) ?string {
	for c in courses {
		if c.starts_with(prefix) {
			return c
		}
	}
	return none
}
```

`return c` renvoie une `string` : V l'enveloppe dans l'option. L'appelant ne peut pas utiliser le résultat directement comme une `string` :

```v
fn main() {
	name := find_course('rust')
	println(name.to_upper())
}
```

```text
e03_option_in_expression.v:14:10: error: Option type `string` cannot be called directly, you should unwrap it first
   12 | fn main() {
   13 |     name := find_course('rust')
   14 |     println(name.to_upper())
      |             ~~~~
   15 | }
e03_option_in_expression.v:14:2: error: `println` can not print void expressions
   12 | fn main() {
   13 |     name := find_course('rust')
   14 |     println(name.to_upper())
      |     ~~~~~~~~~~~~~~~~~~~~~~~~
   15 | }
```

C# avec les [types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references) ne ferait qu'avertir (CS8602), et Java compilerait puis lèverait une `NullPointerException` à l'exécution. Deux façons de déballer :

```v
// or { } donne une valeur par défaut, comme ?? en C# ou orElse en Java
println(find_course('lady') or { 'no course' })
println(find_course('zig') or { 'no course' })

// if unwrapping : la variable n'existe que s'il y a une valeur
if c := find_course('rust') {
	println('found ${c}')
}

// Dans un bloc or, `err` est l'erreur ; pour une option, c'est `none`
find_course('java') or { println('java: ${err}') }
```

```text
ladybugdb
no course
found rust-for-csharp-java
java: none
```

## Results : `!T` et `error()`

[`strconv.atoi`](https://modules.vlang.io/strconv.html#atoi) renvoie `!int` : un `int`, ou une erreur là où `int.Parse` lèverait une `FormatException` et `Integer.parseInt` une `NumberFormatException`. Un result doit être traité à chaque appel :

```v
import strconv

fn main() {
	lines := strconv.atoi('474')
	println(lines)
}
```

```text
e03_unhandled_result.v:4:19: error: strconv.atoi() returns `!int`, so it should have either an `or {}` block, or `!` at the end
    2 | 
    3 | fn main() {
    4 |     lines := strconv.atoi('474')
      |                      ~~~~~~~~~~~
    5 |     println(lines)
    6 | }
```

Même une fonction qui ne renvoie rien mais peut échouer, `!` seul, ne peut pas être appelée puis oubliée. [`os.write_file`](https://modules.vlang.io/os.html#write_file) en est une :

```v
import os

fn main() {
	os.write_file('journal.md', '## 2026-09-14')
	println('saved')
}
```

```text
e03_unhandled_void.v:4:5: error: os.write_file() returns `!void`, so it should have either an `or {}` block, or `!` at the end
    2 | 
    3 | fn main() {
    4 |     os.write_file('journal.md', '## 2026-09-14')
      |        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    5 |     println('saved')
    6 | }
```

C'est plus strict que les exceptions vérifiées de Java, qui ne s'appliquent qu'aux exceptions qu'une méthode déclare : en V, chaque appel qui peut échouer le dit.

### Quatre façons de traiter un result

```v
// 1. ! transmet l'erreur à l'appelant, qui doit lui-même renvoyer un result
fn parse_lines(field string) !int {
	n := strconv.atoi(field)!
	if n < 0 {
		return error('negative line count: ${n}')
	}
	return n
}

fn total_lines(fields []string) !int {
	mut total := 0
	for f in fields {
		total += parse_lines(f)!
	}
	return total
}
```

```v
// 2. Une valeur par défaut
println(parse_lines('474') or { -1 })
// 3. Faire quelque chose avec `err`
parse_lines('12abc') or { println(err) }
parse_lines('-3') or { println(err) }
// 4. Quitter la boucle, ou la fonction, depuis le bloc or
for fields in [['474', '341'], ['474', 'x', '341']] {
	total := total_lines(fields) or {
		println('${fields}: ${err}')
		continue
	}
	println('${fields}: ${total} lines')
}
```

```text
474
strconv.atoi: parsing "12abc": invalid radix 10 character
negative line count: -3
['474', '341']: 815 lines
['474', 'x', '341']: strconv.atoi: parsing "x": invalid radix 10 character
```

`if x := f() { } else { }` fonctionne aussi pour les results, avec `err` dans la branche `else`. [`error()`](https://modules.vlang.io/builtin.html#error) crée une erreur à partir d'un message ; `error_with_code()` ajoute un numéro.

`!` après un appel est l'équivalent visible du fait de laisser une exception se propager. Il lui faut une fonction qui renvoie un result :

```v
import strconv

fn parse_lines(field string) int {
	return strconv.atoi(field)!
}
```

```text
e03_propagate_without_result.v:4:28: error: to propagate the Result call, `parse_lines` must return a Result
    2 | 
    3 | fn parse_lines(field string) int {
    4 |     return strconv.atoi(field)!
      |                               ^
    5 | }
    6 | 
Details: e03_propagate_without_result.v:3:30: details: prepend ! before the declaration of the return type of `parse_lines`
    1 | import strconv
    2 | 
    3 | fn parse_lines(field string) int {
      |                              ~~~
    4 |     return strconv.atoi(field)!
    5 | }
```

Pour une option, le même opérateur est `?` : `dot := title.index('. ')?` renvoie `none` depuis la fonction courante quand il n'y a pas de correspondance.

:::caution[Les raccourcis qui n'échouent pas]
Les méthodes de chaîne [`int()`](https://modules.vlang.io/builtin.html#string.int), `i64()` ou `f64()` renvoient un simple nombre, sans option ni result, et ne signalent jamais d'erreur :

```v
println('${'12abc'.int()} ${'abc'.int()} ${'99999999999'.int()}')
```

```text
12 0 2147483647
```

`'12abc'` donne 12, `'abc'` donne 0, et un nombre trop grand donne le `int` maximal. Là où C# et Java lèveraient une exception, V renvoie une valeur. Utilise `strconv.atoi` quand l'entrée peut être erronée.
:::

## Panics

Un panic arrête le programme : il affiche `V panic:` et un message, puis une backtrace, et se termine avec le code 1. Il n'y a pas de `catch`.

Un index de tableau hors limites déclenche un panic, comme une `IndexOutOfRangeException` que rien n'intercepte :

```v
fn main() {
	courses := ['duckdb', 'ladybugdb']
	i := 2
	println(courses[i])
}
```

```text
V panic: array.get: index out of range (i,a.len):2, 2
```

`or { }` après un index transforme le panic en valeur : `courses[10] or { 'index out of range' }`.

`!` dans `main`, qui ne peut pas transmettre l'erreur plus loin, déclenche un panic :

```v
import strconv

fn main() {
	lines := strconv.atoi('forty-two')!
	println(lines)
}
```

```text
V panic: result not set (strconv.atoi: parsing "forty-two": invalid radix 10 character)
```

`or { panic(err) }` fait la même chose avec le message propre à l'erreur :

```v
import os

fn main() {
	text := os.read_file('missing.csv') or { panic(err) }
	println(text)
}
```

```text
V panic: failed to open file "missing.csv"; code: 2
```

La première ligne est la même sur les trois OS. Sous Windows, les lignes suivantes donnent le commit de V, les identifiants du processus et du thread, et une backtrace dans le fichier C généré, comme `C://Users//spare//AppData//Local//Temp//v_0//P03_OR~1.C:4689: at builtin___v_panic: Backtrace` ; son contenu dépend de l'OS et du compilateur C, et la CI du cours ne compare que la première ligne.

## Types d'erreur personnalisés

Une erreur est n'importe quel type qui implémente l'interface [`IError`](https://modules.vlang.io/builtin.html#IError), avec `msg() string` et `code() int`. Embarquer la struct intégrée `Error` fournit les deux, et tu redéfinis ce dont tu as besoin :

```v
struct ParseError {
	Error
	line_no int
	reason  string
}

fn (e ParseError) msg() string {
	return 'line ${e.line_no}: ${e.reason}'
}

fn (e ParseError) code() int {
	return e.line_no
}
```

`data/pages.csv` contient une ligne par page de ce site. Un premier parseur découpe chaque ligne sur les virgules, et renvoie une `ParseError` quand une ligne n'a pas cinq champs :

```v
fn parse_page(line_no int, line string) !Page {
	fields := line.split(',')
	if fields.len != 5 {
		return ParseError{
			line_no: line_no
			reason:  'expected 5 fields, got ${fields.len}'
		}
	}
	lines := strconv.atoi(fields[4]) or {
		return ParseError{
			line_no: line_no
			reason:  err.msg()
		}
	}
	return Page{fields[0], fields[1], fields[2], fields[3], lines}
}
```

`return ParseError{…}` dans une fonction qui renvoie `!Page` est une erreur, pas une page : V convertit la struct en `IError`. L'appelant collecte les erreurs, puis teste leur type avec `is`, l'équivalent de `catch (ParseError e)` :

```v
lines := os.read_lines('data/pages.csv')!
mut pages := []Page{}
mut errors := []IError{}
for i, line in lines[1..] {
	page := parse_page(i + 2, line) or {
		errors << err
		continue
	}
	pages << page
}
println('naive split: ${pages.len} pages, ${errors.len} errors')
for e in errors[..3] {
	if e is ParseError {
		println('  code ${e.code()}: ${e.msg()}')
	}
}
```

```text
naive split: 269 pages, 50 errors
  code 10: line 10: expected 5 fields, got 6
  code 21: line 21: expected 5 fields, got 6
  code 26: line 26: expected 5 fields, got 6
```

Dans `if e is ParseError`, `e` est une `ParseError` avec son champ `line_no` : V la convertit automatiquement, comme un [motif](https://learn.microsoft.com/dotnet/csharp/fundamentals/functional/pattern-matching) `if (e is ParseError pe)` en C#. La ligne 10 du fichier montre pourquoi le parseur naïf échoue :

```text
/duckdb/08-persistence/,en,duckdb,"8. Persistence, transactions and concurrency",394
```

Le titre est entre guillemets parce qu'il contient des virgules. [`encoding.csv`](https://modules.vlang.io/encoding.csv.html) gère les guillemets ; son lecteur renvoie `![]string` pour chaque ligne, et une erreur à la fin du fichier :

```v
mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
reader.read()! // l'en-tête
mut parsed := []Page{}
for {
	row := reader.read() or {
		if err is csv.EndOfFileError {
			break
		}
		panic(err)
	}
	parsed << Page{row[0], row[1], row[2], row[3], strconv.atoi(row[4])!}
}
```

```text
encoding.csv: 319 pages
  8. Persistence, transactions and concurrency: 394 lines
```

Un piège avec une erreur ayant subi un *smart cast* : `${err}` affiche alors la struct avec tous ses champs, pas `msg()`, donc appelle `err.msg()` explicitement (voir le [journal](../journal/)).

`csv.EndOfFileError` est déclarée sans `pub` dans [`reader.v`, lignes 25-31](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/encoding/csv/reader.v#L25-L31), et pourtant V 0.5.2 l'accepte après `is` dans un autre module. Atteindre la fin du fichier est signalé comme une erreur, comme `io.EOF` en Go, et non comme une option.

## À retenir

- `?T` est une valeur ou `none` ; `!T` est une valeur ou une erreur. Le compilateur refuse un appel dont l'option ou le result n'est pas traité, même pour une fonction qui ne renvoie rien.
- `or { }` donne une valeur par défaut, ou sort avec `return`, `continue`, `break` ou `panic` ; `if x := f() { }` déballe ; `!` et `?` transmettent l'erreur ou le `none` à l'appelant.
- `string.int()` et ses semblables n'échouent jamais : ils renvoient 0 ou saturent. Analyse les entrées non fiables avec `strconv`.
- Un panic arrête le programme avec le code 1, et ne peut pas être intercepté. Un index hors limites déclenche un panic, sauf s'il a un `or { }`.
- Une erreur personnalisée embarque `Error`, redéfinit `msg()` et `code()`, et se reconnaît avec `is`.

## Exercices

1. Écris `fn lesson_number(title string) ?int`, qui renvoie le nombre avant `'. '` dans un titre comme `'8. Persistence, transactions and concurrency'`, et `none` pour `'Mission'` ou `'v2. Draft'`. [`string.index`](https://modules.vlang.io/builtin.html#string.index) renvoie `?int`.

<details>
<summary>Solution</summary>

[`examples/s03_lesson_number.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s03_lesson_number.v#L4-L8) :

```v
fn lesson_number(title string) ?int {
	dot := title.index('. ')?
	return strconv.atoi(title[..dot]) or { return none }
}
```

```text
8: 8. Persistence, transactions and concurrency
-: Mission
-: v2. Draft
12: 12. Cross-compilation
```

`?` transmet le `none` de `index`. `strconv.atoi` renvoie un result, pas une option : `or { return none }` transforme son erreur en `none`, et `'v2'` donne `none`.

</details>

2. Modifie `total_lines` pour que son erreur indique quel champ est erroné : `field 2: strconv.atoi: parsing "x": invalid radix 10 character`.

<details>
<summary>Solution</summary>

[`examples/s03_lesson_number.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s03_lesson_number.v#L10-L17) :

```v
fn total_lines(fields []string) !int {
	mut total := 0
	for i, f in fields {
		total += strconv.atoi(f) or { return error('field ${i + 1}: ${err.msg()}') }
	}
	return total
}
```

```text
815
field 2: strconv.atoi: parsing "x": invalid radix 10 character
```

`return` dans un bloc `or` quitte la fonction avec une nouvelle erreur, qui reprend le message de l'erreur d'origine : l'équivalent de lever une nouvelle exception avec l'originale comme exception interne, sans la chaîne.

</details>

3. Un collègue lit la colonne `lines` avec `row[4].int()`, et une ligne contient `n/a`. Que se passe-t-il en V, et que se passerait-il avec `int.Parse` en C# et `Integer.parseInt` en Java ?

<details>
<summary>Solution</summary>

En V, `'n/a'.int()` renvoie 0 : la page compte zéro ligne et rien ne signale le problème. `int.Parse("n/a")` lève une `FormatException`, et `Integer.parseInt("n/a")` une `NumberFormatException`. `strconv.atoi(row[4])` rétablit une erreur qu'il faut traiter. La [leçon 4](../04-arrays-maps-memory/) utilise encore `row[4].int()` sur `pages.csv`, un fichier dont le parseur de cette leçon a vérifié la colonne `lines`.

</details>

## Sources

- [Documentation de V — Option/Result types and error handling](https://docs.vlang.io/type-declarations.html#optionresult-types-and-error-handling), [Custom error types](https://docs.vlang.io/type-declarations.html#custom-error-types), [If unwrapping](https://docs.vlang.io/statements-&-expressions.html#if-unwrapping)
- [Bibliothèque standard de V — `builtin` (`IError`, `error`, `panic`)](https://modules.vlang.io/builtin.html), [`strconv`](https://modules.vlang.io/strconv.html), [`encoding.csv`](https://modules.vlang.io/encoding.csv.html)
- [C# — Exceptions et gestion des exceptions](https://learn.microsoft.com/dotnet/csharp/fundamentals/exceptions/), [Types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references)
- [Java — Exceptions vérifiées et non vérifiées](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html), [`Optional`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html)
