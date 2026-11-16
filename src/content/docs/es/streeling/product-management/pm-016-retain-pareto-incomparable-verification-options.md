---
title: Conservar opciones de verificación incomparables según Pareto
description: Conservar opciones de verificación incomparables según Pareto — Gestión de productos y proyectos
sidebar:
  label: PM-016 · Conservar opciones de verificación incomparables según Pareto
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-016-retain-pareto-incomparable-verification-options.es.md
---

:::note[Streeling University]
**PM-016** · Conservar opciones de verificación incomparables según Pareto · intermedio · 45 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-016-retain-pareto-incomparable-verification-options.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-014](../../product-management/pm-014-select-a-budgeted-portfolio-with-prerequisite-closure/), [PM-004](../../product-management/pm-004-craft-extension-release-decision/)
:::

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un coordinador de Learn compara procesos opcionales de verificación según esfuerzo inicial y una cantidad estipulada de defectos. Una opción puede ser más barata y otra presentar menos defectos. Una puntuación única necesitaría una regla explícita de intercambio entre dimensiones. La comparación de Pareto empieza descartando opciones que no ofrecen ventaja en los objetivos representados.

Aquí se minimizan todos los objetivos. Una opción domina a otra cuando no es peor en ninguna coordenada y mejora estrictamente al menos una. La igualdad completa no es dominancia estricta. Compare cada pareja y conserve las opciones no dominadas. Este orden parcial puede dejar varios candidatos: es un resultado honesto, no un fallo del optimizador.

El caso fijo contiene una opción dominada y varios compromisos genuinos. El control empeora otra opción hasta hacerla dominada. Descartarlas no decide entre los compromisos restantes ni demuestra cumplimiento de los criterios de publicación. Dimensiones ausentes, incertidumbre y prioridades podrían cambiar una decisión real. Las coordenadas son ficticias, no defectos medidos de los cursos. Un DSL debería mostrar el conjunto no dominado y la preferencia pendiente antes de recomendar una opción única.

## Fuentes y alcance del proyecto

[Prerrequisito: pm-014-select-a-budgeted-portfolio-with-prerequisite-closure](../../product-management/pm-014-select-a-budgeted-portfolio-with-prerequisite-closure/)

[Prerrequisito: pm-004-craft-extension-release-decision](../../product-management/pm-004-craft-extension-release-decision/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://web.stanford.edu/~boyd/cvxbook/bv_cvxslides.pdf)

## Modelo fijo y control negativo

```json
{
  "values": {
    "names": [
      "A",
      "B",
      "C",
      "D"
    ],
    "objectives": [
      [
        2,
        5
      ],
      [
        4,
        2
      ],
      [
        5,
        6
      ],
      [
        3,
        4
      ]
    ]
  },
  "formula": "Minimize every coordinate. i dominates j iff all objectives[i]<=objectives[j] coordinatewise and at least one strict inequality. Return nondominated names and all ordered [dominator,dominated] pairs in name order.",
  "expected": {
    "nondominated": [
      "A",
      "B",
      "D"
    ],
    "dominance_pairs": [
      [
        "A",
        "C"
      ],
      [
        "B",
        "C"
      ],
      [
        "D",
        "C"
      ]
    ]
  },
  "negative_control": {
    "values": {
      "names": [
        "A",
        "B",
        "C",
        "D"
      ],
      "objectives": [
        [
          2,
          5
        ],
        [
          4,
          2
        ],
        [
          5,
          6
        ],
        [
          4,
          5
        ]
      ]
    },
    "expected": {
      "nondominated": [
        "A",
        "B"
      ],
      "dominance_pairs": [
        [
          "A",
          "C"
        ],
        [
          "A",
          "D"
        ],
        [
          "B",
          "C"
        ],
        [
          "B",
          "D"
        ],
        [
          "D",
          "C"
        ]
      ]
    },
    "why": "Worsening an option removes its distinct tradeoff without supplying a preference among survivors."
  },
  "input_types": {
    "names": "ordered distinct option strings",
    "objectives": "equal-length finite minimization vectors, one per option"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No observed defects, chosen product policy, approved release or subjective utility scale is supplied."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Comparar parejas en una tabla de objetivos antes de ponderar.

**Criterio de refutación:** Una opción supuestamente dominada mejora un objetivo o se inventa un ganador entre opciones incomparables.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Halle el conjunto no dominado fijo.

> **Respuesta:** Los supervivientes son `[A,B,D]`. Cada uno domina a `C`, pero ninguno domina a otro superviviente.

### Ejercicio 2

Aplique el control de opción empeorada.

> **Respuesta:** Con `D=[4,5]`, tanto `A` como `B` dominan a `D`. El conjunto no dominado es `[A,B]`.

### Ejercicio 3

¿El conjunto restante justifica una elección única?

> **Respuesta:** No. El filtro de Pareto conserva compromisos. Elegir exige prioridades declaradas y todas las restricciones obligatorias.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Los supervivientes son `[A,B,D]`. Cada uno domina a `C`, pero ninguno domina a otro superviviente.
- Ejercicio 2: Con `D=[4,5]`, tanto `A` como `B` dominan a `D`. El conjunto no dominado es `[A,B]`.
- Ejercicio 3: No. El filtro de Pareto conserva compromisos. Elegir exige prioridades declaradas y todas las restricciones obligatorias.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
