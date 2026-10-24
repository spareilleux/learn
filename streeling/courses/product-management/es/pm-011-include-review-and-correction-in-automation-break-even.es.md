---
module_id: "pm-011-include-review-and-correction-in-automation-break-even"
department: "product-management"
course: "Incluir revisión y corrección en el equilibrio de automatización"
level: "intermediate"
prerequisites: ["pm-006-test-a-pilot-against-its-decision-horizon", "pm-008-size-a-fifty-course-batch-by-review-capacity"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Incluir revisión y corrección en el equilibrio de automatización

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un equipo observa borradores generados rápidamente y propone automatizar la siguiente tanda. La velocidad de redacción omite preparación, revisión y corrección. El prerrequisito de horizonte valora información para futuras decisiones; el de capacidad mantiene visible la revisión. Esta lección calcula si un modelo operativo construido recupera preparación conservando la misma tarea terminada y revisión obligatoria.

Defina la referencia manual como trabajo activo de un elemento aceptado equivalente, sin compararlo con una nota sin revisar. La ruta automática incluye redacción y revisión por elemento, más coste de corrección multiplicado por su probabilidad. La probabilidad es inventada y se refiere a elementos que necesitan esa corrección. No afirma independencia ni detección de todos los defectos. Una comparación real debe medir toda la ruta y conservar fallos de calidad.

Reste coste automático por elemento del manual antes de calcular equilibrio. Solo un ahorro positivo recupera preparación positiva. La igualdad en el umbral no aporta ahorro, así que una recomendación estricta necesita el siguiente entero. Si desaparece el ahorro unitario, aumentar la tanda nunca elimina el coste inicial. Un informe que cita solo latencia de borradores oculta ese límite.

El registro conservado separa pérdidas construidas de tiempo real y advierte que metodología no calibra rendimiento. Aquí usamos minutos, pero siguen siendo entradas inventadas. El [NIST](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm) motiva comparar operadores y condiciones equivalentes en una medición futura. Un DSL o bucle de agentes sigue como candidato hasta que un ensayo conserve registros manuales y asistidos, alcance equivalente, historial de correcciones y salidas realmente aceptadas.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: pm-006-test-a-pilot-against-its-decision-horizon](../../product-management/en/pm-006-test-a-pilot-against-its-decision-horizon.md)

[Prerrequisito: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/en/pm-008-size-a-fifty-course-batch-by-review-capacity.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lectura primaria: NIST/SEMATECH e-Handbook section 5.3.3.2, read 2026-10-24](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

## Modelo fijado y control

```json
{
  "values": {
    "items": 40,
    "manual_minutes_per_item": 12,
    "setup_minutes": 60,
    "draft_minutes_per_item": 3,
    "review_minutes_per_item": 5,
    "correction_probability": 0.25,
    "correction_minutes_if_needed": 8
  },
  "formula": "automated_per_item=draft+review+p*correction; manual_total=n*manual; automated_total=setup+n*automated_per_item; net_saved=manual_total-automated_total; strict break-even requires n>setup/(manual-automated_per_item) when denominator positive.",
  "expected": {
    "automated_minutes_per_item": 10,
    "manual_total_minutes": 480,
    "automated_total_minutes": 460,
    "net_saved_minutes": 20,
    "equal_cost_items": 30,
    "minimum_integer_items_for_strict_saving": 31
  },
  "negative_control": {
    "values": {
      "items": 40,
      "manual_minutes_per_item": 12,
      "setup_minutes": 60,
      "draft_minutes_per_item": 3,
      "review_minutes_per_item": 5,
      "correction_probability": 0.25,
      "correction_minutes_if_needed": 16
    },
    "expected": {
      "automated_minutes_per_item": 12,
      "manual_total_minutes": 480,
      "automated_total_minutes": 540,
      "net_saved_minutes": -60,
      "equal_cost_items": null,
      "minimum_integer_items_for_strict_saving": null
    },
    "why": "Zero per-item savings cannot recover a positive setup cost at any finite batch size."
  },
  "assumptions": [
    "All times are invented active-work minutes on one comparable task.",
    "Correction probability and conditional cost are stable and review is always performed.",
    "Quality and completed scope must be comparable before cost comparison."
  ],
  "limits": "Expected-cost arithmetic, not measured throughput, real savings, learner value, monetary cost or production adoption."
}
```

### Ejercicio 1

Calcule el trabajo activo automático esperado por elemento.

<details><summary>Respuesta 1</summary>

Es `3+5+0.25*8=10` minutos. Se cobra revisión para cada elemento y corrección según probabilidad estipulada. Es una esperanza, sin ejecución de tiempos observados.

</details>

### Ejercicio 2

Calcule totales y ahorro neto de la tanda declarada.

<details><summary>Respuesta 2</summary>

El total manual es `480` minutos, automático `460` y ahorro `20` minutos. La preparación se cobra una vez; todo trabajo unitario escala con `40` elementos.

</details>

### Ejercicio 3

Encuentre igualdad y menor tanda entera con ahorro estricto.

<details><summary>Respuesta 3</summary>

La igualdad ocurre en `30` elementos porque el ahorro unitario es `2` minutos y la preparación `60` minutos. El menor entero con ahorro estricto es `31`. Un empate no es ahorro positivo.

</details>

### Ejercicio 4

Aplique el control de corrección más larga. ¿Una tanda mayor recuperaría preparación?

<details><summary>Respuesta 4</summary>

El coste unitario esperado pasa a `12` minutos. El total declarado es `540` y el ahorro `-60`. Al ser nulo el ahorro unitario, no existe equilibrio estricto finito bajo el modelo.

</details>

### Ejercicio 5

¿Qué refutaría una recomendación práctica de automatización?

<details><summary>Respuesta 5</summary>

Trabajo activo real completo sin el ahorro previsto, con calidad aceptada comparable, la rechazaría. Conserve preparación, revisión, fallos, correcciones y ayuda. Generar rápido o usar estos tiempos inventados no demuestra adopción ni eficiencia de producción.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
