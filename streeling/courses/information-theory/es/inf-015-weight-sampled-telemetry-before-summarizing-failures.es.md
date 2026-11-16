---
module_id: "inf-015-weight-sampled-telemetry-before-summarizing-failures"
department: "information-theory"
course: "Ponderar la telemetría muestreada antes de resumir fallos"
level: "intermediate"
prerequisites: ["inf-011-separate-compressed-size-from-preserved-information", "pm-009-separate-release-adoption-from-artifact-downloads"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Ponderar la telemetría muestreada antes de resumir fallos

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un agente resume una muestra de telemetría como si todos los eventos tuvieran igual probabilidad de aparecer. Una política puede conservar clases con probabilidades distintas. El prerrequisito de compresión examina información preservada; el de adopción fija unidades de eventos y cohortes. Esta lección añade probabilidad de inclusión para interpretar los eventos, sin contar las filas visibles como población completa.

Asigne a cada evento retenido el inverso de su probabilidad. Estos recuentos ajustados representan los eventos atribuidos a cada observación bajo el diseño declarado. Súmelos para el total y sume las contribuciones fallidas para fallos ajustados. Su cociente es una estimación descriptiva útil, sin ser la media de las etiquetas binarias. Mantenga constantes unidad y alcance del muestreo.

La especificación [OpenTelemetry](https://opentelemetry.io/docs/specs/otel/trace/tracestate-handling/) denomina recuento ajustado a esa cantidad inversa. Nuestras probabilidades decimales son entradas construidas, sin leer trazas reales ni decodificar su umbral. La fuente respalda la ponderación; no proporciona probabilidades de GA ni certifica representatividad de esta pequeña muestra. El cociente de totales estimados también requiere análisis de incertidumbre antes de afirmar algo fuerte sobre la población.

El control con probabilidades iguales elimina ponderación desigual y hace coincidir las tasas. Probabilidades ausentes o nulas dejarían indefinido el estimador. No las sustituya por valores convenientes tras ver el resultado. Un resumen componible podría conservar metadatos de inclusión, pero primero reproduzca la tabla manualmente. Las observaciones del proyecto enumeran campos y distinguen puntuaciones de retención, sin aportar una población de fallos a la que atribuir los números inventados.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/en/inf-011-separate-compressed-size-from-preserved-information.md)

[Prerrequisito: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/en/pm-009-separate-release-adoption-from-artifact-downloads.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria: OpenTelemetry specification 1.62.0 displayed, read 2026-10-24](https://opentelemetry.io/docs/specs/otel/trace/tracestate-handling/)

## Modelo fijado y control

```json
{
  "values": {
    "sampled_failures": [
      1,
      0,
      0
    ],
    "inclusion_probabilities": [
      0.5,
      0.25,
      0.25
    ]
  },
  "formula": "weight_i=1/p_i; adjusted_total=sum(weight_i); adjusted_failures=sum(weight_i*failure_i); ratio=adjusted_failures/adjusted_total; raw_rate=sum(failure_i)/n.",
  "expected": {
    "weights": [
      2,
      4,
      4
    ],
    "adjusted_total": 10,
    "adjusted_failures": 2,
    "weighted_ratio": 0.2,
    "raw_rate": 0.3333333333333333
  },
  "negative_control": {
    "values": {
      "sampled_failures": [
        1,
        0,
        0
      ],
      "inclusion_probabilities": [
        1,
        1,
        1
      ]
    },
    "expected": {
      "weights": [
        1,
        1,
        1
      ],
      "adjusted_total": 3,
      "adjusted_failures": 1,
      "weighted_ratio": 0.3333333333333333,
      "raw_rate": 0.3333333333333333
    },
    "why": "Equal inclusion weights make the weighted ratio equal the raw sample rate."
  },
  "assumptions": [
    "Positive known inclusion probabilities correspond to each retained event.",
    "Failure indicators refer to one declared event unit."
  ],
  "limits": "Adjusted counts and ratio are estimates; this finite ratio is not promised unbiased and does not reveal exact population failures."
}
```

### Ejercicio 1

Calcule el peso de cada evento muestreado.

<details><summary>Respuesta 1</summary>

Los pesos son `[2,4,4]`, inversos de las probabilidades. Son recuentos ajustados de eventos, no milisegundos, confianza ni copias de eventos reales observados en la población.

</details>

### Ejercicio 2

Calcule total ajustado, fallos ajustados y cociente.

<details><summary>Respuesta 2</summary>

El total es `10`, los fallos `2` y el cociente `0.2`. Solo el primer evento contribuye a fallos. Los valores son estimaciones bajo el diseño supuesto.

</details>

### Ejercicio 3

Compare la tasa bruta y explique la diferencia.

<details><summary>Respuesta 3</summary>

La tasa bruta es `1/3=0.3333333333333333`. Da igual peso a cada fila. El cociente ponderado atribuye más contribución a eventos correctos de menor probabilidad, por lo que difiere en esta muestra construida.

</details>

### Ejercicio 4

Aplique el control con probabilidades iguales.

<details><summary>Respuesta 4</summary>

Los pesos pasan a `[1,1,1]`, total `3`, fallos `1` y cociente `0.3333333333333333`, igual a la tasa bruta. Pesos positivos iguales se cancelan en el cociente.

</details>

### Ejercicio 5

¿Puede presentarse el cociente como tasa exacta de fallos de producción?

<details><summary>Respuesta 5</summary>

No. La población no está observada, las probabilidades se estipulan y queda incertidumbre finita. Una probabilidad ausente deja el cálculo sin resolver. Conserve metadatos y no afirme que un cociente de totales estimados sea automáticamente insesgado.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
