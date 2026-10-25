---
title: Hallar cuántas respuestas faltantes invierten la clasificación
description: Hallar cuántas respuestas faltantes invierten la clasificación — Ciencia cognitiva
sidebar:
  label: COG-016 · Hallar cuántas respuestas faltantes invierten la clasificación
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-016-find-the-missing-answer-tipping-count.es.md
---

:::note[Streeling University]
**COG-016** · Hallar cuántas respuestas faltantes invierten la clasificación · intermedio · 45 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-016-find-the-missing-answer-tipping-count.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/), [PHI-007](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/)
:::

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un resumen de revisión asistida omite ofertas sin respuesta y se sitúa por encima de una comparación manual completa. El curso previo ya aporta límites de completado. Ahora planteamos una pregunta de sensibilidad: ¿cuántas respuestas faltantes tendrían que ser correctas para que la clasificación fuera estrictamente favorable?

Conserve el denominador original de ofertas elegibles. Cada completado hipotético es un supuesto, no una observación. Enumere los posibles aciertos faltantes y compare cada tasa completada con la manual fija. La igualdad no cumple un criterio de superioridad estricta. Este umbral entero se audita mejor que un relato que elige implícitamente el extremo optimista.

El registro conservado distingue respuestas ausentes de errores observados. La procedencia W3C ayuda a separar la actividad que produce un resultado de su resumen derivado. Ninguna fuente aporta las respuestas faltantes. Aquí faltan respuestas del punto de evaluación, no resultados bajo otra intervención como en el curso contrafactual. Un completado favorable tampoco demostraría beneficio causal.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cog-007-separate-unaided-recall-from-assisted-success](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/)

[Requisito previo: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Modelo fijo y control

```json
{
  "values": {
    "offered": 10,
    "observed_successes": 6,
    "missing": 4,
    "comparison_successes": 7,
    "comparison_offered": 10
  },
  "formula": "For k missing successes in integers 0..missing, rate=(successes+k)/offered; strict superiority requires rate>comparison_successes/comparison_offered. Return smallest feasible k or null.",
  "expected": {
    "lower": 0.6,
    "upper": 1,
    "comparison_rate": 0.7,
    "minimum_missing_successes_for_strict_superiority": 2,
    "identified_strict_superiority": false
  },
  "negative_control": {
    "values": {
      "offered": 10,
      "observed_successes": 6,
      "missing": 0,
      "comparison_successes": 7,
      "comparison_offered": 10
    },
    "expected": {
      "lower": 0.6,
      "upper": 0.6,
      "comparison_rate": 0.7,
      "minimum_missing_successes_for_strict_superiority": null,
      "identified_strict_superiority": false
    },
    "why": "Complete inferior results leave no missing-answer assignment that can reverse the ranking."
  },
  "assumptions": [
    "One binary endpoint per eligible offer; comparison complete.",
    "Missing results may be either value; no missingness model."
  ],
  "limits": "Descriptive ranking sensitivity only; no causal benefit, probability for completions or statistical interval.",
  "input_types": {
    "offered": "positive integer",
    "observed_successes": "integer in [0,offered-missing]",
    "missing": "integer in [0,offered]",
    "comparison_successes": "integer",
    "comparison_offered": "positive integer"
  }
}
```

### Ejercicio 1

Calcule los límites para todas las ofertas.

<details><summary>Respuesta 1</summary>

Son `0.6` y `1`; la comparación completa tiene tasa `0.7`. Siguen siendo posibles varias clasificaciones.

</details>

### Ejercicio 2

¿Cuántos aciertos faltantes producen igualdad?

<details><summary>Respuesta 2</summary>

Con `1` acierto faltante, la tasa es `0.7`. La igualdad no satisface superioridad estricta.

</details>

### Ejercicio 3

Halle el umbral de superioridad estricta.

<details><summary>Respuesta 3</summary>

El menor recuento es `2`, que da `0.8`. Es un requisito hipotético, no evidencia de respuestas correctas.

</details>

### Ejercicio 4

Aplique el control sin datos faltantes.

<details><summary>Respuesta 4</summary>

Ambos límites son `0.6`, menores que `0.7`; el mínimo es `null`. Ningún completado factible invierte el orden.

</details>

### Ejercicio 5

¿Es el umbral una probabilidad de beneficio?

<details><summary>Respuesta 5</summary>

No. No asignamos probabilidades a los completados, y una clasificación descriptiva no identifica un efecto causal. Conserve las ofertas sin respuesta.

</details>

## Tarea con consulta de fuentes

Prepare una nota de sensibilidad para respuestas ficticias de revisión de GA asistida y manual.

**Referencia manual directa:** Enumere aciertos faltantes enteros con el denominador completo y marque el primer cruce estricto.

**Criterio de refutación:** Se llama superioridad a la igualdad o se presenta una respuesta hipotética como observada.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
