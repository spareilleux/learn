---
title: "6. Enums, tipos suma y match"
description: Enums sin aritmética, tipos suma en lugar de jerarquías selladas, y un match que debe cubrir todos los casos — probados con las versiones de paquetes de GuitarAlchemist/ga.
sidebar:
  order: 6
---

Código: [`examples/l06_enums.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v) y [`examples/l06_versions.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v) — `v run examples/l06_versions.v` desde `code/v-for-csharp-java`. Los datos son los proyectos de ga de la [lección 5](../05-interfaces-generics/#datos-nuevos-los-proyectos-de-una-solución-net).

## Enums

| | C# | Java | V |
|---|---|---|---|
| Declaración | `enum Sdk { Library, Web }` | `enum Sdk { LIBRARY, WEB }` | `enum Sdk { library web }` |
| Valor subyacente | `int`, convertido con un cast | un objeto, con `ordinal()` | `int` por defecto, `enum Sdk as u8` |
| Métodos | métodos de extensión | sí | sí |
| `<`, `+ 1` | permitidos | `compareTo`, sin `+` | rechazados: primero `int(sdk)` |
| Desde una cadena | `Enum.Parse<Sdk>("Web")` | `Sdk.valueOf("WEB")` | `Sdk.from('web')!` |
| Conjunto de flags | [`[Flags]`](https://learn.microsoft.com/dotnet/api/system.flagsattribute) | [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html) | `@[flag]` |

Fuente: [Enums](https://docs.vlang.io/type-declarations.html#enums).

En ga, la columna `sdk` tiene dos valores. [`Sdk`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L4-L23) les da nombre, con un método, y una función que lee el nombre MSBuild:

```v
enum Sdk {
	library
	web
}

// Un enum puede tener métodos
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

Donde el tipo es conocido, basta con `.web`: en otros sitios, `Sdk.web` completo. `match` es una expresión, como una [expresión switch](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) de C# o un `switch` de Java con `->`.

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

Un enum imprime su nombre, e `int(sdk)` da su valor. Sin embargo, un enum no es un número:

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

C# acepta ambas líneas. El segundo mensaje ayuda menos que el primero: dice que `1` no es un `Sdk`, no que `+` esté rechazado.

### `match` debe cubrir todos los valores

`msbuild_name` no tiene `else`: nombra ambos valores. Añade un tercer valor al enum, y todos esos `match` dejan de compilar:

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

C# solo emite una advertencia: con .NET 11, una expresión switch sobre un enum sin `Worker` da `warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern 'Sdk.Worker' is not covered.`, y lanza una [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception) en tiempo de ejecución si llega ese valor. Un `match` sobre cadenas o números no puede enumerar todos los valores, así que siempre necesita `else`:

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

Una rama puede enumerar varios valores, o un rango inclusivo con tres puntos ([`size`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L47-L54)); los slices de la lección 4 usan dos puntos, y excluyen el final:

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

### Flags

Un enum `@[flag]` da un bit a cada valor, como `[Flags]` en C#. [`traits`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L25-L45) activa los flags de un proyecto a partir de sus campos CSV:

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

Seis de los 16 proyectos web de ga no figuran en `AllProjects.slnx`, el archivo de la solución.

## Tipos suma

Una versión NuGet no siempre son tres números. El `package_refs.csv` de ga tiene versiones estables (`9.5.1`), preliminares (`1.0.0-beta.24164.1`) y [versiones flotantes](https://learn.microsoft.com/nuget/concepts/dependency-resolution#floating-versions) (`8.*-*`, la última 8.x, preliminares incluidas). Cada forma tiene sus propios datos. C# y Java lo modelan con una jerarquía de clases o records; V tiene un tipo para ello:

| | C# | Java 21+ | V |
|---|---|---|---|
| Declaración | un `record Version` abstracto, y `record Release(…) : Version` | [`sealed interface Version permits …`](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) y records | `type Version = Floating \| Prerelease \| Release` |
| Cerrado | no: cualquier ensamblado puede derivar | sí | sí |
| Probar y convertir | `if (v is Release r)` | `if (v instanceof Release r)` | `if v is Release { }` |
| Un caso olvidado en un `switch` | advertencia CS8509, y luego una excepción en tiempo de ejecución | un error de compilación | un error de compilación |

Fuente: [Sum types](https://docs.vlang.io/type-declarations.html#sum-types).

[`Version`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v#L5-L53) es uno de tres structs. Una función que devuelve `!Version` devuelve cualquiera de ellos:

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

`match` sobre un tipo suma tiene una rama por variante; dentro de cada rama, `v` tiene el tipo de la variante, como con `is`:

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

`${v}` en la rama `Release` usa `Release.str()`, que une las partes con puntos. `type_name()` da la variante en tiempo de ejecución.

Una variante olvidada es un error, como un valor de enum olvidado:

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

El mismo código en Java 25, con una `sealed interface` y tres records, da `error: the switch expression does not cover all possible input values`. Una rama `else {}` silencia la comprobación, y con ella el recordatorio cuando se añade una variante.

### Las versiones de ga

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

Las 478 versiones se analizan sin error. Dos son flotantes: cada restauración de `DemerzelBridge` y `ReactApp1.Server` puede elegir un paquete más reciente, así que dos compilaciones del mismo commit pueden diferir, salvo que el proyecto use un [archivo de bloqueo](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies). `0.91.241101.1` tiene cuatro partes, lo que NuGet acepta ([números de versión normalizados](https://learn.microsoft.com/nuget/concepts/package-versioning#normalized-version-numbers)).

### `as`, y un campo que solo tiene una variante

`as` convierte a una variante, y hace panic con la equivocada:

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

Prefiere `is` o `match`, que no pueden fallar. Una trampa: V 0.5.2 también acepta `v.parts` directamente sobre un `Version`, sin `as`, porque solo `Release` tiene un campo llamado `parts`. Compila, y hace panic con el mismo mensaje:

```v
fn main() {
	v := Version(Floating{'0.*'})
	println(v.parts)
}
```

```text
V panic: as cast: cannot cast `main.Floating` to `main.Release`
```

El checker reescribe un campo que existe en exactamente una variante como un cast `as` ([`checker.v`, líneas 3180-3201](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/checker.v#L3180-L3201)). La documentación no lo menciona. Un campo que tienen todas las variantes, con el mismo tipo, se puede leer sin cast ([`table.v`, líneas 878-925](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/ast/table.v#L878-L925)).

### Un tipo suma recursivo

Una variante puede contener el propio tipo suma. [`Tree`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v#L55-L106) es un proyecto y los proyectos que referencia, hasta los proyectos que no referencian nada:

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

Una rama de una expresión `match` puede contener sentencias; su última expresión, `n`, es su valor. `print` recorre el árbol de la misma manera:

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

El árbol tiene 20 nodos para 8 proyectos: `GA.Domain.Core` aparece cuatro veces, una bajo cada uno de los cuatro proyectos que lo referencian. Las referencias forman un grafo, no un árbol; la [lección 7](../07-concurrency/) cuenta cada proyecto una sola vez.

## Puntos clave

- Un enum tiene métodos e imprime su nombre; solo `==` y `!=` funcionan con él, `int(e)` da el número, `Sdk.from` lee un nombre o un valor, `@[flag]` crea un conjunto de bits.
- Un tipo suma enumera sus variantes: es cerrado, como una sealed interface de Java, y no necesita clase base.
- `match` debe cubrir todos los valores del enum o todas las variantes, o tener `else`; sobre cadenas y números, `else` es obligatorio. Un `else` también oculta las variantes añadidas más tarde.
- `is` y `match` convierten de forma segura; `as` hace panic con la variante equivocada, y lo mismo un campo que solo tiene una variante, que V 0.5.2 acepta sin `as`.

## Ejercicios

1. Añade `fn (v Version) major() ?int`, que devuelve el primer número de una versión estable o preliminar, y de una versión flotante cuando empieza por un número (`8.*-*` da 8, `*` da `none`).

<details>
<summary>Solución</summary>

[`examples/s06_major.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s06_major.v#L19-L25):

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

La rama `Floating` sale de la función con `none` cuando el patrón no empieza por un número; las otras ramas dan un `int`, que se convierte en el option.

</details>

2. ga añade un servicio worker, y `Sdk` recibe un tercer valor, `worker`, para `Microsoft.NET.Sdk.Worker`. ¿Qué funciones de `l06_enums.v` te obliga el compilador a cambiar, y qué pasa con las demás?

<details>
<summary>Solución</summary>

`msbuild_name` deja de compilar, con el error de `e06_match_enum.v`: su `match` sobre el enum no tiene `else`. `parse_sdk` sigue compilando: hace match sobre cadenas, con un `else` que devuelve un error, así que un proyecto `Microsoft.NET.Sdk.Worker` fallaría en tiempo de ejecución, en `by_sdk[parse_sdk(f[3])!]++`, con `unknown SDK: Microsoft.NET.Sdk.Worker`. `traits` no cambia, y contaría un worker como ni `web` ni ninguna otra cosa.

</details>

3. ¿Por qué `if v is Release { v.parts }` es seguro, mientras que `v.parts` a secas puede hacer panic, aunque ambos compilen?

<details>
<summary>Solución</summary>

Dentro de `if v is Release`, el compilador conoce la variante y lee el campo directamente. `v.parts` a secas se reescribe como `(v as Release).parts`, un cast comprobado en tiempo de ejecución, que hace panic cuando `v` contiene otra variante. En términos de C#, lo primero es `if (v is Release r) { r.Parts }`, lo segundo es `((Release)v).Parts`, que lanza una `InvalidCastException`, salvo que en V nada en el código fuente muestra el cast.

</details>

## Fuentes

- [Documentación de V — Enums](https://docs.vlang.io/type-declarations.html#enums), [Sum types](https://docs.vlang.io/type-declarations.html#sum-types), [Smart casting](https://docs.vlang.io/type-declarations.html#smart-casting), [Matching sum types](https://docs.vlang.io/type-declarations.html#matching-sum-types); la documentación de 0.5.2: [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [C# — Expresión switch](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [Tipos de enumeración](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/enum), [`FlagsAttribute`](https://learn.microsoft.com/dotnet/api/system.flagsattribute)
- [Java — Sealed classes and interfaces](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), [Pattern matching for switch](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html), [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html)
- [NuGet — Versiones de paquetes](https://learn.microsoft.com/nuget/concepts/package-versioning), [Versiones flotantes](https://learn.microsoft.com/nuget/concepts/dependency-resolution#floating-versions)
