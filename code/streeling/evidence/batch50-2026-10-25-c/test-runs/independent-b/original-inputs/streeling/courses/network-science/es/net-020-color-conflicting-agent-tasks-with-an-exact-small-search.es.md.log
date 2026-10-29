---
module_id: "net-020-color-conflicting-agent-tasks-with-an-exact-small-search"
department: "network-science"
course: "Colorear tareas agénticas incompatibles con búsqueda exacta"
title: "Colorear tareas agénticas incompatibles con búsqueda exacta"
level: "intermediate"
prerequisites: ["net-017-match-simultaneous-roles-without-double-booking", "net-007-separate-dag-readiness-from-admission"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Colorear tareas agénticas incompatibles con búsqueda exacta

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Varias tareas agénticas listas pueden ser incompatibles en el mismo turno porque modifican un recurso compartido. Un DAG de precedencia no captura todas esas incompatibilidades. Un grafo no dirigido conecta tareas que no pueden compartir turno. Un color representa un turno, no un trabajador ni una prueba de capacidad.

Busque asignaciones aumentando el número de colores. Acepte una asignación solo si cada arista tiene extremos de colores distintos. La primera cantidad factible demuestra optimalidad para este pequeño grafo enumerado por completo. Para mostrar un resultado determinista, conserve el primer vector lexicográfico en el orden de nodos declarado. Renombrar colores no altera la cantidad mínima de turnos.

El ciclo fijo necesita menos turnos que el control, que añade una diagonal y forma un triángulo. Este da una cota inferior inmediata porque sus vértices son incompatibles entre sí. La documentación presenta la coloración voraz como un intento de usar pocos colores, sin prometer el óptimo exacto de nuestra enumeración. Faltan duraciones, disponibilidad, memoria y dependencias entre turnos. Un futuro DSL no debería confundir esta coloración con un plan completo de ejecución concurrente.

## Fuentes y alcance del proyecto

[Prerrequisito: net-017-match-simultaneous-roles-without-double-booking](../../network-science/en/net-017-match-simultaneous-roles-without-double-booking.md)

[Prerrequisito: net-007-separate-dag-readiness-from-admission](../../network-science/en/net-007-separate-dag-readiness-from-admission.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.coloring.greedy_color.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "nodes": [
      "A",
      "B",
      "C",
      "D"
    ],
    "edges": [
      [
        "A",
        "B"
      ],
      [
        "B",
        "C"
      ],
      [
        "C",
        "D"
      ],
      [
        "D",
        "A"
      ]
    ]
  },
  "formula": "For k from 1 to len(nodes), enumerate color vectors in lexicographic order from range(k)^len(nodes); valid iff every undirected edge has different endpoint colors. Return first feasible k and first valid vector.",
  "expected": {
    "chromatic_number": 2,
    "colors": [
      0,
      1,
      0,
      1
    ]
  },
  "negative_control": {
    "values": {
      "nodes": [
        "A",
        "B",
        "C",
        "D"
      ],
      "edges": [
        [
          "A",
          "B"
        ],
        [
          "B",
          "C"
        ],
        [
          "C",
          "D"
        ],
        [
          "D",
          "A"
        ],
        [
          "A",
          "C"
        ]
      ]
    },
    "expected": {
      "chromatic_number": 3,
      "colors": [
        0,
        1,
        2,
        1
      ]
    },
    "why": "A new conflict closes a triangle and raises the required slot count."
  },
  "input_types": {
    "nodes": "ordered distinct node strings",
    "edges": "simple undirected pairs; edge means simultaneous-slot incompatibility"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No actual schedule, capability assignment, equal-duration guarantee, worker availability or greedy-optimality theorem is claimed."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Dibujar conflictos y enumerar asignaciones comprobando cada arista.

**Criterio de refutación:** Un turno contiene extremos incompatibles o se afirma optimalidad voraz sin prueba.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Coloree el ciclo de conflictos fijo.

> **Respuesta:** La primera coloración mínima es `[0,1,0,1]`, con `2` turnos. Cada arista separa colores distintos.

### Ejercicio 2

Explique el control con diagonal.

> **Respuesta:** Añadir `[A,C]` crea un triángulo. El mínimo es `3`, con primera coloración `[0,1,2,1]`.

### Ejercicio 3

¿Un resultado voraz certifica aquí el mínimo?

> **Respuesta:** Por sí solo, no. La búsqueda exacta y las cotas justifican el mínimo; una asignación voraz solo demuestra factibilidad.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: La primera coloración mínima es `[0,1,0,1]`, con `2` turnos. Cada arista separa colores distintos.
- Ejercicio 2: Añadir `[A,C]` crea un triángulo. El mínimo es `3`, con primera coloración `[0,1,2,1]`.
- Ejercicio 3: Por sí solo, no. La búsqueda exacta y las cotas justifican el mínimo; una asignación voraz solo demuestra factibilidad.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
