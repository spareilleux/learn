---
title: Conectar una red de diagnóstico con coste mínimo
description: Conectar una red de diagnóstico con coste mínimo — Ciencia de redes
sidebar:
  label: NET-019 · Conectar una red de diagnóstico con coste mínimo
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/es/net-019-connect-a-diagnostic-backbone-at-minimum-edge-cost.es.md
---

:::note[Streeling University]
**NET-019** · Conectar una red de diagnóstico con coste mínimo · intermedio · 45 minutos

Generado por el departamento *Ciencia de redes* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/es/net-019-connect-a-diagnostic-backbone-at-minimum-edge-cost.es.md) · [Mi diario](../../journal/)

Requisitos previos: [NET-014](../../network-science/net-014-bound-throughput-with-a-capacity-cut/), [MAT-019](../../mathematics/mat-019-graphs-centrality-spectral/)
:::

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un boceto del observatorio necesita una pequeña red de diagnóstico que conecte varios componentes. Los enlaces candidatos tienen costes de instalación estipulados. Elegir por separado el enlace más barato de cada componente puede crear ciclos o dejar grupos desconectados. Un árbol de expansión expresa conectividad global sin enlaces redundantes para este objetivo concreto.

Enumere subconjuntos con la cantidad de aristas requerida, descarte los desconectados y compare la suma de costes. En un grafo no dirigido, un subconjunto conectado de ese tamaño es un árbol. El ejemplo pequeño permite comparación exhaustiva verificable. Si hay varios árboles de coste mínimo, consérvelos todos; los nombres de vértices no autorizan una selección arbitraria.

El control aumenta el coste de un enlace hasta que otra red resulta preferible. El árbol anterior sigue conectado, pero ya no es óptimo con esos costes. No se trata de un despliegue de red medido. Un árbol carece de ruta alternativa cuando falla una arista: coste mínimo no implica resiliencia. La documentación también distingue entradas desconectadas, que producen un bosque. Un futuro DSL de topología debería conservar estos supuestos de coste y conectividad.

## Fuentes y alcance del proyecto

[Prerrequisito: net-014-bound-throughput-with-a-capacity-cut](../../network-science/net-014-bound-throughput-with-a-capacity-cut/)

[Prerrequisito: mat-019-graphs-centrality-spectral](../../mathematics/mat-019-graphs-centrality-spectral/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.tree.mst.minimum_spanning_tree.html)

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
        "B",
        1
      ],
      [
        "A",
        "C",
        4
      ],
      [
        "A",
        "D",
        6
      ],
      [
        "B",
        "C",
        2
      ],
      [
        "B",
        "D",
        5
      ],
      [
        "C",
        "D",
        3
      ]
    ]
  },
  "formula": "Enumerate subsets of len(nodes)-1 undirected edges, retain connected subsets, sum weights and keep all minimum-cost trees. Sort each tree edge label and the list of optimal trees lexicographically.",
  "expected": {
    "minimum_cost": 6,
    "optimal_trees": [
      [
        "AB",
        "BC",
        "CD"
      ]
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
          "B",
          1
        ],
        [
          "A",
          "C",
          4
        ],
        [
          "A",
          "D",
          6
        ],
        [
          "B",
          "C",
          2
        ],
        [
          "B",
          "D",
          5
        ],
        [
          "C",
          "D",
          8
        ]
      ]
    },
    "expected": {
      "minimum_cost": 8,
      "optimal_trees": [
        [
          "AB",
          "BC",
          "BD"
        ]
      ]
    },
    "why": "The changed edge cost changes the minimum-cost connected subset."
  },
  "input_types": {
    "nodes": "ordered distinct node strings",
    "edges": "simple undirected [endpoint,endpoint,nonnegative cost] records on connected input"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No deployed topology, redundant connectivity, throughput optimum, failure probability or actual link cost is measured."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Enumerar subconjuntos conexos y comparar sus costes totales.

**Criterio de refutación:** La red está desconectada o existe un árbol más barato con los mismos datos.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Halle la red mínima fija.

> **Respuesta:** Las aristas `[AB,BC,CD]` conectan todos los nodos con coste `6`. El subconjunto es conexo y sin ciclos.

### Ejercicio 2

Aplique el control del enlace caro.

> **Respuesta:** El óptimo pasa a `[AB,BC,BD]`, con coste `8`. Mantener el árbol anterior costaría `11`.

### Ejercicio 3

¿El coste mínimo implica una ruta alternativa?

> **Respuesta:** No. Quitar cualquier arista del árbol lo desconecta. La resiliencia necesita otro objetivo o restricción.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Las aristas `[AB,BC,CD]` conectan todos los nodos con coste `6`. El subconjunto es conexo y sin ciclos.
- Ejercicio 2: El óptimo pasa a `[AB,BC,BD]`, con coste `8`. Mantener el árbol anterior costaría `11`.
- Ejercicio 3: No. Quitar cualquier arista del árbol lo desconecta. La resiliencia necesita otro objetivo o restricción.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
