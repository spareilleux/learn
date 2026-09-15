---
title: Diario
description: Notas de progreso fechadas del curso C# avanzado — la versión fijada de GA, la comprobación del IL y de los errores del compilador en tres sistemas operativos, lo que hicieron el JIT y el runtime que la documentación no dice, benchmarks en un procesador híbrido, hallazgos en GA y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Código del curso: el programa de las lecciones, los ejemplos descompilados, los fragmentos rechazados y los benchmarks, comparados con su salida esperada por `check.sh`
- [x] CI en Linux, Windows y macOS, con una ejecución de prueba (dry run) de cada benchmark
- [x] Lección 1: memoria, valores, referencias y spans
- [x] Lección 2: el recolector de basura
- [x] Lección 3: async y await por dentro
- [x] Lección 4: rendimiento medido
- [ ] Lección 5: genéricos en profundidad

## 2026-09-14 — Configuración y la versión fijada de GA

- El curso se compila con tres proyectos de GA, `GA.Core`, `GA.Domain.Core` y `GA.Business.Config`, descargados por [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/fetch-ga.sh) desde el commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), la cabeza de la rama `main` de GA ese día, con un clon disperso y sin blobs: unos 11 MB en lugar del repositorio entero. Es el mismo commit y el mismo script que los del [curso de teoría musical](../../music-theory-ga/journal/), así que ambos cursos leen el mismo código.
- Mi máquina tiene el SDK de .NET 10.0.112 y una preview de 11.0. El `global.json` del curso fija `10.0.100` con `rollForward: latestFeature`, así que `dotnet` elige 10.0.112 en la carpeta del curso y la preview fuera de ella.
- `GA.Core` hace referencia al paquete [`Microsoft.Net.Compilers.Toolset`](https://www.nuget.org/packages/Microsoft.Net.Compilers.Toolset) en su versión 4.11.0: ese proyecto lo compila el Roslyn 4.11 del paquete, no el Roslyn 5.0 del SDK. Compila sin problemas; no he buscado diferencias en el IL que produce, *por verificar*.
- `ilspycmd` 11.0.0.9375 es una herramienta local, restaurada por `check.sh`. Dos sorpresas: `-il` desensambla el ensamblado entero e ignora `-t Type`, así que `check.sh` desensambla una sola vez el ensamblado `Snippets`; y el IL contiene comentarios `// Method begins at RVA 0x…`, que cambian con cada modificación de un método no relacionado, así que `check.sh` los elimina antes de comparar.
- Descompilar con `-lv CSharp4` muestra la máquina de estados asíncrona: en el nivel de lenguaje C# 4, ILSpy no puede volver a convertirla en `await`.

## 2026-09-14 — Comprobar los errores del compilador

- Los fragmentos rechazados se compilan en memoria con un pequeño programa Roslyn, [`CompileFail`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/CompileFail/Program.cs), en lugar de con un proyecto por fragmento: una sola compilación en lugar de once. Añade los `using` implícitos del SDK como un árbol de sintaxis aparte y hace referencia a los ensamblados del runtime. Sus mensajes son idénticos a los de `dotnet build`.
- **Faltaba CS4007** al principio: el comprobador llamaba a `compilation.GetDiagnostics()`, y un `Span<int>` usado a través de un `await` compilaba sin error. Ese error solo se notifica mientras el compilador reescribe el método como máquina de estados, cosa que `GetDiagnostics()` no hace. El comprobador llama ahora a `compilation.Emit(Stream.Null)` y lee sus diagnósticos.
- Esperaba CS8175 para un span capturado por una lambda, por lo que recordaba de compiladores más antiguos; Roslyn 5.0 notifica **CS9108** («Cannot use parameter 'frets' that has ref-like type inside an anonymous method…»). La lección 1 cita el mensaje real.
- El fragmento de CS8425 produce una advertencia, no un error: el comprobador la espera y falla si no aparece.

## 2026-09-14 — Lo que hizo el runtime y el IL no dice

- **Encapsulado (boxing) eliminado por el JIT.** Un `box` seguido de `unbox.any` del mismo tipo no asigna nada, ni siquiera en el nivel 0. Con `DOTNET_TieredCompilation=0`, una caja que no escapa del método se asigna en la pila, también cuando el valor se convierte a una interfaz: es la asignación de objetos en la pila de .NET 9, ampliada en .NET 10. `check.sh` ejecuta la lección 1 de las dos maneras.
- **El umbral del montón de objetos grandes** se comprueba sobre el tamaño antes de redondear: `byte[84,975]` cuesta 85 000 bytes y se queda en la generación 0, `byte[84,976]` cuesta lo mismo y va al LOH (lección 2).
- **Los literales están en un montón congelado**: `GC.GetGeneration("C major")` y `GC.GetGeneration(typeof(PitchClass))` devuelven `int.MaxValue`.
- Una primera versión del bucle de presupuesto de asignación de la lección 2 guardaba sus arrays en una variable local, y el JIT podía asignarlos en la pila después de OSR, sin dejar basura que recolectar. Ahora los arrays escapan a un anillo de 16.
- `Task.WhenAll` conserva las excepciones internas en el orden en que fallaron las tareas, que cambia entre ejecuciones: el programa las ordena, e imprime el orden real en una línea que depende de la máquina.
- `SearchValues.Create("#b")` devuelve `Any2CharPackedSearchValues` en x64 y ``Any2SearchValues`2`` en Arm64 (el runner de macOS): otra línea que depende de la máquina.
- El presupuesto de gen0 depende del tamaño de la caché de la máquina: 18 MB en mi máquina, 16 MB en el runner de Linux, 24 MB en el de Windows y 6 MB en el de macOS, donde los mismos 32 MB de basura provocaron cinco recolecciones en lugar de una.

## 2026-09-14 — Benchmarks

- BenchmarkDotNet 0.15.8. Máquina: Intel Core Ultra 9 285K (24 núcleos), 64 GB, Windows 11 25H2, .NET SDK 10.0.112, runtime 10.0.12. BenchmarkDotNet cambió el plan de energía de Windows a *Alto rendimiento* en cada ejecución, y lo restauró después.
- La CI ejecuta cada benchmark con `--job Dry`. La primera ejecución de prueba tardó **8 min 30 s**: `JitBenchmarks` declara sus cuatro jobs en una configuración, y `--job Dry` *añadió* un job de prueba a esos cuatro en lugar de sustituirlos. La configuración usa ahora `Job.Dry` cuando `BENCHMARKS_DRY=1`, y toda la ejecución de prueba tarda unos 30 s en local, y entre 17 y 53 s en los runners.
- La ejecución completa de las siete clases, una tras otra y sin nada más en marcha, tardó unos 45 minutos. `JitBenchmarks` por sí sola ejecuta cuatro jobs y tardó 4 minutos.
- **El mismo código midió 31 ns en el calentamiento y entre 41 y 52 ns en las iteraciones reales** (`VoicingWithSpans`). Fijado a un núcleo con `--affinity`, midió 32.4 ns, tanto en el primer núcleo como en el último. El Core Ultra 9 285K tiene núcleos de rendimiento y de eficiencia; no he comprobado de qué tipo son esos dos núcleos, ni he confirmado que la migración de subprocesos explique las iteraciones más lentas, *por verificar*. La lección 4 cuenta la historia y conserva las tablas sin fijar, ya que es lo que obtendrá un lector por defecto.
- Añadí `[MemoryDiagnoser]` a `JitBenchmarks` mientras se ejecutaban las demás clases, sin recompilar: la ejecución usó la compilación anterior y no imprimió ninguna columna `Allocated`. Tras recompilar y volver a ejecutar, mostró el resultado en el que se basa la lección 4: con PGO, el bucle sobre `IEnumerable<int>` ya no asigna su enumerador de 40 bytes, y es 9 veces más rápido.
- Dos de mis expectativas eran erróneas: `FrozenDictionary` no fue más rápido que `Dictionary` con doce sufijos de acorde cortos, y `SearchValues` fue 1.7 veces *más lento* que un bucle con símbolos de acorde de 1 a 6 caracteres. Ambos resultados aparecen en la lección 4 tal como se midieron.

## 2026-09-14 — Dogfooding: lo que las lecciones encontraron en GA

Todavía no he comunicado ninguno de estos hallazgos al proyecto GA; los enumero para que sus mantenedores decidan.

- [`PitchClassSetId.ItemsSpan`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L59-L71) copia los 4096 identificadores en un array nuevo en cada llamada, 16 408 bytes. `Items` está declarado como `IReadOnlyCollection<PitchClassSetId>` e inicializado con una expresión de colección, así que el compilador crea un `<>z__ReadOnlyList<PitchClassSetId>`, y la prueba `is PitchClassSetId[]` que debería evitar la copia siempre es falsa (lecciones 1 y 2).
- [El operador `-` de `PitchClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L110-L137) busca en un `FrozenDictionary` de 144 tuplas para calcular `(a - b + 12) % 12`. Tarda 583 ns para los 144 pares, frente a 134 ns de la aritmética y 41.5 ns de un array plano de 144 valores (lección 4).
- [`Try.OfAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Functional/Try.cs#L62-L73) espera sin `ConfigureAwait(false)`, así que bloquear esperándolo bajo un contexto de sincronización de un solo subproceso provoca un interbloqueo, y además captura `OperationCanceledException`, con lo que convierte una cancelación en un fallo ordinario (lección 3).
- [`LazyWithExpiration<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Utilities/LazyWithExpiration.cs#L20-L40) mide su caducidad con un `Thread.Sleep` en un subproceso del grupo de subprocesos, uno por valor. Con 64 valores que caducan al cabo de un segundo, un `Task.Run` sin relación esperó 2 s en mi máquina y entre 10 y 12 s en los runners de 3 y 4 núcleos (lección 3). No he buscado los sitios en los que GA lo usa, *por verificar*.

## 2026-09-14 — CI

- Commit [`d85a319`](https://github.com/spareilleux/learn/commit/d85a319), ejecución [34915741516](https://github.com/spareilleux/learn/actions/runs/34915741516): en verde en los tres sistemas operativos, solo el código de las lecciones.
- Commit [`8ba378e`](https://github.com/spareilleux/learn/commit/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3), ejecución [34919815590](https://github.com/spareilleux/learn/actions/runs/34919815590): las soluciones de los ejercicios, en verde en los tres sistemas operativos. Los jobs tardaron 1 min 23 s en Linux, 2 min en macOS y 3 min 14 s en Windows, de los cuales la ejecución de prueba de los 37 benchmarks ocupó 23 s, 27 s y 53 s. Unos 14 s de cada job corresponden a la demostración de `LazyWithExpiration` de la lección 3: un `Task.Run` esperó 11 001 ms en Linux, 11 766 ms en macOS y 11 050 ms en Windows, donde la ejecución anterior había medido 9878 ms.
- El runner de Windows dio los mismos anchos de vector y las mismas diferencias en coma flotante que mi máquina; el runner de Linux tiene AVX-512.

## Por verificar

- Si `PoolingAsyncValueTaskMethodBuilder` elimina los 104 bytes de `ValueTaskAfterYield` (lección 3).
- El IL de `GA.Core` compilado por Roslyn 4.11 frente al del Roslyn 5.0 del SDK.
- Las lecciones se escribieron en x64; los resultados de Arm64 provienen solo de las líneas dependientes de la máquina del runner de macOS, nunca de un benchmark.
