---
module_id: "net-015-condense-mutual-dependencies-before-ordering-work"
department: "network-science"
course: "Condensar dependencias mutuas antes de ordenar el trabajo"
level: "intermediate"
prerequisites: ["net-009-detect-global-cycles-in-a-panel-stack"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Condensar dependencias mutuas antes de ordenar el trabajo

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un borrador de plan de Demerzel contiene varios ciclos. Mostrar uno impide ordenar topológicamente el grafo original, pero no indica qué tareas pertenecen a la misma región de dependencia mutua. Las componentes fuertemente conexas aportan esa partición y conservan la identidad de cada tarea.

NetworkX documenta su contracción y señala que el resultado es acíclico. Las etiquetas son construidas y no ejecutamos bibliotecas. Compruebe alcanzabilidad en ambos sentidos antes de agrupar nodos. Un camino unidireccional no basta. Elimine después las aristas internas solo en la vista condensada y conserve el mapa de miembros.

El DAG permite razonar sobre el orden entre grupos. No resuelve las dependencias internas, que quizá exijan revisar un contrato, dividir una tarea o definir una iteración. Añadir un retorno puede fusionar grupos, como muestra el control. La contracción no demuestra que se haya entregado una programación ejecutable o paralelismo seguro.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: net-009-detect-global-cycles-in-a-panel-stack](../../network-science/en/net-009-detect-global-cycles-in-a-panel-stack.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.components.condensation.html)

## Modelo fijo y control

```json
{
  "values": {
    "nodes": [
      "a",
      "b",
      "c",
      "d",
      "e"
    ],
    "edges": [
      [
        "a",
        "b"
      ],
      [
        "b",
        "a"
      ],
      [
        "b",
        "c"
      ],
      [
        "c",
        "d"
      ],
      [
        "d",
        "c"
      ],
      [
        "d",
        "e"
      ]
    ]
  },
  "formula": "Group nodes by mutual reachability (including zero-length self path); sort members and components lexically. Emit unique edges between distinct components. Count SCCs and condensed edges.",
  "expected": {
    "components": [
      [
        "a",
        "b"
      ],
      [
        "c",
        "d"
      ],
      [
        "e"
      ]
    ],
    "component_count": 3,
    "condensed_edges": [
      [
        "ab",
        "cd"
      ],
      [
        "cd",
        "e"
      ]
    ],
    "condensed_edge_count": 2
  },
  "negative_control": {
    "values": {
      "nodes": [
        "a",
        "b",
        "c",
        "d",
        "e"
      ],
      "edges": [
        [
          "a",
          "b"
        ],
        [
          "b",
          "a"
        ],
        [
          "b",
          "c"
        ],
        [
          "c",
          "d"
        ],
        [
          "d",
          "c"
        ],
        [
          "d",
          "e"
        ],
        [
          "e",
          "a"
        ]
      ]
    },
    "expected": {
      "components": [
        [
          "a",
          "b",
          "c",
          "d",
          "e"
        ]
      ],
      "component_count": 1,
      "condensed_edges": [],
      "condensed_edge_count": 0
    },
    "why": "One return dependency makes every node mutually reachable; hiding only the obvious local cycles would miss the larger component."
  },
  "assumptions": [
    "Exact finite directed dependency graph; condensed labels concatenate sorted unique single-letter names.",
    "An edge means a dependency relation only, not a legal execution trigger."
  ],
  "limits": "Contraction identifies coupled groups; it does not resolve a cycle, execute a fixed point or authorize simultaneous writes.",
  "input_types": {
    "nodes": "set<unique single-letter string>",
    "edges": "list<[node,node]>"
  }
}
```

### Ejercicio 1

Halle los grupos de dependencia mutua.

<details><summary>Respuesta 1</summary>

Los grupos son `[a,b]`, `[c,d]` y `[e]`, con `3` componentes. Cada pareja interna tiene caminos en ambos sentidos.

</details>

### Ejercicio 2

Escriba las aristas condensadas.

<details><summary>Respuesta 2</summary>

Son `ab->cd` y `cd->e`, un total de `2`. Las aristas internas quedan representadas por membresía, no por bucles de grupo.

</details>

### Ejercicio 3

¿El DAG resuelve los ciclos originales?

<details><summary>Respuesta 3</summary>

No. Solo ordena grupos. Las dependencias internas y las identidades originales siguen pendientes y deben poder recuperarse.

</details>

### Ejercicio 4

Aplique el retorno del control.

<details><summary>Respuesta 4</summary>

Todos forman `[a,b,c,d,e]`; hay `1` componente y `0` aristas condensadas. El retorno acopla todo el grafo.

</details>

### Ejercicio 5

¿Por qué conservar el mapa de miembros?

<details><summary>Respuesta 5</summary>

Sin él, una vista acíclica breve ocultaría tareas todavía interdependientes. La contracción es una vista, no permiso para fusionar efectos.

</details>

## Tarea con consulta de fuentes

Prepare un mapa de regiones de dependencia para un plan ficticio de Demerzel.

**Referencia manual directa:** Marque parejas mutuamente alcanzables, forme clases y dibuje aristas entre ellas.

**Criterio de refutación:** La alcanzabilidad unidireccional fusiona grupos o el DAG condensado se presenta como programación resuelta.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
