---
title: Escuchar y examinar el movimiento paralelo en dos cuerdas de guitarra
description: Escuchar y examinar el movimiento paralelo en dos cuerdas de guitarra — Estudios de guitarra
sidebar:
  label: GTR-004 · Escuchar y examinar el movimiento paralelo en dos cuerdas de guitarra
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/es/gtr-004-hear-and-audit-parallel-motion.es.md
---

:::note[Streeling University]
**GTR-004** · Escuchar y examinar el movimiento paralelo en dos cuerdas de guitarra · intermedio · 35 minutos

Generado por el departamento *Estudios de guitarra* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/es/gtr-004-hear-and-audit-parallel-motion.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GTR-003](../../guitar-studies/gtr-003-audit-voicing-playability/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/voicing-learning-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Estudios de Guitarra** | Nivel: intermedio | Etapa: Albedo | Duración: 35 minutos | Borrador español; revisión pendiente

## Objetivos

Después de esta lección podrá convertir un pequeño conjunto de datos de dos cuerdas de guitarra en alturas de notas, predecir cuándo el analizador de progresiones de GA señala quintas paralelas, distinguir ese informe de un juicio sobre sonido o comodidad y realizar una prueba de ejecución repetible. También identificará un caso que el algoritmo de correspondencia entre cuerdas no evalúa.

## La pregunta del proyecto

[GAA-004](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/) enseña a examinar una disposición candidata; [GTR-003](../../guitar-studies/gtr-003-audit-voicing-playability/) separa la geometría de los trastes de la comodidad del intérprete. Una progresión añade otra pregunta: **¿qué cambia entre dos disposiciones sucesivas?** El [`ProgressionVoiceLeadingAnalyzer`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingAnalyzer.cs) de GA en la revisión fijada detecta un patrón definido de quintas justas u octavas paralelas entre notas tocadas emparejadas por cuerda. Su [`ProgressionVoiceLeadingReport`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingReport.cs) registra problemas y expone indicadores. Estos enlaces y las demás fuentes de GA fijan el commit `dc2e74cbd992a298f67efb928b5b3754615e1924`.

El código puede determinar si se cumplen sus propias condiciones. No puede oír la articulación del intérprete, inferir una voz musical independiente que cambia de cuerda ni decidir si el movimiento paralelo es deseable en un género. Esta lección utiliza un **nuevo conjunto sintético de trastes** construido a partir de la [afinación de guitarra predeterminada de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs), no una respuesta capturada del generador. Es físicamente posible pisar y pulsar las posiciones indicadas, pero aquí no se afirma que nadie las haya ejecutado. El informe previsto se deriva del código fuente fijado, no de una medición con el analizador en ejecución.

## 1. Definir las cuerdas y las notas

La afinación predeterminada de GA es `E2 A2 D3 G3 B3 E4`, ordenada de grave a agudo en `Tuning.Default`; los números de cuerda del analizador siguen el sentido contrario, desde 1 para el E agudo hasta 6 para el E grave. Nuestra pareja utiliza la **cuerda 4**, D3 al aire, y la **cuerda 3**, G3 al aire. En el cálculo de notas MIDI, D3 es 50 y G3 es 55. Cada traste positivo eleva la nota al aire un semitono. Solo haremos sonar estas dos cuerdas y silenciaremos las demás.

| Díada | Cuerda 4 (cuerda D) | Cuerda 3 (cuerda G) | Propósito |
|---|---|---|---|
| A | traste 2: E3, MIDI 52 | traste 4: B3, MIDI 59 | pareja inicial |
| B | traste 4: F♯3, MIDI 54 | traste 6: C♯4, MIDI 61 | ambas voces suben |
| C | traste 4: F♯3, MIDI 54 | traste 2: A3, MIDI 57 | las voces se mueven en sentidos opuestos |

Son **díadas**, no afirmaciones de que GA haya generado una progresión de acordes con nombre. Anote ambos números de traste y ambas alturas en cualquier registro de la prueba. Un nombre aislado como «A a B» no permitirá reproducir el ejercicio si se separa del cuadro. Si su guitarra no está en la afinación predeterminada de GA, reafínela con cuidado o calcule otro conjunto de datos e indique las alturas reales de las cuerdas al aire; la clave de respuestas siguiente supone D3 y G3.

### Ejercicio 1 — Convertir trastes en alturas

Partiendo de D3 = MIDI 50 y G3 = MIDI 55, calcule las dos notas de A y B. ¿Qué cuerda produce la nota más aguda en cada díada?

> **Respuesta:** A da cuerda 4: `50 + 2 = 52` (E3), cuerda 3: `55 + 4 = 59` (B3). B da cuerda 4: `50 + 4 = 54` (F♯3), cuerda 3: `55 + 6 = 61` (C♯4). La cuerda 3 es más aguda en ambos casos. Estos cálculos suponen afinación estándar y un semitono por traste; no son una observación de una ejecución.

## 2. Calcular la prueba de intervalos del código fuente

El analizador construye una correspondencia entre cada **número de cuerda tocada** y su nota MIDI suministrada. Obtiene la intersección de las claves de cuerda de ambas correspondencias. Si menos de dos cuerdas aparecen en las dos disposiciones, no devuelve problemas para esa transición. En caso contrario, comprueba cada pareja de cuerdas compartidas. Para una pareja, primero pregunta si ambas notas MIDI se desplazan y lo hacen en el mismo sentido. Después calcula `abs(noteB - noteA) % 12` antes y después. Un valor de `7` en ambos casos produce un problema `Fifths`; un valor de `0` en ambos produce un problema `Octaves`. La clase `0` incluye intervalos equivalentes a la octava, así que hay que interpretar esa etiqueta con cuidado cuando las notas reales están al unísono.

En A, `59 - 52 = 7` semitonos. En B, `61 - 54 = 7`. Hay una pareja compartida, las cuerdas 3 y 4, y ninguna nota está silenciada. Esto satisface la parte de intervalos de la prueba de quintas. La operación módulo del código indica que comprueba una clase de intervalo, sin realizar un análisis armónico o estilístico completo. Para el ejercicio físico, los valores MIDI deben corresponder a los trastes y la afinación reales, pero el analizador utiliza los valores MIDI suministrados. La distinción importa porque quien lo invoca podría proporcionar posiciones y notas incoherentes.

Las [pruebas unitarias](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.Core.Tests/Fretboard/Voicings/ProgressionVoiceLeadingAnalyzerTests.cs) de la revisión fijada cubren quintas y octavas detectadas, movimiento contrario y oblicuo, una progresión de tres acordes y entradas vacías o de un solo elemento. Su función auxiliar construye posiciones tocadas en el traste cero con números MIDI elegidos; son datos de prueba del algoritmo, no ejemplos que necesariamente concuerden con la afinación de guitarra. El cuadro de trastes de esta lección es un conjunto didáctico distinto y físicamente coherente. Las pruebas son evidencia guardada en el código fuente, no una nueva ejecución de pruebas para este curso.

### Ejercicio 2 — Comprobar ambos intervalos

Calcule la clase de intervalo del código para A y B: `abs(string 3 MIDI - string 4 MIDI) % 12`. ¿Bastaría la condición de intervalo por sí sola para señalar quintas paralelas?

> **Respuesta:** En A, `abs(59 - 52) % 12 = 7`; en B, `abs(61 - 54) % 12 = 7`. Se cumple la condición de intervalo. El analizador también debe encontrar las mismas dos cuerdas tocadas en ambas disposiciones y verificar que ambas notas se desplazaron en el mismo sentido, con un desplazamiento distinto de cero.

## 3. Comparar movimientos, no solo dos instantáneas

De A a B, la cuerda 4 se mueve `52 → 54`, una subida de dos semitonos. La cuerda 3 se mueve `59 → 61`, también una subida de dos. Con dos cuerdas compartidas, ambos desplazamientos positivos e intervalos `7 → 7`, el algoritmo fijado predice **un problema `Fifths`**. En el informe, `HasParallelFifths` sería verdadero e `IsClean` falso para una progresión de dos disposiciones formada por objetos `Voicing` coherentes con este cuadro. Aquí no hemos construido ni ejecutado esos objetos; es una predicción derivada del código fuente.

Compare ahora A con C. La cuerda 4 sigue moviéndose `52 → 54`, pero la cuerda 3 se mueve `59 → 57`, una bajada de dos. Las direcciones difieren y el intervalo de llegada es `abs(57 - 54) = 3`. Por tanto, esta transición no es una quinta paralela según el detector. **No** conserva la misma armonía de llegada que B. No considere C musicalmente mejor solo porque evita ese indicador. En la música real, los intervalos justos paralelos pueden ser intencionados, y una alternativa en movimiento contrario puede cambiar el acorde o la melodía. El ejercicio pide la clasificación del informe, no una regla universal de composición.

### Ejercicio 3 — Predecir el informe de A→B

Indique ambos desplazamientos y el indicador de quintas del informe para una progresión ordenada `[A, B]` representada con las dos cuerdas tocadas y las notas MIDI del cuadro. ¿Cuántos problemas de quintas puede aportar esta pareja de dos cuerdas?

> **Respuesta:** La cuerda 4 sube `52 → 54` (+2); la cuerda 3 sube `59 → 61` (+2). Ambos intervalos son de 7 semitonos, así que el analizador predice `HasParallelFifths = true` e `IsClean = false`. Hay una pareja de cuerdas compartidas, por lo que aporta un problema `Fifths`.

### Ejercicio 4 — Predecir la alternativa con cuidado

Para `[A, C]`, indique las direcciones, el intervalo final y el valor previsto de `IsClean`. ¿Es C un destino intercambiable con B?

> **Respuesta:** La cuerda 4 sube 2; la cuerda 3 baja 2. El intervalo de C es `57 - 54 = 3` semitonos. El código omite las parejas con desplazamientos en sentidos opuestos, de modo que este conjunto de dos díadas predice `IsClean = true`. C difiere de B en su nota superior y su armonía de llegada; no es un sustituto musical intercambiable solo porque el detector no señale problemas.

## 4. Tocar una transición cuyo éxito pueda refutarse

Si tiene una guitarra en afinación estándar, haga sonar A solo en las cuerdas 4 y 3. Pulse cada nota por separado y después ambas juntas. Pase a B y repita. Use un metrónomo lento a **60 pulsos por minuto**: toque A en un pulso, muévase y haga sonar B en el siguiente, dejándolo resonar durante un pulso. Realice diez intentos A→B. Registre las dos alturas de llegada, con un afinador o una grabación comprobada nota por nota, si cada nota sonó con claridad durante el pulso y si sonaron cuerdas no deseadas. Defina un intento correcto como **ambas notas de llegada en las alturas esperadas y resonando con claridad durante todo el pulso de llegada**. Fije antes un umbral de práctica de 8 aciertos de 10; informe el numerador observado aunque sea menor que ocho. Deténgase si le duele la mano. Este umbral es un criterio de clase, no una puntuación del modelo GA ni una norma validada para una población.

La prueba puede fallar: una afinación incorrecta, una nota superior silenciada o que trastea, una tercera cuerda involuntaria o menos de ocho díadas de llegada correctas refutan «hoy cumplí el objetivo de práctica declarado». Si no dispone de una herramienta para medir la altura, escriba «altura no comprobada de forma independiente» y mantenga aparte el recuento de notas claras. No se han registrado intentos físicos para este borrador. Una clave de respuestas no puede sustituir las observaciones del alumno. Compare el sonido de A→B con el de A→C como propuesta de escucha, sin afirmar que uno tenga que sonar mejor.

## 5. Entender lo que omite un informe sin problemas

La lista de problemas del analizador solo contiene patrones que puede detectar según su regla de correspondencia entre cuerdas. Imagine A seguido de una nueva díada D tocada en las cuerdas 4 y 2, con la cuerda 3 silenciada. Solo la cuerda 4 es compartida con A. El detector no devuelve problemas antes de comparar intervalos porque necesita al menos dos cuerdas tocadas compartidas. En ese informe, `IsClean` significa `Issues.Count == 0`, sin garantizar que la progresión tenga buen contrapunto, sea fácil de tocar o carezca de sonidos no deseados. Un músico podría oír una voz que continúa de la cuerda 3 a la 2, pero este algoritmo no sigue esa continuidad entre cuerdas.

La misma distinción se aplica a una entrada de un solo acorde. `Analyze` devuelve un informe sin problemas cuando se proporcionan menos de dos disposiciones; no hay transición que examinar. Una lista vacía debería mostrarse como «no se ha detectado ningún patrón definido de quintas u octavas paralelas en las correspondencias entre cuerdas analizadas», dejando visible el alcance de la entrada. Trate el informe como un diagnóstico limitado junto al juicio musical, en lugar de una calificación completa de la conducción de voces.

### Ejercicio 5 — Examinar la comparación que falta

Partiendo de A en las cuerdas 4 y 3, suponga que D toca solo las cuerdas 4 y 2. ¿Cuántas claves de cuerda se comparten, qué devuelve el analizador para A→D y qué no permite establecer ese resultado?

> **Respuesta:** Solo se comparte la cuerda 4, así que hay una clave común de cuerda tocada. El detector no devuelve problemas antes de evaluar una pareja de intervalos y el informe resultante tiene `IsClean = true`. Esto no establece que las voces que suenan carezcan de movimiento paralelo entre cuerdas, que la transición sea cómoda ni que sea musicalmente preferible.

## Evidencia, límites y próxima comprobación

Las predicciones anteriores siguen el [analizador](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingAnalyzer.cs), el [informe](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingReport.cs), la [afinación](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs) y el [código de las pruebas](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.Core.Tests/Fretboard/Voicings/ProgressionVoiceLeadingAnalyzerTests.cs) de GA en la revisión fijada. Los arreglos didácticos de trastes y las notas MIDI se construyeron para este curso; no son salidas capturadas de GA. No se afirma que haya habido una ejecución del analizador, una grabación de un alumno, una evaluación de un tutor ni una nueva ejecución de pruebas C#. El código usa las cuerdas de guitarra como identificadores de voces, utiliza clases de intervalo módulo doce y no mide calidad del sonido, precisión rítmica, esfuerzo de la mano ni adecuación musical. Una próxima comprobación debería ejecutar estos objetos `Voicing` exactos y coherentes en la versión fijada, conservar el informe y recoger el registro de los diez intentos de ejecución. Siguen pendientes la revisión temática por una persona, las pruebas con alumnos, la revisión lingüística y la publicación.
