---
title: Diario
description: Notas de progreso fechadas del curso de V — la instalación de V 0.5.2, la CI en tres SO, sorpresas en el compilador y la documentación, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] V 0.5.2 instalado en Windows, y en CI en Linux, Windows y macOS
- [x] CI: ejemplos, snippets rechazados y panics comparados con su salida esperada en tres SO
- [x] Lección 1: instalación, `v run`, módulos y proyectos
- [x] Lección 2: tipos, variables inmutables, structs y métodos
- [x] Lección 3: errores, `?`, `!` y `or { }`
- [x] Lección 4: arrays, maps, slices y memoria
- [x] Lección 5: interfaces y genéricos
- [x] Lección 6: enums, tipos suma y `match`
- [x] Lección 7: concurrencia, `spawn`, canales y `shared`
- [x] Lección 8: pruebas, `v fmt`, `v vet` y `v doc`
- [ ] Lección 9: llamar a C

## 2026-09-14 — Instalación de V 0.5.2

- [0.5.2](https://github.com/vlang/v/releases/tag/0.5.2) es la última versión, publicada el 2026-07-12; su etiqueta apunta al commit [`7647ce1`](https://github.com/vlang/v/commit/7647ce1c6fad63b5578bc07883139906de74b2f8). La última versión semanal es `weekly.2026.08`, de febrero.
- Windows: `v_windows.zip` pesa 23,745,972 bytes. Lo descomprimí en `C:\Users\spare\tools\v-0.5.2`, fuera del `PATH`. `v version` imprime `V 0.5.2 7647ce1`; `v doctor` imprime `V 0.5.2 45ae01d23168b6372f734eeb38a77360bbcf184a.7647ce1`. También probé los comandos de la lección 1 en una carpeta de pruebas: `Invoke-WebRequest` descargó el archivo en 3 s, `Expand-Archive` tardó 53 s en descomprimirlo.
- Los tres archivos (`v_windows.zip`, `v_linux.zip`, `v_macos_arm64.zip`) contienen todos TCC como `thirdparty/tcc/tcc.exe`, con el `.exe` también en Linux y macOS, y conservan los bits de ejecución de `v` y de `tcc.exe`.
- El primer `v run hello.v` compiló y se ejecutó en 1.6 s, con TCC y sin ningún otro compilador C instalado.
- [docs.vlang.io](https://docs.vlang.io/introduction.html) sigue `master`, no la versión publicada. Su página [The default compiler](https://docs.vlang.io/the-default-compiler.html) no está en el [`docs.md` de la 0.5.2](https://github.com/vlang/v/blob/0.5.2/doc/docs.md), y ni siquiera coincide con `master`: la página web (generada desde el commit `5db92f0`) dice que el ejecutable `v` "contains only the experimental V3 C compiler", mientras que [`doc/docs.md` en `master`](https://github.com/vlang/v/blob/master/doc/docs.md) dice ahora que "contains the default compiler whose source lives in `vlib/v`". Las lecciones comprueban cada comportamiento con la propia 0.5.2.

## 2026-09-14 — La CI

- [`v-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/v-examples.yml) descarga el archivo de la versión de cada SO, añade su carpeta a `GITHUB_PATH`, y ejecuta [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/check.sh). El primer push pasó en los tres SO: las salidas y los mensajes del compilador capturados en Windows son idénticos en Linux y macOS.
- `check.sh` compara la salida estándar *y* la salida de error estándar de cada ejemplo, así que una nueva advertencia o un nuevo aviso hace fallar el job. Los snippets rechazados se compilan desde su carpeta, así que los mensajes muestran `e02_immutable.v:3:2` en lugar de una ruta que variaría entre SO.
- Un panic imprime su mensaje, luego `v hash`, los identificadores del proceso y del hilo, y un backtrace cuyas líneas dependen del SO y del compilador C. `check.sh` compara la primera línea y el código de salida, 1 en los tres SO.
- `v fmt -verify` falla con los snippets rechazados, porque comprueba sus tipos: `check.sh` formatea todas las carpetas salvo `compile_fail`.
- Compiladores C, según `v -showcc` en la CI: TCC para las compilaciones de desarrollo en Windows y Linux; `cc` (Apple clang 21) para las compilaciones de desarrollo en macOS, aunque `v doctor` también lista TCC allí; `gcc` (MinGW 15.2) para `-prod` en el runner Windows, `cc` (gcc 13.3) en Linux, `cc` en macOS.
- En mi máquina, `v doctor` dice `msvc version N/A`, y sin embargo `v -showcc -prod` compila con el `cl.exe` de las Visual Studio 2022 Build Tools.

## 2026-09-14 — Sorpresas al escribir las lecciones 1-4

**`v new` sin entrada escribe `<EOF>` en `v.mod`.** Con la entrada estándar cerrada (`v new hello < /dev/null`), `v new` no se detiene y escribe `description: '<EOF>'`, `version: '<EOF>'` y `license: '<EOF>'`. [`os.input`](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/os/os.v#L436-L441) devuelve `'<EOF>'` al final de la entrada, y [`vcreate.v`](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/cmd/tools/vcreate/vcreate.v#L170-L181) solo sustituye una cadena vacía por el valor por defecto. La CI le pasa tres respuestas por una tubería.

**`-autofree` desactiva el recolector de basura.** La documentación dice que autofree libera la mayoría de los objetos y que "the remaining small percentage of objects is freed via GC". En la 0.5.2, [`pref.v`, líneas 807-811](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/pref.v#L807-L811) fija `gc_mode = .no_gc` para `-autofree`, y `gc_is_enabled()` devuelve `false` en el ejemplo de la lección 4. Lo que autofree no libera se pierde en fugas.

**`-prod` con MSVC desactiva el recolector de basura.** [`default.v`, líneas 369-381](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/default.v#L369-L381) cambia a `no_gc` cuando el compilador C es MSVC en Windows y no se da ninguna opción `-gc`. En mi máquina, `v -prod run examples/l04_memory.v` imprime `GC enabled: false` y llega a 542 MB después de 50 rondas, frente a 20 MB con `v run`; `v -prod -gc boehm run` se queda en 30 MB. El runner Windows usa `gcc` para `-prod`, y no lo muestra. No he encontrado esta regla en la documentación.

**Un array entero se comparte, un slice se clona.** `alias := original` comparte la memoria de un array `mut` sin ningún aviso, hasta que `original` crece más allá de su capacidad; `first := lines[..2]` sobre el mismo array se clona, con un aviso. El checker solo busca los slices ([`assign.v`, líneas 845-855](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/assign.v#L845-L855)). La lección 4 muestra ambos casos.

**Dos funciones con el mismo nombre: el error depende de la llamada.** Con `fn describe(lines int)` y `fn describe(title string)`, llamar a `describe('Mission')` da `builder error: redefinition of function describe`, el error de la lección 2. Llamar en cambio a `describe(474)` solo da `cannot use int literal as string in argument 1 to describe`: el checker informa del error de tipo, y la compilación se detiene antes de informar del duplicado.

**El tipo de `7.0 / 2` es `float literal`.** La documentación dice que un literal de coma flotante se convierte en `f64` cuando hay que decidir su tipo. Y sin embargo:

```v
y := 7.0 / 2
println(typeof(y).name) // float literal
z := 3.5
println(typeof(z).name) // f64
```

La expresión conserva el tipo del literal, que nombra [`types.v`, línea 1278](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/ast/types.v#L1278). `println(y)` sigue imprimiendo `3.5`.

**Un error convertido por *smart cast* se interpola como un struct.** Después de `if err is ParseError`, `${err}` imprime el struct entero en lugar de `msg()`:

```text
line_no 7
interpolated: &ParseError{
    Error: Error{}
    line_no: 7
}
```

Sin la conversión, `${err}` sobre un `IError` imprime el mensaje, y `error_with_code('negative', 99)` imprime `negative; code: 99`. La lección 3 llama a `err.msg()` explícitamente.

**Un tipo de error privado se puede comprobar desde otro módulo.** `csv.EndOfFileError` no tiene `pub` ([`reader.v`, líneas 25-31](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/encoding/csv/reader.v#L25-L31)), y sin embargo `err is csv.EndOfFileError` compila en `module main`.

**Un option se puede almacenar sin desenvolverlo.** `z := find_course('java')` compila, y `println(z)` imprime `Option(none)`. El compilador solo se queja cuando `z` se usa como un `string`, como en el `name.to_upper()` de la lección 3.

**`main` no puede devolver un error.** `return err` en un bloque `or` de `main` da `unexpected argument, current function does not return anything`; el ejemplo de la lección 3 usa `panic(err)`.

**De cadena a número nunca falla.** `'12abc'.int()` vale 12, `'abc'.int()` vale 0, `'99999999999'.int()` vale 2147483647. `strconv.atoi` informa de los tres casos.

**Una expresión de ordenación no ve las variables locales.** `courses.sort(lines[a] > lines[b])` da cuatro errores, empezando por `can not access external variable lines`; el tercero y el cuarto revelan que `a` y `b` son `&string`.

**Un error, dos mensajes de error.** Un error de tipo dentro de `println(…)` va seguido de `println can not print void expressions` en la misma línea (lecciones 2 y 3).

**El analizador CSV ingenuo falla en 50 líneas.** `pages.csv` pone entre comillas los títulos que contienen comas: `line.split(',')` da 6 campos en 50 de las 319 líneas. Un script `awk` sobre el mismo archivo coincide con los recuentos de la lección 4: 117 páginas en inglés, 101 en francés y 101 en español, y las líneas en inglés por curso.

## 2026-09-14 — Lecciones 5-8: el plan y los datos

- La lección 8 era «pruebas, `v fmt`, `v vet`, documentación y paquetes». Las pruebas, las tres herramientas y sus rarezas en CI llenaron una lección; los paquetes (`v install`, `vpm`) pasan a la lección 12, junto a la compilación cruzada y el despliegue.
- Las lecciones 5 a 8 usan los proyectos .NET de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en el commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893), copiados del curso de LadybugDB en [`data/ga`](https://github.com/spareilleux/learn/tree/main/code/v-for-csharp-java/data/ga). Ningún campo contiene una coma, así que `split(',')` basta.
- [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/check.sh) imprime ahora sin compararlas las líneas de un ejemplo que empiezan por `# `, como hace el curso de LadybugDB en su lección 8: tiempos, número de CPU, el resultado de una carrera de datos (data race). Los runners de CI indican 4 CPU lógicas en Linux y Windows, 3 en macOS.
- El primer push del código de la lección 8 falló en los tres SO, por la misma razón: `v test` oculta las líneas `OK` en CI (ver más abajo).

## 2026-09-14 — Lo que muestran los datos de ga

Son observaciones sobre ga en `a26a7893`, para que las valoren sus mantenedores; no se ha informado de nada al proyecto.

- **Dos versiones flotantes.** `Apps/demerzel-bridge/DemerzelBridge/DemerzelBridge.csproj` referencia `ModelContextProtocol` en la versión `0.*`, y `Experiments/React/ReactApp1.Server/ReactApp1.Server.csproj` referencia `Microsoft.AspNetCore.SpaProxy` en la versión `8.*-*`, versiones preliminares incluidas. Sin un archivo de bloqueo de NuGet, dos restauraciones del mismo commit pueden elegir paquetes distintos (lección 6).
- **Una versión de cuatro partes.** `GaCLI/GaCLI.csproj` referencia `Microsoft.KernelMemory.Core` `0.91.241101.1`: válida para NuGet, pero la única de las 478 versiones que no es `major.minor.patch` con una etiqueta opcional.
- **Dos pares de nombres parecidos.** Dos proyectos se llaman `GaApi.Tests` (`Tests/Apps/GaApi.Tests` y `Tests/GaApi.Tests`, el curso de LadybugDB también los encontró), y dos solo difieren en mayúsculas y minúsculas: `GaCLI/GaCLI.csproj` (C#, fuera de la solución) y `Apps/GaCli/GaCli.fsproj` (F#). Un map indexado por nombre, como en la lección 5, pierde un `GaApi.Tests`; con una clave que no distinga mayúsculas de minúsculas, también fusionaría las dos CLI.
- **Seis proyectos web fuera de la solución.** `FloorManager`, `GA.DocumentProcessing.Service`, `ScenesService`, `GA.Business.AI`, `FretboardExplorer` y `GA.WebBlazorApp` usan `Microsoft.NET.Sdk.Web` y no aparecen en `AllProjects.slnx` (lección 6). `GA.Business.AI` sigue estando referenciado por proyectos de la solución.

## 2026-09-14 — Sorpresas al escribir las lecciones 5-8

**V envía por defecto los errores del compilador C a un servidor.** Mientras escribía la lección 7, un programa se topó con el bug del compilador descrito más abajo, y V imprimió `Sent C compiler bug report to https://bugs.vlang.io/bug-report.`, con un identificador de informe y un comando `curl -X DELETE`. El informe contiene el C generado que falla y las líneas del código V, con rutas de mi máquina. [`c_error_report.v`, líneas 485-506](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/builder/c_error_report.v#L485-L506) lo envía salvo que `V_C_ERROR_BUG_REPORT_DISABLED` esté definida, y lo omite en la CI de GitHub. La única mención que encontré está en `v help build-c`, no en el `docs.md` de la 0.5.2. El `check.sh` del curso define la variable, y también mis ejecuciones locales desde entonces.

**Una función anónima con `return` dentro de `lock` genera C inválido.** V 0.5.2 acepta:

```v
shared usage := Usage{}
rlock usage {
	count := fn () int {
		return 1
	}
	println(count())
}
```

y luego TCC falla con `'usage' undeclared`: el C generado de la función anónima contiene `sync__RwMutex_runlock(&usage->mtx);return _t1;`, el desbloqueo del bloque que la contiene. También ocurre con `lock`, capture o no `usage`. [`compiler_bugs/b07_return_in_lock.v`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/compiler_bugs/b07_return_in_lock.v) se comprueba en CI, así que el curso se dará cuenta cuando una versión lo corrija. No lo he buscado en las issues de V, ni lo he notificado.

**Un método de interfaz `mut:` acepta un receptor inmutable.** La documentación dice que con `fn (s MyStruct) write(a string) string`, `MyStruct` "implements the interface Foo, but *not* interface Bar", donde `Bar` declara `write` bajo `mut:`. El propio ejemplo de la documentación, con `fn fn2(mut s Bar)` descomentado y llamado con `fn2(mut s2)`, compila e imprime `Bar`. [`table.v`, líneas 280-294](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/ast/table.v#L280-L294) solo rechaza el caso inverso, un receptor `mut` para un método de interfaz inmutable. El `Tally.total()` de la lección 5 se apoya en ello.

**Un campo que solo tiene una variante es un `as` implícito.** Sobre `type Version = Floating | Release`, `v.parts` compila aunque solo `Release` tiene `parts`, y provoca un panic con `as cast: cannot cast main.Floating to main.Release` cuando `v` contiene un `Floating`. [`checker.v`, líneas 3180-3201](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/checker.v#L3180-L3201) reescribe el acceso al campo como un `AsCast`. La CI lo comprueba con `panics/p06_variant_field.v`.

**El *smart cast* de un tipo suma `mut` no necesita `mut`.** La documentación dice que para una variable mutable se requiere `if mut w is Mars`, "otherwise `w` would keep its original type". Con `mut v := Version(Release{[9, 5, 1]})`, `if v is Release { println(v.major()) }`, donde `major` es un método solo de `Release`, compila e imprime `9`. No he buscado el caso contra el que protege la regla.

**El error de una función genérica no nombra la llamada.** Con `largest[T]` llamada sobre un struct sin `<`, el único error es `cannot use > as <= operator method is not defined`, sobre el `>` dentro de la función genérica ([`infix.v`, líneas 831-833](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/infix.v#L831-L833)): no aparecen ni el tipo ni la línea de la llamada, y `<`, el método que hay que definir, no se nombra.

**`go` es `spawn`.** La documentación presenta `go` como un hilo ligero gestionado por el runtime de V. Sin `-use-coroutines`, el parser produce un `spawn` ([`parser.v`, líneas 1391-1405](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/parser/parser.v#L1391-L1405)); incluso con esa opción, un `go` cuyo handle se usa vuelve a un hilo ([`spawn_and_go.v`, líneas 20-30](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/gen/c/spawn_and_go.v#L20-L30)).

**Un canal cerrado no provoca un panic.** La documentación dice que enviar a un canal cerrado provoca un panic en tiempo de ejecución. `ch <- x` sobre un canal cerrado no hace nada: el `pushval` generado llama a `try_push_priv` e ignora el `.closed` que devuelve, y `popval` devuelve un valor cero sobre un canal cerrado y vacío ([`cgen.v`, líneas 2492-2501](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/gen/c/cgen.v#L2492-L2501)). Con `or`, ambas operaciones informan de `channel closed`. La lección 7 muestra los cuatro casos.

**`fn [mut x]` modifica una copia.** Una closure lanzada con `spawn fn [mut total] (n int) { total += n }(i)` en un bucle compila, deja `total` a 0 en `main`, y la única pista es `warning: unused variable: total` sobre la lista de captura.

**Un map escrito por varios hilos se estrella.** El ejercicio 3 de la lección 7, el recuento de paquetes con una referencia `mut` en lugar de `shared`: en 20 ejecuciones, 8 resultados erróneos, 4 panics `array.get: index out of range`, 8 `Unhandled Exception`. El compilador lo acepta, como lo harían C# y Java.

**`v test` oculta los archivos que pasan en CI.** Cuando `CI` o `GITHUB_JOB` están definidas, [`common.v`, líneas 37-43](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/cmd/tools/modules/testing/common.v#L37-L43) oculta las líneas `OK` salvo que `VTEST_HIDE_OK=0`. La primera ejecución de CI de la lección 8 falló en los tres SO por ese motivo.

**Los números de un informe de pruebas.** `Left value (len: 6): [9, 5]` da la longitud del texto impreso, no la del array. Con `-stats`, una función marcada con `@[assert_continues]` cuyos asserts fallaron aparece como `OK` con `1 assert`, y el resumen `3 failed, 3 passed, 6 total` cuenta asserts, no funciones de prueba. El código de salida es correcto: 1.

**`v doc` muestra un campo privado.** `v doc -comments deps` omite las funciones privadas, pero imprime `struct Graph` con su campo privado `mut: refs`.

**Aritmética de enums, dos mensajes.** `sdk < Sdk.web` da `only == and != are defined on enum, use an explicit cast to int if needed`; `sdk + 1` da `infix expr: cannot use int literal (right expression) as Sdk`, que no dice que se rechaza `+`.

## Por verificar

- `v symlink` en Windows, y si modifica el `PATH` del usuario.
- Una distribución Linux mínima sin las cabeceras C: ¿encuentra TCC lo que necesita?
- macOS: el atributo de cuarentena en un archivo descargado con un navegador, y las compilaciones de desarrollo con TCC en lugar de `cc`.
- `v -prod -cc gcc` en una máquina Windows que tenga a la vez MSVC y MinGW.
- [`.vvmrc`](https://docs.vlang.io/project-local-compiler-versions-with-.vvmrc.html), que fija la versión del compilador de un proyecto como `global.json`: documentado en el `docs.md` de la 0.5.2, aún no probado.
- `go` con `-use-coroutines`: qué SO lo admiten en la 0.5.2, y si una instrucción `go` evita entonces realmente un hilo del SO.
- La carrera de datos sobre el map del ejercicio 3 de la lección 7 en Linux y macOS, donde solo ejecuté la carrera del contador (en CI).
- Si el gestor de issues de V ya conoce el bug del `return` dentro de `lock`, y el del canal cerrado que no provoca un panic.
