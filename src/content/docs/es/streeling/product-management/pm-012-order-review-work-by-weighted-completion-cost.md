---
title: Ordenar revisiones por su coste ponderado de finalización
description: Ordenar revisiones por su coste ponderado de finalización — Gestión de productos y proyectos
sidebar:
  label: PM-012 · Ordenar revisiones por su coste ponderado de finalización
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-012-order-review-work-by-weighted-completion-cost.es.md
---

:::note[Streeling University]
**PM-012** · Ordenar revisiones por su coste ponderado de finalización · intermedio · 45 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-012-order-review-work-by-weighted-completion-cost.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-003](../../product-management/pm-003-review-queue-flow-metrics/), [NET-010](../../network-science/net-010-compute-critical-paths-with-resource-assumptions/)
:::

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Una cola de revisión de Learn dispone de un solo revisor. Dos órdenes pueden terminar toda la cola a la vez y dejar trabajos esperando durante tiempos distintos. El rendimiento y la duración total no permiten elegir entre ellos. Hace falta un objetivo declarado y pesos justificados antes de optimizar con un agente.

La lectura de OR-Tools describe no interrupción, precedencia y recursos exclusivos, y optimiza la duración total. Nuestro caso pequeño no tiene precedencias y elige otro objetivo: cada trabajo acumula su pérdida declarada por unidad de tiempo hasta terminar. Enumere órdenes sin introducir un solucionador ni afirmar una política universal.

Calcule tiempos de finalización, no solo de inicio. Adelantar un trabajo corto de peso alto puede reducir el coste, pero ordenar solo por duración no sigue siendo óptimo cuando cambian los pesos. El control cambia únicamente esos pesos e invierte el primer trabajo preferido. Los puntos ficticios no son minutos medidos ni permiso para omitir revisiones.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: pm-003-review-queue-flow-metrics](../../product-management/pm-003-review-queue-flow-metrics/)

[Requisito previo: net-010-compute-critical-paths-with-resource-assumptions](../../network-science/net-010-compute-critical-paths-with-resource-assumptions/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://developers.google.com/optimization/scheduling/job_shop)

## Modelo fijo y control

```json
{
  "values": {
    "jobs": [
      "A",
      "B",
      "C"
    ],
    "duration_ticks": {
      "A": 4,
      "B": 1,
      "C": 2
    },
    "weight_per_tick": {
      "A": 4,
      "B": 3,
      "C": 1
    },
    "baseline_order": [
      "A",
      "B",
      "C"
    ]
  },
  "formula": "Single nonpreemptive reviewer, all jobs ready at time zero. Completion time is cumulative duration. Cost=sum(weight[j]*completion[j]). Enumerate all permutations; choose minimum cost.",
  "expected": {
    "optimal_order": [
      "B",
      "A",
      "C"
    ],
    "optimal_completion": {
      "B": 1,
      "A": 5,
      "C": 7
    },
    "optimal_cost": 30,
    "baseline_cost": 38,
    "makespan": 7
  },
  "negative_control": {
    "values": {
      "jobs": [
        "A",
        "B",
        "C"
      ],
      "duration_ticks": {
        "A": 4,
        "B": 1,
        "C": 2
      },
      "weight_per_tick": {
        "A": 8,
        "B": 1,
        "C": 1
      },
      "baseline_order": [
        "A",
        "B",
        "C"
      ]
    },
    "expected": {
      "optimal_order": [
        "A",
        "B",
        "C"
      ],
      "optimal_completion": {
        "A": 4,
        "B": 5,
        "C": 7
      },
      "optimal_cost": 44,
      "baseline_cost": 44,
      "makespan": 7
    },
    "why": "Changing delay weights reverses the preferred first job despite identical durations and makespan."
  },
  "assumptions": [
    "All work available initially; one exclusive reviewer; no interruptions, deadlines or setup costs.",
    "Weights are stipulated cardinal delay loss per tick, not human importance or measured money."
  ],
  "limits": "No real review capacity, optimal general scheduler, quality tradeoff or authority to skip gates.",
  "input_types": {
    "jobs": "list<unique string>",
    "duration_ticks": "map<job,positive integer>",
    "weight_per_tick": "map<job,nonnegative real>",
    "baseline_order": "permutation<jobs>"
  }
}
```

### Ejercicio 1

Calcule el coste de referencia.

<details><summary>Respuesta 1</summary>

En `ABC`, las finalizaciones son `[4,5,7]`; el coste es `4*4+3*5+1*7=38`. La duración total es `7`.

</details>

### Ejercicio 2

Calcule el coste del orden propuesto.

<details><summary>Respuesta 2</summary>

En `BAC`, las finalizaciones son `[1,5,7]`; el coste es `3*1+4*5+1*7=30`. La duración total sigue en `7`.

</details>

### Ejercicio 3

¿Cómo verificar optimalidad sin solucionador?

<details><summary>Respuesta 3</summary>

Enumere las `6` permutaciones y calcule el objetivo en cada una. Un orden factible favorable no demuestra optimalidad.

</details>

### Ejercicio 4

Aplique el control de pesos.

<details><summary>Respuesta 4</summary>

`ABC` pasa a ser óptimo con coste `44`, mientras `BAC` cuesta `48`. Duraciones fijas no implican prioridades fijas.

</details>

### Ejercicio 5

¿El mejor orden permite omitir una aprobación del alumno?

<details><summary>Respuesta 5</summary>

No. Optimizar trabajos elegibles no cambia elegibilidad ni autoridad. Las decisiones y costes reales siguen siendo distintos.

</details>

## Tarea con consulta de fuentes

Prepare una ficha de orden ficticio de revisión de Learn con un objetivo explícito de coste de demora.

**Referencia manual directa:** Enumere todos los órdenes en papel con tiempos de finalización y costes ponderados.

**Criterio de refutación:** Un óptimo declarado cuesta más que otro orden factible o se optimiza la duración total sin declararlo.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
