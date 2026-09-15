---
title: 4. Arrays, maps, slices y memoria
description: Arrays y maps comparados con List, Dictionary, ArrayList y HashMap, lo que comparte una asignación, y las cuatro formas de V de gestionar la memoria, medidas en tres SO.
sidebar:
  order: 4
---

Código: [`examples/l04_arrays.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_arrays.v), [`examples/l04_maps.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_maps.v), [`examples/l04_references.v`](https://github.com/spareilleux/learn/blob/391a0c46439cb27c820aae4238475d9f3bec5a10/code/v-for-csharp-java/examples/l04_references.v) y [`examples/l04_memory.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_memory.v) — `v run examples/l04_maps.v` desde `code/v-for-csharp-java`.

## Arrays

Un array de V, `[]int`, crece como una `List<int>` o un `ArrayList<Integer>`; en el código del día a día no hay un tipo de array de tamaño fijo aparte (`[3]int` existe, para los buffers).

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
| Tipo | `List<int>` | `ArrayList<Integer>` | `[]int` |
| Literal | `[474, 341]` (C# 12) | `List.of(474, 341)` (inmutable) | `[474, 341]` |
| Vacío, con capacidad | `new List<int>(100)` | `new ArrayList<>(100)` | `[]int{cap: 100}` |
| Añadir | `Add(x)`, `AddRange(xs)` | `add(x)`, `addAll(xs)` | `a << x`, `a << xs` |
| Número de elementos | `Count` | `size()` | `len` |
| Contiene | `Contains(x)` | `contains(x)` | `x in a` |
| Índice fuera de rango | `ArgumentOutOfRangeException` | `IndexOutOfBoundsException` | panic, o `a[i] or { }` |

Fuentes: [V arrays](https://docs.vlang.io/v-types.html#arrays), [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [`ArrayList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html).

`init` se evalúa para cada elemento, con `index` como posición. Los elementos siempre se inicializan: `[]int{len: 5}` son cinco ceros.

### `filter`, `map` y ordenación

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

`filter`, `map`, `any` y `all` reciben una expresión en la que `it` es el elemento, o una función. Devuelven un nuevo array de inmediato: no son perezosos (lazy) como LINQ o los streams.

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

`sort` ordena en su sitio, `sorted` devuelve una copia. La expresión de ordenación llama a los dos elementos `a` y `b`, y no puede usar nada más: una variable de la función que la contiene queda fuera de su alcance.

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

Los errores tercero y cuarto muestran cómo funciona `sort`: `a` y `b` son referencias (`&string`) a los elementos. [`sort_with_compare`](https://modules.vlang.io/builtin.html#array.sort_with_compare) recibe en cambio una función de comparación; la [sección sobre los maps](#maps) más abajo ordena un array de structs por un campo.

## Slices

```v
counts := [474, 341, 326, 394, 120, 88]
first := counts[..2]
println('${first} ${counts[4..]} ${counts#[-2..]}')
```

```text
[474, 341] [120, 88] [120, 88]
```

`a[start..end]` excluye `end`, como los rangos de C# `a[..2]`. Un índice negativo cuenta desde el final, pero solo con `#[…]`: `counts#[-2..]` es `counts[^2..]` en C#. En V, un slice es un array corriente (`[]int`), no un tipo aparte como `Span<int>` o una vista `subList`.

Que un slice comparta la memoria de su array depende de la mutabilidad ([array slices](https://docs.vlang.io/v-types.html#array-slices)):

- Si el array y el slice son ambos inmutables, el slice comparte la memoria del array: ninguno de los dos puede modificarla.
- Si alguno de los dos es `mut`, V clona el slice, y lo indica con un aviso (notice):

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

`first` conservó `[474, 341]` después de `lines[0] = 0`: es una copia.

## Lo que comparte una asignación

Un struct se copia en la asignación ([lección 2](../02-types-structs-methods/#los-structs-son-valores)). Un array no. El checker en [`assign.v`, líneas 845-855](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/assign.v#L845-L855) solo clona los *slices* (`a[..]`); un array entero asignado a otra variable comparte su memoria:

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

1. `alias := original` comparte la memoria: el `alias` inmutable ve `original[0] = 100`, sin ningún aviso.
2. `original << 4` supera la capacidad de 3: V mueve `original` a un bloque más grande. `alias` sigue apuntando al antiguo, y ya no ve `original[1] = 200`.
3. `clone()` hace una copia independiente, como `new List<int>(list)` o `new ArrayList<>(list)`.

Una `List<int>` de C# o un `ArrayList` de Java asignado a otra variable es el mismo objeto para siempre; un array de V se comparte hasta que crece, como un slice en Go. Aunque sea inmutable, `alias` no protege nada: el array que lee puede seguir cambiando a través de `original`.

V rechaza el sentido contrario, una variable mutable que compartiría un array inmutable:

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

`data/pages.csv` tiene una línea por página de este sitio. [`encoding.csv`](https://modules.vlang.io/encoding.csv.html) lo lee ([lección 3](../03-errors-option-result/#tipos-de-error-personalizados)), y dos maps cuentan las páginas por idioma y las líneas en inglés por curso:

```v
mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
reader.read()! // la cabecera: url,locale,course,title,lines
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

`pages_per_locale[row[1]]++` funciona la primera vez que aparece un idioma: una clave ausente se lee como el valor cero del tipo. Esa es la principal diferencia con C# y Java:

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
| Tipo | `Dictionary<string, int>` | `HashMap<String, Integer>` | `map[string]int` |
| Clave ausente, `m[k]` | `KeyNotFoundException` | `get` devuelve `null` | el valor cero, `0` |
| Clave ausente, explícito | `TryGetValue`, `GetValueOrDefault` | `getOrDefault` | `m[k] or { … }`, `if v := m[k] { }` |
| Contiene la clave | `ContainsKey(k)` | `containsKey(k)` | `k in m` |
| Eliminar | `Remove(k)` | `remove(k)` | `m.delete(k)` |
| Orden de iteración | indefinido | indefinido (`LinkedHashMap`: inserción) | inserción |

Fuentes: [V maps](https://docs.vlang.io/v-types.html#maps), [`Dictionary<TKey,TValue>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2), [`HashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/HashMap.html).

El valor cero oculta las erratas: `m['fr ']` devuelve 0 sin decir nada. Un módulo puede renunciar a él con `@[strict_map_index]`, que convierte en error cada índice sin `or { }`:

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

Para ordenar las entradas, el ejemplo las copia en un array de structs, ya que una expresión de ordenación solo ve `a` y `b`:

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

`${t.course:-22}` rellena hasta 22 caracteres por la derecha, `${t.lines:5}` hasta 5 por la izquierda, como `{t.Course,-22}` y `{t.Lines,5}` en C#.

A diferencia de un array, un map no se puede asignar a otra variable, sea mutable o no:

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

`clone()` hace explícita la copia:

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

## Memoria

### La pila, el montón (heap) y las referencias

V pone los structs en la pila cuando puede, y en el montón cuando su dirección escapa ([stack and heap](https://docs.vlang.io/memory-management.html#stack-and-heap)). Los arrays y los maps guardan sus elementos en el montón. No eliges con una palabra clave como `class` y `struct` en C#: el compilador decide según lo que hace el código con la dirección.

```v
struct Page {
	title string
}

fn newest() &Page {
	p := Page{'Journal'}
	return &p
}
```

`&Page` es una referencia a un `Page`, y `&p` toma la dirección de `p`. Devolverla está permitido: V ve que la dirección sale de `newest` y asigna `p` en el montón. `&Page{…}` asigna directamente en el montón, como `new` en C# y Java:

```v
lesson := &Page{'4. Arrays, maps, slices and memory'}
println(typeof(lesson).name)
println(lesson.title)
```

```text
&Page
4. Arrays, maps, slices and memory
```

Dentro de una función que recibe una referencia, el compilador no puede saber dónde vive el struct. Se niega a almacenar la referencia, porque el struct puede estar en la pila del llamador:

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

Como dice el mensaje, `@[heap]` sobre el struct asigna cada instancia en el montón, y el mismo código compila ([`l04_references.v`, líneas 13-26](https://github.com/spareilleux/learn/blob/391a0c46439cb27c820aae4238475d9f3bec5a10/code/v-for-csharp-java/examples/l04_references.v#L13-L26)). Una referencia nula se escribe `unsafe { nil }`: fuera de `unsafe`, una referencia no puede ser nula.

### Por defecto: un recolector de basura

La [documentación](https://docs.vlang.io/memory-management.html) enumera cuatro formas de gestionar la memoria:

| Modo | Opción | Qué libera la memoria |
|---|---|---|
| Recolector de basura (GC) | el comportamiento por defecto | el recolector conservador [Boehm-Demers-Weiser](https://github.com/bdwgc/bdwgc), incluido en `thirdparty/libgc` |
| Autofree | `-autofree` | llamadas a `free()` insertadas por el compilador; la documentación lo describe como un trabajo en curso y lo desaconseja |
| Manual | `-gc none` | nada: llamas a `free()` en código `unsafe`, o hay fugas |
| Arena | `-prealloc` | un asignador de arena, para programas de corta duración, de un solo hilo, de tipo lote |

[`l04_memory.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_memory.v#L5-L24) construye 50 arrays de 100,000 cadenas, uno tras otro, y no conserva ninguno. [`runtime.used_memory`](https://modules.vlang.io/runtime.html#used_memory) da la memoria residente del proceso, en los tres SO:

```v
for round in 1 .. 51 {
	lines := make_lines(100_000)
	total += lines.len
	if round % 25 == 0 {
		println('round ${round}: ${runtime.used_memory()! / 1024 / 1024} MB resident')
	}
}
```

Memoria residente después de la ronda 50, tal como la imprime la CI del curso y en mi máquina:

| Compilación | Windows (mi máquina) | Runner Windows | Runner Linux | Runner macOS |
|---|---|---|---|---|
| `v run` (GC) | 20 MB | 20 MB | 18 MB | 36 MB |
| `v -gc none run` | 540 MB | 540 MB | 383 MB | 384 MB |
| `v -autofree run` | 10 MB | 9 MB | 6 MB | 6 MB |
| `v -prod run` | 542 MB (MSVC) | | | |
| `v -prod -gc boehm run` | 30 MB (MSVC) | | | |

- Con el GC, la memoria se mantiene estable, como en un programa .NET o Java: los arrays de las rondas anteriores se recolectan.
- Con `-gc none`, no se libera nada: la memoria crece de 8 a 11 MB por ronda.
- `-autofree` libera cada array al final de su ronda, y es el que menos memoria usa aquí. También *desactiva* el GC: `-autofree` fija `gc_mode = .no_gc` en [`pref.v`, líneas 807-811](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/pref.v#L807-L811), así que todo lo que autofree no libera se pierde en fugas, cuando la documentación dice que el GC lo libera.
- En Windows, una compilación `-prod` compilada por MSVC desactiva el GC sin avisar: [`default.v`, líneas 369-381](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/default.v#L369-L381) cambia a `no_gc` cuando el compilador C es MSVC y no se da ninguna opción `-gc`. El mismo programa que se queda en 20 MB en desarrollo crece hasta 542 MB en producción. `-gc boehm` recupera el GC.

`gc_is_enabled()` indica en qué caso estás: el ejemplo lo imprime en su primera línea, `GC enabled: false` con `-gc none`, `-autofree`, y `-prod` compilado por MSVC.

## Puntos clave

- `[]T` es un array que crece con `<<`, `filter`, `map`, `sort`; los métodos funcionales no son perezosos, y una expresión de ordenación solo ve `a` y `b`.
- Un slice de un array inmutable comparte su memoria; con `mut` en cualquiera de los dos lados, V lo clona e imprime un aviso.
- Asignar un array entero lo comparte hasta que crece más allá de su capacidad; `clone()` hace una copia real. Un map no se puede asignar sin `clone()`.
- Una clave de map ausente devuelve el valor cero; usa `or { }`, `if v := m[k]`, `in`, o `@[strict_map_index]`.
- El compilador elige la pila o el montón; `&T{}` y `@[heap]` fuerzan el montón.
- El GC es el comportamiento por defecto, `-gc none` pierde en fugas lo que no liberas, y `-autofree` desactiva el GC. En Windows, `-prod` con MSVC también lo desactiva.

## Ejercicios

1. Cuenta las lecciones en francés de cada curso en `data/pages.csv` (los títulos que empiezan por un dígito), e imprime los cursos ordenados por nombre.

<details>
<summary>Solución</summary>

[`examples/s04_lessons_per_course.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s04_lessons_per_course.v#L5-L20):

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

El map conserva el orden en que los cursos aparecen por primera vez en el archivo; `keys()` y `sort()` dan el orden alfabético. Comprobé los recuentos con `awk` sobre el mismo archivo.

</details>

2. ¿Qué imprime esto?

```v
mut a := [1, 2, 3]
b := a
a << 4
a[0] = 9
println('a ${a}, b ${b}')
```

<details>
<summary>Solución</summary>

```text
a [9, 2, 3, 4], b [1, 2, 3]
```

`b := a` comparte el array, pero `a << 4` supera su capacidad de 3 y mueve `a` a un nuevo bloque antes de `a[0] = 9`. Intercambia las dos líneas, `a[0] = 9` y luego `a << 4`, y `b` imprime `[9, 2, 3]`.

</details>

3. Un servicio V de larga duración se compila con `v -prod` en una máquina Windows con las Visual Studio Build Tools, y su memoria crece sin parar. ¿Qué compruebas primero?

<details>
<summary>Solución</summary>

Si el GC está activado: imprime `gc_is_enabled()`, o compila con `v -showcc -prod` y busca el `cl.exe` de MSVC. Con MSVC y sin opción `-gc`, V 0.5.2 compila sin GC, y cada asignación de memoria se pierde en fugas. Compila con `-prod -gc boehm`, o con otro compilador C (`-cc gcc`, *por verificar* en una máquina que tenga ambos).

</details>

## Fuentes

- [Documentación de V — Arrays, Maps](https://docs.vlang.io/v-types.html), [Memory management](https://docs.vlang.io/memory-management.html), [References](https://docs.vlang.io/references.html)
- [Biblioteca estándar de V — `array` y `map`](https://modules.vlang.io/builtin.html), [`runtime`](https://modules.vlang.io/runtime.html), [`encoding.csv`](https://modules.vlang.io/encoding.csv.html)
- [C# — `List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [`Dictionary<TKey,TValue>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2), [Fundamentos de la recolección de elementos no utilizados](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals)
- [Java — `ArrayList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html), [`HashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/HashMap.html), [Garbage collection tuning](https://docs.oracle.com/en/java/javase/25/gctuning/)
- [Recolector de basura Boehm-Demers-Weiser](https://github.com/bdwgc/bdwgc)
