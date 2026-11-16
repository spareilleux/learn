---
module_id: "cog-012-separate-review-alert-hit-rate-from-response-bias"
department: "cognitive-science"
course: "Separar la tasa de aciertos de las alertas y la tendencia de respuesta"
level: "intermediate"
prerequisites: ["cog-011-measure-rubric-disagreement-before-adjudication"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Separar la tasa de aciertos de las alertas y la tendencia de respuesta

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un asistente detecta casi todos los defectos introducidos y recibe elogios por su sensibilidad. Puede estar señalando también casi todos los elementos correctos. El prerrequisito compara revisores sin decidir quién tiene razón. Esta lección proporciona una clave externa explícita y pregunta cómo se comporta cada respuesta condicionada a ella. Coincidir con otro revisor y detectar un defecto real son resultados diferentes.

Coloque el estado real en filas y la decisión de alerta en columnas, según la definición oficial de matriz de confusión. Un acierto pertenece a la fila de defectos y una falsa alarma a la de elementos correctos. Necesitan denominadores distintos. La frecuencia global de alerta mezcla ambas filas y depende de la cantidad de defectos. Llamarla sensibilidad ocultaría esa dependencia.

Usamos la diferencia entre aciertos y falsas alarmas como medida descriptiva declarada de separación. No es sensibilidad gaussiana de detección de señales ni identifica un mecanismo psicológico. Una tendencia a responder sí puede cambiar ambas tasas. El control que siempre alerta resulta útil: su tasa perfecta de aciertos coexiste con separación nula. Expone lo que omite el titular sin exigir un modelo distribucional.

El registro conservado de GA indica que una confianza mostrada es un valor de recuperación y que los datos seleccionados no contienen respuestas de alumnos. No proporciona la clave externa ni respuestas reales de revisión. Un futuro ensayo debe conservar elementos correctos y defectuosos, clave adjudicada, alertas originales e historial de ayuda. Calcule primero la tabla manualmente y cuestione cualquier resumen que convierta solo los aciertos en evidencia de mejor juicio.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cog-011-measure-rubric-disagreement-before-adjudication](../../cognitive-science/en/cog-011-measure-rubric-disagreement-before-adjudication.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria: scikit-learn 1.9.1 documentation, read 2026-10-24](https://scikit-learn.org/stable/modules/generated/sklearn.metrics.confusion_matrix.html)

## Modelo fijado y control

```json
{
  "values": {
    "true_positive": 8,
    "false_negative": 2,
    "false_positive": 4,
    "true_negative": 6
  },
  "formula": "hit=TP/(TP+FN); false_alarm=FP/(FP+TN); alert=(TP+FP)/N; accuracy=(TP+TN)/N; separation=hit-false_alarm.",
  "expected": {
    "hit_rate": 0.8,
    "false_alarm_rate": 0.4,
    "alert_rate": 0.6,
    "accuracy": 0.7,
    "separation": 0.4
  },
  "negative_control": {
    "values": {
      "true_positive": 10,
      "false_negative": 0,
      "false_positive": 10,
      "true_negative": 0
    },
    "expected": {
      "hit_rate": 1,
      "false_alarm_rate": 1,
      "alert_rate": 1,
      "accuracy": 0.5,
      "separation": 0
    },
    "why": "Alerting on every item maximizes hits while destroying discrimination under this rate contrast."
  },
  "assumptions": [
    "Independent external defect key is stipulated correct.",
    "Positive means flagging a defect; both true classes are nonempty."
  ],
  "limits": "Authored confusion table, not a human sensitivity estimate or evidence of psychological response bias; no signal-distribution model is assumed."
}
```

### Ejercicio 1

Calcule tasas de aciertos y falsas alarmas con sus denominadores propios.

<details><summary>Respuesta 1</summary>

La tasa de aciertos es `8/10=0.8`; la de falsas alarmas `4/10=0.4`. Ambas condicionan sobre el estado real. Dividir ambos recuentos por la colección entera respondería otra pregunta de frecuencia conjunta.

</details>

### Ejercicio 2

Calcule frecuencia de alertas, exactitud y separación declarada.

<details><summary>Respuesta 2</summary>

Son `0.6`, `0.7` y `0.4`. La frecuencia cuenta decisiones de alertar; la exactitud cuenta coincidencias con la clave; la separación contrasta tasas condicionales. Ninguna es un rasgo psicológico medido.

</details>

### Ejercicio 3

Aplique el control que siempre alerta. ¿Qué ocurre con la tasa de aciertos aparentemente excelente?

<details><summary>Respuesta 3</summary>

Los aciertos pasan a `1`, pero las falsas alarmas también son `1`, la exactitud `0.5` y la separación `0`. Detectarlo todo no demuestra discriminación si se señalan todos los elementos correctos.

</details>

### Ejercicio 4

¿La tabla de acuerdo del prerrequisito permitiría la misma conclusión?

<details><summary>Respuesta 4</summary>

No. El acuerdo necesita etiquetas emparejadas de revisores; este cálculo requiere una clave externa. Dos revisores pueden coincidir en una alerta equivocada, y la propia clave adjudicada puede necesitar validación independiente.

</details>

### Ejercicio 5

¿Qué debe conservar un estudio real antes de hablar de sesgo de respuesta?

<details><summary>Respuesta 5</summary>

Conserve estado de defecto, alertas originales, mezcla de elementos, construcción de la clave, instrucciones y ayuda. Las tasas motivan una pregunta sobre respuestas; no diagnostican cognición ni prueban una mejora de producción con recuentos inventados.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
