---
module_id: "pm-010-standardize-dogfood-failures-to-a-declared-task-mix"
department: "product-management"
course: "Estandarizar fallos de dogfooding con una mezcla declarada de tareas"
level: "intermediate"
prerequisites: ["pm-009-separate-release-adoption-from-artifact-downloads", "cog-009-counterbalance-practice-order-before-comparing-interfaces"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Estandarizar fallos de dogfooding con una mezcla declarada de tareas

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un equipo compara informes y celebra un porcentaje global de fallos inferior. Un informe puede contener más tareas rutinarias y menos casos límite. El prerrequisito define personas y acciones del denominador; esta lección pregunta cómo cambia el resumen según la mezcla, aun con rendimiento idéntico en cada clase. Hay que declarar una mezcla objetivo antes de interpretar el titular.

Calcule primero la tasa dentro de cada estrato. Así conserva perfiles de dificultad representados por los datos construidos. La tasa agrupada pondera según intentos reales de la tabla. La estandarizada usa la mezcla objetivo. Responden a preguntas distintas: qué describe la muestra y qué implicarían esas tasas bajo los pesos elegidos. Ninguna estima automáticamente la distribución de futuros usuarios.

La discusión del [NIST](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm) motiva conservar grupos de factores molestos y comparar dentro de ellos. Esta aritmética no constituye experimento aleatorizado ni ajuste causal para toda confusión. Un estrato puede seguir mezclando tareas, ayuda e intentos repetidos. Mantenga esos límites sin presentar estandarización como prueba de comparación completamente justa. La mezcla objetivo es una elección construida que necesita razón del proyecto.

El control cambia recuentos manteniendo tasas de cada estrato. El porcentaje agrupado se acerca al estandarizado sin mejora en ninguna clase. Eso refuta un titular ingenuo de progreso. La fuente del proyecto enumera campos de ejercicios, pero no eventos reales de respuesta; no calibra nuestros números. Antes de pedir a un agente un informe, calcule ambos resúmenes manualmente y conserve identidad, revisión y ayuda.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/en/pm-009-separate-release-adoption-from-artifact-downloads.md)

[Prerrequisito: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/en/cog-009-counterbalance-practice-order-before-comparing-interfaces.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria: NIST/SEMATECH e-Handbook section 5.3.3.2, read 2026-10-24](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

## Modelo fijado y control

```json
{
  "values": {
    "strata": [
      "routine",
      "edge"
    ],
    "attempts": [
      30,
      10
    ],
    "failures": [
      3,
      4
    ],
    "target_weights": [
      0.9,
      0.1
    ]
  },
  "formula": "rate_i=failures_i/attempts_i; pooled=sum(failures)/sum(attempts); standardized=sum(target_weight_i*rate_i).",
  "expected": {
    "stratum_rates": [
      0.1,
      0.4
    ],
    "pooled_rate": 0.175,
    "standardized_rate": 0.13
  },
  "negative_control": {
    "values": {
      "strata": [
        "routine",
        "edge"
      ],
      "attempts": [
        90,
        10
      ],
      "failures": [
        9,
        4
      ],
      "target_weights": [
        0.9,
        0.1
      ]
    },
    "expected": {
      "stratum_rates": [
        0.1,
        0.4
      ],
      "pooled_rate": 0.13,
      "standardized_rate": 0.13
    },
    "why": "Changing sample mix to match the declared target aligns pooled and standardized rates without improving either stratum."
  },
  "assumptions": [
    "Target weights are authored, nonnegative and sum to unity.",
    "Within-stratum rates are descriptive of supplied attempts; no representativeness guarantee."
  ],
  "limits": "No real dogfood cohort, user distribution, causal improvement or statistical precision was measured."
}
```

### Ejercicio 1

Calcule las tasas de fallo de ambos estratos.

<details><summary>Respuesta 1</summary>

La rutinaria es `3/30=0.1`; la de casos límite `4/10=0.4`. Conserve etiquetas y denominadores, porque el total oculta la tasa mucho mayor de los casos límite.

</details>

### Ejercicio 2

Calcule la tasa agrupada de la muestra principal.

<details><summary>Respuesta 2</summary>

Es `7/40=0.175`. Describe la mezcla suministrada. No usa pesos objetivo y no debe llamarse tasa estandarizada de la población objetivo.

</details>

### Ejercicio 3

Calcule la tasa estandarizada a la mezcla declarada.

<details><summary>Respuesta 3</summary>

Es `0.9*0.1+0.1*0.4=0.13`. Aplica pesos construidos a tasas por estrato, sin validar que sean la distribución real de uso.

</details>

### Ejercicio 4

Aplique el control y determine si mejoró algún estrato.

<details><summary>Respuesta 4</summary>

La tasa agrupada pasa a `13/100=0.13`, igual a la estandarizada. Las tasas siguen `[0.1,0.4]`. La bajada del titular viene de cambiar la mezcla, sin mejora interna.

</details>

### Ejercicio 5

¿Qué debe conservar una comparación futura de dogfooding?

<details><summary>Respuesta 5</summary>

Conserve definiciones, intentos, fallos, pesos y razón, respuestas reales, ayuda y revisiones. Compare estratos equivalentes antes de agregar. Cambiar mezcla o usar recuentos inventados no demuestra mejora real de una función.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
