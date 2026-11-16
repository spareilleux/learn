---
module_id: "net-018-reduce-precedence-edges-without-erasing-evidence"
department: "network-science"
course: "Reducir aristas de precedencia sin borrar evidencias"
title: "Reducir aristas de precedencia sin borrar evidencias"
level: "intermediate"
prerequisites: ["net-015-condense-mutual-dependencies-before-ordering-work"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Reducir aristas de precedencia sin borrar evidencias

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un esquema de pipeline IX acumula flechas directas entre tareas ya ordenadas mediante otras. El dibujo se vuelve difícil de inspeccionar. Se pueden quitar flechas para simplificarlo, pero primero hay que elegir su significado. Si una arista lleva un artefacto o una autorización concretos, otra ruta no sustituye automáticamente esa obligación directa.

En esta lección todas las aristas significan solo precedencia. En un grafo acíclico, una arista sobra si sus extremos siguen conectados en la misma dirección al retirarla. Compruebe la ruta alternativa antes de ocultar la flecha. Compare toda la relación de accesibilidad antes y después, no solo el número de nodos o la existencia de un orden topológico.

El grafo fijo contiene una cadena completa y varios atajos. La cadena conserva todos los pares ordenados alcanzables. El control quita una arista central de la cadena. Un antiguo atajo pasa a ser necesario porque desaparece la ruta alternativa. Así, la reducción pertenece a una revisión concreta: una arista redundante ayer puede ser esencial tras otra edición.

NetworkX exige un DAG y advierte de que su reducción no copia automáticamente datos de aristas ni nodos. Es un recordatorio concreto de pérdida de representación, sin ejecutar la biblioteca. El requisito resuelve ciclos agrupando componentes; reducir es otra operación sobre un grafo ya acíclico. Conserve el grafo fuente y todas las evidencias. Una vista DSL puede ocultar precedencias redundantes, pero no borrar silenciosamente procedencia, cargas requeridas o aprobaciones que el modelo nunca representó.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: net-015-condense-mutual-dependencies-before-ordering-work](../../network-science/en/net-015-condense-mutual-dependencies-before-ordering-work.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.dag.transitive_reduction.html)

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
        "A",
        "C"
      ],
      [
        "C",
        "D"
      ],
      [
        "A",
        "D"
      ],
      [
        "B",
        "D"
      ]
    ]
  },
  "formula": "For a DAG retain edge [u,v] iff deleting that edge leaves no directed u-to-v path. Sort edge lists lexicographically. Count ordered distinct reachable node pairs before and after. Never apply this DAG rule to a cyclic graph.",
  "expected": {
    "retained_edges": [
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
      ]
    ],
    "removed_edges": [
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
        "D"
      ]
    ],
    "reachable_pairs_before": 6,
    "reachable_pairs_after": 6
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
          "A",
          "C"
        ],
        [
          "C",
          "D"
        ],
        [
          "A",
          "D"
        ],
        [
          "B",
          "D"
        ]
      ]
    },
    "expected": {
      "retained_edges": [
        [
          "A",
          "B"
        ],
        [
          "A",
          "C"
        ],
        [
          "B",
          "D"
        ],
        [
          "C",
          "D"
        ]
      ],
      "removed_edges": [
        [
          "A",
          "D"
        ]
      ],
      "reachable_pairs_before": 5,
      "reachable_pairs_after": 5
    },
    "why": "Removing the middle chain edge makes the former shortcut necessary to preserve reachability."
  },
  "input_types": {
    "nodes": "ordered finite unique strings",
    "edges": "unique directed node pairs forming a DAG"
  },
  "assumptions": [
    "Edges mean precedence only, without latency, required payload, direct authorization or evidence semantics.",
    "Every reachability relation of the supplied DAG is the preservation target."
  ],
  "limits": "Do not delete production dependencies or receipts from this drawing exercise. Equivalent reachability need not preserve data or authority contracts."
}
```

### Ejercicio 1

Dé el conjunto reducido fijo.

<details><summary>Respuesta 1</summary>

Es `[[A,B],[B,C],[C,D]]`. Los atajos retirados son `[[A,C],[A,D],[B,D]]`; cada uno tiene otra ruta dirigida en el grafo fijo.

</details>

### Ejercicio 2

Compruebe la propiedad conservada.

<details><summary>Respuesta 2</summary>

Hay `6` pares ordenados alcanzables antes y `6` después. Igualar recuentos no basta en general: deben coincidir los conjuntos reales.

</details>

### Ejercicio 3

¿Qué aristas del control siguen siendo necesarias?

<details><summary>Respuesta 3</summary>

La reducción es `[[A,B],[A,C],[B,D],[C,D]]`; solo se retira `[[A,D]]`. Los recuentos alcanzables siguen en `5` antes y `5` después.

</details>

### Ejercicio 4

¿Puede borrarse el recibo de una flecha redundante?

<details><summary>Respuesta 4</summary>

No. La accesibilidad de precedencia no codifica identidad del recibo, datos directos ni autoridad. Conserve esos registros aparte y mantenga disponible el grafo original.

</details>

### Ejercicio 5

¿Por qué rechazar una entrada cíclica?

<details><summary>Respuesta 5</summary>

La regla declarada supone un DAG. Condense o resuelva ciclos con un modelo justificado antes de aplicarla; no reutilice silenciosamente la misma garantía de unicidad.

</details>

## Tarea con consulta de fuentes

Simplifique un dibujo ficticio de precedencias IX conservando sus evidencias fuente.

**Referencia manual directa:** Para cada arista dibuje una ruta alternativa o márquela necesaria y compare los pares alcanzables.

**Criterio de refutación:** El dibujo simplificado pierde un par alcanzable o afirma conservar datos ocultos de aristas.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Dé el conjunto reducido fijo. — Decisión sin resolver.
- Ejercicio 2: Compruebe la propiedad conservada. — Decisión sin resolver.
- Ejercicio 3: ¿Qué aristas del control siguen siendo necesarias? — Decisión sin resolver.
- Ejercicio 4: ¿Puede borrarse el recibo de una flecha redundante? — Decisión sin resolver.
- Ejercicio 5: ¿Por qué rechazar una entrada cíclica? — Decisión sin resolver.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
