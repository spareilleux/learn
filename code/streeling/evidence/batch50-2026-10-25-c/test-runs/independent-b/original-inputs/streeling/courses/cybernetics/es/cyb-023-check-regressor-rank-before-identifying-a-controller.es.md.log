---
module_id: "cyb-023-check-regressor-rank-before-identifying-a-controller"
department: "cybernetics"
course: "Comprobar el rango de los regresores antes de identificar un controlador"
title: "Comprobar el rango de los regresores antes de identificar un controlador"
level: "intermediate"
prerequisites: ["cyb-018-reconstruct-hidden-state-from-distinct-dynamics", "cyb-016-test-feedforward-against-disturbance-mismatch"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Comprobar el rango de los regresores antes de identificar un controlador

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Antes de que un agente ajuste una regla de respuesta, debe comprobar si los experimentos distinguen los parámetros desconocidos. Más filas no crean necesariamente información independiente. Repetir la misma proporción entre componentes de entrada puede dejar varios vectores de parámetros indistinguibles, incluso con respuestas ajustadas exactamente.

Escriba la respuesta estipulada como matriz de diseño por vector de parámetros. Examine la matriz de Gram y su rango antes de resolver las ecuaciones normales. Una matriz no singular da una solución única de mínimos cuadrados para este problema finito. Una matriz singular revela direcciones paramétricas que los ensayos nunca distinguen. Añadir silenciosamente regularización seleccionaría una solución mediante otro supuesto.

El diseño fijo excita direcciones independientes y recupera la pareja indicada. El control tiene columnas proporcionales: varias parejas con la misma suma pertinente reproducen todas las respuestas. El rango finito sirve como comprobación concreta de excitación; no demuestra excitación persistente uniforme en una señal infinita. Ruido, error de modelo y condicionamiento necesitan otras evidencias. Un futuro DSL debería conservar regresores e identidades de ensayo, no solo un residuo pequeño.

## Fuentes y alcance del proyecto

[Prerrequisito: cyb-018-reconstruct-hidden-state-from-distinct-dynamics](../../cybernetics/en/cyb-018-reconstruct-hidden-state-from-distinct-dynamics.md)

[Prerrequisito: cyb-016-test-feedforward-against-disturbance-mismatch](../../cybernetics/en/cyb-016-test-feedforward-against-disturbance-mismatch.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://underactuated.csail.mit.edu/sysid.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "X": [
      [
        1,
        0
      ],
      [
        0,
        1
      ],
      [
        1,
        1
      ]
    ],
    "y": [
      2,
      3,
      5
    ]
  },
  "formula": "Compute Gram=X^T*X, rhs=X^T*y, exact rank and determinant. If full column rank solve Gram*theta=rhs; otherwise unique_parameters=null and report rank deficiency without pseudoinverse.",
  "expected": {
    "gram": [
      [
        2,
        1
      ],
      [
        1,
        2
      ]
    ],
    "rhs": [
      7,
      8
    ],
    "determinant": 3,
    "rank": 2,
    "unique_parameters": [
      2,
      3
    ]
  },
  "negative_control": {
    "values": {
      "X": [
        [
          1,
          1
        ],
        [
          2,
          2
        ],
        [
          3,
          3
        ]
      ],
      "y": [
        5,
        10,
        15
      ]
    },
    "expected": {
      "gram": [
        [
          14,
          14
        ],
        [
          14,
          14
        ]
      ],
      "rhs": [
        70,
        70
      ],
      "determinant": 0,
      "rank": 1,
      "unique_parameters": null
    },
    "why": "Repeated proportional regressors identify only a sum of parameters."
  },
  "input_types": {
    "X": "nonempty rational matrix with two columns",
    "y": "same-length rational response vector"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "Finite rank is not a uniform infinite-horizon persistent-excitation guarantee, noise robustness or an identified production controller."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Formar las matrices de diseño y Gram y mostrar una dirección nula cuando proceda.

**Criterio de refutación:** Se anuncia identificación única desde un diseño singular.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Calcule la matriz de Gram fija.

> **Respuesta:** La matriz es `[[2,1],[1,2]]`, con determinante `3` y rango `2`; los parámetros únicos son `[2,3]`.

### Ejercicio 2

Diagnostique el control colineal.

> **Respuesta:** La matriz `[[14,14],[14,14]]` tiene determinante `0` y rango `1`. Las parejas `[2,3]` y `[1,4]` ajustan igualmente.

### Ejercicio 3

¿Duplicar las filas del control identificaría ambos parámetros?

> **Respuesta:** No. Duplicar filas proporcionales cambia su peso, no la dirección ausente. Se necesita un regresor independiente.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: La matriz es `[[2,1],[1,2]]`, con determinante `3` y rango `2`; los parámetros únicos son `[2,3]`.
- Ejercicio 2: La matriz `[[14,14],[14,14]]` tiene determinante `0` y rango `1`. Las parejas `[2,3]` y `[1,4]` ajustan igualmente.
- Ejercicio 3: No. Duplicar filas proporcionales cambia su peso, no la dirección ausente. Se necesita un regresor independiente.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
