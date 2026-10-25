---
module_id: "cyb-016-test-feedforward-against-disturbance-mismatch"
department: "cybernetics"
course: "Probar la compensación anticipada con una perturbación mal estimada"
level: "intermediate"
prerequisites: ["cyb-010-separate-derivative-noise-from-plant-motion"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Probar la compensación anticipada con una perturbación mal estimada

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un agente prevé una carga entrante y propone compensarla antes de observar un error de salida. Esa vía de información difiere de la realimentación del residuo. La referencia directa ignora la estimación de perturbación; la propuesta la resta antes de dividir por la ganancia supuesta.

El extracto oficial de Caltech consultado describe la compensación anticipada con una perturbación medida y su dependencia del modelo de planta. Solo estuvo disponible ese pasaje extraído; falló la descarga completa. Nuestra ecuación escalar estática es una simplificación construida, sin inferir ajustes de producción de la lectura. Permite ver el desajuste de estimación.

Calcule la salida con la perturbación real estipulada, no con la estimación usada para mandar. De lo contrario, el modelo confirmaría su propia predicción. Compare los residuos absolutos con la referencia directa. El control introduce una estimación errónea: ayudar en un caso no garantiza ayudar en otro. El DSL debe conservar el papel de cada cantidad.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cyb-010-separate-derivative-noise-from-plant-motion](../../cybernetics/en/cyb-010-separate-derivative-noise-from-plant-motion.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://www.cds.caltech.edu/~murray/books/AM08/pdf/cds101-complete_20Sep07.pdf)

## Modelo fijo y control

```json
{
  "values": {
    "target": 10,
    "plant_gain": 2,
    "disturbance": 4,
    "measured_disturbance": 3,
    "assumed_gain": 2
  },
  "formula": "No compensation: u=target/assumed_gain. Feedforward: u=(target-measured_disturbance)/assumed_gain. Actual y=plant_gain*u+disturbance; error=y-target.",
  "expected": {
    "baseline_command": 5,
    "baseline_output": 14,
    "baseline_error": 4,
    "command": 3.5,
    "output": 11,
    "error": 1
  },
  "negative_control": {
    "values": {
      "target": 10,
      "plant_gain": 2,
      "disturbance": 4,
      "measured_disturbance": 10,
      "assumed_gain": 2
    },
    "expected": {
      "baseline_command": 5,
      "baseline_output": 14,
      "baseline_error": 4,
      "command": 0,
      "output": 4,
      "error": -6
    },
    "why": "Overstating the disturbance makes compensation worse in absolute error than the direct baseline."
  },
  "assumptions": [
    "Static scalar plant, known positive gain, additive disturbance; command unrestricted.",
    "Measurement available before command; no feedback, delay or noise distribution."
  ],
  "limits": "No live GA controller or universal benefit; inaccurate gain or disturbance can reverse the comparison.",
  "input_types": {
    "target": "real output units",
    "plant_gain": "positive real output/command",
    "disturbance": "real output units",
    "measured_disturbance": "real output units",
    "assumed_gain": "positive real output/command"
  }
}
```

### Ejercicio 1

Calcule la referencia sin compensación.

<details><summary>Respuesta 1</summary>

El mando `5` produce una salida de `14` y un error de `4`. Usa la meta y la ganancia supuesta sin restar la perturbación.

</details>

### Ejercicio 2

Calcule el mando propuesto y su salida.

<details><summary>Respuesta 2</summary>

El mando `3.5` produce una salida de `11` y un error de `1`. La perturbación sigue en `4`, aunque se estime en `3`.

</details>

### Ejercicio 3

¿Por qué no usar la estimación para la salida real?

<details><summary>Respuesta 3</summary>

Sustituiría el mundo estipulado por la estimación del controlador y ocultaría el desajuste. La predicción y la entrada real del modelo tienen papeles distintos.

</details>

### Ejercicio 4

Aplique el control sobreestimado.

<details><summary>Respuesta 4</summary>

El mando `0` produce una salida de `4` y un error de `-6`. Su valor absoluto supera el `4` de referencia; la compensación empeora el resultado.

</details>

### Ejercicio 5

¿Qué falta para recomendar un cambio?

<details><summary>Respuesta 5</summary>

Una ganancia justificada, una medición oportuna, límites de mando y evidencia real de la tarea. El cálculo fijo no aporta esas observaciones.

</details>

## Tarea con consulta de fuentes

Compare mandos directos y compensados en una nota de carga ficticia de GA.

**Referencia manual directa:** Separe en papel la ganancia supuesta, la perturbación estimada y la ecuación de salida real.

**Criterio de refutación:** Se afirma que la compensación siempre mejora pese al peor residuo del control.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
