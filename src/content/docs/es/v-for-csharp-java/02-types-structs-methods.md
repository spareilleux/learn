---
title: 2. Tipos, variables inmutables, structs y métodos
description: Variables inmutables por defecto, los tipos primitivos de V, y structs con métodos en lugar de clases — comparados con C# y Java, con los errores reales del compilador.
sidebar:
  order: 2
---

Código: [`examples/l02_variables.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l02_variables.v) y [`examples/l02_structs.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l02_structs.v) — `v run examples/l02_structs.v` desde `code/v-for-csharp-java`.

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
| Declarar, tipo inferido | `var lessons = 4;` | `var lessons = 4;` | `lessons := 4` |
| Declarar, tipo indicado | `long big = 3_000_000_000;` | `long big = 3_000_000_000L;` | `big := i64(3_000_000_000)` |
| No se puede reasignar | `const`, campo `readonly` | `final var` | el comportamiento por defecto |
| Se puede reasignar | el comportamiento por defecto | el comportamiento por defecto | `mut done := 0` |
| Asignar | `done = 2;` | `done = 2;` | `done = 2` |

[`:=`](https://docs.vlang.io/variables.html) es la única forma de declarar una variable, así que una variable siempre tiene un valor. `=` solo asigna, y solo a una variable `mut`:

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

Una variable no puede reutilizar el nombre de una variable de un bloque que la contiene. C# ([CS0136](https://learn.microsoft.com/dotnet/csharp/misc/cs0136)) y Java también lo rechazan:

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

Una variable sin usar es una advertencia, como [CS0219](https://learn.microsoft.com/dotnet/csharp/misc/cs0219) en C#, mientras que `javac` no dice nada:

```text
w02_unused.v:2:2: warning: unused variable: `count`
    1 | fn main() {
    2 |     count := 3
      |     ~~~~~
    3 |     println('done')
    4 | }
done
```

El mismo archivo con `v -prod` no compila: las [advertencias se convierten en errores](https://docs.vlang.io/variables.html#warnings-and-declaration-errors) en las compilaciones de producción.

```text
e02_unused_prod.v:3:2: error: unused variable: `count`
    1 | // flags: -prod
    2 | fn main() {
    3 |     count := 3
      |     ~~~~~
    4 |     println('done')
    5 | }
```

## Tipos primitivos

| V | C# | Java | Notas |
|---|---|---|---|
| `bool` | `bool` | `boolean` | |
| `i8`, `i16`, `int`, `i64` | `sbyte`, `short`, `int`, `long` | `byte`, `short`, `int`, `long` | `int` siempre tiene 32 bits |
| `u8`, `u16`, `u32`, `u64` | `byte`, `ushort`, `uint`, `ulong` | — | Java no tiene tipos sin signo |
| `f32`, `f64` | `float`, `double` | `float`, `double` | |
| `isize`, `usize` | `nint`, `nuint` | — | el tamaño de un puntero |
| `rune` | `int` que contiene un punto de código, [`Rune`](https://learn.microsoft.com/dotnet/api/system.text.rune) | `int` que contiene un punto de código | un punto de código Unicode; `char` en C# y Java es una unidad UTF-16 |
| `string` | `string` (UTF-16) | `String` (UTF-16) | UTF-8, inmutable |

Fuente: [V types](https://docs.vlang.io/v-types.html). Un literal entero es un `int`, un literal de coma flotante un `f64`, y una conversión se escribe como una llamada: `i64(3_000_000_000)`.

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

V promueve un tipo más pequeño a uno más grande cuando no se puede perder ningún valor: `int` a `i64` o `f64`, `u8` a `int`. Nunca mezcla con signo y sin signo, mientras que C# convertiría silenciosamente `uint + int` en `long`:

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

El segundo error es consecuencia del primero: una vez que la suma no tiene tipo, `println` no tiene nada que imprimir. Lee primero el primer error.

V tampoco convierte un número en cadena. `"lessons: " + 4` es C# y Java válido; en V, usa la interpolación:

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

La aritmética se comporta como C# en un contexto `unchecked` y como Java: los enteros dan la vuelta (desbordamiento circular), y la división entera trunca hacia cero.

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

### Las cadenas son bytes UTF-8

```v
word := 'journée'
println('${word.len} bytes, ${word.runes().len} runes')
println('${word[0]} ${typeof(word[0]).name} ${`é`} ${typeof(`é`).name}')
```

```text
8 bytes, 7 runes
106 u8 é rune
```

En C# y Java, `"journée".Length` y `"journée".length()` valen 7: cuentan unidades UTF-16. En V, [`len`](https://modules.vlang.io/builtin.html#string) cuenta los bytes de la codificación UTF-8, y `é` ocupa dos. Indexar una cadena da un byte (`u8`), no un carácter: `word[0]` es 106, el código de `j`. [`runes()`](https://modules.vlang.io/builtin.html#string.runes) decodifica los puntos de código; un literal de rune usa comillas invertidas.

### `if` y `match` son expresiones

V no tiene operador ternario: `if` devuelve un valor. [`match`](https://docs.vlang.io/statements-&-expressions.html#match) es el equivalente de una expresión `switch` de C# o de un `switch` con flechas de Java, y debe cubrir todos los casos, aquí con `else`:

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

## Structs en lugar de clases

V no tiene clases, ni herencia, ni constructores. Un [struct](https://docs.vlang.io/structs.html) contiene los datos, y los métodos se declaran junto a él:

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

- Un literal de struct nombra los campos, o los da todos en orden.
- Un campo que no se da toma su valor por defecto: `locale` vale `'en'`, y en los demás casos el valor cero (`0`, `''`, un array vacío).
- No hay `null`: un campo `string` nunca falta, solo está vacío.

`@[required]` hace un campo obligatorio en cada literal, como el modificador [`required`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/required) de C# 11:

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

### Los campos son privados e inmutables por defecto

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

`mut p` hace mutable la variable, no sus campos. Los [modificadores de acceso](https://docs.vlang.io/structs.html#access-modifiers) son secciones del struct:

| Sección V | Leer desde otro módulo | Escribir en el módulo | Escribir desde otro módulo | Lo más parecido en C# | Lo más parecido en Java |
|---|---|---|---|---|---|
| (ninguna) | no | no | no | `private readonly` | `private final` |
| `mut:` | no | sí | no | `private` | `private` |
| `pub:` | sí | no | no | `public` + `init` | `public final` |
| `pub mut:` | sí | sí | no | `public` + `private set` | getter público, setter privado |
| `__global:` | sí | sí | sí | `public` | `public` |

El código del curso usa un solo módulo, así que solo necesita `mut:`:

```v
struct Progress {
mut:
	done int
pub:
	total int
}
```

## Métodos

```v
fn (p Page) is_lesson() bool {
	return p.title.len > 0 && p.title[0].is_digit()
}

fn (mut p Progress) complete() {
	p.done++
}
```

Un [método](https://docs.vlang.io/structs.html#methods) es una función con un **receptor** entre `fn` y su nombre. No hay `this`: el receptor tiene un nombre, por convención de una letra. El receptor es inmutable salvo que se declare `mut`, y un método `mut` solo se puede llamar sobre una variable mutable:

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

La misma regla se aplica a los parámetros: `fn f(mut pages []Page)` se llama como `f(mut pages)`, así que el punto de llamada muestra lo que puede cambiar. Pero V rechaza `mut` para un número, donde C# tiene `ref int`:

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

### `str()`, métodos estáticos y actualización de structs

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

- `str()` cumple el papel de `ToString()` y `toString()`: `println` y `${…}` lo llaman.
- `fn Page.translation` es un [método estático](https://docs.vlang.io/structs.html#static-type-methods), que se llama `Page.translation(…)`. Es la forma de V de escribir una factoría, ya que no hay constructores.
- `...p` copia los campos de `p` y sustituye los que se enumeran, como una [expresión `with`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/with-expression) de C# sobre un record.

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

### Argumentos con nombre y opcionales

V no tiene sobrecarga, ni argumentos por defecto, ni argumentos con nombre. Dos funciones con el mismo nombre se rechazan, sean cuales sean sus parámetros:

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

Un struct marcado con [`@[params]`](https://docs.vlang.io/structs.html#trailing-struct-literal-arguments), como último parámetro, da la misma comodidad que los argumentos con nombre y opcionales de C#, o que un builder en Java:

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

La llamada enumera los campos sin llaves; los que se omiten conservan su valor por defecto.

## Los structs son valores

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

Un struct de V se comporta como un `struct` o un `record struct` de C#, no como una clase: la asignación lo copia, y `==` compara los campos, como la igualdad de un record de C# o de un record de Java. `mut p2 := p1` crea un segundo `Progress`. Un struct sin `str()` imprime todos sus campos.

Internamente, V pasa un argumento struct inmutable por valor o por referencia, según le convenga ([referencias](https://docs.vlang.io/references.html)); como la función llamada no puede modificarlo, la diferencia no se nota. La lección 4 vuelve sobre las referencias, `&Page`, y sobre lo que se comparte: los arrays y los maps no siguen la misma regla que los structs.

## Puntos clave

- `x := 1` declara una variable inmutable; hace falta `mut` para reasignarla, para cambiar un campo o para llamar a un método `mut`.
- `int` tiene 32 bits en todas partes; V nunca mezcla tipos con signo y sin signo, y nunca convierte implícitamente un número en cadena.
- Una cadena es UTF-8: `len` cuenta bytes, indexar da un `u8`, `runes()` da los puntos de código.
- Un struct tiene campos privados e inmutables por defecto, métodos con un receptor explícito, y ningún constructor: los métodos estáticos y `...p` los sustituyen.
- Sin sobrecarga, sin argumentos por defecto ni con nombre: un struct `@[params]` los sustituye.
- Los structs son valores, copiados en la asignación y comparados campo a campo.

## Ejercicios

1. Escribe un struct `Course` con un nombre, un número de lecciones y un contador mutable `done`, un método `finish_lesson()` que nunca pase del número de lecciones, y un `str()` que imprima `V: 2/2`. Llama tres veces a `finish_lesson()` sobre un curso de dos lecciones.

<details>
<summary>Solución</summary>

[`examples/s02_course.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s02_course.v#L1-L28):

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

`for _ in 0 .. 3` se repite tres veces; `_` ignora el contador, y `0 .. 3` excluye el 3.

</details>

2. ¿Qué imprime esto? ¿Imprimiría lo mismo una `class Course` de C#?

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
<summary>Solución</summary>

```text
Rust: 0/15 | Rust: 1/15
```

`mut b := a` copia el struct: `a` no cambia. Con una clase de C#, `b` y `a` serían el mismo objeto y ambos imprimirían `Rust: 1/15`; con un `struct` de C#, la salida sería la misma que en V.

</details>

3. `fn double(mut n int)` no compila. Escribe en su lugar la función que V espera, y llámala.

<details>
<summary>Solución</summary>

Devuelve el nuevo valor, como sugiere el mensaje de error:

```v
fn double(n int) int {
	return n * 2
}

x := double(2)
```

V solo permite parámetros `mut` para arrays, maps, structs, interfaces y punteros. La [documentación](https://docs.vlang.io/functions-2.html#mutable-arguments) incluso prefiere devolver valores para esos casos, y reserva la modificación de un argumento en su sitio para las partes de un programa donde las copias cuestan demasiado.

</details>

## Fuentes

- [Documentación de V — Variables](https://docs.vlang.io/variables.html), [V Types](https://docs.vlang.io/v-types.html), [Structs](https://docs.vlang.io/structs.html), [Functions 2](https://docs.vlang.io/functions-2.html), [References](https://docs.vlang.io/references.html)
- [Biblioteca estándar de V — `string`](https://modules.vlang.io/builtin.html#string)
- [C# — Tipos integrados](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/built-in-types), [Registros](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record), [Tipos de estructura](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct)
- [Java Language Specification — Types, values and variables](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html), [Record classes](https://docs.oracle.com/en/java/javase/25/language/records.html)
