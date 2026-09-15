---
title: "8. Tests, v fmt, v vet y v doc"
description: Funciones de test encontradas por su nombre, assert en lugar de Assert.Equal, y el formateador, el linter y el generador de documentación que vienen con el compilador — sobre un módulo que analiza las dependencias de GuitarAlchemist/ga.
sidebar:
  order: 8
---

Código: [`l08-testing`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing), un módulo y sus tests, y [`l08-failing`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-failing), tests que fallan a propósito — `v test .` desde `code/v-for-csharp-java/l08-testing`.

## Tests

| | C# con xUnit | Java con JUnit 5 | V |
|---|---|---|---|
| Framework | un paquete: [xUnit](https://xunit.net/), NUnit, MSTest | una dependencia: [JUnit](https://docs.junit.org/current/user-guide/) | integrado |
| Un test | un método con `[Fact]` | un método con `@Test` | una función llamada `test_…` en un archivo llamado `…_test.v` |
| Comprobación | `Assert.Equal(expected, actual)` | `assertEquals(expected, actual)` | `assert actual == expected` |
| Antes y después de todos los tests | un fixture, `IClassFixture<T>` | `@BeforeAll`, `@AfterAll` | `testsuite_begin()`, `testsuite_end()` |
| Probar código privado | [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) | un test en el mismo paquete | un test en el mismo módulo |
| Ejecutar | [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) | `mvn test`, `gradle test` | `v test .`, o `v file_test.v` |

Fuente: [Testing](https://docs.vlang.io/testing.html).

### Un módulo y sus tests

`l08-testing` es un proyecto con un módulo, `deps`, que reúne el parser de versiones de la lección 6 y un grafo de referencias entre proyectos:

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

Un archivo de test cuya primera línea es `module deps` es un test **interno**: pertenece al módulo, y puede llamar a sus funciones privadas, como `parse_release` ([`version_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/version_test.v)):

```v
// Un test interno: mismo módulo, así que puede llamar a la función privada parse_release
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

No hay biblioteca de aserciones: `assert` acepta cualquier expresión booleana y, si falla, imprime ambos lados de la comparación. Una función de test puede devolver `!`, y entonces `!` tras una llamada hace fallar el test con el error, donde un test de xUnit dejaría escapar la excepción. Un error esperado se comprueba con `or`, donde xUnit tiene `Assert.Throws` y JUnit `assertThrows`.

Un archivo de test que en cambio importa el módulo es un test **externo**, y solo ve lo que `deps` hace `pub`. [`tests/ga_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/tests/ga_test.v) ejecuta el módulo sobre los archivos reales de ga:

```v
// Un test externo: importa el módulo, y solo ve su API pública
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

`@VMODROOT` es la carpeta del `v.mod` más cercano, conocida en tiempo de compilación: el test encuentra sus datos desde dondequiera que se ejecute.

### `v test`

`v test .` encuentra todos los archivos `_test.v` bajo la carpeta, compila cada uno como un programa aparte, y los ejecuta en paralelo:

```text
---- Testing... ----------------------------------------------------------------
OK    [1/4] C:   594.6 ms, R:    83.349 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/graph_test.v
OK    [2/4] C:   593.6 ms, R:    84.106 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/s08_cycle_test.v
OK    [3/4] C:   594.1 ms, R:    84.014 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/tests/ga_test.v
OK    [4/4] C:   593.8 ms, R:    84.440 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/version_test.v
--------------------------------------------------------------------------------
Summary for all V _test.v files: 4 passed, 4 total. Elapsed time: 787 ms, on 4 parallel jobs. Comptime: 2376 ms. Runtime: 335 ms.
```

`C:` es el tiempo de compilación y `R:` el tiempo de ejecución de cada archivo: 0.6 s de compilación para 0.08 s de tests. El resumen cuenta archivos, no tests. El orden de los archivos, los tiempos y las rutas cambian de una ejecución a otra y de un sistema operativo a otro, así que [`check.sh`](https://github.com/spareilleux/learn/blob/f6c34f637df430c031060cb89fb903e7c15be266/code/v-for-csharp-java/check.sh#L99-L108) ordena las líneas `OK` y conserva solo la ruta dentro del proyecto antes de comparar.

Una diferencia más en la CI: cuando la variable de entorno `CI` o `GITHUB_JOB` está definida, `v test` oculta las líneas `OK`, e imprime solo los fallos y el resumen ([`common.v`, líneas 37-43](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/cmd/tools/modules/testing/common.v#L37-L43)). La primera ejecución de la CI de esta lección falló por eso; `VTEST_HIDE_OK=0` las hace volver.

### Cuando un test falla

[`l08-failing/failing_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-failing/failing_test.v) falla de cuatro maneras:

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

`v failing_test.v`, desde su carpeta, ejecuta un solo archivo:

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

El código de salida es 1. Lo que muestra el informe:

- `assert` imprime la expresión y el valor de cada lado, como `Assert.Equal` imprime *Expected* y *Actual*. El `len` entre paréntesis es la longitud del texto impreso, no del array: `[9, 5]` tiene 6 caracteres.
- Un `assert` fallido termina su función de test, como un `Assert` fallido en xUnit o JUnit: `not printed` no se imprime. Los demás tests se siguen ejecutando.
- El mensaje después de la coma es la única forma de saber qué iteración de un bucle falló. V no tiene `[Theory]` ni `@ParameterizedTest`: un bucle sobre los casos con un mensaje hace ese trabajo.
- Un error propagado con `!` hace fallar el test, con la línea de la llamada.
- `@[assert_continues]` informa de cada fallo y continúa, como el `assertAll` de JUnit. `-assert continues` en la línea de comandos lo hace para todas las funciones.

`-stats` enumera cada función de test:

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

(`check.sh` elimina los tiempos, que cambian en cada ejecución.) Dos cosas no cuadran. `test_continues` está `OK`, con `1 assert`, aunque dos de sus tres asserts fallaron: el archivo sigue fallando, pero esta línea lo oculta. Y el resumen cuenta asserts, no tests: `test_message` cuenta como 1 superado y 1 fallido.

`assert` también funciona fuera de los tests, en cualquier función: ahí un fallo es un panic, `V panic: Assertion failed...`. Con `-prod`, los asserts se eliminan, como dice la documentación: en mi máquina, `v -prod run` de un programa cuyo `assert 1 + 1 == 3` falla sin `-prod` imprime la línea siguiente y sale con 0. `Debug.Assert` en C# desaparece de la misma manera de una compilación Release.

## `v fmt`

`v fmt` es el formateador, el equivalente de [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format); Java no tiene ninguno en el JDK. No tiene opciones de estilo: las tabulaciones, los espacios y los saltos de línea son los de V. [`vet/v08_vet.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/vet/v08_vet.v) está mal formateado a propósito:

```v
module main

// Cuenta las referencias de un proyecto
pub fn count(refs []string) int {
    return refs.len
}

fn main() {
	println(count( ['GA.Core','GA.Domain.Core'] ))
}
```

`v fmt -verify` comprueba sin escribir, para la CI, como `dotnet format --verify-no-changes`:

```text
v08_vet.v is not vfmt'ed
Encountered a total of: 1 formatting errors.
```

El código de salida es 1, y el mensaje real empieza por la ruta absoluta del archivo. `v fmt v08_vet.v` imprime el archivo formateado, y `v fmt -w` lo reescribe:

```v
module main

// Cuenta las referencias de un proyecto
pub fn count(refs []string) int {
	return refs.len
}

fn main() {
	println(count(['GA.Core', 'GA.Domain.Core']))
}
```

El `check.sh` del curso ejecuta `v fmt -verify` en todas sus carpetas excepto los snippets rechazados, que `v fmt` comprueba en cuanto a tipos y rechaza ([diario](../journal/)).

## `v vet`

`v vet` señala código sospechoso, un pequeño equivalente de los [analizadores de .NET](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview):

```text
v08_vet.v:4: warning: A function name is missing from the documentation of "pub fn count(refs []string) int".
v08_vet.v:5: error: Looks like you are using spaces for indentation.
Note: You can run `v fmt -w v08_vet.v` to fix these errors automatically
```

El código de salida es 1, por el error; `-W` convierte también las advertencias en errores. La advertencia se refiere al comentario: V espera que la documentación de una función pública empiece por su nombre, `// count devuelve …`, como hace Go. `v fmt -w` corrige la indentación, no el comentario.

## `v doc`

`v doc` genera la documentación de un módulo a partir de los comentarios situados sobre sus declaraciones públicas, como `javadoc` o los [comentarios de documentación XML](https://learn.microsoft.com/dotnet/csharp/language-reference/xmldoc/) de C#, sin etiquetas. [`version.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/version.v) y [`graph.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/graph.v) siguen la regla de `v vet`. Desde `l08-testing`, `v doc -comments deps` imprime:

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

Las funciones privadas, como `parse_release`, se omiten, pero el campo privado `refs` de `Graph` sí se muestra. `-f html` o `-f md` escriben otros formatos.

## Puntos clave

- Un test es una función `test_` en un archivo `_test.v`; `module x` lo hace interno, `import x` externo. `v test .` compila cada archivo como un programa aparte y los ejecuta en paralelo.
- `assert` imprime ambos lados de una comparación fallida, más un mensaje opcional; termina el test salvo con `@[assert_continues]`, y desaparece con `-prod`.
- Las funciones de test pueden devolver `!`; un error esperado se comprueba con `or`.
- `-stats` y los resúmenes cuentan asserts, e informan como `OK` de un test con fallos que continuaron: lee las líneas de fallo, y el código de salida.
- En la CI, `v test` oculta los archivos que pasan salvo con `VTEST_HIDE_OK=0`.
- `v fmt -verify`, `v vet` y `v doc` vienen con el compilador; `v vet` quiere comentarios de documentación que empiecen por el nombre.

## Ejercicios

1. `Graph.reachable` no debe entrar en bucle con un ciclo de referencias. Escribe un test para `A → B → A`: ¿qué debería devolver `reachable('A')`?

<details>
<summary>Solución</summary>

[`l08-testing/deps/s08_cycle_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/s08_cycle_test.v):

```v
// Lección 8, ejercicio 1: un ciclo de referencias
module deps

fn test_cycle() ! {
	g := Graph.parse(['from,to', 'A,B', 'B,A'])!
	assert g.reachable('A') == ['A', 'B']
	assert g.reachable('B') == ['A', 'B']
}
```

`v deps/s08_cycle_test.v` no imprime nada y sale con 0. El conjunto `seen` detiene el recorrido. `A` está en su propio resultado, porque `B` lo referencia: `reachable` devuelve todos los proyectos alcanzados desde `A`, y `A` es uno de ellos. Si eso es correcto es una decisión que el test ahora deja registrada. `v test .` encuentra el archivo junto con los demás: el resumen de arriba tiene 4 archivos.

</details>

2. En `failing_test.v`, `test_message` se detiene en `9.5` y nunca comprueba `1.0.0-beta.1`, que tiene 4 partes una vez dividido por los puntos. ¿Cómo ves ambos fallos sin cambiar el bucle?

<details>
<summary>Solución</summary>

Pon `@[assert_continues]` encima de `fn test_message()`, o ejecuta `v -assert continues failing_test.v` para todas las funciones del archivo. El informe tiene entonces un bloque para `9.5`, con `` Left value (len: 1): `2` ``, y otro para `1.0.0-beta.1`, con `` `4` ``: `'1.0.0-beta.1'.split('.')` da `['1', '0', '0-beta', '1']`. Con `@[assert_continues]`, `-stats` informa entonces de `test_message` como `OK`, igual que `test_continues`.

</details>

3. Corrige `vet/v08_vet.v` para que `v vet` no señale nada.

<details>
<summary>Solución</summary>

`v fmt -w v08_vet.v` corrige la indentación. La advertencia necesita un comentario que empiece por el nombre de la función:

```v
// count devuelve el número de referencias de un proyecto.
pub fn count(refs []string) int {
	return refs.len
}
```

Los archivos de `l08-testing` siguen esa regla: `v vet .` no señala nada ahí.

</details>

## Fuentes

- [Documentación de V — Testing](https://docs.vlang.io/testing.html): [Asserts](https://docs.vlang.io/testing.html#asserts), [Asserts that do not abort your program](https://docs.vlang.io/testing.html#asserts-that-do-not-abort-your-program), [Test files](https://docs.vlang.io/testing.html#test-files), [Running tests](https://docs.vlang.io/testing.html#running-tests); [Tools — v fmt](https://docs.vlang.io/tools.html#v-fmt); [Writing documentation](https://docs.vlang.io/writing-documentation.html); la documentación de 0.5.2: [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- `v help test`, `v help vet`, `v help doc` y `v help fmt`, impresos por V 0.5.2
- [xUnit](https://xunit.net/), [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test), [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format), [Análisis de código en .NET](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview)
- [Guía del usuario de JUnit 5](https://docs.junit.org/current/user-guide/)
