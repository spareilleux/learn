---
module_id: "cyb-015-carry-covariance-through-smoothed-telemetry"
department: "cybernetics"
course: "Propagar la covarianza en la telemetría suavizada"
level: "intermediate"
prerequisites: ["cyb-010-separate-derivative-noise-from-plant-motion"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Propagar la covarianza en la telemetría suavizada

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un panel más tranquilo no es necesariamente más preciso. Las mediciones sucesivas pueden compartir una fuente de error. Aplicarles una fórmula que supone independencia puede subestimar la incertidumbre aunque el suavizado sea correcto. El curso sobre derivadas ya ofrece una recurrencia; este añade el cálculo de incertidumbre para una historia finita.

NIST presenta una aproximación de varianza para una serie larga y declara condiciones de independencia. Aquí la serie es corta y tiene un estado inicial. Expanda primero los pesos y use después toda la matriz de covarianza. Los términos fuera de la diagonal importan cuando los errores varían juntos. El estado inicial determinista conserva peso y puede causar sesgo.

Mantenga unidades simbólicas de seguimiento. La esperanza procede de errores estipulados; no es un promedio observado de trazas del proyecto. Antes de proponer un ajuste de agente, conserve la inicialización, las hipótesis de covarianza y el retraso de respuesta que este modelo constante omite.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cyb-010-separate-derivative-noise-from-plant-motion](../../cybernetics/en/cyb-010-separate-derivative-noise-from-plant-motion.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc324.htm)

## Modelo fijo y control

```json
{
  "values": {
    "alpha": 0.5,
    "initial": 0,
    "true_level": 4,
    "error_covariance": [
      [
        4,
        2
      ],
      [
        2,
        4
      ]
    ]
  },
  "formula": "After two EWMA updates weights are [alpha*(1-alpha),alpha]; expected=sum(weights)*true_level+(1-alpha)^2*initial; bias=expected-true_level; variance=w^T*Cov*w.",
  "expected": {
    "weights": [
      0.25,
      0.5
    ],
    "expected_level": 3,
    "bias": -1,
    "variance": 1.75
  },
  "negative_control": {
    "values": {
      "alpha": 0.5,
      "initial": 0,
      "true_level": 4,
      "error_covariance": [
        [
          4,
          0
        ],
        [
          0,
          4
        ]
      ]
    },
    "expected": {
      "weights": [
        0.25,
        0.5
      ],
      "expected_level": 3,
      "bias": -1,
      "variance": 1.25
    },
    "why": "Removing cross-covariance changes variance while the initialized mean and bias stay fixed."
  },
  "assumptions": [
    "Two zero-mean errors with the stipulated covariance matrix; deterministic initial state.",
    "No feedback or changing true level."
  ],
  "limits": "Finite authored moments, not estimated GA noise, confidence intervals or closed-loop stability.",
  "input_types": {
    "alpha": "real in (0,1]",
    "initial": "real",
    "true_level": "real",
    "error_covariance": "positive semidefinite 2x2 matrix"
  }
}
```

### Ejercicio 1

Expanda los pesos de las mediciones.

<details><summary>Respuesta 1</summary>

Los pesos son `[0.25,0.5]`; el estado inicial conserva `0.25`. Las mediciones suman `0.75`, por lo que la inicialización aún importa.

</details>

### Ejercicio 2

Calcule la esperanza y el sesgo.

<details><summary>Respuesta 2</summary>

El nivel esperado es `3` y el sesgo respecto a `4` es `-1`. Esta historia finita aún no alcanza el nivel estipulado.

</details>

### Ejercicio 3

Calcule la varianza completa.

<details><summary>Respuesta 3</summary>

La diagonal aporta `1.25` y los términos cruzados `0.5`, para un total de `1.75`. Omitir la covarianza cambia el cálculo.

</details>

### Ejercicio 4

Aplique el control independiente.

<details><summary>Respuesta 4</summary>

La varianza pasa a `1.25`. La esperanza sigue en `3` y el sesgo en `-1`; la independencia no elimina el sesgo inicial.

</details>

### Ejercicio 5

¿Un panel más tranquilo demuestra estabilidad?

<details><summary>Respuesta 5</summary>

No. El modelo no contiene planta ni realimentación. Hacen falta errores, tiempos y costes reales antes de elegir una política.

</details>

## Tarea con consulta de fuentes

Prepare una nota de incertidumbre para dos actualizaciones ficticias del seguimiento de GA.

**Referencia manual directa:** Expanda las actualizaciones en papel, conserve el peso inicial y use la covarianza completa.

**Criterio de refutación:** Una varianza favorable omite términos cruzados o aplica la fórmula asintótica a este caso finito inicializado.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
