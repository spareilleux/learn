---
title: Componer cálculos de GA con interrupción al primer fallo
description: Componer cálculos de GA con interrupción al primer fallo — Ciencias de la computación
sidebar:
  label: CS-010 · Componer cálculos de GA con interrupción al primer fallo
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-010-compose-fail-fast-ga-computations.es.md
---

:::note[Streeling University]
**CS-010** · Componer cálculos de GA con interrupción al primer fallo · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-010-compose-fail-fast-ga-computations.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-004](../../computer-science/cs-004-composable-agentic-audio-loop/)
:::

> **Alcance del borrador.** Experimento basado en el código fuente del proyecto, con entradas sintéticas. Siguen pendientes la revisión humana del contenido, la revisión por una persona con dominio del idioma y la revisión por un estudiante; no se afirma que se haya publicado el curso ni verificado su contenido mediante una lectura pública.

## Objetivos y pregunta para el proyecto

Componer un cálculo dependiente con las operaciones reales de `GaAsync` de GA, predecir qué funciones de retorno se ejecutan tras un error y distinguir la reasociación algebraica del permiso para reordenar efectos. **Pregunta para el proyecto:** ¿cómo puede una cadena de procesamiento de guitarra o de agentes conservar el motivo del fallo de un requisito previo e impedir que comience el trabajo que depende de él?

La fuente principal es el [módulo GaAsync de GA en `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs). Su tipo `GaAsync<'T>` es `Async<Result<'T, GaError>>`. Aquí `Result` es el [tipo result de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/results), y no el tipo independiente `Result<TValue,TError>` de GA en C#. Las [pruebas de clausuras existentes de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/GaClosureAndCeTests.cs) ya comprueban la propagación de errores tempranos y la transformación de errores. Esta lección ejecuta el módulo de F# directamente; no afirma que se haya ejecutado toda la suite de NUnit.

## 1. Separar una transformación de valor de un cálculo dependiente

En la revisión fijada, `ok x` crea un resultado asíncrono satisfactorio y `fail e` crea uno fallido. `map f` transforma un valor satisfactorio con una función ordinaria. `bind f` acepta una función que devuelve otro cálculo `GaAsync` y propaga su resultado. Ante un `Error`, ambas operaciones conservan ese error y omiten la función de retorno suministrada. Esta es una propiedad local del flujo de control de una composición; no es una política global de planificación de agentes.

El laboratorio comienza con 5. Su primera función enlazada duplica el valor, la segunda suma 1 y el map final da formato a una etiqueta. El resultado observado por el ejecutor es `Ok "ready:11"`; su traza es `["double"; "increment"]`. Estos valores aritméticos representan salidas de requisitos previos. No son frecuencias de guitarra, puntuaciones de calidad ni constancias de revisión aceptadas.

### Ejercicio práctico 1

Predice el resultado de las mismas funciones partiendo de 8. ¿Qué paso necesita `bind` y cuál puede usar `map`? Explica por qué dar formato a la etiqueta no debe confundirse con aprobar el resultado.

> **Respuesta:** La duplicación y el incremento dan 17, por lo que el formato produce `Ok "ready:17"`. Las funciones del laboratorio que devuelven `GaAsync` se componen con `bind`; la función ordinaria de formato puede usar `map`. Una etiqueta con formato es solo un valor. Ni su texto ni el éxito de un cálculo otorgan autoridad de revisión o publicación.

## 2. Conservar el primer fallo

El caso interrumpido comienza con `Error (DomainError "invalid-pitch")` y después compone las mismas funciones enlazadas. El resultado observado conserva exactamente ese error de dominio y la traza de funciones de retorno es `[]`. No se introduce ningún valor de sustitución satisfactorio. Así se mantiene visible la acción correctiva, en lugar de convertir un requisito previo fallido en un número plausible.

Importa una sutileza al leer el código fuente: construir un cálculo y ejecutarlo son operaciones distintas. `GaAsync` usa [flujos de trabajo asíncronos de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/async-expressions). Una función de retorno omitida por `bind` no es invocada por ese bind, pero los efectos producidos antes de construir la cadena ya han ocurrido. La traza mide estas funciones de retorno del escenario de prueba; no demuestra que una cadena cualquiera carezca de efectos externos.

### Ejercicio práctico 2

El primer requisito previo devuelve `DomainError "missing-artifact"`. La siguiente función de retorno carga un artefacto derivado. En esta cadena de `bind`, ¿se invoca esa función? ¿Se desharía una carga realizada antes de construir la cadena?

> **Respuesta:** Se omite la función de retorno y el error sigue siendo `DomainError "missing-artifact"`. Una carga anterior no se deshace. La composición con interrupción al primer fallo no ofrece una transacción ni compensación por los efectos externos a la función omitida.

## 3. Comprobar una ley con un experimento acotado

Para funciones puras con los tipos indicados, la asociatividad de bind compara `(m |> bind f) |> bind g` con `m |> bind (fun x -> f x |> bind g)`. Ambas expresiones mantienen el orden `f` y luego `g`; la reasociación no las intercambia. El laboratorio usa `validate`, que rechaza enteros no positivos, y `format`, que devuelve una etiqueta satisfactoria. Para las entradas 5 y -1, ambas formas coinciden, respectivamente, en `Ok "note:5"` y `Error (DomainError "nonpositive-note")`.

Dos ejemplos aportan evidencia para esos casos, no una demostración para todos los valores o todos los efectos secundarios. Tampoco pueden establecer equivalencia en tiempos, cancelación, reintentos o duración de los recursos. Una mejora útil al usar el propio proyecto consiste en escribir la predicción de un contraejemplo antes de modificar la cadena y conservar como evidencia una predicción que resulte refutada.

### Ejercicio práctico 3

Un colega sustituye `validate` seguido de `format` por `format` seguido de `validate` y cita la asociatividad. ¿Es la misma transformación? ¿Qué entrada concreta pone de manifiesto el problema?

> **Respuesta:** No. La asociatividad cambia la agrupación y conserva el orden; esta propuesta intercambia las operaciones e incluso cambia sus tipos de entrada. El caso original -1 devuelve el error de dominio antes del formato. Una expresión reordenada debe superar primero la comprobación de tipos y tener una semántica propia; las dos coincidencias del escenario de prueba no la justifican.

## 4. Añadir contexto sin convertir el fallo en éxito

El `mapError` del laboratorio transforma `DomainError "invalid-pitch"` en `DomainError "wrapped: DomainError: invalid-pitch"`. El caso satisfactorio `Ok 42` permanece igual y no llama a la función que transforma el error. Es una transformación explícita del canal de error. Debe conservar suficiente estructura para la siguiente acción correctiva; convertir repetidamente errores estructurados en prosa puede destruir campos útiles.

La envoltura textual de esta lección es deliberadamente pequeña. Un traspaso real entre agentes debería conservar la identidad del artefacto, su productor, la revisión y la categoría de error cuando sean relevantes. Es un requisito de diseño del proyecto que debe evaluarse en el límite correspondiente, no una función que proporcione este escenario textual.

### Ejercicio práctico 4

¿Sería `mapError` la operación adecuada para devolver una altura predeterminada satisfactoria tras una entrada ausente? Indica el comportamiento observado en la ruta de éxito y la información que necesitaría una decisión de recuperación.

> **Respuesta:** No. `mapError` cambia el valor del error y mantiene el resultado fallido. En el laboratorio, su ejemplo de la ruta de éxito sigue siendo `Ok 42` y no se invoca la función de transformación. La recuperación necesita una política explícita, una entrada de sustitución justificada y un registro del fallo original; es una operación distinta de añadir contexto al error.

### Ejercicio práctico 5

Escribe el resultado y la traza esperados para una cadena cuyo primer resultado es `Error (DomainError "stale-source")` y cuya única función enlazada registra `"publish"`. ¿Qué afirmación más amplia seguiría sin estar justificada si esta comprobación pasara?

> **Respuesta:** Se esperan el mismo error y una traza vacía de funciones de retorno. Superar ese caso solo establecería que este bind omite esa función para esa entrada. No demostraría una publicación sin condiciones de carrera, revisión humana, entrega duradera, seguridad de cancelación ni ausencia de efectos en otros lugares.

## Reproducir el experimento del proyecto

Usa el [laboratorio docente compartido](https://github.com/spareilleux/learn/blob/main/code/streeling/functional-composition/README.md), que carga una copia sin cambios del módulo de GA en la revisión fijada y conserva su licencia MIT. [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) ejecuta el laboratorio sin referencias a paquetes NuGet. Desde la raíz del repositorio Learn, el comando se escribe igual en Windows, Linux/WSL y macOS:

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

El autor observó el SDK `10.0.113` en Windows, código de salida 0, ningún aviso del compilador y 24 aserciones superadas. Queda por verificar el funcionamiento en los demás sistemas operativos. El [registro del experimento](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/functional-composition-2026-10-22/README.md) separa la procedencia de las entradas, la ejecución y la revisión. Son entradas sintéticas ejecutadas por el módulo real de la revisión fijada, no tráfico capturado de la aplicación GA. Lee el cuaderno del estudiante antes de abrir el ejecutor, que contiene las respuestas.

## Evidencia y siguiente comprobación

El módulo inmutable de GA y sus pruebas existentes establecen el caso de estudio basado en el código fuente; las observaciones registradas del laboratorio solo acreditan las entradas que ejecutó. No cuentes una revisión estática de IA como aprobación humana. Una persona revisora debería contrastar las afirmaciones con el código fuente de la revisión fijada; después, un estudiante debería intentar resolver el cuaderno separado con ayuda del código fuente antes de consultar las respuestas. La integración, el despliegue y la verificación pública anónima mediante lectura siguen siendo pasos independientes.
