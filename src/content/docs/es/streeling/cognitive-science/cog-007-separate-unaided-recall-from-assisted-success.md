---
title: Separar el recuerdo sin ayuda del éxito asistido
description: Separar el recuerdo sin ayuda del éxito asistido — Ciencia cognitiva
sidebar:
  label: COG-007 · Separar el recuerdo sin ayuda del éxito asistido
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-007-separate-unaided-recall-from-assisted-success.es.md
---

:::note[Streeling University]
**COG-007** · Separar el recuerdo sin ayuda del éxito asistido · intermedio · 40 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-007-separate-unaided-recall-from-assisted-success.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-002](../../cognitive-science/cog-002-feedback-integrity-fretboard-recall/), [COG-003](../../cognitive-science/cog-003-calibrating-fretboard-confidence/), [GAA-007](../../guitar-alchemist-academy/gaa-007-turn-a-voicing-result-into-a-practice-item/)
:::

> **Alcance del borrador.** Historial binario de intentos de un estudiante inventado, cálculos exactos de denominadores y lectura de fuentes primarias y código. Quedan pendientes las revisiones humanas técnica, musical, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se observaron un estudiante real, un flujo de práctica, un modelo de memoria ni una evaluación diferida.

## La pregunta del proyecto

Un informe de práctica de GA dice que seis de siete respuestas finales son correctas. ¿Significa que el estudiante recordó seis respuestas sin ayuda? Necesitamos el historial de eventos y el criterio de resultado declarado. [GAA-007](../../guitar-alchemist-academy/gaa-007-turn-a-voicing-result-into-a-practice-item/) define objetivo, política de pistas y regla de aceptación. Aquí todos los resultados binarios se crearon para la aritmética; ningún usuario proporcionó las respuestas.

El [resumen de Roediger y Karpicke publicado por el editor](https://www.psychologicalscience.org/journals/psychological-science/j.1467-9280.2006.01693.x/) informa de resultados inmediatos y diferidos distintos para el recuerdo de textos en sus condiciones estudiadas. Solo se leyó ese resumen; un intento de obtener el PDF completo alojado por el autor agotó el tiempo de espera. El estudio motiva nombrar el retraso de evaluación, pero no establece un efecto de aprendizaje de guitarra ni un programa universal de práctica. No se importa ningún tamaño de efecto del estudio a este paquete.

## 1. Contar primeras respuestas admisibles

Ofrece ocho preguntas de práctica a un estudiante ficticio. Siete tienen respuesta inicial. Tres respuestas iniciales son correctas, pero P03 tenía la respuesta visible antes de responder y no puede contar como recuerdo sin ayuda según nuestra regla. P08 no tiene respuesta. Las seis primeras respuestas observadas y admisibles restantes contienen dos correctas.

| Pregunta | Respuesta inicial | Respuesta visible de antemano | Respuesta posterior |
| --- | --- | --- | --- |
| P01 | correcta | no | ninguna |
| P02 | incorrecta | no | correcta tras pista |
| P03 | correcta | sí | ninguna |
| P04 | incorrecta | no | correcta tras pista |
| P05 | incorrecta | no | reintento incorrecto sin pista |
| P06 | correcta | no | ninguna |
| P07 | incorrecta | no | correcta tras pista |
| P08 | ausente | no | ninguna |

La tasa bruta de primeras respuestas es `3/7`; la tasa observada admisible de primeras respuestas sin ayuda es `2/6=1/3`. Excluir P03 protege el criterio declarado. No borra la exposición del historial ni convierte la ausencia de P08 en una respuesta incorrecta. [COG-002](../../cognitive-science/cog-002-feedback-integrity-fretboard-recall/) audita por separado la clave; una clave válida por sí sola no resuelve estas decisiones de ayuda y muestreo.

### Ejercicio 1: aplicar la regla de admisibilidad

Calcula las tasas bruta de primeras respuestas y observada admisible de primeras respuestas sin ayuda. Explica por qué tanto la respuesta correcta P03 como la ausente P08 necesitan estados distintos.

> **Respuesta:** Las primeras respuestas brutas dan `3/7`; quitar P03, con respuesta expuesta, deja `2/6=1/3` entre las respuestas observadas admisibles. P03 no es admisible para este criterio sin ayuda, no es numéricamente incorrecta. P08 está ausente, no es un fallo observado. Conserva ambos estados y sus motivos.

## 2. No agrupar intentos como si fueran preguntas nuevas

El historial contiene siete respuestas iniciales completadas y cuatro reintentos: once filas de respuestas completadas. Tres reintentos son correctos, así que agrupar todas las respuestas da `6/11`. Elegir solo la última respuesta observada de cada pregunta da en cambio `6/7`. El criterio de primera respuesta sin ayuda sigue siendo `2/6`.

Estas tres fracciones responden a preguntas distintas. Los intentos repetidos están vinculados a la misma pregunta y estudiante, a menudo después de retroalimentación. No son once estudiantes independientes ni once ensayos nuevos de primera respuesta. Un panel puede informar de varios criterios si etiqueta sus denominadores y políticas de ayuda en lugar de seleccionar silenciosamente la tasa mayor.

### Ejercicio 2: comparar políticas de agregación

Indica las tasas de todas las respuestas y de últimas respuestas observadas por pregunta. ¿Por qué ninguna puede sustituir la tasa de primera respuesta sin ayuda solo porque incluya más filas o sea mayor?

> **Respuesta:** Todas las respuestas dan `6/11`; las últimas respuestas observadas por pregunta dan `6/7`. Los reintentos, respuestas visibles y ayuda cambian el evento muestreado. Las filas dependientes adicionales no los redefinen como ensayos nuevos sin ayuda y la tasa final responde a otro criterio de resultado.

## 3. Conservar el éxito asistido útil sin cambiarle la etiqueta

Los tres reintentos con pista tienen éxito, dando `3/3` para ese criterio asistido seleccionado. Puede ser información útil sobre lo ocurrido en la traza didáctica. No demuestra que las pistas causen beneficio, que todas funcionen ni que las respuestas puedan recordarse después sin ayuda.

Hay siete propuestas de práctica admisibles en principio tras excluir la pregunta con respuesta filtrada, pero solo seis respuestas. Si el único resultado binario ausente no está restringido, la fracción correcta del conjunto completo de propuestas está entre `2/7` y `3/7`. Tratar una no respuesta como fallo puede definir otro criterio que tenga en cuenta la finalización, pero debe declararse como esa política y no presentarse como recuerdo observado.

### Ejercicio 3: conservar ayuda y datos ausentes

Calcula la tasa de éxito de reintentos con pista y las cotas admisibles del conjunto completo de propuestas. ¿Demostraría la tasa con pistas un beneficio causal o diferido, o justificaría borrar la respuesta ausente?

> **Respuesta:** Los reintentos con pista dan `3/3`. Las cotas admisibles del conjunto completo son `2/7` a `3/7`, según si el resultado binario no observado es incorrecto o correcto. Los éxitos asistidos seleccionados no establecen beneficio causal ni diferido y no proporcionan el valor ausente.

## 4. Acotar una evaluación diferida incompleta

Un conjunto didáctico separado contiene ocho preguntas reservadas para evaluación, ofrecidas tras un retraso estipulado de 24 horas. Seis tienen respuesta: cinco correctas y una incorrecta. Faltan dos. La tasa de respuestas observadas es `5/6`. La tasa del conjunto de ocho propuestas puede ir de `5/8` a `7/8` cuando los resultados binarios ausentes no están restringidos de otro modo.

Ese intervalo es una cota determinista de las posibles formas de completar los datos, no un intervalo de confianza ni un modelo de por qué las personas no responden. Sus cuatro formas posibles de completar los valores ausentes se conservan en el [registro de traza](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/recall-trace.json). Ni elegir el extremo optimista ni imputar automáticamente cero crea un resultado diferido observado. La comparabilidad y dificultad de las preguntas también siguen sin medirse.

### Ejercicio 4: informar de un denominador diferido

Indica los resultados observados y las cotas del conjunto completo de propuestas. ¿Por qué es incompleto informar «cinco de seis respondieron correctamente, por tanto cinco de ocho es la tasa medida de recuerdo»?

> **Respuesta:** Las respuestas observadas dan `5/6`; las cotas del conjunto completo son `5/8` a `7/8`. Cinco de ocho es la cota inferior al completar los datos o una política explícita de ausentes como fallos, no una medición directa de ambas respuestas ausentes. Informa conjuntamente de propuestas, respuestas, retraso, política de ayuda y datos ausentes.

## 5. Separar métricas del código y pruebas de aprendizaje

El [vocabulario de seguimiento de práctica](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/PracticeRoutineTypes.fs#L81-L101) de GA de la revisión fijada incluye etiquetas de precisión y tasa de mejora. Su [registro de evaluación de recuperación](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs#L3-L31) registra métricas de consultas. Ninguna definición seleccionada aporta la respuesta real anterior a la retroalimentación, el estado de pistas, la filiación de intentos ni la observación diferida de este historial.

### Ejercicio 5: sustituir una afirmación inflada de aprendizaje

Un agente llama al resultado final `6/7` «retención sin ayuda demostrada, mejorada por el sistema de pistas». Escribe una sustitución acotada y especifica las pruebas ausentes.

> **Respuesta:** En la traza didáctica, las últimas respuestas observadas por pregunta son `6/7`, las primeras respuestas observadas admisibles sin ayuda `2/6` y los reintentos con pista seleccionados `3/3`. El registro didáctico diferido tiene `5/6` observadas con cotas del conjunto completo `5/8` a `7/8`. Ninguno es evidencia de estudiantes reales ni beneficio causal. Una afirmación futura necesita respuestas reales con fecha y hora bajo el protocolo declarado de pistas y ayuda, un criterio diferido comparable especificado y un diseño justificado de comparación.

[PHI-007](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/) explica a continuación por qué incluso una observación completa antes y después no identificaría por sí sola el efecto de la intervención.
