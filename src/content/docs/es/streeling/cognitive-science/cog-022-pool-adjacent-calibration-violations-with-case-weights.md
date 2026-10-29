---
title: Agrupar violaciones adyacentes de calibración con pesos
description: Agrupar violaciones adyacentes de calibración con pesos — Ciencia cognitiva
sidebar:
  label: COG-022 · Agrupar violaciones adyacentes de calibración con pesos
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-022-pool-adjacent-calibration-violations-with-case-weights.es.md
---

:::note[Streeling University]
**COG-022** · Agrupar violaciones adyacentes de calibración con pesos · intermedio · 45 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-022-pool-adjacent-calibration-violations-with-case-weights.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-003](../../cognitive-science/cog-003-calibrating-fretboard-confidence/), [PSY-017](../../psychohistory/psy-017-calibration-with-six-observations/)
:::

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un informe de revisión agéntica ordena grupos según su puntuación de confianza, pero sus frecuencias de éxito disminuyen entre grupos vecinos. Un ajuste monótono puede eliminar ese conflicto conservando el peso de cada grupo. No corrige el sesgo de muestreo ni demuestra que las previsiones sean fiables. Mantenga las frecuencias originales y sus pesos junto a la curva ajustada.

Empiece con un bloque por puntuación ordenada. Cuando la media de un bloque supera la siguiente, fusiónelos y calcule su media ponderada. Revise después la frontera anterior: una fusión puede descubrir otra violación. Los valores finales minimizan el error cuadrático ponderado sujeto a un orden no decreciente. Ordenar las respuestas separaría los resultados de sus grupos originales de confianza.

Los grupos centrales del caso propuesto violan el orden. Cambiar sus pesos desplaza el nivel común sin alterar los resultados ni el orden de las puntuaciones. Usar pesos iguales respondería otra pregunta. La curva describe solo los grupos de entrenamiento: validar con intentos reservados, registrar la ayuda y tratar puntuaciones nuevas siguen siendo tareas distintas. Un futuro DSL necesitaría conservar las identidades y los pesos de los grupos.

## Fuentes y alcance del proyecto

[Prerrequisito: cog-003-calibrating-fretboard-confidence](../../cognitive-science/cog-003-calibrating-fretboard-confidence/)

[Prerrequisito: psy-017-calibration-with-six-observations](../../psychohistory/psy-017-calibration-with-six-observations/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://docs.scipy.org/doc/scipy-1.14.0/reference/generated/scipy.optimize.isotonic_regression.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "y": [
      0.2,
      0.8,
      0.4,
      0.9
    ],
    "weights": [
      1,
      1,
      3,
      1
    ]
  },
  "formula": "Weighted nondecreasing least squares: minimize sum(weights[i]*(fit[i]-y[i])**2) subject to fit[i]<=fit[i+1]. PAVA merges adjacent decreasing block means using summed weights.",
  "expected": {
    "fit": [
      0.2,
      0.5,
      0.5,
      0.9
    ],
    "weighted_squared_error": 0.12
  },
  "negative_control": {
    "values": {
      "y": [
        0.2,
        0.8,
        0.4,
        0.9
      ],
      "weights": [
        1,
        3,
        1,
        1
      ]
    },
    "expected": {
      "fit": [
        0.2,
        0.7,
        0.7,
        0.9
      ],
      "weighted_squared_error": 0.12
    },
    "why": "Changing case weights changes the pooled mean; sorting responses is not weighted fitting."
  },
  "input_types": {
    "y": "ordered finite observed frequencies",
    "weights": "same-length strictly positive case weights"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No held-out calibration, actual learner counts or behavior of a deployed agent is established."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Escribir sumas ponderadas y fusionar fronteras decrecientes.

**Criterio de refutación:** El ajuste ignora pesos o mueve resultados entre grupos.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Calcule el bloque agrupado.

> **Respuesta:** Los valores en conflicto dan `(1*0.8+3*0.4)/4=0.5`; el ajuste es `[0.2,0.5,0.5,0.9]`.

### Ejercicio 2

Aplique el control que intercambia los pesos.

> **Respuesta:** El valor común pasa a `(3*0.8+1*0.4)/4=0.7`. Ambos objetivos valen `0.12`, pero las secuencias ajustadas son distintas.

### Ejercicio 3

¿Por qué conservar el orden original de los grupos?

> **Respuesta:** El orden pertenece a las puntuaciones de confianza. Ordenar las frecuencias movería los resultados a otras puntuaciones.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Los valores en conflicto dan `(1*0.8+3*0.4)/4=0.5`; el ajuste es `[0.2,0.5,0.5,0.9]`.
- Ejercicio 2: El valor común pasa a `(3*0.8+1*0.4)/4=0.7`. Ambos objetivos valen `0.12`, pero las secuencias ajustadas son distintas.
- Ejercicio 3: El orden pertenece a las puntuaciones de confianza. Ordenar las frecuencias movería los resultados a otras puntuaciones.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
