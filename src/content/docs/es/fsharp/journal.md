---
title: Diario
description: Notas de progreso fechadas del curso de F# — el SDK y F# Interactive, cómo funcionan las comprobaciones y lo que las lecciones encontraron en TARS y Guitar Alchemist, con los puntos aún por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Código del curso: scripts, sesiones de F# Interactive, fragmentos rechazados, soluciones de los ejercicios y tres proyectos pequeños, comparados con su salida esperada por `check.sh`
- [ ] CI en Linux, Windows y macOS: el workflow está escrito pero aún no se ha subido (ver más abajo)
- [x] Lección 1: scripts, F# Interactive y proyectos
- [x] Lección 2: valores, funciones e inferencia de tipos
- [x] Lección 3: tuplas, records, uniones y opciones
- [x] Lección 4: coincidencia de patrones
- [x] Lección 5: listas, arrays y secuencias
- [x] Lección 6: módulos, espacios de nombres y organización del proyecto
- [x] Lección 7: errores con `Result`
- [x] Lección 8: expresiones de cómputo aplicadas al parsing de un DSL
- [x] Lección 14: proveedores CSV y JSON con FSharp.Data 8.2.0

## Experimentos

| Pregunta | Hipótesis | Resultado medido | Veredicto | Evidencia |
|---|---|---|---|---|
| ¿Una expresión de cómputo mínima hace legible la gramática de un DSL sin ocultar errores? | `Bind` y `Return` bastan para la gramática secuencial de notas. | Pasan cuatro casos, incluido el rechazo de una letra inválida y de texto sobrante. | Confirmada | [Entrada de 2026-09-20](#2026-09-20--expresiones-de-cómputo-y-proveedores-de-tipos), [`l08_parser_ce.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l08_parser_ce.fsx) |
| ¿FSharp.Data infiere miembros CSV y JSON anidados útiles en .NET 10? | FSharp.Data 8.2.0 expondrá columnas y propiedades tipadas en F# 10. | Dos filas CSV y un documento JSON anidado compilan e imprimen los valores esperados. | Confirmada | [Entrada de 2026-09-20](#2026-09-20--expresiones-de-cómputo-y-proveedores-de-tipos), [`l14_type_providers.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l14_type_providers.fsx) |

## 2026-09-15 — El SDK y F# Interactive

- Mi máquina tiene los SDK de .NET 10.0.112 y 11.0.100-preview.3.26207.106. El [`global.json`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/global.json) del curso fija `10.0.100` con `rollForward: latestFeature`, lo que selecciona 10.0.112: F# Interactive 14.0.112.0 para F# 10.0, y FSharp.Core con la versión de ensamblado 10.0.0.0.
- Los ejemplos son scripts `.fsx` ejecutados con `dotnet fsi`, en lugar de proyectos: un script arranca en unos 2 segundos en mi máquina, no necesita compilación y puede cargar los archivos de GA con `#load` y referenciar FParsec con `#r "nuget: …"`. Solo la lección 1 compila proyectos, tres pequeños, cada uno en unos 2 segundos.
- **Un script se comprueba entero antes de ejecutarse**: en `l01_format_type.fsx`, el `printfn` que está por encima del error no imprime nada.
- **F# Interactive señaló un error por ejecución** en los scripts de este lote: el ejercicio 3 de la lección 2 tiene tres errores independientes y necesita cuatro ejecuciones. No he comprobado si `dotnet build` señala varios a la vez en un proyecto.
- Los mensajes del compilador de un script muestran el nombre del archivo sin su carpeta, incluso cuando el script se ejecuta desde otra carpeta. `dotnet build` muestra la ruta completa, añade ` [project.fsproj]` e imprime cada error dos veces (una cuando ocurre y otra en el resumen): [`check.sh`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/check.sh) conserva las líneas `error FS`/`warning FS`, quita la ruta y el sufijo, y elimina los duplicados. Los mensajes de varias líneas, como el «expected to have type» de FS0001, terminan algunas líneas con espacios, que `check.sh` también quita.
- Una excepción no controlada en un script imprime la pila de llamadas con rutas completas, luego `Stopped due to error`, y `dotnet fsi` sale con el código 1. `check.sh` elimina las líneas `   at …`.
- Las sesiones de F# Interactive se comprueban enviando un archivo a `dotnet fsi --nologo`: la salida contiene los indicadores `>` y las respuestas, sin las líneas escritas. Las lecciones muestran la entrada junto a las respuestas, como las ve una persona.
- Una igualdad usada como instrucción (`strings = 7`) recibe la advertencia FS0020 dentro de una función, pero ninguna advertencia en el nivel superior de un script: lo probé fuera del código del curso, y la lección 2 solo muestra la función.
- La indentación con una tabulación se rechaza: `error FS1161: TABs are not allowed in F# code unless the #indent "off" option is used` (probado fuera del código del curso).
- Una comprobación en C# detrás de la lección 4, compilada aparte con el SDK 10.0.112: ver [2026-09-15 — Comparaciones con C#](#2026-09-15--comparaciones-con-c).

## 2026-09-15 — CI

- El workflow `.github/workflows/fsharp-examples.yml` ejecuta `check.sh` en `ubuntu-latest`, `windows-latest` y `macos-latest`, como los demás cursos. No se ha subido: el token con el que se sube este repositorio no puede crear archivos de workflow (le falta el ámbito `workflow`). Mientras tanto, las salidas solo se han comprobado en Windows, y todo lo específico de Linux y macOS está marcado *por verificar*.
- Dos salidas contienen caracteres no ASCII: `EbΔ9` y las comillas `‘…’` de FParsec en `l04_ga_parse`. Son correctos en Git Bash en mi máquina; el runner de Windows podría imprimirlos con otra codificación (*por verificar*).

## 2026-09-15 — Dogfooding: TARS

TARS en el commit [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24).

- **Lo que está activo.** El README dice que todo el desarrollo activo está en `v2/`. El workflow de CI [`dotnet.yml`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/.github/workflows/dotnet.yml#L19-L30) restaura, compila y prueba solo `v2`, y `v2/Tars.sln` contiene 17 proyectos bajo `v2/src` y un proyecto de pruebas. El nivel superior del repositorio conserva decenas de carpetas más antiguas (`TarsEngine.FSharp.*`, `backup_fake_elimination_*`…) que ningún workflow compila: las lecciones no las citan.
- **Nueve archivos `.fs` que nada compila.** El propio `v2/src` contiene `Fibonacci.fs`, `FSharp.ReverseList.fs`, `LintRunner.fs`, `Main.fs`, `OllamaClient.fs`, `PalindromeChecker.fs`, `Program.fs`, `StaticAnalysisRunner.fs` y `ToolFactory.fs`. Ningún `.fsproj` los lista (los proyectos con los mismos nombres de archivo listan sus propias copias, como `Tars.Llm/OllamaClient.fs`), y dos de ellos están casi vacíos (95 y 3 bytes). `v2/src/Tars.LSP` tiene un proyecto, `Tars.LSP.fsproj`, que `Tars.sln` no incluye, así que la CI tampoco lo compila. La lección 1 lo usa para mostrar que un proyecto F# solo compila los archivos que lista.
- **Sin archivo de licencia.** El README muestra una insignia «License: MIT» que enlaza a `./LICENSE`, pero el repositorio no tiene archivo `LICENSE` en este commit, así que el enlace está roto. El curso enlaza y cita el código de TARS pero no copia sus archivos; `examples/l02_tars_normalize.fsx` vuelve a escribir una función de ocho líneas para ejecutarla.
- **Casos de unión que ocultan `Result`.** [`Domain.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Domain.fs#L62-L78) declara `PartialFailure.Error` y `ExecutionOutcome.Failure` sin `[<RequireQualifiedAccess>]`. Cada archivo compilado después que quiere decir `Result.Error` debe calificarlo: `v2/src` tiene 342 apariciones de `Result.Error`, y `ArcTypes.fs` escribe `FSharp.Core.Result.Error`. Los archivos compilados antes, como `Budget.fs`, escriben un simple `Error`. Añadir el atributo rompería código dentro de TARS (cada `Warning`, `Error`, `Success`, `Failure` de estas uniones necesitaría el nombre de su tipo). Reproducido en `compile_fail/l03_case_shadowing.fsx`; se muestra en la lección 3.
- **`TextNormalizer.normalize` solo conserva ASCII.** La expresión regular `[^a-z0-9\s]` de [`TextNormalizer.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L51-L58) elimina `#` (`"learn F#"` da las palabras clave `learn` y `f`) y todas las letras acentuadas (`café` da `caf`). Sus pruebas solo usan frases en inglés, y no encontré ningún llamador en `v2/src` aparte de sus pruebas (`grep` en este commit). Se muestra en la lección 2.
- Para la lección 16: `BudgetGovernor` en [`Budget.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Budget.fs#L133-L150) se declara seguro para hilos y lee su `mutable consumed` con un bloqueo en `Remaining`, pero su propiedad `Consumed` devuelve el campo sin el bloqueo.

## 2026-09-15 — Dogfooding: Guitar Alchemist

GA en el commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381). Seis archivos están copiados en [`code/fsharp/external/ga`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/external/ga), sin cambios salvo sus finales de línea.

- **`ChordParser.parse` descarta el final de la entrada.** `pChord` no va seguido de `eof`, así que el parser se detiene en el primer carácter que no reconoce y devuelve `Ok` con lo que ha leído: `C7sus4` se normaliza a `C7`, y `Am(maj7)` a `Am` (`examples/l04_ga_parse.fsx`, lección 4). `ChordDslService.Parse` y `Normalize` lo heredan, y el `ResponseValidator` en C# del chatbot, que solo comprueba si `Parse` tuvo éxito, acepta cualquier palabra que empiece como un acorde y coincida con su expresión regular. Un posible arreglo es `run (pChord .>> eof) chordStr`, añadiendo `C7sus4` y `Am(maj7)` a [`ChordDslTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs#L11-L18); un `sus4` real después de una extensión necesitaría entonces también una regla del parser.
- **`HarmonicTransformationService.GetNormalForm` depende de la transposición.** Para el conjunto `{0, 4, 7, 8}` devuelve `[0; 4; 7; 8]`, y para el mismo conjunto transpuesto 8 semitonos devuelve `[0; 3; 4; 8]`: dos rotaciones tienen la misma extensión, y `List.minBy fst` se queda con la primera en lugar de comparar los intervalos interiores como hace el orden normal (`examples/l02_ga_transformations.fsx`, lección 2). La búsqueda de código de GitHub no encontró ningún llamador de `GetNormalForm` en GA el 2026-09-15, y el `HarmonicTransformationTests.cs` de GA no la prueba. En el mismo archivo, `Invert` y `ApplyNegativeHarmony` calculan la misma fórmula (`2 * axis - pc` y `sumAxis - pc`), y el comentario de `ApplyNegativeHarmony` todavía pregunta «axis = 3.5 semitones?».
- **`Scripts/BinObj.fsx` selecciona de más y no ejecuta nada.** `isObjOrBinFolder` comprueba si una ruta completa *termina en* `bin` u `obj`, sin distinguir mayúsculas, así que se seleccionan carpetas llamadas `cabin` o `Robin`, y sus subcarpetas no se visitan. El script define sus funciones y nunca las llama (`examples/l04_ga_binobj.fsx`, lección 4).
- **`Scripts/ModesConfig.fsx` no se ejecuta.** Ejecutado tal cual con `dotnet fsi` desde la carpeta `Scripts`, se detiene en la línea 21 con dos `error FS3373: Invalid interpolated string` (en las columnas 57 y 59): un literal de cadena `", "` dentro de una interpolación `$"…"`. Con una cadena entre comillas triples, la misma línea recibe `FS0039: The value, constructor, namespace or type 'Join' is not defined`, ya que el script no tiene `open System` (reproducido en el ejercicio 2 de la lección 1). Además, `#r "nuget: GA.Business.Config, 1.0.0"` nombra un paquete que nuget.org no tiene (su índice de paquetes respondió `BlobNotFound` el 2026-09-15), y `#I` añade una carpeta donde buscar ensamblados, no un origen de paquetes. Existe otro `ModesConfig.fsx` en la raíz del repositorio.
- **Dos árboles para un acorde.** `ChordAst` puede escribir `Bbmaj7` como `Quality = None` con `Extension "maj7"` (lo que produce el parser) o como `Quality = Some Major` con `Extension "7"`; ambos se renderizan con el mismo texto y se comparan como distintos (ejercicio 3 de la lección 3).

## 2026-09-15 — Comparaciones con C#

La lección 4 compara la comprobación de exhaustividad de F# con la de C#. Los dos archivos C# de abajo se compilaron aparte con `dotnet run` y el SDK 10.0.112, no en la CI del curso:

- Una jerarquía de records `abstract record Fingering` con tres subclases `sealed`, y una expresión `switch` con un brazo por subclase:

  ```text
  hierarchy.cs(3,42): warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern '_' is not covered.
  ```

- Un `enum Accidental { Natural, Sharp, Flat }` y una expresión `switch` con un brazo por valor con nombre:

  ```text
  enumswitch.cs(3,41): warning CS8524: The switch expression does not handle some values of its input type (it is not exhaustive) involving an unnamed enum value. For example, the pattern '(Accidental)3' is not covered.
  ```

Los dos programas se ejecutaron igualmente e imprimieron su resultado.

## 2026-09-20 — Colecciones, módulos y `Result`

- Se añadió la lección 5 con comparaciones ejecutables entre las transformaciones inmediatas de `List` y `Array` y un pipeline `Seq` perezoso.
- Se añadió la lección 6 con módulos anidados, visibilidad explícita y un ejemplo pequeño de organización que mantiene estrecha la superficie pública.
- Se añadió la lección 7 con un pipeline de validación basado en `Result`, composición explícita de errores y la frontera entre fallos esperados y excepciones.
- `dotnet fsi` reprodujo las salidas guardadas para `l05_collections.fsx`, `l06_modules.fsx` y `l07_result.fsx` con el SDK .NET 10.0.112.

## 2026-09-20 — Expresiones de cómputo y proveedores de tipos

- Se añadió la lección 8 en torno a un builder real `Parser<'T>`. El harness ejecuta casos de éxito, token inválido y texto sobrante; este último mantiene explícito el invariante de final de entrada.
- Se añadió la lección 14 con FSharp.Data 8.2.0, fijado desde NuGet. Las muestras CSV y JSON son strings locales, por lo que el tipado no depende de un esquema remoto.
- `dotnet fsi` produjo las salidas guardadas en `expected/l08_parser_ce.txt` y `expected/l14_type_providers.txt` con el SDK .NET 10.0.112.

## Por verificar

- Todo el curso en Linux y macOS, y en el runner de Windows, una vez subido el workflow.
- Las carpetas de salida de la compilación de la lección 1 en Linux y macOS (ejecutable `Hello`, carpetas de recursos).
- <kbd>Alt</kbd>+<kbd>Enter</kbd> para enviar código a F# Interactive en VS Code con Ionide, Rider y Visual Studio.
- Si `dotnet build` señala en una sola ejecución varios errores independientes de un mismo archivo, donde F# Interactive señaló uno.
