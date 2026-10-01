---
title: Diario
description: Notas de progreso fechadas del curso C# para principiantes — el SDK y las aplicaciones basadas en archivos, las comprobaciones en tres sistemas operativos, las sorpresas encontradas al escribir los ejemplos y los puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Código del curso: aplicaciones basadas en archivos, fragmentos rechazados y soluciones de ejercicios, comparados con su salida esperada por `check.sh`
- [x] CI en Linux, Windows y macOS
- [x] Lección 1: instalar .NET y ejecutar tu primer programa
- [x] Lección 2: variables, tipos y entrada
- [x] Lección 3: condiciones y bucles
- [x] Lección 4: métodos, arrays y listas
- [x] Lección 5: clases y objetos
- [x] Lección 6: records, structs y enums

## 2026-09-14 — El SDK y las aplicaciones basadas en archivos

- Mi máquina tiene dos SDK: 10.0.112 y 11.0.100-preview.3.26207.106. Sin un [`global.json`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/global.json), `dotnet` elige la preview. La carpeta del curso fija `10.0.100` con `rollForward: latestFeature`, lo que selecciona 10.0.112 aquí.
- WinGet ofrece `Microsoft.DotNet.SDK.10` en la versión 10.0.401 ese mismo día: una banda de características más reciente que la mía. La [página de aplicaciones basadas en archivos](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps) indica que `#:include` está disponible desde el SDK 10.0.300, así que la lección 1 dice que una aplicación basada en archivos es un solo archivo por defecto, y que `#:include` añade otros a partir de ese SDK. No he probado `#:include`: mi SDK es anterior.
- Los ejemplos son aplicaciones basadas en archivos en lugar de un proyecto por lección: un principiante escribe un archivo y lo ejecuta, sin nada que configurar. Un único `dotnet run app.cs` tardó 0.9 s la primera vez y 0.2 s la siguiente.
- Los demás archivos `.cs` de la misma carpeta no se compilan con la aplicación: `hello.cs` se ejecutó sin problemas junto a un archivo lleno de errores.
- **Las advertencias solo se imprimen cuando el SDK compila.** Un segundo `dotnet run` de un archivo sin cambios no imprime ninguna advertencia, y `dotnet run --no-cache` tampoco ayuda: se salta la comprobación de actualización de la aplicación basada en archivos, pero MSBuild sigue viendo la salida compilada al día y se salta el compilador. `dotnet clean app.cs` antes de cada ejecución devuelve las advertencias; [`check.sh`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/check.sh#L25-L50) lo hace, y la lección 3 se lo cuenta al lector.
- Los errores del compilador van a la salida estándar, con la ruta completa del archivo; `The build failed. Fix the build errors and run again.` va a la salida de error. `check.sh` junta ambas y conserva solo el nombre del archivo, para que los archivos esperados sean iguales en todas las máquinas.
- Los errores de sintaxis ocultan los demás: en el programa roto del ejercicio 2 de la lección 1, el `Writeline` mal escrito (CS0117) solo se señala una vez corregidos el `;` y las comillas que faltan. El ejercicio se basa en eso.
- Entrada estándar: cuando la entrada viene de un archivo, el texto tecleado no aparece en la salida, así que los archivos esperados contienen las preguntas seguidas directamente de las respuestas. Las lecciones muestran la terminal tal como la ve una persona, con las líneas tecleadas, y lo dicen.
- Cultura: la cultura de mi Windows es `en-CA`. Con `es-ES`, `double.TryParse("1.5")` devuelve `true` y 15, ya que el punto es el separador de miles en español; con `fr-FR`, devuelve `false`. El ejemplo fija cada cultura explícitamente, así que la salida es la misma en todos los sistemas operativos. Los demás ejemplos solo usan formatos que se imprimen igual en `en-CA`, `en-US` y la cultura invariable del runner Linux.

## 2026-09-14 — CI

- Commit [`b19a296`](https://github.com/spareilleux/learn/commit/b19a296), ejecución [34914488934](https://github.com/spareilleux/learn/actions/runs/34914488934): en verde en los tres sistemas operativos. `actions/setup-dotnet` con el `global.json` del curso instaló el SDK **10.0.401** en los tres runners, mientras que las salidas se capturaron con 10.0.112: todos los mensajes del compilador son idénticos. Los jobs tardaron 54 s en Linux, 1 min 36 s en macOS y 2 min 18 s en Windows, con un `dotnet clean` y una compilación para cada una de las 58 aplicaciones basadas en archivos.
- `Math.Pow(2, 7 / 12.0)` impreso con todos sus dígitos, `164.81377845643496`, es igual en los tres sistemas operativos.
- La línea shebang `#!/usr/bin/env -S dotnet --` funciona en los runners Linux y macOS después de `chmod +x`, y `dotnet run` la ignora en Windows.
- Los códigos de salida de una excepción no controlada difieren, así que `check.sh` los imprime y solo compara `exit crash`:
  - Linux y macOS: 134 (el proceso aborta, `SIGABRT`) para los tres ejemplos que fallan;
  - Windows, visto desde Git Bash: 127 para `IndexOutOfRangeException` y `SwitchExpressionException`, y 139 con un mensaje «Segmentation fault» para `NullReferenceException`;
  - Windows, visto desde PowerShell: `0xE0434352` (-532462766), el código de una excepción .NET, para `IndexOutOfRangeException`, pero `0xC0000005` (-1073741819), una violación de acceso, para `NullReferenceException`.

## 2026-09-14 — Dogfooding

- Los ejemplos usan Guitar Alchemist como datos pequeños: la afinación estándar de [`Tuning.Default`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L23) en el commit `a826864`, y doce nombres de proyectos de `code/ladybugdb/data/ga/projects.csv`, extraídos en el commit `a26a7893`. Nada en estas lecciones reveló un problema en GA.

## 2026-09-29 — Clases y objetos

- La lección 5 presenta la construcción, la identidad de las instancias, los campos privados, las propiedades públicas, los métodos y un contador `static` compartido; después propone crear una clase `PracticeSession`. Las páginas inglesa, francesa y española comparten los mismos fragmentos C# probados y las mismas salidas del compilador.
- En Windows, con el SDK 10.0.112, `C:/Program Files/Git/bin/bash.exe check.sh` pasó para los ejemplos, soluciones y fragmentos rechazados del curso, incluidos los nuevos archivos `l05_*`. Los dos nuevos fragmentos rechazados produjeron CS0122 y CS0200, respectivamente. El `bash` predeterminado del equipo era WSL y no encontraba el `dotnet` de Windows: aquel primer fallo era del entorno de pruebas, no del código.
- Este resultado local no sustituye una nueva CI en tres sistemas ni demuestra que la lección esté publicada. Las lecciones 6–12 siguen solo en el plan.

## 2026-09-30 — La lección 5 en la CI de tres sistemas

- La [ejecución 36664604662](https://github.com/spareilleux/learn/actions/runs/36664604662) del workflow *C# for beginners examples*, sobre el commit `669d42a` de la [PR #60](https://github.com/spareilleux/learn/pull/60), pasó en `ubuntu-latest`, `windows-latest` y `macos-latest`. En la salida de cada job, `check.sh` imprime `ok` para `l05_objects`, `l05_ex_practice`, `l05_get_only_property` y `l05_private_field`: las salidas y los diagnósticos CS0122 y CS0200 coinciden con `expected/` en los tres sistemas.

## 2026-10-01 — Records, structs y enums

- La lección 6 compara una estructura con una clase (copia al asignar, copia como argumento, `Equals`), y después presenta los records (`==` sobre los datos, `ToString`, `with`, `readonly record struct`) y las enumeraciones (numeradas desde 0, valor predeterminado, casts, `Enum.IsDefined`, `Enum.Parse`). Tiene cuatro ejemplos, tres ejercicios y cinco fragmentos rechazados, cuyos diagnósticos son CS0019, CS1612, CS8852 (tres veces en dos archivos) y CS0266. Un script comprobó que los tres idiomas comparten los mismos bloques de código, sin contar los comentarios, y que cada bloque coincide con su archivo en `code/csharp-beginner` y `expected/`.
- En Windows, con el SDK 10.0.112 y Git Bash, `check.sh` terminó con código 0 y 75 líneas `ok`, incluidos los 12 archivos `l06_*`. Todavía no es una ejecución de la CI en tres sistemas.
- Después, en la CI: la [ejecución 36865237779](https://github.com/spareilleux/learn/actions/runs/36865237779) del workflow *C# for beginners examples*, sobre el commit `114b5ed` de la [PR #93](https://github.com/spareilleux/learn/pull/93), pasó en `ubuntu-latest`, `windows-latest` y `macos-latest`. Cada job imprime `ok` para los 12 archivos `l06_*`; los jobs cuentan 76 líneas `ok` en Linux y macOS y 75 en Windows, porque `check.sh` solo ejecuta el ejemplo con shebang mediante `./` en Linux y macOS.
- Sorpresas, todas recogidas en la lección: CS8524 avisa de una expresión `switch` que tiene un brazo por nombre, y su ejemplo es `(ChordQuality)5` mientras el programa falla con 7; el literal `0` se convierte en una enumeración sin cast, mientras que `2` da CS0266; una `List<T>` de estructuras modificables rechaza `shape[0].Fret = 5` con CS1612.
- Un borrador del ejercicio 3 decía que `shape[i].Fret += 2` sobre una lista de `readonly record struct` da el mismo CS1612. Una sonda compilada antes de publicar dio CS8852; el texto se corrigió, y `compile_fail/l06_readonly_position.cs` guarda ahora las dos líneas CS8852. Otras dos frases se apoyan en sondas que quedaron fuera del código del curso: guardar una copia modificada con `shape[0] = position;` mostró 5, y `List<T>.Contains` sobre una clase sin igualdad propia respondió `False`.
- Dogfooding: en el commit `5c3a52a` de GA, [`ChordQuality`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordQuality.cs#L10-L23) empieza por `Other`, y `PositionLocation`, `Str` y `Fret` son tipos `readonly record struct`. Nada en esta lección reveló un problema en GA.

## Por verificar

- Los comandos de instalación para Linux y macOS: en esos sistemas operativos solo se ejecutó el `setup-dotnet` de la CI.
- El recorrido del depurador de la lección 3 en VS Code, Visual Studio y Rider, para una aplicación basada en archivos y para un proyecto. VS Code 1.118 y Rider están instalados en mi máquina; Visual Studio no.
- Las condiciones de licencia de los tres editores, en el momento de leerlas.

## Preguntas abiertas

- Los `Str` y `Fret` de GA declaran cada uno una conversión implícita desde `int` ([Str.cs:45](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/Str.cs#L45), [Fret.cs:72](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/Fret.cs#L72)). ¿Compila sin advertencia `new PositionLocation(3, 5)`, con la cuerda y el traste intercambiados como simples números? No ejecutado.
