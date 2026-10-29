---
module_id: "cog-014-report-risk-and-coverage-when-an-agent-abstains"
department: "cognitive-science"
course: "Informar del riesgo y la cobertura cuando un agente se abstiene"
level: "intermediate"
prerequisites: ["cog-003-calibrating-fretboard-confidence"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Informar del riesgo y la cobertura cuando un agente se abstiene

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un agente solo emite respuestas cuya confianza supera un umbral e informa de menos errores. Puede estar contestando menos preguntas. El prerrequisito evalúa exactitud probabilística con una puntuación adecuada; esta lección evalúa la selección. Un orden de confianza puede servir para seleccionar aunque los números no se hayan validado como probabilidades. El nombre del campo no demuestra calibración.

Conserve todos los elementos candidatos, incluidas las abstenciones. La cobertura divide respuestas aceptadas por elementos elegibles. El riesgo condicional divide errores aceptados por respuestas aceptadas. Los denominadores expresan preguntas distintas y ambos son necesarios. Informar solo del recuento de errores recompensa el silencio sin mostrar el servicio retirado.

El resumen de los autores sobre clasificación selectiva plantea un compromiso entre riesgo y cobertura. Usamos ese marco para una tabla finita, sin tomar resultados neuronales ni garantías probabilísticas del artículo. El umbral principal incluye igualdad. Una respuesta falsa muy bien clasificada sigue aceptada: seleccionar no elimina la necesidad de una clave. En un conjunto elegible fijo, bajar el umbral no puede reducir la cobertura. El riesgo condicional puede aumentar, disminuir o mantenerse según la corrección de los nuevos elementos aceptados; su dirección no está garantizada para datos arbitrarios.

El control de abstención total es esencial. Sin elementos aceptados, el denominador del riesgo está vacío. Regístrelo como no resuelto, sin asignarle perfección. Las observaciones conservadas distinguen confianza de recuperación y resultados de alumnos, por lo que no proporcionan nuestro vector. Una propuesta de dogfooding debe comparar la misma tarea elegible manualmente, conservar rechazos y declarar el coste de abstenerse antes de recomendar umbral.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cog-003-calibrating-fretboard-confidence](../../cognitive-science/en/cog-003-calibrating-fretboard-confidence.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria: Geifman and El-Yaniv, 1705.08500v2, 2017-06-01](https://arxiv.org/abs/1705.08500)

## Modelo fijado y control

```json
{
  "values": {
    "confidence": [
      0.95,
      0.9,
      0.8,
      0.6,
      0.4
    ],
    "correct": [
      1,
      0,
      1,
      0,
      1
    ],
    "threshold": 0.8
  },
  "formula": "Accept when confidence>=threshold; coverage=accepted/n; risk=accepted_errors/accepted, null if accepted=0.",
  "expected": {
    "accepted_indices": [
      0,
      1,
      2
    ],
    "accepted": 3,
    "errors": 1,
    "coverage": 0.6,
    "risk": 0.3333333333333333
  },
  "negative_control": {
    "values": {
      "confidence": [
        0.95,
        0.9,
        0.8,
        0.6,
        0.4
      ],
      "correct": [
        1,
        0,
        1,
        0,
        1
      ],
      "threshold": 0.99
    },
    "expected": {
      "accepted_indices": [],
      "accepted": 0,
      "errors": 0,
      "coverage": 0,
      "risk": null
    },
    "why": "Abstaining on everything supplies no conditional error estimate, rather than perfect answers."
  },
  "assumptions": [
    "Correctness key is stipulated external and fixed.",
    "Equality at threshold is accepted; original item order retained."
  ],
  "limits": "Finite authored risk/coverage point, not calibrated confidence, statistical risk guarantee or measured GA use."
}
```

### Ejercicio 1

¿Qué índices se aceptan en el umbral declarado, incluida la frontera?

<details><summary>Respuesta 1</summary>

Se aceptan `[0,1,2]`. Hay `3` respuestas aceptadas y `1` error. Se incluye la confianza `0.8` porque la comparación usa mayor o igual y no mayor estricto.

</details>

### Ejercicio 2

Calcule cobertura y riesgo condicional del caso principal.

<details><summary>Respuesta 2</summary>

La cobertura es `0.6`; el riesgo es `1/3=0.3333333333333333`. La primera usa todos los elementos elegibles y el segundo solo respuestas emitidas. Mantenga explícitos los denominadores.

</details>

### Ejercicio 3

Si el umbral baja a `0.4`, ¿qué sucede en esta tabla exacta?

<details><summary>Respuesta 3</summary>

Se aceptan los `5` elementos, la cobertura es `1` y el riesgo `2/5=0.4`. La comparación corresponde a un orden fijo, sin demostrar una ley universal de monotonía del riesgo empírico.

</details>

### Ejercicio 4

Aplique el control de abstención total. ¿Su riesgo es cero?

<details><summary>Respuesta 4</summary>

No. La cobertura es `0` y el riesgo `null` porque no se emitieron respuestas. Un denominador condicional vacío no proporciona estimación; llamarlo perfecto premiaría no contestar nada.

</details>

### Ejercicio 5

¿Qué justificaría recomendar un umbral real?

<details><summary>Respuesta 5</summary>

Conserve tarea elegible, clave real, respuestas emitidas y retenidas, ayuda y coste de abstención. Compare con la referencia manual. Ni un valor de recuperación ni estos vectores inventados demuestra capacidad del alumno o garantías de riesgo en producción.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
