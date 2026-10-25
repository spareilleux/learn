---
title: Equilibrar costes de preparación y espera de verificación
description: Equilibrar costes de preparación y espera de verificación — Gestión de productos y proyectos
sidebar:
  label: PM-015 · Equilibrar costes de preparación y espera de verificación
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-015-balance-verification-setup-and-waiting-costs.es.md
---

:::note[Streeling University]
**PM-015** · Equilibrar costes de preparación y espera de verificación · intermedio · 45 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-015-balance-verification-setup-and-waiting-costs.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-008](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/), [PM-011](../../product-management/pm-011-include-review-and-correction-in-automation-break-even/)
:::

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un flujo futuro de Learn podría verificar cada llegada inmediatamente o reunir varias antes de repetir una preparación fija. La verificación inmediata minimiza la espera, pero repite a menudo la preparación. Los grupos grandes reducen esa frecuencia y hacen esperar a los primeros ítems. Elegir una cadencia exige ambos términos en una escala comparable, sin suponer que siempre convenga el lote menor o mayor.

Las llegadas construidas ocurren a intervalos regulares. La verificación es instantánea cuando llega el último ítem del grupo. Este no espera; el anterior espera un intervalo y los anteriores progresivamente más. Sumar esa escalera da ítems-ticks, no duración de calendario del grupo completo. Cobre preparación una vez por grupo y espera una vez por ítem-tick.

Enumere solo los divisores declarados de la carga para terminar grupos completos. El coste fijo genera un óptimo interior. El control reduce ese cargo y crea un empate exacto entre dos tamaños pequeños. Conserve ambos minimizadores: desempatar necesitaría otro criterio declarado. El grupo mayor no es mejor solo porque minimiza preparaciones.

La lección de inventario del MIT motiva el equilibrio entre preparación y conservación; nuestra fórmula finita de espera se deriva por separado. No convierte cursos en existencias físicas ni estima costes reales. Los requisitos de capacidad y punto de equilibrio responden a otras preguntas. En particular, el alcance solicitado sigue fijo: este ejemplo hipotético de cadencia no autoriza cambiarlo. Aplicarlo exigiría medir preparación, tiempo de verificación, llegadas y consecuencias de espera, manteniendo todas las revisiones obligatorias. Una tabla manual precede cualquier política de lotes o planificador de agentes.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/pm-008-size-a-fifty-course-batch-by-review-capacity/)

[Requisito previo: pm-011-include-review-and-correction-in-automation-break-even](../../product-management/pm-011-include-review-and-correction-in-automation-break-even/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://live.ocw.mit.edu/courses/2-854-introduction-to-manufacturing-systems-fall-2016/6c8fec8f99bcf7059b73b82e96d43901_MIT2_854F16_Inventory.pdf)

## Modelo fijo y control negativo

```json
{
  "values": {
    "items": 12,
    "candidate_sizes": [
      1,
      2,
      3,
      4,
      6,
      12
    ],
    "setup_cost": 9,
    "waiting_cost_per_item_tick": 1
  },
  "formula": "Items arrive one per tick; each batch is verified instantly when its qth item arrives. For q dividing N, batch_count=N/q; waiting_item_ticks=(N/q)*q*(q-1)/2; total=setup_cost*N/q+waiting_cost_per_item_tick*waiting_item_ticks. Retain all minimum-cost candidate sizes.",
  "expected": {
    "total_costs": [
      108,
      60,
      48,
      45,
      48,
      75
    ],
    "waiting_item_ticks": [
      0,
      6,
      12,
      18,
      30,
      66
    ],
    "optimal_sizes": [
      4
    ],
    "minimum_cost": 45
  },
  "negative_control": {
    "values": {
      "items": 12,
      "candidate_sizes": [
        1,
        2,
        3,
        4,
        6,
        12
      ],
      "setup_cost": 1,
      "waiting_cost_per_item_tick": 1
    },
    "expected": {
      "total_costs": [
        12,
        12,
        16,
        21,
        32,
        67
      ],
      "waiting_item_ticks": [
        0,
        6,
        12,
        18,
        30,
        66
      ],
      "optimal_sizes": [
        1,
        2
      ],
      "minimum_cost": 12
    },
    "why": "Lower setup charge changes the balance and creates a tie that must remain explicit."
  },
  "input_types": {
    "items": "positive integer N",
    "candidate_sizes": "distinct positive integer divisors of N",
    "setup_cost": "nonnegative rational points per batch",
    "waiting_cost_per_item_tick": "nonnegative rational points per item-tick"
  },
  "assumptions": [
    "Periodic deterministic arrivals; verification time is zero in this toy cost model.",
    "Setup and waiting are converted to the same stipulated point scale; quality and required reviews are unchanged."
  ],
  "limits": "Not an instruction to alter the actual requested fifty-course batch, a measured cost model, a staffing schedule or a release approval."
}
```

### Ejercicio 1

Derive la espera del candidato interior.

<details><summary>Respuesta 1</summary>

Con tamaño `4`, la espera total es `18` ítems-ticks y hay `3` preparaciones. Cuestan `27`, dando un total de `45` puntos con la conversión declarada.

</details>

### Ejercicio 2

Encuentre todos los óptimos fijos.

<details><summary>Respuesta 2</summary>

Los costes son `[108,60,48,45,48,75]`; solo el tamaño `[4]` los minimiza. Minimizar solo el número de preparaciones elegiría otro candidato más costoso.

</details>

### Ejercicio 3

Aplique el control de menor preparación.

<details><summary>Respuesta 3</summary>

Los costes pasan a `[12,12,16,21,32,67]`. Los tamaños óptimos son `[1,2]`, ambos con `12` puntos. Conserve el empate sin inventar una preferencia.

</details>

### Ejercicio 4

¿Pueden sumarse directamente ítems-ticks y minutos?

<details><summary>Respuesta 4</summary>

No. El modelo convierte explícitamente espera y preparación a puntos comunes. Un equilibrio real exige una conversión justificada u otro objetivo, no unidades mezcladas.

</details>

### Ejercicio 5

¿Cambia el óptimo pequeño el alcance solicitado?

<details><summary>Respuesta 5</summary>

No. Es aritmética construida condicional para una cadencia futura. Solicitud real, autoridad de revisión y calidad siguen siendo restricciones vigentes; no se han medido costes reales.

</details>

## Tarea con consulta de fuentes

Compare cadencias hipotéticas de verificación conservando el alcance real solicitado.

**Referencia manual directa:** Dibuje llegadas, cuente espera por ítem y tabule preparación más espera para cada tamaño.

**Criterio de refutación:** Un óptimo anunciado omite espera, mezcla unidades o descarta un minimizador empatado sin regla declarada.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Derive la espera del candidato interior. — Decisión sin resolver.
- Ejercicio 2: Encuentre todos los óptimos fijos. — Decisión sin resolver.
- Ejercicio 3: Aplique el control de menor preparación. — Decisión sin resolver.
- Ejercicio 4: ¿Pueden sumarse directamente ítems-ticks y minutos? — Decisión sin resolver.
- Ejercicio 5: ¿Cambia el óptimo pequeño el alcance solicitado? — Decisión sin resolver.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
