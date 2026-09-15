---
title: "5. Interfaces y genéricos"
description: Interfaces que un tipo implementa sin declararlo, y genéricos sin restricciones — probados con los 111 proyectos .NET de GuitarAlchemist/ga.
sidebar:
  order: 5
---

Código: [`examples/l05_interfaces.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v) y [`examples/l05_generics.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v) — `v run examples/l05_generics.v` desde `code/v-for-csharp-java`.

## Datos nuevos: los proyectos de una solución .NET

A partir de esta lección, los ejemplos leen los proyectos .NET de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), una aplicación de teoría musical, en el commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893). El [curso de LadybugDB](../../ladybugdb/05-csharp/) los extrajo de los archivos `.csproj` y `.fsproj`; [`data/ga`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/data/ga) contiene una copia de sus tres archivos CSV:

| Archivo | Filas | Columnas |
|---|---|---|
| `projects.csv` | 111 | `path,name,language,sdk,frameworks,in_solution` |
| `project_refs.csv` | 266 | `from,to`: un `ProjectReference`, de la ruta de un proyecto a la ruta de otro |
| `package_refs.csv` | 478 | `project,package,version`: un `PackageReference` |

Ningún campo contiene una coma, así que aquí basta con `line.split(',')`, a diferencia de los títulos de página de la [lección 3](../03-errors-option-result/).

## Interfaces

| | C# | Java | V |
|---|---|---|---|
| Un tipo implementa una interfaz | declarándola: `class Package : INamed` | declarándola: `implements Named` | teniendo sus métodos y campos |
| La declaración | obligatoria | obligatoria | opcional: `struct Package implements Named` |
| Miembros | métodos, propiedades, [implementaciones predeterminadas](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/default-interface-methods-versions) | métodos, [métodos predeterminados](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html) | métodos y campos |
| Probar el tipo | `if (n is Project p)` | `if (n instanceof Project p)` | `if n is Project { }` |

Fuente: [Interfaces](https://docs.vlang.io/type-declarations.html#interfaces).

Una interfaz enumera métodos, y también campos. [`Project` y `Package`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L4-L38) tienen ambos un campo `name` y un método `kind()`, así que ambos son `Named`, sin una palabra al respecto en sus declaraciones:

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

Un array de valores de interfaz contiene tipos distintos, como lo haría un `List<INamed>`. `is` prueba el tipo y hace un cast de la variable dentro del `if`, como los tipos de error de la lección 3:

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

`Named(project)` convierte el primer elemento; V convierte luego los demás al tipo de elemento del array.

### Un método que falta se señala donde se convierte el valor

C# señala un miembro que falta en la declaración de la clase (`error CS0535: 'Package' does not implement interface member 'INamed.Kind()'`), y javac también (`Package is not abstract and does not override abstract method kind() in Named`). En V, `Package` no declara nada, así que el error aparece donde un `Package` se convierte en un `Named`:

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

Un struct que nunca se convierte nunca se comprueba. El `implements` opcional traslada la comprobación a la declaración, como en C# y Java:

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

El [`Language`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L73-L79) del ejemplo lo usa.

### Los métodos sobre la interfaz no son implementaciones predeterminadas

`fn (n Named) label()` declara un método sobre la propia interfaz. Todo valor `Named` lo tiene, y los tipos no lo implementan. La documentación advierte que esto «NO es una "implementación predeterminada" como en C#»: si `Project` tuviera su propio `label()`, llamar a `label()` sobre un `Named` seguiría ejecutando el método de la interfaz, y el de `Project` solo después de `is Project`. Se comporta como un método de extensión de C# sobre `INamed`, escrito como un método.

### Métodos `mut:`

Un método que modifica su receptor va en la sección `mut:` de la interfaz. [`Counter` y `Distinct`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L40-L71) cuentan las referencias a paquetes de dos maneras:

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

`for mut t` es necesario para llamar a `add`. Fuera de `mut:`, un método de interfaz se llama sobre un valor inmutable, y un tipo cuyo método tiene un receptor `mut` no lo implementa:

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

Lo contrario se acepta: `total()` está en la sección `mut:`, y `Counter` lo implementa con un receptor inmutable. La documentación de 0.5.2 dice lo contrario (un tipo con `fn (s MyStruct) write` «implementa la interfaz Foo, pero *no* la interfaz Bar», cuyo `write` está en `mut:`); el compilador solo rechaza un receptor `mut` para un método fuera de `mut:` (consulta el [diario](../journal/)).

### Un struct se copia dentro de una interfaz

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

Convertir un valor struct en una interfaz lo copia, como el [boxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing) de un `struct` de C#: con `struct Counter : ITally`, `ITally copied = counter;` también deja `counter.N` en 0, lo que comprobé con .NET 11. Convertir una referencia (`&Counter`) comparte el struct, como convertir una clase de C# o cualquier objeto de Java.

Las interfaces también pueden incrustar otras interfaces, como los structs incrustan structs: `interface ReaderWriter { Reader Writer }` ([Embedded interface](https://docs.vlang.io/type-declarations.html#embedded-interface)).

## Genéricos

| | C# | Java | V |
|---|---|---|---|
| Función genérica | `Dictionary<string, int> CountBy<T>(…)` | `<T> Map<String, Integer> countBy(…)` | `fn count_by[T](…) map[string]int` |
| Argumentos de tipo | inferidos, o `CountBy<Project>(…)` | inferidos, o `Util.<Project>countBy(…)` | inferidos, o `count_by[Project](…)` |
| Restricciones | [`where T : IComparable<T>`](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters) | [`<T extends Comparable<T>>`](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html) | ninguna: cada uso se comprueba con el tipo concreto |
| En tiempo de ejecución | una versión por tipo de valor, código compartido para las referencias | [borrados](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html) a `Object` o a la cota | una copia de la función por cada tipo usado |

Fuente: [Generics](https://docs.vlang.io/type-declarations.html#generics).

### Funciones genéricas

[`count_by`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L35-L47) agrupa elementos por una clave, como `GroupBy(key).ToDictionary(g => g.Key, g => g.Count())` en LINQ o `Collectors.groupingBy(key, Collectors.counting())` en Java:

```v
fn count_by[T](items []T, key fn (T) string) map[string]int {
	mut counts := map[string]int{}
	for item in items {
		counts[key(item)]++
	}
	return counts
}

// Sin restricción: T solo necesita un campo `name` en cada llamada
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

ga tiene 105 proyectos C# y 6 proyectos F#, 16 de ellos proyectos web. V infiere `T` a partir de los argumentos. Cuando ningún argumento es de tipo `T`, hay que indicarlo:

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

`names` lee `it.name` sobre un `T` que nada restringe. C# se negaría a compilar la propia función; V vuelve a comprobar el cuerpo para cada tipo con el que se la llama, como una plantilla de C++. `Project` y `Package` tienen ambos un `name`. Un tipo sin él falla, y el error apunta al interior de la función genérica, no a la llamada:

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

### Structs genéricos

[`Index[T]`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L49-L61) es un map de una clave a un `T`, con métodos. `get` devuelve un option, donde C# tendría `TryGetValue` y Java `Optional<T>`:

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

El nombre es una mala clave para ga: dos proyectos se llaman `GaApi.Tests`, en `Tests/Apps/GaApi.Tests` y `Tests/GaApi.Tests`, así que el segundo `add` reemplaza al primero, y el índice contiene 110 proyectos. La ruta es única.

### Operadores en una función genérica

[`largest`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L63-L84) compara con `>`. C# lo rechaza en el propio método genérico (`error CS0019: Operator '>' cannot be applied to operands of type 'T' and 'T'`) salvo que `T` tenga una restricción. V lo acepta para números y cadenas, y para un struct que define `<`: V genera `>`, `<=` y `>=` a partir de él ([sobrecarga de operadores](https://docs.vlang.io/limited-operator-overloading.html#implicitly-generated-overloads)).

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

[Spectre.Console](https://spectreconsole.net/) es el paquete que más proyectos de ga referencian, 20 de ellos. Sin `<`, el error vuelve a estar dentro de la función, y su redacción es extraña:

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

El mensaje no nombra `Usage`, ni menciona la línea 18, la llamada que lo pide. Tampoco nombra `<`, el operador que hay que definir: `>` se genera a partir de `<`. En un programa con varias llamadas a `largest`, tienes que encontrar tú mismo la que usa un struct.

### Una prueba en tiempo de compilación en lugar de una restricción

Sin restricciones, una función genérica puede probar su argumento de tipo en tiempo de compilación con `$if T is …` ([compile-time types](https://docs.vlang.io/conditional-compilation.html#compile-time-types)), y `T.name` da el nombre del tipo:

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

Solo se compila la rama que corresponde a `T`, así que `x.name` no se comprueba para `int`. A diferencia de un `where` de C#, la prueba no rechaza una llamada: elige el código para cada tipo.

## Puntos clave

- Un tipo implementa una interfaz teniendo sus métodos y campos; la comprobación ocurre donde se convierte un valor, o en la declaración con el `implements` opcional.
- Las interfaces pueden exigir campos. Los métodos declarados sobre la interfaz no son implementaciones predeterminadas.
- Un método de la sección `mut:` necesita un valor de interfaz mutable; un receptor `mut` no puede implementar un método fuera de ella.
- Convertir un valor struct en una interfaz copia el struct, como el boxing en C#; convertir una referencia lo comparte.
- Los genéricos no tienen restricciones: el cuerpo se comprueba para cada tipo usado, y los errores apuntan al interior de la función genérica en lugar de a la llamada. `$if T is` elige el código en tiempo de compilación.

## Ejercicios

1. Escribe `fn group_by[T](items []T, key fn (T) string) map[string][]T` e imprime los nombres de los proyectos F# de ga.

<details>
<summary>Solución</summary>

[`examples/s05_group_by.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s05_group_by.v#L10-L16):

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

`groups[key(item)] << item` funciona con una clave ausente: indexar un map para modificarlo crea el array vacío, igual que `counts[key]++` crea el 0 en `count_by`.

</details>

2. Llama a `largest` sobre los proyectos F# del ejercicio 1, de modo que devuelva el último por nombre.

<details>
<summary>Solución</summary>

`Project` necesita `<` ([`s05_group_by.v`, líneas 31-34](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s05_group_by.v#L31-L34)):

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

La comparación de cadenas es ordinal, como `string.CompareOrdinal` en C# y `compareTo` en Java: `'a'` va después de `'A'`, así que `GaMusicTheoryLsp` va después de `GA.Business.ProbabilisticGrammar`.

</details>

3. En el ejemplo de la copia, `copied.total()` vale 1 y `counter.n` vale 0. ¿Qué imprimiría `copied: counter.n = 1`, y cuál es el equivalente en C#?

<details>
<summary>Solución</summary>

Convertir una referencia en lugar de un valor: `mut counter := &Counter{}`, y luego `Tally(counter)`, como hace el ejemplo con `shared_counter`. En C#, la interfaz tendría que referirse al mismo objeto: convierte `Counter` en una `class` en lugar de un `struct`. Con un `struct`, `ITally copied = counter;` hace boxing de una copia.

</details>

## Fuentes

- [Documentación de V — Interfaces](https://docs.vlang.io/type-declarations.html#interfaces), [Generics](https://docs.vlang.io/type-declarations.html#generics), [Limited operator overloading](https://docs.vlang.io/limited-operator-overloading.html), [Compile-time types](https://docs.vlang.io/conditional-compilation.html#compile-time-types); la documentación de 0.5.2: [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [C# — Interfaces](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces), [Restricciones de parámetros de tipo](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Boxing y unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing)
- [Java — Default methods](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html), [Bounded type parameters](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html), [Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html)
- [GuitarAlchemist/ga en `a26a7893`](https://github.com/GuitarAlchemist/ga/tree/a26a7893), extraídos por el [curso de LadybugDB](../../ladybugdb/05-csharp/)
