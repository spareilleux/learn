---
title: Comprobar la coherencia de signos en un ciclo de costuras
description: Comprobar la coherencia de signos en un ciclo de costuras — Semiótica
sidebar:
  label: SEM-016 · Comprobar la coherencia de signos en un ciclo de costuras
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-016-check-sign-consistency-around-a-craft-seam-cycle.es.md
---

:::note[Streeling University]
**SEM-016** · Comprobar la coherencia de signos en un ciclo de costuras · avanzado · 45 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-016-check-sign-consistency-around-a-craft-seam-cycle.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-013](../../semiotics/sem-013-align-two-motif-periods-at-a-textile-seam/), [NET-009](../../network-science/net-009-detect-global-cycles-in-a-panel-stack/)
:::

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Una composición artesanal puede contener un ciclo de costuras sin contradicción. Importa qué significa cada enlace. El prerrequisito de apilamiento prohíbe ciclos de orden estricto en altura; esta lección usa restricciones binarias no dirigidas de igualdad u oposición, con ciclos que pueden ser coherentes. Rechazar todo ciclo excluiría composiciones válidas.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Elija un bit para un parche y propague cada igualdad o diferencia. Al volver al parche inicial debe recuperar su bit. En el triángulo declarado, el xor de etiquetas debe anularse. La guía lógica define xor y satisfacibilidad, sin imponer ese código a una costura. El parentesco Atlas es otra relación y no aporta una solución de costuras. Complementar todos los bits conserva las restricciones: explica las soluciones emparejadas y la falta de orientación absoluta.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "nodes": [
      "A",
      "B",
      "C"
    ],
    "edges": [
      [
        "A",
        "B",
        1
      ],
      [
        "B",
        "C",
        1
      ],
      [
        "C",
        "A",
        0
      ]
    ]
  },
  "formula": "Enumerate bit assignments in node order, require bit[u] XOR bit[v] == edge parity for every edge; return assignments lexicographically; cycle_parity=XOR of the three supplied edge bits",
  "expected": {
    "assignments": [
      [
        0,
        1,
        0
      ],
      [
        1,
        0,
        1
      ]
    ],
    "cycle_parity": 0,
    "consistent": true
  },
  "negative_control": {
    "values": {
      "nodes": [
        "A",
        "B",
        "C"
      ],
      "edges": [
        [
          "A",
          "B",
          1
        ],
        [
          "B",
          "C",
          1
        ],
        [
          "C",
          "A",
          1
        ]
      ]
    },
    "expected": {
      "assignments": [],
      "cycle_parity": 1,
      "consistent": false
    }
  }
}
```

### Ejercicio 1

Resuelva las restricciones principales.

<details><summary>Respuesta 1</summary>

Las asignaciones son `[0,1,0]` y `[1,0,1]` en orden de nodos. Ambas satisfacen todos los enlaces.

</details>

### Ejercicio 2

¿Por qué el ciclo existente no obliga a rechazar?

<details><summary>Respuesta 2</summary>

Su paridad es `0`. Los enlaces significan igual u opuesto, no estrictamente encima; el teorema de apilamiento trata otra relación.

</details>

### Ejercicio 3

Aplique el enlace de cierre modificado.

<details><summary>Respuesta 3</summary>

La paridad pasa a `1`, las asignaciones son `[]` y `consistent=false`. Cada enlace sigue siendo satisfacible localmente, pero el conjunto es incompatible.

</details>

### Ejercicio 4

¿Una solución fija una orientación absoluta?

<details><summary>Respuesta 4</summary>

No. Complementar todos los bits produce otra solución. Haría falta un parche de referencia externo para fijar esa libertad.

</details>

### Ejercicio 5

¿Qué debe conservar un agente al componer costuras?

<details><summary>Respuesta 5</summary>

Mantenga identidades de nodos, tipo de relación, convención de paridad y cualquier ancla. No interprete un grafo de signos como un grafo dirigido de alturas.

</details>

## Tarea con consulta de fuentes

Propague los bits en papel alrededor del triángulo e inspeccione después los enlaces parentales Atlas, indicando por qué no son restricciones de paridad. Conserve un recorrido cerrado contradictorio como testigo del rechazo.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

El ciclo coherente principal refuta rechazar todos los ciclos; el control refuta la regla inversa de que costuras localmente válidas siempre componen un conjunto válido.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: sem-013-align-two-motif-periods-at-a-textile-seam](../../semiotics/sem-013-align-two-motif-periods-at-a-textile-seam/)

- [Prerrequisito ya confirmado: net-009-detect-global-cycles-in-a-panel-stack](../../network-science/net-009-detect-global-cycles-in-a-panel-stack/)

- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/)

- [Paquete inventado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
