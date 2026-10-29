---
title: Elegir una cartera con presupuesto y cierre de requisitos
description: Elegir una cartera con presupuesto y cierre de requisitos — Gestión de productos y proyectos
sidebar:
  label: PM-014 · Elegir una cartera con presupuesto y cierre de requisitos
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-014-select-a-budgeted-portfolio-with-prerequisite-closure.es.md
---

:::note[Streeling University]
**PM-014** · Elegir una cartera con presupuesto y cierre de requisitos · intermedio · 45 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-014-select-a-budgeted-portfolio-with-prerequisite-closure.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-008](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)
:::

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un coordinador de Learn compara mejoras opcionales de verificación para un flujo futuro. Una función atractiva necesita una base compartida, pero la estimación solo muestra su coste propio. Elegir la mejor proporción aparente puede generar una cartera que cabe en el presupuesto en papel y omite su requisito. Cuente todo el cierre de dependencias antes de comparar beneficios.

El catálogo construido contiene una base sin valor independiente, una mejora que la requiere y alternativas autónomas. Cada elemento elegido aporta coste y valor una sola vez. Un subconjunto es admisible si contiene sus requisitos y el coste total cabe en el presupuesto. Enumerar el catálogo pequeño permite inspeccionar todos los rechazos y conservar empates sin inventar un óptimo único.

El óptimo fijo elige las alternativas independientes. Una propuesta atractiva de función y elemento pequeño falla al incluir la base requerida. El control quita el requisito y cambia el óptimo. Ese cambio de premisa es deliberadamente decisivo: no puede justificarse llamando a la base detalle de implementación ni cargándola a un presupuesto futuro indefinido.

La guía de Google define el problema ordinario de valor bajo capacidad. La regla adicional de cierre es una extensión construida, no una afirmación sobre el esquema del solucionador. El requisito de capacidad evalúa una solicitud fija; aquí se evalúa trabajo opcional con puntos comparables inventados. La lección no reduce el alcance solicitado ni elimina revisiones obligatorias. Una decisión real necesitaría valores defendibles, costes medidos, evidencias de dependencia y autoridad para elegir. Una tabla de subconjuntos es la referencia antes de proponer un optimizador de agente o DSL de planificación.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://developers.google.com/optimization/pack/knapsack)

## Modelo fijo y control negativo

```json
{
  "values": {
    "items": {
      "A": {
        "cost": 3,
        "value": 0,
        "requires": []
      },
      "B": {
        "cost": 3,
        "value": 8,
        "requires": [
          "A"
        ]
      },
      "C": {
        "cost": 4,
        "value": 7,
        "requires": []
      },
      "D": {
        "cost": 2,
        "value": 3,
        "requires": []
      }
    },
    "budget": 6
  },
  "formula": "Enumerate all item subsets including empty. Feasible iff total cost<=budget and every selected item has all requires selected. Sum each selected item cost/value once. Maximize total value; retain every optimal subset, sorted lexicographically.",
  "expected": {
    "feasible_count": 7,
    "optimal_sets": [
      [
        "C",
        "D"
      ]
    ],
    "optimal_costs": [
      6
    ],
    "optimal_value": 10
  },
  "negative_control": {
    "values": {
      "items": {
        "A": {
          "cost": 3,
          "value": 0,
          "requires": []
        },
        "B": {
          "cost": 3,
          "value": 8,
          "requires": []
        },
        "C": {
          "cost": 4,
          "value": 7,
          "requires": []
        },
        "D": {
          "cost": 2,
          "value": 3,
          "requires": []
        }
      },
      "budget": 6
    },
    "expected": {
      "feasible_count": 9,
      "optimal_sets": [
        [
          "B",
          "D"
        ]
      ],
      "optimal_costs": [
        5
      ],
      "optimal_value": 11
    },
    "why": "Removing the real prerequisite changes which subset is admissible, not merely its display order."
  },
  "input_types": {
    "items": "mapping of item to nonnegative integer cost/value and prerequisite-name list",
    "budget": "nonnegative integer"
  },
  "assumptions": [
    "All named prerequisites are items; acyclic dependency model.",
    "Values are additive stipulated comparable points; costs are charged once per selected item."
  ],
  "limits": "No portfolio value, real review cost, authorization or scope change is measured. This does not alter the user-requested course batch."
}
```

### Ejercicio 1

¿Por qué es inviable la pareja atractiva?

<details><summary>Respuesta 1</summary>

El subconjunto `[B,D]` cuesta directamente `5`, pero omite `A`. Su cierre `[A,B,D]` cuesta `8`, superando el presupuesto `6`. El ahorro aparente procede de una obligación ausente.

</details>

### Ejercicio 2

Encuentre la cartera óptima fija.

<details><summary>Respuesta 2</summary>

Hay `7` subconjuntos admisibles. El óptimo es `[C,D]`, con coste `6` y valor `10`. Cumple requisitos y presupuesto.

</details>

### Ejercicio 3

Aplique el control sin requisito.

<details><summary>Respuesta 3</summary>

Hay `9` subconjuntos admisibles; `[B,D]` cuesta ahora `5` y vale `11`. El resultado exige cambiar la dependencia, no acelerar el optimizador.

</details>

### Ejercicio 4

¿Puede cobrarse varias veces una base compartida?

<details><summary>Respuesta 4</summary>

No en este modelo: cada elemento elegido se cobra una sola vez. Cobrarlo repetidamente definiría otro modelo de costes y podría invertir la comparación.

</details>

### Ejercicio 5

¿Optimiza esto el alcance actual de entrega?

<details><summary>Respuesta 5</summary>

No. La solicitud real sigue definiendo el alcance. Las mejoras opcionales ficticias ilustran el cierre; una selección real exige costes, valores y autoridad explícita.

</details>

## Tarea con consulta de fuentes

Compare mejoras opcionales hipotéticas sin omitir el trabajo previo requerido.

**Referencia manual directa:** Enumere todos los subconjuntos y compruebe cierre y coste antes de puntuar el valor.

**Criterio de refutación:** Una cartera solo cabe porque falta una base obligatoria o se carga sin justificación a otro lugar.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: ¿Por qué es inviable la pareja atractiva? — Decisión sin resolver.
- Ejercicio 2: Encuentre la cartera óptima fija. — Decisión sin resolver.
- Ejercicio 3: Aplique el control sin requisito. — Decisión sin resolver.
- Ejercicio 4: ¿Puede cobrarse varias veces una base compartida? — Decisión sin resolver.
- Ejercicio 5: ¿Optimiza esto el alcance actual de entrega? — Decisión sin resolver.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
