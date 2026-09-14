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
- [ ] Lección 9 — Concurrencia e hilos virtuales
- [ ] Lección 10 — Maven y Gradle a fondo
- [ ] Lección 11 — Pruebas
- [ ] Lección 12 — La biblioteca estándar del día a día
- [ ] Lección 13 — La JVM en tiempo de ejecución
- [ ] Lección 14 — Anotaciones, reflexión y módulos

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

- ¿Merece ya la pena enseñar Maven 4, dado que la mayoría de los proyectos siguen usando la 3.9? *Por verificar*: su estado de publicación.
- ¿Cómo se comparan las inspecciones de IntelliJ IDEA con `-Xlint:all` de javac para las trampas de las lecciones 2 y 3?
