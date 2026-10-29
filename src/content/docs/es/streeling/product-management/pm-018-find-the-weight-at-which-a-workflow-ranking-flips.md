---
title: Hallar el peso que invierte el orden de procesos
description: Hallar el peso que invierte el orden de procesos — Gestión de productos y proyectos
sidebar:
  label: PM-018 · Hallar el peso que invierte el orden de procesos
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-018-find-the-weight-at-which-a-workflow-ranking-flips.es.md
---

:::note[Streeling University]
**PM-018** · Hallar el peso que invierte el orden de procesos · intermedio · 45 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-018-find-the-weight-at-which-a-workflow-ranking-flips.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-011](../../product-management/pm-011-include-review-and-correction-in-automation-break-even/), [PM-004](../../product-management/pm-004-craft-extension-release-decision/)
:::

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un equipo ordena procesos de verificación mediante una mezcla ponderada de puntos de latencia y retrabajo. Un asistente puede hacer que una preferencia parezca objetiva ocultando el peso en una puntuación compuesta. El análisis de sensibilidad pregunta qué preferencias sostienen realmente la recomendación. Las coordenadas deben usar escalas comparables declaradas; ponderar unidades incompatibles no justifica un modelo de utilidad.

Escriba cada puntuación como función afín del peso de latencia y asigne el peso restante al retrabajo. Iguale ambas funciones y resuelva el cruce. Compruebe que el peso pertenece al intervalo permitido. Evalúe un punto a cada lado para identificar la opción preferida y conserve ambas cuando hay igualdad exacta.

El peso fijo favorece un proceso y el control favorece el otro. Ningún resultado establece un ganador universal. El cruce expone una frontera de decisión antes de adoptar una política. No se miden distribuciones reales de latencia, calidad de correcciones ni incertidumbre de las escalas. La lectura sobre escalarización aporta el concepto ponderado; la comparación afín finita es propia. Una recomendación debería mostrar su peso y advertir qué preferencias invierten el orden.

## Fuentes y alcance del proyecto

[Prerrequisito: pm-011-include-review-and-correction-in-automation-break-even](../../product-management/pm-011-include-review-and-correction-in-automation-break-even/)

[Prerrequisito: pm-004-craft-extension-release-decision](../../product-management/pm-004-craft-extension-release-decision/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://web.stanford.edu/~boyd/cvxbook/bv_cvxslides.pdf)

## Modelo fijo y control negativo

```json
{
  "values": {
    "names": [
      "A",
      "B"
    ],
    "latency": [
      2,
      6
    ],
    "rework": [
      8,
      2
    ],
    "latency_weight": "1/4"
  },
  "formula": "score[i]=w*latency[i]+(1-w)*rework[i], minimize. Solve equal affine scores for crossover w; report scores there and all tied winners. Exact rationals.",
  "expected": {
    "scores": [
      "13/2",
      "3"
    ],
    "winners": [
      "B"
    ],
    "crossover_weight": "3/5",
    "crossover_scores": [
      "22/5",
      "22/5"
    ],
    "crossover_winners": [
      "A",
      "B"
    ]
  },
  "negative_control": {
    "values": {
      "names": [
        "A",
        "B"
      ],
      "latency": [
        2,
        6
      ],
      "rework": [
        8,
        2
      ],
      "latency_weight": "3/4"
    },
    "expected": {
      "scores": [
        "7/2",
        "5"
      ],
      "winners": [
        "A"
      ],
      "crossover_weight": "3/5",
      "crossover_scores": [
        "22/5",
        "22/5"
      ],
      "crossover_winners": [
        "A",
        "B"
      ]
    },
    "why": "Different declared preferences reverse the winner without changing either workflow coordinate."
  },
  "input_types": {
    "names": "two distinct option strings",
    "latency": "two finite rational points on declared comparable scale",
    "rework": "two finite rational points on declared comparable scale",
    "latency_weight": "rational string in closed unit interval"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No measured workflow cost, accepted utility scale, stakeholder preference or production recommendation is established."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Escribir las funciones afines, resolver su intersección y comprobar ambos lados.

**Criterio de refutación:** Se presenta una recomendación independiente del peso pese a un cruce dentro del intervalo permitido.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Calcule el orden fijo.

> **Respuesta:** Con peso `1/4`, las puntuaciones son `[13/2,3]`; minimizar elige `B`.

### Ejercicio 2

Halle el cruce y el control.

> **Respuesta:** El cruce es `3/5`, donde ambas puntuaciones son `22/5`. Con `3/4`, las puntuaciones `[7/2,5]` eligen `A`.

### Ejercicio 3

¿Qué autoriza el empate?

> **Respuesta:** Permite informar ambos mínimos bajo ese objetivo. Recomendar uno exige otro criterio declarado, no un desempate oculto.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Con peso `1/4`, las puntuaciones son `[13/2,3]`; minimizar elige `B`.
- Ejercicio 2: El cruce es `3/5`, donde ambas puntuaciones son `22/5`. Con `3/4`, las puntuaciones `[7/2,5]` eligen `A`.
- Ejercicio 3: Permite informar ambos mínimos bajo ese objetivo. Recomendar uno exige otro criterio declarado, no un desempate oculto.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
