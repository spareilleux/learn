---
module_id: "cog-013-retain-catch-trial-misses-in-assisted-review"
department: "cognitive-science"
course: "Conservar los fallos omitidos en ensayos trampa de revisión asistida"
level: "intermediate"
prerequisites: ["cog-007-separate-unaided-recall-from-assisted-success", "cog-009-counterbalance-practice-order-before-comparing-interfaces"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Conservar los fallos omitidos en ensayos trampa de revisión asistida

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un informe de dogfooding afirma que un asistente facilita revisar porque se completan más tareas. La finalización puede coexistir con aceptar una sugerencia incorrecta. El prerrequisito distingue modos de ayuda; el de orden trata efectos de secuencia. Esta lección elige elementos trampa con sugerencias deliberadamente falsas y conserva qué errores se omiten en cada modo. Pregunta por supervisión en un límite explícito, sin medir aprendizaje general.

La clave externa debe establecerse antes de presentar el elemento. Omitir significa aceptar la sugerencia falsa, con la misma definición en ambas condiciones. Empareje resultados por identidad antes de restar totales. Los errores omitidos solo con ayuda identifican explicaciones concretas que examinar; los omitidos en ambos modos pueden reflejar otra dificultad. Una diferencia media pierde esa distinción diagnóstica.

La explicación de bloques del [NIST](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm) motiva comparar condiciones dentro de grupos con factores molestos controlados. Los vectores inventados son un ejemplo contable, sin constituir un experimento aleatorizado. Ver un elemento puede enseñar su respuesta, y una sugerencia falsa puede influir en un juicio manual posterior. Un diseño real necesita elementos paralelos adecuados o asignación y orden justificados antes de afirmar causalidad.

Las observaciones conservadas dejan sin implementar el estudio y no muestran eventos de respuestas en las fuentes elegidas. No pueden convertirse en las observaciones emparejadas siguientes. Una ficha de evaluación propuesta debería guardar clave, sugerencia original, respuesta y modo. La referencia manual es la tabla emparejada, incluidos resultados negativos. Ni una sensación de facilidad ni más tareas terminadas aporta la evidencia de los elementos trampa.

Ambas condiciones examinan la misma respuesta propuesta y clave. La condición manual no recibe respaldo del asistente; la asistida ve además un respaldo de esa respuesta. Son condiciones estipuladas del modelo, sin exposiciones reales de participantes.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cog-007-separate-unaided-recall-from-assisted-success](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md)

[Prerrequisito: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/en/cog-009-counterbalance-practice-order-before-comparing-interfaces.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria: NIST/SEMATECH e-Handbook section 5.3.3.2, read 2026-10-24](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

## Modelo fijado y control

```json
{
  "values": {
    "item_ids": [
      "a",
      "b",
      "c",
      "d"
    ],
    "manual_miss": [
      1,
      0,
      0,
      0
    ],
    "assisted_miss": [
      1,
      1,
      1,
      0
    ]
  },
  "formula": "Miss=1 means accepting the planted wrong suggestion; miss_rate=sum(miss)/n; paired excess=(assisted misses-manual misses)/n; count discordant paired items.",
  "expected": {
    "manual_miss_rate": 0.25,
    "assisted_miss_rate": 0.75,
    "paired_excess": 0.5,
    "assisted_only_misses": [
      "b",
      "c"
    ],
    "manual_only_misses": []
  },
  "negative_control": {
    "values": {
      "item_ids": [
        "a",
        "b",
        "c",
        "d"
      ],
      "manual_miss": [
        1,
        0,
        0,
        0
      ],
      "assisted_miss": [
        1,
        0,
        0,
        0
      ]
    },
    "expected": {
      "manual_miss_rate": 0.25,
      "assisted_miss_rate": 0.25,
      "paired_excess": 0,
      "assisted_only_misses": [],
      "manual_only_misses": []
    },
    "why": "Equal paired outcomes remove the excess without manufacturing independent human observations."
  },
  "assumptions": [
    "Same stipulated item key and paired item identities.",
    "Vectors are authored; no causal effect of assistance is inferred."
  ],
  "limits": "Catch items assess these planted errors; tiny paired counts and unobserved order cannot establish automation complacency in users."
}
```

### Ejercicio 1

Calcule ambas tasas de omisión según la definición.

<details><summary>Respuesta 1</summary>

La tasa manual es `0.25`; la asistida es `0.75`. Omitir significa aceptar la respuesta falsa introducida. Son vectores construidos, no observaciones de revisores reales.

</details>

### Ejercicio 2

Calcule el exceso emparejado y nombre los elementos discordantes.

<details><summary>Respuesta 2</summary>

El exceso es `0.5`. Los elementos `b` y `c` son omisiones solo asistidas; no hay omisiones solo manuales. Conserve identidades para examinar después el razonamiento real.

</details>

### Ejercicio 3

Aplique el control de vectores iguales. ¿Copiar crea otro revisor?

<details><summary>Respuesta 3</summary>

Ambas tasas pasan a `0.25` y el exceso a `0`. No hay discordancias. Copiar es un control matemático; no crea revisión independiente ni otra condición real.

</details>

### Ejercicio 4

¿Demuestra la diferencia que la asistencia causa complacencia?

<details><summary>Respuesta 4</summary>

No. Los datos son inventados y no se observaron orden, familiaridad, equivalencia ni asignación. El cálculo identifica una posible señal de supervisión sin diagnosticar su causa psicológica.

</details>

### Ejercicio 5

¿Qué debe guardar un registro real antes de revelar una corrección?

<details><summary>Respuesta 5</summary>

Conserve sugerencia original, error de la clave, respuesta, identidad, modo, orden y otras ayudas. Mantenga la omisión inicial antes de corregir; sustituirla por la respuesta final borraría el evento evaluado.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
