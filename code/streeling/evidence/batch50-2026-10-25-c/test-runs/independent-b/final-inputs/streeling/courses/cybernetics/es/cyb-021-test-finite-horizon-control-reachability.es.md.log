---
module_id: "cyb-021-test-finite-horizon-control-reachability"
department: "cybernetics"
course: "Comprobar la alcanzabilidad en un horizonte finito"
title: "Comprobar la alcanzabilidad en un horizonte finito"
level: "intermediate"
prerequisites: ["cyb-018-reconstruct-hidden-state-from-distinct-dynamics", "cyb-019-test-coupled-feedback-eigenmodes", "mat-024-dynamical-systems-stability-feedback"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Comprobar la alcanzabilidad en un horizonte finito

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un coordinador agéntico puede observar una cola sin disponer de acciones que alcancen una meta antes del plazo. Ni siquiera un rango completo de controlabilidad resuelve la cuestión cuando las órdenes son acotadas o discretas. El curso de matemáticas ya enseña ese criterio para el doble integrador. Aquí se añade otra operación: enumerar secuencias permitidas, comprobar el punto final y minimizar una energía de mando declarada.

Desarrolle la recurrencia en orden temporal de entradas. Las primeras órdenes atraviesan más transiciones y tienen columnas distintas de las últimas. Conserve la matriz como diagnóstico, pero imponga el alfabeto de acciones durante la enumeración. Propague cada candidato, retenga coincidencias exactas con la meta y compare las sumas de cuadrados de órdenes. La búsqueda finita da un óptimo reproducible para ese alfabeto, no una solución de control continuo.

El horizonte fijo permite que una orden temprana acumule desplazamiento sin superar su magnitud permitida. El control acorta el horizonte: conserva rango completo, pero la solución sin límites requiere una orden prohibida. Ninguna secuencia admisible funciona. Más telemetría no crea la acción ausente y el rango no debe anular el rechazo. Un futuro DSL debería conservar horizonte, dominio de acciones y conjunto factible vacío antes de declarar ejecutable la meta.

## Fuentes y alcance del proyecto

[Prerrequisito: cyb-018-reconstruct-hidden-state-from-distinct-dynamics](../../cybernetics/en/cyb-018-reconstruct-hidden-state-from-distinct-dynamics.md)

[Prerrequisito: cyb-019-test-coupled-feedback-eigenmodes](../../cybernetics/en/cyb-019-test-coupled-feedback-eigenmodes.md)

[Prerrequisito: mat-024-dynamical-systems-stability-feedback](../../mathematics/en/mat-024-dynamical-systems-stability-feedback.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://hankyang.seas.harvard.edu/OptimalControlEstimation/app-lti-system-theory.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "A": [
      [
        1,
        1
      ],
      [
        0,
        1
      ]
    ],
    "B": [
      0,
      1
    ],
    "initial": [
      0,
      0
    ],
    "target": [
      2,
      1
    ],
    "horizon": 3,
    "allowed_controls": [
      -1,
      0,
      1
    ]
  },
  "formula": "For x_next=A*x+B*u, enumerate every allowed_controls sequence of length horizon in lexicographic order. Propagate from initial; retain sequences whose final state equals target. Report reachability_matrix=[A^(horizon-1)*B,...,B] and its exact rank separately. Minimize sum(u*u) over feasible sequences, retaining all ties. Empty feasible set has null minimum_energy and null final_state.",
  "expected": {
    "reachability_matrix": [
      [
        2,
        1,
        0
      ],
      [
        1,
        1,
        1
      ]
    ],
    "rank": 2,
    "feasible_sequences": [
      [
        1,
        0,
        0
      ]
    ],
    "minimum_energy": 1,
    "optimal_controls": [
      [
        1,
        0,
        0
      ]
    ],
    "final_state": [
      2,
      1
    ]
  },
  "negative_control": {
    "values": {
      "A": [
        [
          1,
          1
        ],
        [
          0,
          1
        ]
      ],
      "B": [
        0,
        1
      ],
      "initial": [
        0,
        0
      ],
      "target": [
        2,
        1
      ],
      "horizon": 2,
      "allowed_controls": [
        -1,
        0,
        1
      ]
    },
    "expected": {
      "reachability_matrix": [
        [
          1,
          0
        ],
        [
          1,
          1
        ]
      ],
      "rank": 2,
      "feasible_sequences": [],
      "minimum_energy": null,
      "optimal_controls": [],
      "final_state": null
    },
    "why": "The shorter horizon retains full linear controllability rank but cannot reach the target with the declared bounded discrete action alphabet."
  },
  "input_types": {
    "A": "rational two-by-two transition matrix",
    "B": "rational two-vector for scalar input",
    "initial": "rational initial two-vector",
    "target": "rational target two-vector",
    "horizon": "positive integer",
    "allowed_controls": "ordered distinct finite rational scalar actions"
  },
  "assumptions": [
    "Every action sequence uses only the declared finite action alphabet.",
    "Energy is the stipulated sum of squared commands, not measured electricity or human effort."
  ],
  "limits": "Finite exhaustive bounded-command feasibility and energy are new here; unrestricted linear rank is baseline knowledge. No actual queue, continuous-input optimum, physical controller or execution permission is established."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Enumerar secuencias permitidas, propagar estados y comparar energías cuadráticas de llegadas exactas.

**Criterio de refutación:** La meta declarada ejecutable por su rango no tiene secuencia que respete horizonte y alfabeto de acciones.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

¿Por qué conservar el orden temporal de las órdenes?

> **Respuesta:** La matriz fija es `[A*A*B,A*B,B]` para `[u0,u1,u2]`. Las primeras órdenes se propagan más tiempo y tienen efectos finales distintos.

### Ejercicio 2

Halle el óptimo acotado fijo.

> **Respuesta:** La matriz `[[2,1,0],[1,1,1]]` tiene rango `2`. La única secuencia factible `[1,0,0]` alcanza `[2,1]` con energía cuadrática `1`.

### Ejercicio 3

¿Por qué el rango completo no salva el control de horizonte corto?

> **Respuesta:** Con horizonte `2`, la matriz mantiene rango `2`, pero la solución sin límites `[2,-1]` usa la acción prohibida `2`. El conjunto factible está vacío; la energía mínima es `null`.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: La matriz fija es `[A*A*B,A*B,B]` para `[u0,u1,u2]`. Las primeras órdenes se propagan más tiempo y tienen efectos finales distintos.
- Ejercicio 2: La matriz `[[2,1,0],[1,1,1]]` tiene rango `2`. La única secuencia factible `[1,0,0]` alcanza `[2,1]` con energía cuadrática `1`.
- Ejercicio 3: Con horizonte `2`, la matriz mantiene rango `2`, pero la solución sin límites `[2,-1]` usa la acción prohibida `2`. El conjunto factible está vacío; la energía mínima es `null`.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
