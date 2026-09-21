---
title: Diario
description: Notas de progreso fechadas del curso C# avanzado — la versión fijada de GA, la comprobación del IL y de los errores del compilador en tres sistemas operativos, lo que hicieron el JIT y el runtime que la documentación no dice, benchmarks en un procesador híbrido, programas deterministas para canales, Dataflow y Rx, el nuevo plan, hallazgos en GA y puntos por verificar.
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
- [x] Lección 5: genéricos en profundidad
- [x] Un nuevo plan en cuatro partes y 24 lecciones, con ASP.NET Core en profundidad y los equivalentes en Spring y Reactor
- [x] Lección 6: canales
- [x] Lección 7: TPL Dataflow
- [x] Lección 8: Rx.NET
- [x] Lección 9: elegir un flujo
- [x] Lecciones 10-14: estado compartido y ruta de una petición ASP.NET Core
- [x] Lección 15: servicios hospedados y trabajo en segundo plano
- [x] Lección 16: autenticación y autorización
- [x] Lección 17: traducción de un oráculo de especificación Petri acotado en diseño de pruebas deterministas para Channel, TPL Dataflow y Rx
- [x] Apéndice 1: cinco miembros de GA optimizados, demostrados sobre los 4096 conjuntos de clases de altura y luego medidos — con los benchmarks reescritos en cuanto se vio que medían el JIT
- [x] Apéndice 2: el pipeline de indexación de GA perfilado, tres cambios demostrados contra la propia salida de GA y medidos, y enviados aguas arriba como pull requests

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

## 2026-09-15 — Un nuevo plan, y empieza la parte 2

- El curso pasa de 12 a 24 lecciones en cuatro partes: runtime y rendimiento, concurrencia y flujo de datos, ASP.NET Core en profundidad, metaprogramación y herramientas. Las lecciones 1 a 4 conservan sus slugs; las antiguas lecciones 6 y 12 pasan a ser las lecciones 10 y 19, y las lecciones 2 y 3 apuntan ahora a ellas. Las lecciones 6 a 9 se escribieron antes que la lección 5.
- Las partes 2 y 3 comparan cada tema con Spring y Reactor, de C# a Java. El [curso de Spring Boot, Spring Cloud y Reactor](../../spring-cloud-reactor/) hace la comparación en el otro sentido, así que las lecciones enlazan con sus páginas en lugar de volver a explicar Reactor, y la parte 3 construirá el equivalente en ASP.NET Core de su servicio de escalas.

## 2026-09-15 — Volver deterministas los programas concurrentes

Cada comportamiento de las lecciones 6 a 9 lo imprime el programa y se compara con `expected/`, en tres sistemas operativos. Una primera versión de cada lección imprimía algo que cambiaba entre ejecuciones; cada lección se ejecutó al menos nueve veces seguidas antes de hacer commit de su salida.

- **Barreras, no retardos.** Los elementos se retienen con un `TaskCompletionSource` hasta que el programa ha visto lo que quiere mostrar, y «el productor está atascado» se mide esperando a que un contador deje de moverse, e imprimiendo después el contador.
- **Las continuaciones se ejecutan cuando quieren.** Un `WriteAsync(...).AsTask()` que había terminado seguía indicando `IsCompleted` en false en algunas ejecuciones, porque su continuación es asíncrona: el programa ahora lo espera. Lo mismo con `Fault` sobre un bloque de Dataflow, cuyo `Completion.Exception` seguía siendo `null` justo después de la llamada.
- **`EnsureOrdered = false` no significa «al revés».** Una primera prueba esperaba que el lento elemento 0 saliera el último; no lo hizo en 8 ejecuciones de 20. La lección 7 muestra ahora lo que un consumidor puede recibir mientras el elemento 0 se ejecuta.
- **Límites en tiempo virtual.** Las notas en exactamente 500 o 1.000 ms caían en el borde de las ventanas de `Sample` y `Buffer`; las notas de la lección 8 están colocadas lejos de ellos.
- **`Reader.Count` lanza** `NotSupportedException` en un canal no acotado creado con `SingleReader = true`: su `CanCount` es `false`. El programa vacía el canal para contar lo que queda.
- **Rx.NET 7.0 no tiene puente hacia `IAsyncEnumerable`**: `ToAsyncEnumerable()` sobre un observable no compiló. La lección 9 escribe a mano las dos direcciones.
- La primera versión de la lección 7 etiquetaba Dm7 como Forte 4-3, a partir de `ProgrammaticForteCatalog` de GA; la tabla de Forte dice 4-26. La lección toma ahora las etiquetas de `CanonicalForteCatalog` e imprime ambas.
- Commits [`69bb214`](https://github.com/spareilleux/learn/commit/69bb2145cf22795d6394209ff82220e8a2bdf0d4) y [`b4d713f`](https://github.com/spareilleux/learn/commit/b4d713f86711b770a75d7504f334c5871c95f820), ejecuciones [34994143077](https://github.com/spareilleux/learn/actions/runs/34994143077) y [34995561655](https://github.com/spareilleux/learn/actions/runs/34995561655): en verde en los tres sistemas operativos.
- El benchmark de flujos de la lección 9 se ejecutó solo durante 5 minutos en la misma máquina que la lección 4. BenchmarkDotNet indicó una distribución bimodal para `RxObserveOnTaskPool`.

## 2026-09-15 — Dogfooding: canales, Dataflow y Rx en GA

GA usa canales en su generador de voicings y en su comando de indexación, y TPL Dataflow y Rx.NET en una demo de rendimiento. Nada de esto se ha notificado todavía aguas arriba.

- [`VoicingGenerator.GenerateAllVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs#L180-L249): un consumidor que se detiene antes de tiempo, como el `.Take(100)` del ejemplo de uso, deja a los productores generando todas las ventanas en un canal no acotado; una ventana que lanza una excepción deja al consumidor esperando para siempre, porque nunca se llega a `Writer.Complete()`; el resumen dice que el orden se conserva, los comentarios de debajo dicen que no (lecciones 6 y 9).
- [`IndexVoicingsCommand`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaCLI/Commands/IndexVoicingsCommand.cs#L158-L251): cuando el consumidor falla, por ejemplo porque la base de datos está caída, registra el error y retorna, y los productores esperan para siempre ante el canal lleno (lección 6). El canal acotado en modo `Wait` es la elección correcta.
- [`PerformanceOptimizationDemo`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs): la parte de Dataflow cuenta los resultados de una `List<T>` que llena otro subproceso sin esperar a ese subproceso, e ignora el resultado de `SendAsync` (lección 7); la parte Rx cuenta lotes como eventos, 10 en lugar de 1.000, y espera 500 ms fijos en lugar de esperar el pipeline (lección 8). Su parte de canales es correcta.
- La misma demo y `MusicalAnalysisApp`, ambos `net10.0`, hacen referencia al paquete `System.Threading.Tasks.Dataflow` 9.0.10, que .NET 10 ya tiene en su framework compartido. Un proyecto `net10.0` nuevo con la misma referencia recibe la advertencia NU1510 al restaurar, y carga de todos modos el ensamblado del framework.
- Los números de `ProgrammaticForteCatalog` siguen otro orden que la tabla de Forte, aunque sus observaciones dicen que las diferencias son menores: 4-3 para el acorde de séptima menor donde Forte dice 4-26 (lección 7).
- GA tiene varias clases `BackgroundService`, entre ellas el precalentamiento de la caché y la inicialización del índice de voicings; la lección 15 es el lugar para leerlas.

## 2026-09-15 — Apéndice 1: optimizar GA, primero la demostración

La lección 4 medía el código de GA tal cual. Este apéndice reescribe tres de sus miembros, y lo interesante resultó no ser la ganancia de velocidad sino lo que la reescritura *no* tiene permitido cambiar.

- Los tres son `PitchClassSetId.IsClusterFree`, `PitchClassSet.IntervalClassVector` y `PitchClassSet.ClosestDiatonicKey`. Todos reciben un conjunto de 12 bits, así que el dominio de entrada entero tiene 4096 valores: `Advanced -- a1` compara cada reescritura con la respuesta de GA para cada uno de ellos, y la CI lo ejecuta en tres sistemas operativos. Escribir la demostración antes que el benchmark cambió lo que estaba dispuesto a afirmar.
- `IntervalClassVectorId` empaqueta seis cuentas como dígitos en base 12, y las cuentas de 12 del agregado cromático acarrean. GA lo documenta como una limitación conocida. Empaquetarlo correctamente cambiaría el identificador del conjunto 4095, y `ProgrammaticForteCatalog` ordena cada cardinalidad por ese identificador, así que todos los números de Forte podrían moverse — la versión rápida reproduce el acarreo en su lugar. Una «corrección» colada dentro de un cambio de rendimiento es justamente de lo que trata este apéndice.
- La respuesta de `ClosestDiatonicKey` depende de que `OrderByDescending` sea estable: los empates van a la tonalidad que `Key.Items` lista primero, las 15 mayores antes que las 15 menores. Un bucle que sustituyera al que va ganando con `>=` en lugar de `>` devolvería en silencio otra tonalidad en cada empate; el que sustituye con `>` coincide con GA en los 4096 conjuntos.
- **Los primeros benchmarks estaban mal, y halagaban.** Llamar a cada miembro una vez sobre un argumento `const` dejó que el JIT plegara la llamada en un literal: el `IsClusterFree` rápido salía a 0,0107 ns, una veinticincoava parte de un ciclo. Un estático mutable eliminó el plegado y seguía dando una mediana de cero, porque BenchmarkDotNet resta un método vacío. Reescritos para barrer los 4096 conjuntos, `IsClusterFree` es 4 veces más rápido, no 31 — y yo habría publicado el 31.
- El hallazgo son los 175 KB, no los microsegundos. `IdentifyClosestKey` recibe un `Dictionary<Key, IReadOnlyCollection<PitchClass>>` y lo desestructura como `foreach (var (key, _) in items)`: los valores se construyen para las 30 tonalidades y nunca se leen. No hizo falta ningún perfilador — bastó con leer el método.
- `ToNormalForm` y `PrimeForm` también están hechos, así que el apéndice demuestra ahora cinco miembros y no tres. Tabular la forma normal quitó los últimos 16 KB del `ClosestDiatonicKey` rápido, que ya no asigna nada: 1.615 veces más rápido, 175 KB por llamada eliminados. `PrimeForm`, que ya era aritmética de bits, solo dio 1,8 — el techo honesto de reescribir aritmética correcta, y merece estar al lado del 1.615.
- Nada de esto se ha reportado aún aguas arriba.

## 2026-09-16 — Lección 5: genéricos en profundidad

- La lección 5 llena el hueco entre las lecciones 4 y 6, que se escribieron antes. Sus salidas proceden de la misma máquina y del mismo SDK que el resto del curso; commit del código [`378eec1`](https://github.com/spareilleux/learn/commit/378eec1333390889e29fd0c42af0fae47512035e).
- Ejecución de CI [35173274425](https://github.com/spareilleux/learn/actions/runs/35173274425): verde en Linux, Windows y macOS. Las líneas que dependen de la máquina fueron las mismas en los tres runners que en mi máquina, incluido el de Arm64: 4592 bytes en el primer acceso a la caché de `Str`, y 1 y luego 0 métodos compilados para `Shared<string>` y luego `Shared<object>`.
- **El propio resumen del JIT como prueba.** `DOTNET_JitDisasmSummary=1` y `DOTNET_JitStdOutFile` funcionan en el runtime publicado, así que `check.sh` compara la lista de compilaciones de `Shared<T>.Describe`: cuatro para seis argumentos de tipo, una de ellas sobre `System.__Canon`. Lanza `Advanced.dll` directamente: a través de `dotnet run`, el propio proceso del SDK heredaría las variables y escribiría en el mismo archivo.
- **Lo que el runtime no comprueba.** `MakeGenericMethod` aceptó `(int, string)` para un parámetro `where T : unmanaged`; el compilador lo rechaza con CS8377. `notnull` no deja nada en `GenericParameterAttributes`.
- **Un fragmento que esperaba que fallara compiló.** `IStaticReadonlyCollectionFromValues<TSelf>` de GA oculta el `Items` abstracto estático con una propiedad `new static` que tiene cuerpo. Esperaba que `T.Items`, sobre un parámetro de tipo restringido a esa interfaz, se rechazara; Roslyn 5.0 lo compiló. Quité el fragmento; a qué miembro se enlaza esa llamada queda *por verificar*.
- **El desensamblado cambió mi lectura del benchmark.** En el código compartido, leer un campo estático de `Counter<T>` llama a `CORINFO_HELP_GET_NONGCSTATIC_BASE` en cada iteración, tanto en el nivel 1 como con la compilación por niveles desactivada, y aun así el bucle solo fue 1.46 veces más lento que la versión para `int`.
- **De nuevo la PGO.** Un `foreach` sobre `PitchClass.Items` asigna 72 bytes en las primeras llamadas del programa y 40 bytes en el benchmark, después de la PGO dinámica.

## 2026-09-16 — Dogfooding: las interfaces de objetos de valor de GA

Nada de esto se ha notificado todavía aguas arriba.

- [`ValueObjectUtils<TSelf>.Items`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L10) crea un `ValueObjectCollection<TSelf>` nuevo de 32 bytes en cada lectura, aunque la interfaz documenta `Items` como memoizado; un `foreach` sobre él asigna 72 bytes (lección 5).
- `Values` está declarado como `IReadOnlyList<int>` en [`IStaticValueObjectList<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L57), y las implementaciones devuelven un `ImmutableArray<int>`: 24 bytes de boxing por lectura. Doce lecturas tardaron 41.8 ns y asignaron 288 bytes, frente a 3.1 ns y nada a través del `ImmutableArray` (lección 5).
- [`ValueObjectCache<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52) construye en su primer uso dos `FrozenSet` que nada lee en los tres proyectos descargados: 4592 bytes para los 26 valores de `Str` (lección 5).
- [`IRangeValueObject<TSelf>.EnsureValueInRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L55-L63) normaliza con un tamaño de rango de `max - min` en lugar de `max - min + 1`: 12 se convierte en 2 para una clase de altura. Ningún llamador de los proyectos descargados pasa `normalize: true`, así que el error está latente (lección 5).
- `default(Str)`, `new Str[n]` y `new T()` dan la cuerda 0, que la comprobación de rango de `Str` prohíbe; lo mismo vale para todos los objetos de valor de GA cuyo mínimo es 1 (lección 5).
- El `out` de `IStaticReadonlyCollection<out TSelf>` no tiene ningún efecto: 13 de sus 17 implementaciones son structs, y la interfaz no tiene miembros de instancia (lección 5).

## 2026-09-17 — Apéndice 2: perfilar GA, con pull requests

El apéndice 1 eligió qué optimizar leyendo GA. Esta vez eligió un perfilador, sobre el propio pipeline de GA en el commit [`66bdd04`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), y cada cambio se envió aguas arriba. El trabajo fue de la noche del 2026-09-16 a la madrugada del 2026-09-17.

- **Tres pull requests.**
  - [#695](https://github.com/GuitarAlchemist/ga/pull/695): el reconocimiento de acordes con máscaras de 12 bits, calculado una sola vez por conjunto de clases de altura.
  - [#694](https://github.com/GuitarAlchemist/ga/pull/694): el vector de clases de intervalo, calculado una sola vez por conjunto.
  - [#693](https://github.com/GuitarAlchemist/ga/pull/693): `OptickIndexReader.Dimension`, leído una sola vez.

  Cada una se hizo en su propia rama a partir de `main`. Las pruebas de GA pasaron antes de abrir cada PR: GA.Domain.Core.Tests 458/458 y 459/459, y las pruebas de acordes y voicings de GA.Business.Core.Tests 421/421 y 419/419. En GA.Business.ML.Tests, las pruebas de búsqueda y de esquema pasaron 227 de 228; la que falla lo hace de la misma manera en `main`.
- **Adónde iba el tiempo.** `dotnet-trace` sobre el análisis de voicings situó alrededor del 52 % del subproceso principal en `CanonicalChordRecognizer.IdentifyChordSet`, la mayor parte construyendo `HashSet`. Un sondeo dio 173 µs y 347 KB por voicing para `VoicingAnalyzer.Analyze`, y 38 MB por consulta para una búsqueda OPTIC-K.
- **La demostración compara dos compilaciones de GA, no dos métodos.** Un único programa de volcado se compila contra `main` y contra la rama, escribe cada respuesta, y `cmp` compara los archivos. Todos fueron idénticos byte a byte:
  - `TryMatch`: 258.048 líneas;
  - reconocimiento: 106.496 líneas, cada conjunto × 13 bajos × 2 pasadas;
  - vectores de clases de intervalo: 8.192 líneas;
  - los 667.125 voicings de guitarra a través de `VoicingAnalyzer.Analyze`;
  - 2.048 búsquedas sobre el índice real de 313.047 entradas.

  La demostración propia del curso, `GaPerf -- a2`, comprueba 6.856.704 llamadas a `TryMatch` y 106.496 reconocimientos, y se ejecuta en la CI.
- **El hallazgo fue la caché, no las máscaras.** Los 667.125 voicings usan unos 2.500 conjuntos de clases de altura distintos, así que la búsqueda de patrones de cada conjunto se repetía 266 veces. Con un array de 4096 casillas, el reconocimiento es 7.600 veces más rápido en el benchmark del curso. En GA, con los dos cambios, `VoicingAnalyzer.Analyze` pasó de 234,34 ms y 759 MB a 8,94 ms y 22 MB para 2.000 voicings.
- **Los 38 MB de la búsqueda no estaban en la búsqueda.** Un experimento con un recorrido secuencial asignó los mismos 38 MB que el paralelo, lo que descartó a `Parallel.For`. Los bytes venían de `GetVector`, que leía una propiedad que ejecuta un `Where` + `Sum` de LINQ sobre el registro de particiones: 626.094 consultas por búsqueda. Leída una sola vez, una búsqueda pasó de 4,986 ms y 38,25 MB a 2,162 ms y 41 KB.
- **Dos resultados que no esperaba.**
  - La primera versión con máscaras seguía asignando 72 bytes por llamada, por los enumeradores obtenidos a través de `IEnumerable<int>`. Distinguir `int[]` y `HashSet<int>` con un `switch` los eliminó, y la hizo otras 2,7 veces más rápida. La PGO dinámica no eliminó esta asignación, a diferencia de la de la lección 4; por qué no queda *por verificar*.
  - El particionado por rangos de la búsqueda, que parecía un 8 % más rápido antes de la corrección, resultó un 22 % más lento después. Lo descarté.
- **De extremo a extremo**, la exportación OPTIC-K se ejecutó cuatro veces, alternando el `main` de GA y una compilación con los dos cambios de análisis: 142,8 s frente a 62,9 s, y después 95,0 s frente a 38,3 s. Los archivos de índice fueron idénticos entrada a entrada.
- **La máquina no estaba inactiva, y las cifras lo dicen.**
  - Había otras sesiones en marcha. Cada compilación y cada serie de benchmarks tomó un bloqueo global de la máquina, y cada serie de BenchmarkDotNet tomó además el bloqueo de la GPU.
  - Al principio de cada serie registré la RAM libre y los procesos más activos: entre 13,6 y 18,5 GB libres, entre el 32 % y el 100 % de CPU total, con Microsoft Defender, Docker y WSL a la cabeza.
  - El mismo binario de exportación tardó 142,8 s, y luego 95,0 s.
  - El coordinador informó de dos capturas de Chrome sin interfaz hechas por otra sesión entre las 00:47 y las 00:49. Ninguna de mis series se ejecutó en esa ventana: los benchmarks anteriores terminaron a las 00:42:38, y el siguiente empezó a las 00:50:22. Aun así, volví a ejecutar las series de GA que acababan de correr justo antes, con las mismas asignaciones y tiempos dentro de las barras de error.
  - Las tablas de antes y después de GA usan `ShortRun`. Sus asignaciones son exactas; los tiempos, orientativos.
  - Una ejecución de la serie de acordes no llegó a hacerse: mi script apuntaba a un worktree que no existía, y la volví a lanzar.
- **Medido, y sin cambiar.**
  - El camino paralelo de `VoicingGenerator` es el doble de lento que el secuencial (1.419 ms frente a 711 ms para 667.125 voicings), y `PitchClassSet.GetCompatibleKeys` ocupa el 13,5 % del perfil del análisis. Los dos archivos pertenecen a correcciones de GA en curso en otra sesión, así que estos hallazgos fueron allí como propuestas.
  - `KeyIdentificationService.Identify` no está en el camino caliente: 25 µs, una vez por petición.
  - Las asignaciones de los objetos de valor de la lección 5 no aparecen en este perfil.
- **La exportación del índice no siempre es reproducible.** La primera exportación de la noche difiere de las posteriores en 266 de las 313.047 entradas, identificadas por instrumento y diagrama, aunque salió del mismo commit de GA. Todas las comparaciones de arriba se hacen entre exportaciones del mismo grupo; la causa queda *por verificar*.

## 2026-09-21 — Lecciones 10-14: concurrencia y ruta de petición ASP.NET Core

- Cinco lecciones ejecutables en .NET 10.0.12: lost update determinista, `Lock`, `Interlocked`, `ConcurrentDictionary` y `Parallel.ForEachAsync` limitado.
- Servidores Kestrel reales en puertos loopback efímeros; se observaron ciclo de vida, petición, apagado graceful, orden de middleware y short-circuit `429`.
- Se verificaron lifetimes singleton/scoped, rechazo de captive dependency, keyed services y validación de options.
- Se verificaron una Minimal API, un controlador en la misma tabla de routing y una respuesta JSON `IAsyncEnumerable<string>`.
- Las salidas portables están en `expected/l10.txt` a `expected/l14.txt`; los mínimos del thread pool dependen de la máquina.
- Son pruebas locales: buffering de proxy, límites de producción, identity provider real y starvation ante una dependencia remota quedan por medir.

## 2026-09-21 — Lecciones 15-16: trabajo hospedado y autorización local

- La prueba de servicios hospedados usa barreras de terminación en lugar de demoras. Un canal limitado alimenta un worker singleton y dos operaciones resuelven instancias scoped distintas (`scope-1` y `scope-2`). La cancelación del host se observa mientras el worker espera más trabajo.
- Un segundo host libera un fallo deliberado y observa `ApplicationStopping` con `BackgroundServiceExceptionBehavior.StopHost`. Esto demuestra la política del host, no reintento ni recuperación.
- La prueba de autenticación inicia Kestrel en un puerto loopback efímero. Los bearer tokens ausente, mal formado, caducado y con firma incorrecta devuelven 401; una identidad válida sin `scope=scales.read` devuelve 403; la identidad autorizada recibe `200 C major`.
- Ambas claves se generan en memoria para un solo proceso. La vida útil usa un instante fijo y ninguna clave ni token se imprime ni persiste.
- `Advanced` compiló localmente sin advertencias y las dos salidas nuevas coinciden con `expected/l15.txt` y `expected/l16.txt`. Quedan por verificar la CI en tres sistemas, un servidor de autorización real, descubrimiento/rotación de claves y despliegue detrás de proxy.

## 2026-09-21 — Lección 17: oráculos Petri para pruebas de pipelines C#

- Se reutilizó el ciclo de vida ejecutable de un elemento y una plaza de la [lección Petri 14](../../petri-nets/14-on-our-systems/) en vez de crear un segundo modelo. Su suite específica explora los ocho marcados alcanzables, clasifica los tres marcados muertos terminales y comprueba el invariante de cola Channel `free + queued = 1`.
- Se registró la frontera entre modelo y ejecución. Las pruebas Petri validan la especificación finita; no ejecutan `Channel<T>`, TPL Dataflow ni Rx.NET y, por tanto, no demuestran la implementación actual de GA.
- Cada camino del modelo se convirtió en una receta de prueba de ejecución determinista basada en compuertas en lugar de pausas. La receta exige el resultado público de excepción o finalización y el asentamiento de cada participante poseído.
- Se mantuvieron separadas las semánticas de capacidad: Channel cuenta elementos en cola en este modelo, la capacidad de un bloque de ejecución Dataflow incluye el elemento en curso y Rx no tiene límite hasta que el diseño lo añade.
- Se documentaron dos límites deliberados: la cancelación es atómica y anterior al inicio, y la red de un elemento no puede reproducir un productor ya bloqueado por backpressure tras el fallo del consumidor. Quedan por verificar un modelo de dos elementos y fixtures de ejecución.

## Por verificar

- Ejecutar las recetas de la lección 17 contra fixtures fijadas de Channel, Dataflow y Rx, incluido un ordenamiento de dos elementos con productor bloqueado; la evidencia actual es solo el oráculo Petri.
- Por qué la PGO dinámica no eliminó los enumeradores encapsulados de la primera versión con máscaras de `TryMatch` (apéndice 2).
- Por qué la exportación del índice OPTIC-K de GA difiere entre sesiones en 266 de las 313.047 entradas (apéndice 2).
- A qué miembro se enlaza `T.Items` cuando una interfaz derivada oculta una propiedad abstracta estática con una propiedad `new static` (lección 5).
- Por qué una llamada auxiliar por iteración solo hizo 1.46 veces más lento el bucle compartido de `ReadStatic<string>` (lección 5).
- Cuál de los dos objetos de un `foreach` sobre `PitchClass.Items` deja de asignar la PGO dinámica (lección 5).
- Si `PoolingAsyncValueTaskMethodBuilder` elimina los 104 bytes de `ValueTaskAfterYield` (lección 3).
- El IL de `GA.Core` compilado por Roslyn 4.11 frente al del Roslyn 5.0 del SDK.
- Las lecciones se escribieron en x64; los resultados de Arm64 provienen solo de las líneas dependientes de la máquina del runner de macOS, nunca de un benchmark.
