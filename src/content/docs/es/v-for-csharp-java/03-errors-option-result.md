---
title: "3. Errores: ?, ! y or { }"
description: Sin null y sin excepciones — options, results, bloques or, panics y tipos de error personalizados, probados con el archivo CSV de las páginas de este sitio.
sidebar:
  order: 3
---

Código: [`examples/l03_errors.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l03_errors.v) y [`examples/l03_pages.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l03_pages.v) — `v run examples/l03_pages.v` desde `code/v-for-csharp-java`.

## Dos cosas que V no tiene

V no tiene `null` ni excepciones. Una función que puede no tener valor devuelve un **option**, `?T`; una función que puede fallar devuelve un **result**, `!T`. Ambos forman parte del tipo de retorno, y el compilador se niega a dejarte usar el valor sin decidir qué pasa en el otro caso.

| Situación | C# | Java | V |
|---|---|---|---|
| Un valor puede estar ausente | `null`, [tipos que aceptan valores null](https://learn.microsoft.com/dotnet/csharp/nullable-references) (advertencias) | `null`, [`Optional<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html) | `?T`, `return none` |
| Una operación puede fallar | [excepciones](https://learn.microsoft.com/dotnet/csharp/fundamentals/exceptions/), todas no comprobadas | [excepciones comprobadas y no comprobadas](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html) | `!T`, `return error('…')` |
| Gestionarlo | `??`, `try`/`catch` | `orElse`, `try`/`catch` | `or { }`, `if x := f() { }` |
| Pasarlo al llamador | nada que escribir | `throws` en la firma | `!` o `?` después de la llamada |
| Un bug, el programa se detiene | excepción no gestionada, [`Environment.FailFast`](https://learn.microsoft.com/dotnet/api/system.environment.failfast) | excepción no gestionada, [`Error`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Error.html) | `panic()` |

Fuente: [Option/Result types and error handling](https://docs.vlang.io/type-declarations.html#optionresult-types-and-error-handling).

## Options: `?T` y `none`

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

`return c` devuelve un `string`: V lo envuelve en el option. El llamador no puede usar el resultado directamente como un `string`:

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

C# con [tipos de referencia que aceptan valores null](https://learn.microsoft.com/dotnet/csharp/nullable-references) solo daría una advertencia (CS8602), y Java compilaría y lanzaría una `NullPointerException` en tiempo de ejecución. Dos formas de desenvolver:

```v
// or { } da un valor por defecto, como ?? en C# u orElse en Java
println(find_course('lady') or { 'no course' })
println(find_course('zig') or { 'no course' })

// if con desenvolvimiento: la variable solo existe cuando hay un valor
if c := find_course('rust') {
	println('found ${c}')
}

// En un bloque or, `err` es el error; para un option es `none`
find_course('java') or { println('java: ${err}') }
```

```text
ladybugdb
no course
found rust-for-csharp-java
java: none
```

## Results: `!T` y `error()`

[`strconv.atoi`](https://modules.vlang.io/strconv.html#atoi) devuelve `!int`: un `int`, o un error allí donde `int.Parse` lanzaría una `FormatException` e `Integer.parseInt` una `NumberFormatException`. Un result se debe gestionar en cada llamada:

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

Incluso una función que no devuelve nada pero puede fallar, `!` a secas, no se puede llamar y olvidar. [`os.write_file`](https://modules.vlang.io/os.html#write_file) es una de ellas:

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

Esto es más estricto que las excepciones comprobadas de Java, que solo se aplican a las excepciones que declara un método: en V, cada llamada que puede fallar lo dice.

### Cuatro formas de gestionar un result

```v
// 1. ! pasa el error al llamador, que a su vez debe devolver un result
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
// 2. Un valor por defecto
println(parse_lines('474') or { -1 })
// 3. Hacer algo con `err`
parse_lines('12abc') or { println(err) }
parse_lines('-3') or { println(err) }
// 4. Salir del bucle, o de la función, desde el bloque or
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

`if x := f() { } else { }` también funciona con los results, con `err` en la rama `else`. [`error()`](https://modules.vlang.io/builtin.html#error) crea un error a partir de un mensaje; `error_with_code()` añade un número.

`!` después de una llamada es el equivalente visible de dejar que una excepción se propague. Necesita una función que devuelva un result:

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

Para un option, el mismo operador es `?`: `dot := title.index('. ')?` devuelve `none` desde la función actual cuando no hay coincidencia.

:::caution[Los atajos que no fallan]
Los métodos de cadena [`int()`](https://modules.vlang.io/builtin.html#string.int), `i64()` o `f64()` devuelven un número simple, sin option ni result, y nunca informan de un error:

```v
println('${'12abc'.int()} ${'abc'.int()} ${'99999999999'.int()}')
```

```text
12 0 2147483647
```

`'12abc'` da 12, `'abc'` da 0, y un número demasiado grande da el `int` máximo. Donde C# y Java lanzarían una excepción, V devuelve un valor. Usa `strconv.atoi` cuando la entrada puede ser incorrecta.
:::

## Panics

Un panic detiene el programa: imprime `V panic:` y un mensaje, luego un backtrace, y termina con el código 1. No hay `catch`.

Un índice de array fuera de rango provoca un panic, como una `IndexOutOfRangeException` que nada captura:

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

`or { }` después de un índice convierte el panic en un valor: `courses[10] or { 'index out of range' }`.

`!` en `main`, que no puede pasar el error más arriba, provoca un panic:

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

`or { panic(err) }` hace lo mismo con el propio mensaje del error:

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

La primera línea es la misma en los tres SO. En Windows, las líneas siguientes dan el commit de V, los identificadores del proceso y del hilo, y un backtrace en el archivo C generado, como `C://Users//spare//AppData//Local//Temp//v_0//P03_OR~1.C:4689: at builtin___v_panic: Backtrace`; su contenido depende del SO y del compilador C, y la CI del curso solo compara la primera línea.

## Tipos de error personalizados

Un error es cualquier tipo que implemente la interfaz [`IError`](https://modules.vlang.io/builtin.html#IError), con `msg() string` y `code() int`. Incrustar el struct integrado `Error` proporciona ambos, y sobrescribes lo que necesites:

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

`data/pages.csv` tiene una línea por página de este sitio. Un primer analizador divide cada línea por las comas, y devuelve un `ParseError` cuando una línea no tiene cinco campos:

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

`return ParseError{…}` en una función que devuelve `!Page` es un error, no una página: V convierte el struct en `IError`. El llamador reúne los errores y luego comprueba su tipo con `is`, el equivalente de `catch (ParseError e)`:

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

Dentro de `if e is ParseError`, `e` es un `ParseError` con su campo `line_no`: V hace la conversión automáticamente, como un [patrón](https://learn.microsoft.com/dotnet/csharp/fundamentals/functional/pattern-matching) `if (e is ParseError pe)` en C#. La línea 10 del archivo muestra por qué falla el analizador ingenuo:

```text
/duckdb/08-persistence/,en,duckdb,"8. Persistence, transactions and concurrency",394
```

El título va entre comillas porque contiene comas. [`encoding.csv`](https://modules.vlang.io/encoding.csv.html) gestiona las comillas; su lector devuelve `![]string` por cada fila, y un error al final del archivo:

```v
mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
reader.read()! // la cabecera
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

Una trampa con un error convertido por *smart cast*: `${err}` imprime entonces el struct con todos sus campos, no `msg()`, así que llama a `err.msg()` explícitamente (ver el [diario](../journal/)).

`csv.EndOfFileError` se declara sin `pub` en [`reader.v`, líneas 25-31](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/encoding/csv/reader.v#L25-L31), y sin embargo V 0.5.2 lo acepta después de `is` en otro módulo. Llegar al final del archivo se notifica como un error, como `io.EOF` en Go, no como un option.

## Puntos clave

- `?T` es un valor o `none`; `!T` es un valor o un error. El compilador rechaza una llamada cuyo option o result no se gestiona, incluso para una función que no devuelve nada.
- `or { }` da un valor por defecto, o sale con `return`, `continue`, `break` o `panic`; `if x := f() { }` desenvuelve; `!` y `?` pasan el error o el `none` al llamador.
- `string.int()` y sus hermanos nunca fallan: devuelven 0 o saturan. Analiza las entradas no fiables con `strconv`.
- Un panic detiene el programa con el código 1, y no se puede capturar. Un índice fuera de rango provoca un panic salvo que tenga `or { }`.
- Un error personalizado incrusta `Error`, sobrescribe `msg()` y `code()`, y se reconoce con `is`.

## Ejercicios

1. Escribe `fn lesson_number(title string) ?int`, que devuelva el número antes de `'. '` en un título como `'8. Persistence, transactions and concurrency'`, y `none` para `'Mission'` o `'v2. Draft'`. [`string.index`](https://modules.vlang.io/builtin.html#string.index) devuelve `?int`.

<details>
<summary>Solución</summary>

[`examples/s03_lesson_number.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s03_lesson_number.v#L4-L8):

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

`?` transmite el `none` de `index`. `strconv.atoi` devuelve un result, no un option: `or { return none }` convierte su error en `none`, y `'v2'` da `none`.

</details>

2. Modifica `total_lines` para que su error diga qué campo es incorrecto: `field 2: strconv.atoi: parsing "x": invalid radix 10 character`.

<details>
<summary>Solución</summary>

[`examples/s03_lesson_number.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s03_lesson_number.v#L10-L17):

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

`return` en un bloque `or` sale de la función con un nuevo error, que envuelve el mensaje del original: el equivalente de lanzar una nueva excepción con la original como excepción interna, sin la cadena.

</details>

3. Un colega lee la columna `lines` con `row[4].int()`, y una línea dice `n/a`. ¿Qué pasa en V, y qué pasaría con `int.Parse` en C# y con `Integer.parseInt` en Java?

<details>
<summary>Solución</summary>

En V, `'n/a'.int()` devuelve 0: la página cuenta cero líneas y nada informa del problema. `int.Parse("n/a")` lanza una `FormatException`, e `Integer.parseInt("n/a")` una `NumberFormatException`. `strconv.atoi(row[4])` restablece un error que hay que gestionar. La [lección 4](../04-arrays-maps-memory/) sigue usando `row[4].int()` sobre `pages.csv`, un archivo cuya columna `lines` ha comprobado el analizador de esta lección.

</details>

## Fuentes

- [Documentación de V — Option/Result types and error handling](https://docs.vlang.io/type-declarations.html#optionresult-types-and-error-handling), [Custom error types](https://docs.vlang.io/type-declarations.html#custom-error-types), [If unwrapping](https://docs.vlang.io/statements-&-expressions.html#if-unwrapping)
- [Biblioteca estándar de V — `builtin` (`IError`, `error`, `panic`)](https://modules.vlang.io/builtin.html), [`strconv`](https://modules.vlang.io/strconv.html), [`encoding.csv`](https://modules.vlang.io/encoding.csv.html)
- [C# — Excepciones y control de excepciones](https://learn.microsoft.com/dotnet/csharp/fundamentals/exceptions/), [Tipos de referencia que aceptan valores null](https://learn.microsoft.com/dotnet/csharp/nullable-references)
- [Java — Checked and unchecked exceptions](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html), [`Optional`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html)
