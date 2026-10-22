---
title: Convertir un resultado de voicing en una pregunta de práctica
description: Convertir un resultado de voicing en una pregunta de práctica — Guitar Alchemist Academy
sidebar:
  label: GAA-007 · Convertir un resultado de voicing en una pregunta de práctica
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/es/gaa-007-turn-a-voicing-result-into-a-practice-item.es.md
---

:::note[Streeling University]
**GAA-007** · Convertir un resultado de voicing en una pregunta de práctica · early-intermediate · 40 minutos

Generado por el departamento *Guitar Alchemist Academy* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/es/gaa-007-turn-a-voicing-result-into-a-practice-item.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAA-004](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/), [COG-002](../../cognitive-science/cog-002-feedback-integrity-fretboard-recall/)
:::

> **Alcance del borrador.** Ejemplos didácticos de preguntas de guitarra, cálculos exactos de alturas y lectura de código y pruebas públicos fijados a una revisión. Quedan pendientes las revisiones humanas técnica, musical, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se ejecutaron una consulta de búsqueda, un formateador, un cuestionario ni una prueba con guitarra o estudiante.

## La pregunta del proyecto

GA puede proponer un voicing. ¿Qué debe cambiar antes de que el resultado se convierta en una pregunta de práctica comprobable? La [habilidad de voicings de la revisión fijada](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L130-L167) proporciona texto mostrado y campos estructurados de diagrama, nombre de acorde, instrumento y puntuación de recuperación. Son material útil para una lección; no son la respuesta de un estudiante, una política de revelación de respuestas ni una medición de aprendizaje.

[GAA-004](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/) compara propuestas de voicings con las necesidades de un guitarrista. Aquí definimos la pregunta y la regla de aceptación antes de puntuar nada. Las cuatro posiciones candidatas siguientes son casos didácticos, no resultados capturados devueltos por GA.

## 1. Elegir el objetivo antes de ocultar un campo

Considera dos tareas distintas. «Nombra el acorde representado por este diagrama» puede mostrar el diagrama, pero debe ocultar la respuesta con el nombre del acorde. «Da cualquier posición de tríada de C mayor con esta afinación» puede mostrar el nombre del acorde pedido, pero no debe presentar la posición de ejemplo como una respuesta de memoria. Una tercera tarea, «reproduce la posición abierta exacta de C que acabas de aprender», prueba deliberadamente una posición especificada previamente.

El mismo campo de nombre de acorde es una respuesta en la primera tarea y una pista prevista en las otras dos. Una instrucción universal de ocultar todas las etiquetas eliminaría información útil de la tarea. Una pregunta de práctica declara en cambio objetivo, pistas visibles, respuestas aceptadas y momento de revelación. Son campos propuestos de lección, no una API de preguntas implementada en GA.

### Ejercicio 1: clasificar una pista visible

¿Debe verse C mayor al pedir al estudiante que nombre un diagrama de C mayor ya etiquetado? ¿Debe verse al solicitar cualquier posición de tríada de C mayor? ¿Qué precisión adicional hace inequívoca una pregunta sobre una posición exacta?

> **Respuesta:** Ocúltalo cuando sea la respuesta a la tarea de nombrar. Consérvalo como objetivo solicitado en la tarea que acepta cualquier posición. Una tarea de posición exacta debe identificar explícitamente la posición aprendida previamente y su convención de orden de cuerdas; «cualquier C mayor» no especifica una única matriz de trastes.

## 2. Construir una clave a partir de coordenadas declaradas

En el commit `76efbffd5af82b46c3146957a6bd4504008eeb89`, el [formateador de diagramas](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L30-L39) documenta los diagramas almacenados con la cuerda aguda primero y las representaciones con la grave primero. Su ejemplo seleccionado de C abierto invierte el dato bruto `0-1-0-2-3-x` a la representación `x-3-2-0-1-0`. Los [casos de inversión incluidos en el repositorio](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Tests/Common/GA.Business.ML.Tests/Notation/PlayableNotationFormatterTests.cs#L37-L42) incluyen esa pareja. Leer aserciones no es una nueva ejecución de pruebas.

La habilidad formatea el resultado mostrado en orden de representación mientras su campo estructurado `diagram` conserva el valor bruto. Un consumidor debe identificar qué representación lee. Para la clave didáctica, declara afinación MIDI estándar de grave a agudo `[40,45,50,55,59,64]`, sin capo, trastes enteros de temperamento igual y exclusión de cuerdas silenciadas `x`. Las notas MIDI que suenan en la representación son `[48,52,55,60,64]`, o C3, E3, G3, C4, E4 bajo C4 = 60. Esta aritmética comprueba una respuesta propuesta, no si un músico puede ejecutarla limpiamente.

### Ejercicio 2: derivar la clave sonora

Invierte el ejemplo bruto al orden de representación y calcula su secuencia MIDI sonora bajo la afinación declarada. ¿Conservaría la misma asignación de cuerdas tratar el campo bruto estructurado como una representación ya formateada?

> **Respuesta:** La representación es `x-3-2-0-1-0`; sumar los trastes a las cuerdas al aire no silenciadas da `[48,52,55,60,64]`. Tratar el orden bruto como orden de representación asignaría sus símbolos a otras cuerdas y no conservaría la asignación. Conserva revisión del código, afinación, capo y orden con la clave.

## 3. Aceptar una respuesta según la pregunta

Usa estos candidatos didácticos de grave a agudo. El criterio restringido que acepta cualquier tríada exige todas y solo las clases de altura C, E y G, cada una presente al menos una vez; ignora registro y duplicaciones. No es una definición universal de todo voicing musical aceptable etiquetado C.

| Candidato | Representación | Clases de altura distintas, C = 0 | A exacta | Cualquier tríada de C mayor según el criterio restringido |
| --- | --- | --- | --- | --- |
| A | `x-3-2-0-1-0` | 0, 4, 7 | sí | sí |
| B | `x-3-5-5-5-3` | 0, 4, 7 | no | sí |
| C | `x-3-2-0-0-0` | 0, 4, 7, 11 | no | no |
| D | `x-3-2-0-1-x` | 0, 4, 7 | no | sí |

Un validador de matriz exacta rechazaría erróneamente B y D si la pregunta prometiera cualquier posición que cumpla el criterio declarado de tríada. Un validador solo de clases de altura aceptaría erróneamente B y D para la tarea de A exacta. El candidato C añade B y falla esta regla concreta de solo tríadas. Un ejercicio musical que permitiera extensiones necesitaría otra regla.

### Ejercicio 3: auditar la regla de aceptación

¿Qué candidatos pasan la tarea de A exacta y cuáles la tarea restringida de cualquier tríada? ¿Por qué ninguno de los conjuntos de aceptación demuestra que puedan tocarse físicamente ni que sean la única interpretación musicalmente útil?

> **Respuesta:** Solo A pasa A exacta. A, B y D pasan la regla restringida de tríada; C falla porque sobra la clase de altura 11. Son criterios simbólicos declarados. Digitación, duración del sonido, silenciamiento, sonido y otra petición armónica requieren comprobaciones separadas.

## 4. No convertir confianza de recuperación en probabilidad de recuerdo

La habilidad seleccionada asigna confianza de respuesta limitando la mejor puntuación de recuperación entre 0 y 1. Para las puntuaciones finitas didácticas -0.2, 0.8 y 1.2, la operación da 0, 0.8 y 1. No estima si un estudiante recordará un acorde mañana. Un número acotado y una probabilidad sobre un evento definido del estudiante son afirmaciones distintas.

El [registro de evaluación de consultas RAG](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs#L3-L31) describe particiones de consultas, recuentos de resultados, puntuaciones de recuperación y latencia. No es un resultado de retención. No cambies la etiqueta de ninguno de los dos al crear un panel de práctica.

### Ejercicio 4: interpretar una puntuación

Un resultado tiene puntuación de recuperación 0.8 y confianza de respuesta 0.8. ¿Puede una lección mostrar «80% de probabilidad de que lo recuerdes mañana»? Da los dos controles de limitación fuera de rango y la observación ausente.

> **Respuesta:** No. Las puntuaciones -0.2 y 1.2 se limitan a 0 y 1, pero limitar no aporta calibración del estudiante. Falta una respuesta diferida definida sin ayuda bajo una pista registrada y un protocolo de puntuación, además de pruebas que relacionen las predicciones con ese evento.

## 5. Separar un plan de un intento

Los [tipos de rutinas de práctica](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/PracticeRoutineTypes.fs#L81-L101) nombran precisión, tempo y otros objetivos o elementos de seguimiento. La [habilidad de catálogo de práctica](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/PracticeRoutineSkill.cs#L3-L16) proporciona una respuesta de plan estructurado. Ninguno de los dos límites inspeccionados aporta la observación real de respuesta antes de la retroalimentación de esta lección. Es una afirmación sobre fuentes seleccionadas, no de ausencia en todo el repositorio.

### Ejercicio 5: preparar un registro de pregunta comprobable

¿Qué debe conservar un futuro ejercicio además del voicing devuelto y su puntuación? ¿Qué pruebas adicionales hacen falta antes de llamar beneficio de aprendizaje a una pregunta completada?

> **Respuesta:** Conserva identidad de fuente y consulta, orden bruto y mostrado, instrumento, afinación y capo, objetivo, pistas permitidas, clave verificada, regla de aceptación, respuesta antes de revelar, ayuda, identidad y momento del intento. Registra una evaluación diferida real antes de afirmar retención y usa una comparación justificada antes de atribuir beneficio. Un plan, un clic o una puntuación por sí solos no aportan ninguno de esos resultados.

El [paquete fijado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/README.md) conserva la clave y los cálculos de aceptación. [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/) puntúa a continuación un historial de intentos deliberadamente sintético bajo un criterio de resultado explícito.
