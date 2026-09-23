---
title: Diario
description: Notas de progreso fechadas del curso de Java — intentos, sorpresas, casos prácticos en mis repositorios y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Lección 1 — El JDK y las herramientas de build
- [x] Lección 2 — Tipos, igualdad y operadores
- [x] Lección 3 — Clases, records y enums
- [x] Lección 4 — Genéricos y borrado de tipos
- [x] Lección 5 — Excepciones, `null` y `Optional`
- [x] Lección 6 — Lambdas e interfaces funcionales
- [x] Lección 7 — Colecciones y Streams
- [x] Lección 8 — Pattern matching
- [x] Lección 9 — Concurrencia e hilos virtuales
- [x] Lección 10 — Maven y Gradle a fondo
- [x] Lección 11 — Pruebas
- [x] Lección 12 — La biblioteca estándar del día a día
- [ ] Lección 13 — La JVM en tiempo de ejecución
- [ ] Lección 14 — Anotaciones, reflexión y módulos

## QA

OpenJDK 25+36, Maven 3.9.16, Gradle 9.7.1, comparados en todo momento con el SDK de .NET 10. Varias filas son valores por defecto que difieren de los de .NET: el comportamiento de Java está documentado, y la sorpresa solo está en traer la costumbre de C#; la columna Estado dice cuáles. Las dos primeras filas vienen de construir el plugin de JetBrains de GuitarAlchemist/ga, donde empiezan los casos prácticos de este diario. Nada se ha reportado aguas arriba.

No hay tabla de experimentos: ninguna entrada plantea una hipótesis antes de la medición que la pone a prueba. La única frase con forma de hipótesis — que la primera ejecución con carrera perdió más del 90 % de sus incrementos porque el JIT aún no había compilado el bucle — explica un número ya registrado, y el diario la marca *por verificar*.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| Gradle nombra el problema cuando el JDK es demasiado nuevo para él | Gradle 8.5 sobre JDK 25 falla con un mensaje que es solo el número de versión de Java | `jetbrains-plugin/` de GuitarAlchemist/ga en `5560b883`, Gradle 8.5, JDK 25 | `* What went wrong:` seguido de `25`; la traza muestra una `java.lang.IllegalArgumentException: 25` lanzada mientras Gradle compila el script de build en Kotlin | Reproducido; subir Gradle desplaza el fallo a la fila siguiente [casos prácticos](#casos-prácticos-en-mis-repositorios) |
| Una versión de Gradle que admite JDK 25 basta para construir el plugin | Gradle 9.7.1 llega más lejos y muere dentro del antiguo plugin `org.jetbrains.intellij` 1.16.1 | el mismo build, Gradle 9.7.1 | `class org.jetbrains.intellij.MemoizedProvider overrides final method org.gradle.api.internal.provider.AbstractMinimalProvider.toString()` | Reproducido; migrar al IntelliJ Platform Gradle Plugin 2.x es el paso siguiente, no hecho [casos prácticos](#casos-prácticos-en-mis-repositorios) |
| Maven avisa cuando resuelve una dependencia más antigua que la que pidió un módulo | Pone Commons Lang 3.14.0 en el class path frente a una petición de 3.20.0, en silencio, y el programa falla en ejecución | Maven 3.9.16, `l10/check.sh` | `NoClassDefFoundError` en ejecución; hace falta `-Dverbose` solo para ver que se pidió otra versión. El `NU1605` de NuGet convierte la misma situación en un error por defecto | Por diseño [2026-09-13](#2026-09-13--lección-10) |
| «Gana el más cercano» da a una biblioteca y a su artefacto de agente versiones a juego | Mockito 5.23.0 pide Byte Buddy 1.17.7, AssertJ 3.27.7 pide 1.18.3, y Maven empareja `byte-buddy` 1.18.3 con `byte-buddy-agent` 1.17.7 | `l11`, Maven 3.9.16 | Funciona, porque el camino de AssertJ es más corto y trae la versión más nueva — por suerte, no por regla | Reproducido, no reportado [2026-09-13](#2026-09-13--lección-11) |
| `CompletableFuture.cancel(true)` interrumpe la tarea en curso, como dice `mayInterruptIfRunning` | El future dice estar cancelado mientras su tarea llega hasta el final | `CompletableFuture`, OpenJDK 25+36 | El Javadoc dice que el argumento "has no effect in this implementation". Una tarea de cinco segundos cancelada tardó igualmente cinco segundos, porque el `close()` del ejecutor la esperó | Por diseño, y documentado; la lección 9 lo muestra ahora con una tarea de un segundo [2026-09-13](#2026-09-13--lección-9) |
| BlockHound se instala con `BlockHound.install()`, como muestra su README | En JDK 25 la autoconexión falla, el remedio documentado falla de otra forma, y solo funciona `-javaagent` | BlockHound 1.0.17, JDK 25, `l11` | `Could not self-attach to current VM using external process`; con `-Djdk.attach.allowAttachSelf=true`, `Agent JAR loaded but agent failed to initialize` | Reproducido, no reportado; la lección 11 usa `-javaagent` [2026-09-13](#2026-09-13--lección-11) |
| Una biblioteca de instrumentación actual no pide ninguna opción de JVM obsoleta y nombra el método que llamaste | BlockHound exige una opción obsoleta desde JDK 13, y señala `Thread.sleep` con un nombre privado del JDK | BlockHound 1.0.17, JDK 25, `l11/check.sh` | `-XX:+AllowRedefinitionToAddDeleteMethods`; `Thread.sleep` señalado como `java.lang.Thread.sleepNanos0` | Reproducido, no reportado [2026-09-13](#2026-09-13--lección-11) |
| Un procesador de anotaciones que falla informa de su error | Maven imprime un mensaje genérico y oculta la causa salvo con `-e` | NullAway 0.14.1 sobre Error Prone 2.50.0, JDK 25, `l11` | `An unknown compilation problem occurred`; el error real, un `IllegalAccessError` sobre la API interna de javac, solo aparece con `mvn -e` | Reproducido; un `.mvn/jvm.config` con líneas `--add-exports` lo resuelve [2026-09-13](#2026-09-13--lección-11) |
| `javac -XDrawDiagnostics` y la API `javax.tools` dan la misma clave de diagnóstico | Divergen sobre el mismo fragmento rechazado | OpenJDK 25+36, añadir a una `List<? extends Number>` | La línea de comandos da `compiler.err.cant.apply.symbols`, la API `compiler.err.prob.found.req` | Reproducido; las lecciones citan lo que ve la API, porque los tests la usan [2026-09-13](#2026-09-13--lecciones-1-a-4) |
| `YYYY` en un patrón de fecha es el año civil, como en .NET | Es el año de la semana, que difiere a fin de año y depende de la configuración regional | formato de fechas en Java, lección 12 | El 31 de diciembre de 2026 se imprimió `2027` con `Locale.US` y `2026` con `Locale.FRANCE` | Por diseño [2026-09-13](#2026-09-13--lección-12) |
| El `HttpClient` de Java sigue redirecciones y expira, como el de .NET | No hace ninguna de las dos cosas sin configurarlo | `java.net.http.HttpClient`, JDK 25 | El código .NET portado recibe un 302 con el cuerpo vacío, o una llamada que puede esperar para siempre | Por diseño [2026-09-13](#2026-09-13--lección-12) |
| Surefire muestra `@DisplayName` y atribuye los tests a la clase que los declara | Ignora `@DisplayName` sin una opción de reporter, y atribuyó los tests de toda una clase a su clase anidada | Maven Surefire con JUnit 6, `l11` | Los nueve tests de `PriceCalculatorTest` atribuidos a su clase anidada en la salida de consola | Reproducido, no reportado [2026-09-13](#2026-09-13--lección-11) |
| Un `Map.of(…)` inmutable se recorre en un orden estable | El orden cambia de un arranque de la JVM al siguiente | `Map.of`, OpenJDK 25+36 | Cuatro ejecuciones del mismo programa de una línea dieron dos órdenes | Por diseño: `Map.of` sortea su orden de iteración en cada JVM. La salida del ejemplo ya no depende de él [2026-09-13](#2026-09-13--lecciones-5-a-8) |

## 2026-09-13 — Lección 12

- Los ejemplos de la lección 12, sus equivalentes en C# y tres fragmentos que no compilan se ejecutan en CI en Windows, Linux y macOS; el proyecto principal tiene ahora 123 pruebas. Todas las llamadas HTTP van a un servidor local, el `HttpServer` del JDK en el lado Java y `HttpListener` en el lado C#, así que la salida no depende de la red.
- El proyecto C# tenía `InvariantGlobalization` activado. La lección 12 necesita las zonas horarias IANA y culturas con nombre, así que ICU está ahora activado, y `Program.cs` fija la cultura actual en la cultura invariable. Las salidas de las lecciones 2 a 9 no cambiaron.

**Sorpresas viniendo de C#:**

- El `HttpClient` de Java no sigue las redirecciones ni tiene timeout de petición salvo que se configuren. Al portar código .NET se obtiene un 302 con el cuerpo vacío, o una llamada que puede esperar para siempre.
- Para una hora local que ocurre dos veces, `ZonedDateTime` elige el desfase del horario de verano y `TimeZoneInfo.GetUtcOffset` el estándar: una hora de diferencia.
- `YYYY` en un patrón de fecha de Java imprimió 2027 para el 31 de diciembre de 2026 con `Locale.US`, y 2026 con `Locale.FRANCE`.
- `Files.readString` lanza una excepción ante UTF-8 inválido, donde `File.ReadAllText` sustituye el byte.
- Un primer programa de prueba imprimió `héllo`, leído de un archivo UTF-8, como `h�llo` en Git Bash en Windows, aunque el archivo era correcto. JEP 400 deja `System.out` con la codificación de la consola; *por verificar*: qué codificación eligió Java en ese terminal.

**Lo que hice mal al principio:**

- El primer programa de prueba en C# se ejecutó con `InvariantGlobalization` activado. `FindSystemTimeZoneById("Europe/Paris")` lanzó `TimeZoneNotFoundException` en Windows, y `new CultureInfo("fr-FR")` lanzó «Only the invariant culture is supported in globalization-invariant mode.»
- El primer programa de prueba en Java formateaba los números con la configuración regional por defecto, que es `en_CA` en mi máquina y otra distinta en los runners de CI. Los ejemplos pasan ahora un `Locale` allí donde la salida depende de uno.

## 2026-09-13 — Lección 11

- La lección 11 tiene su propio proyecto Maven, [`l11`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/l11), con 24 pruebas. Los mensajes de fallo que cita la lección los produce `FailureMessagesTest` y se comparan con archivos de texto, así que una actualización de biblioteca que cambie un mensaje hace fallar el build. `l11/check.sh` cubre el resto: los nombres de las pruebas, la advertencia de Mockito sin el agente, el fallo de BlockHound sin su opción de la JVM y los errores de NullAway.
- La pregunta abierta de la lección 5 sobre JSpecify y NullAway tiene respuesta en esta lección: NullAway 0.14.1 sobre Error Prone 2.50.0 funciona en JDK 25.

**Sorpresas viniendo de C#:**

- El conflicto de la lección 10 apareció solo en este proyecto. Mockito 5.23.0 pide Byte Buddy 1.17.7, AssertJ 3.27.7 pide la 1.18.3, y la regla de la definición más cercana de Maven puso Byte Buddy 1.18.3 junto a `byte-buddy-agent` 1.17.7. Funciona de casualidad, porque el camino de AssertJ es más corto y trae la versión más nueva.
- JUnit 6 entrecomilla los valores CSV en los nombres de las pruebas parametrizadas, números incluidos, porque los valores siguen siendo cadenas cuando se construye el nombre.
- Los informes de Surefire ignoran `@DisplayName` salvo que se configure una opción del reporter, y su salida de consola atribuyó las nueve pruebas de `PriceCalculatorTest` a su clase anidada.
- Con Mockito cargado como agente, la JVM sigue imprimiendo «Sharing is only supported for boot loader classes because bootstrap classpath has been appended». La lección no lo cita; *por verificar*: si `-Xshare:off` es la forma correcta de silenciarlo.
- BlockHound 1.0.17 necesita `-XX:+AllowRedefinitionToAddDeleteMethods`, una opción de la JVM obsoleta desde JDK 13, e informa de `Thread.sleep` como `java.lang.Thread.sleepNanos0`, el método privado del JDK que instrumenta.

**Lo que hice mal al principio:**

- La primera ejecución de NullAway falló con «An unknown compilation problem occurred». El error real, un `IllegalAccessError` sobre la API interna de javac, solo apareció con `mvn -e`. Error Prone necesita `.mvn/jvm.config` con líneas `--add-exports`.
- Primero instalé BlockHound con `BlockHound.install()`, como hace su README. En JDK 25 falló con «Could not self-attach to current VM using external process», y con `-Djdk.attach.allowAttachSelf=true` falló con «Agent JAR loaded but agent failed to initialize». Solo funcionó `-javaagent` junto con la opción.
- Mi primer borrador hacía corresponder `MockBehavior.Strict` de Moq con los stubs estrictos de Mockito. Comprueban cosas distintas: Moq falla ante una llamada sin setup, Mockito ante un stub que nunca se usa.
- Primero escribí que C# señala el unboxing de un nullable con la advertencia CS8629. Convertir un `int?` en `int` sin cast directamente no compila (CS0266); CS8629 es para `.Value` sobre un `int?` posiblemente nulo.

## 2026-09-13 — Lección 10

- La lección 10 se prueba de otra manera: [`l10/check.sh`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/l10/check.sh) ejecuta los builds de Maven, Gradle y NuGet, y la CI compara 14 archivos de salida con los que cita la lección. El script tarda unos tres minutos en mi máquina, casi todo en el arranque de Maven y Gradle.
- Maven 4: la página de descargas ofrece la 4.0.0-rc-6 como versión preliminar (preview) y la 3.9.x como versión actual, lo que por ahora responde a la pregunta abierta de más abajo.

**Sorpresas viniendo de C#:**

- Maven puso Commons Lang 3.14.0 en el class path cuando una biblioteca del build necesitaba la 3.20.0, sin ninguna advertencia, y el programa solo falló en tiempo de ejecución con `NoClassDefFoundError`. Hace falta `-Dverbose` incluso para ver que se había pedido otra versión.
- Un `implementation("…:3.14.0")` directo en Gradle no degrada nada: es un candidato más, y la 3.20.0 sigue ganando. Solo `strictly` lo fuerza.
- NuGet fue el más estricto de los tres: su advertencia de degradación, NU1605, es un error por defecto.
- `failOnVersionConflict()` dejó que `compileJava` funcionara, porque el conflicto solo existe en el class path de ejecución cuando la otra versión llega a través de una dependencia `implementation`.

**Lo que hice mal al principio:**

- Mi primer build de Gradle compartía sus ajustes con `subprojects { }` en el script raíz. La documentación de Gradle lo llama «an improper way to share build logic»; el ejemplo usa ahora un plugin de convenciones en `buildSrc`.
- La primera ejecución de `mvn install` puso los módulos del ejemplo en mi repositorio local (`~/.m2`). El script compila ahora en el reactor con `package`, que no necesita instalación, y borré las copias instaladas.
- `dotnet list package` imprime mensajes de restauración cuya redacción depende de lo que ya está restaurado, así que el script de comprobación los filtra.
- Mi tabla de resumen decía al principio que Maven no tenía equivalente de `PrivateAssets="all"`, mientras que la tabla de ámbitos, dos secciones más abajo, lo hacía corresponder con `<optional>true</optional>`. La tabla de resumen coincide ahora.

## 2026-09-13 — Lección 9

- El proyecto tiene ahora 113 pruebas: 63 fragmentos rechazados, 26 salidas de ejemplos y 24 soluciones de ejercicios. Los ejemplos de la lección 9 arrancan más de 14.000 hilos virtuales (10.000 tareas que duermen y 4.600 tareas cortas), y el `ExamplesTest` completo sigue ejecutándose en menos de 3 segundos en mi máquina.
- Los ejemplos concurrentes necesitan una salida determinista para poder probarse. Cada uno imprime solo resultados que no dependen de la planificación: totales, listas recolectadas y el orden que imponen los latches.

**Sorpresas viniendo de C#:**

- `CompletableFuture.cancel(true)` no interrumpe la tarea: el Javadoc dice que el argumento «has no effect in this implementation». El future indica que está cancelado mientras su tarea sigue ejecutándose.
- Un `value++` con carrera desde 1.000 tareas de 1.000 incrementos imprimió 76.422, luego 855.000 y luego 803.000. La primera ejecución perdió más del 90 % de las actualizaciones, probablemente antes de que el JIT compilara el bucle: *por verificar*.
- Sincronizar sobre un `Integer` compila. La única señal de problema es una advertencia de lint, en una categoría que Java 25 llama `[identity]`.
- `ScopedValue` no llega a las tareas de un executor normal; solo lo heredan los hilos bifurcados por `StructuredTaskScope`, que sigue en preview. `AsyncLocal` fluye a todas partes.

**Lo que hice mal al principio:**

- El primer ejemplo `Futures` cancelaba una tarea de cinco segundos con `CompletableFuture.cancel(true)`, y el ejemplo tardaba cinco segundos: el `close()` del executor esperaba a la tarea que nunca se interrumpió. Eso pasó a formar parte de la lección, con una tarea de un segundo.
- La línea «interrupted» del worker y la línea «cancelled» de `main` las imprimían dos hilos distintos, así que su orden era una carrera. Un segundo latch lo arregla.
- En el lado C#, primero leí un `ThreadLocal` dentro de `Task.Run` después de un `await`. La continuación se ejecuta en un hilo del pool, y `Task.Run` podía reutilizar ese mismo hilo, así que la salida no estaba garantizada. La comparación usa ahora un `Thread` dedicado.
- Primero comprobé qué hilo ejecutaba un stream paralelo de un solo elemento. Eso dependía de un detalle de implementación; el ejemplo registra ahora todos los hilos que participan en uno grande.

## 2026-09-13 — Lecciones 5 a 8

- El lado C# cubre ahora todas las lecciones: `dotnet run -- l05` a `l08` imprimen el comportamiento de .NET con el que se compara cada lección.
- El proyecto tiene 98 pruebas: 56 fragmentos rechazados, 21 salidas de ejemplos y 21 soluciones de ejercicios.

**Sorpresas viniendo de C#:**

- Cuando el cierre de un recurso falla después de que haya fallado el cuerpo, Java conserva la excepción del cuerpo y le adjunta la otra como *suprimida* (suppressed). El `using` de C# pierde la original: el lado C# imprime `dispose failed: db` en lugar de `query failed on db`.
- `throw e` conserva la traza de pila en Java, porque la traza se captura al crear la excepción. El analizador de C# advierte sobre la misma línea (CA2200).
- Dos evaluaciones de `display::onPrice` producen dos objetos distintos, así que eliminar un listener con una referencia a método nueva no hace nada, sin avisar. Los delegados de C# se comparan como iguales.
- `Map.of(…)` itera en un orden distinto de un arranque de la JVM a otro: cuatro ejecuciones de la misma línea dieron dos órdenes.
- Una expresión `switch` sobre una interfaz sellada que omite un subtipo es un error de compilación, mientras que C# solo advierte (CS8509).
- Los patrones primitivos (`case byte b` sobre un `int`) siguen en preview en Java 25; javac lo dice y sugiere `--enable-preview`.

**Lo que hice mal al principio:**

- La primera captura de la salida esperada del lado C# para la lección 7 incluía una advertencia del analizador, porque `dotnet run` recompiló el proyecto e imprimió la advertencia en la salida estándar. Los archivos esperados se generan ahora con `dotnet run --no-build`, como en la CI.
- `IntSummaryStatistics.toString()` y `printf("%.2f")` formatean los números con la configuración regional por defecto, así que la salida depende de la máquina: `2.200000` aquí, `2,200000` con una configuración regional francesa. La lección 7 imprime ella misma los campos y la lección 8 pasa `Locale.ROOT`. Los ejemplos `Enums` y `Shapes` de la lección 3 siguen usando la configuración regional por defecto: *por verificar* en una máquina con configuración regional francesa.
- Recordaba el error de C# para un brazo de switch dominado como CS8120. Ese código corresponde a las sentencias `switch`; una expresión switch informa de CS8510.
- `reduce(UnaryOperator.identity(), (f, g) -> f.andThen(g))` no compila: `andThen` devuelve una `Function`, no un `UnaryOperator`. El ejercicio 1 de la lección 6 explica por qué.

## 2026-09-13 — Lecciones 1 a 4

- Herramientas en mi máquina: OpenJDK `25+36`, Maven 3.9.16, Gradle 9.7.1 y el SDK de .NET 10 para el lado C#. La CI usa Eclipse Temurin 25 en Windows, Ubuntu y macOS.
- El código del curso está en [`code/java-for-csharp`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp):
  - una prueba JUnit compara la salida de cada ejemplo con la lección;
  - cada fragmento rechazado se compila mediante la API [`javax.tools`](https://docs.oracle.com/en/java/javase/25/docs/api/java.compiler/javax/tools/package-summary.html) y debe producir la clave de diagnóstico de javac que cita la lección (por ejemplo `compiler.err.not.exhaustive`) — el equivalente Java de los códigos `E0xxx` de Rust;
  - las soluciones de los ejercicios son pruebas;
  - un pequeño programa .NET 10 imprime el lado C# de cada comparación.

**Sorpresas viniendo de C#:**

- `Integer a = 128, b = 128; a == b` es `false`, pero con 127 es `true`. El rango de la caché, de −128 a 127, no es un detalle de implementación: lo exige la JLS.
- `java -jar` sobre un JAR de Maven recién construido falla con `no main manifest attribute`. Nada en `dotnet build` te prepara para un artefacto que no conoce su propio punto de entrada.
- Un `enum` de C# acepta `(Size)42`; un enum de Java no puede contener un valor que no declara. Los enums de Java se parecen mucho más a un conjunto sellado de objetos singleton.
- Los mensajes de error de javac a veces son indirectos: crear una clase interna desde un método estático da `non-static variable this cannot be referenced from a static context`.

**Lo que hice mal al principio:**

- En un comentario de código describí `final var` como «una variable local readonly de C#». C# no tiene variables locales readonly. El comentario ahora lo dice.
- Esperaba que `javac -XDrawDiagnostics` y la API del compilador informaran de la misma clave de diagnóstico. No siempre es así: al añadir a una `List<? extends Number>`, la línea de comandos informa de `compiler.err.cant.apply.symbols`, mientras que la API informa de la versión simplificada `compiler.err.prob.found.req`. Las pruebas usan la API, así que las lecciones citan lo que ve la API.
- Varias lecciones mostraban al principio un extracto de un fragmento rechazado junto a un mensaje de error cuyo número de línea se refería al archivo completo. Ahora las lecciones muestran el archivo completo.
- El signo `‰` de un ejemplo aparecía como `�` en la consola de Windows. El ejemplo ahora escribe «per mille».

## Casos prácticos en mis repositorios

Cada caso aplica una lección a un repositorio público, en un commit fijado.

### GuitarAlchemist/ga — el build del plugin de JetBrains (lección 1)

[`jetbrains-plugin/`](https://github.com/GuitarAlchemist/ga/tree/5560b883/jetbrains-plugin) en `ga@5560b883` es un proyecto Gradle con Kotlin DSL (el propio plugin está escrito en Kotlin). Lo copié e intenté compilarlo en esta máquina.

- **El wrapper está incompleto.** Solo está versionado `gradle/wrapper/gradle-wrapper.properties`. Faltan `gradlew`, `gradlew.bat` y `gradle-wrapper.jar`, así que `./gradlew` no existe y cada colaborador necesita tener instalado un Gradle compatible. `gradle wrapper` regenera los tres archivos, que deberían versionarse.
- **Gradle 8.5 no puede ejecutarse sobre JDK 25.** Con el Gradle 8.5 fijado y JDK 25, `gradle help` falla con un mensaje de una sola palabra:

  ```text
  * What went wrong:
  25
  ```

  La traza de pila muestra una `java.lang.IllegalArgumentException: 25` lanzada mientras Gradle compila el script de build en Kotlin: el compilador de Kotlin integrado en esa versión de Gradle no conoce Java 25. La solución es o bien un JDK que Gradle 8.5 admita, o bien un Gradle más reciente; la [matriz de compatibilidad de Gradle](https://docs.gradle.org/current/userguide/compatibility.html) indica qué versión de Gradle funciona con qué Java.
- **Actualizar solo Gradle no basta.** Con Gradle 9.7.1 el build avanza más y falla en el antiguo plugin `org.jetbrains.intellij` 1.16.1:

  ```text
  class org.jetbrains.intellij.MemoizedProvider overrides final method org.gradle.api.internal.provider.AbstractMinimalProvider.toString()Ljava/lang/String;
  ```

  Ese plugin fue sustituido por el [IntelliJ Platform Gradle Plugin 2.x](https://plugins.jetbrains.com/docs/intellij/tools-intellij-platform-gradle-plugin.html), que usa un DSL distinto. Migrar es un cambio real, no una simple subida de versión.
- **La carpeta de caché de Gradle está versionada.** Doce archivos bajo `jetbrains-plugin/.gradle/` (archivos de bloqueo, sumas de comprobación, `last-build.bin`) están en el repositorio, el equivalente en Gradle a versionar `obj/`. Su sitio es el `.gitignore`.
- **Destino de Java sin toolchain.** El script define `sourceCompatibility = "17"` en cada tarea `JavaCompile` en lugar de un bloque `java { toolchain { … } }`, así que el JDK que se usa depende de la máquina que ejecuta Gradle — justo la variabilidad que describe la nota sobre toolchains de la lección 1.

Siguiente paso, *por verificar*: generar el wrapper, migrar al plugin 2.x y comprobar que el plugin sigue cargando en una versión actual de IntelliJ IDEA.

### spareilleux/learn — el ejemplo Spring Boot del curso de WSL (lección 1, ejercicio 2)

[`code/wsl-containers/java-reactor-api`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/java-reactor-api) no tiene ninguna configuración de `maven-jar-plugin` y, sin embargo, `java -jar target/app.jar` funciona. Compilarlo muestra por qué:

```text
Main-Class: org.springframework.boot.loader.launch.JarLauncher
Start-Class: dev.learn.reactorapi.JavaReactorApiApplication
```

El `spring-boot-maven-plugin` reempaqueta el JAR: la `Main-Class` del manifiesto es el lanzador de Spring Boot, que lee `Start-Class` y carga los 62 JAR de dependencias anidados bajo `BOOT-INF/lib/` (35 MB en total). Responde a las dos mitades del ejercicio 2 — el punto de entrada que falta y las dependencias que faltan. El elemento `<parent>` (`spring-boot-starter-parent`) explica también por qué el POM no indica versiones de plugins ni de dependencias: hace el papel de `Directory.Packages.props` y de los valores por defecto del SDK. La lección 10 vuelve sobre ello.

## Preguntas abiertas

- ¿Merece ya la pena enseñar Maven 4? El 2026-09-13 sigue siendo una versión candidata (4.0.0-rc-6); volver a mirarlo cuando la 4.0.0 sea definitiva.
- ¿Cómo se comparan las inspecciones de IntelliJ IDEA con `-Xlint:all` de javac para las trampas de las lecciones 2 y 3?
