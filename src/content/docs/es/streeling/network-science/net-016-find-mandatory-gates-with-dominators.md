---
title: Encontrar pasos obligatorios mediante dominadores
description: Encontrar pasos obligatorios mediante dominadores — Ciencia de redes
sidebar:
  label: NET-016 · Encontrar pasos obligatorios mediante dominadores
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/es/net-016-find-mandatory-gates-with-dominators.es.md
---

:::note[Streeling University]
**NET-016** · Encontrar pasos obligatorios mediante dominadores · intermedio · 45 minutos

Generado por el departamento *Ciencia de redes* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/es/net-016-find-mandatory-gates-with-dominators.es.md) · [Mi diario](../../journal/)

Requisitos previos: [NET-004](../../network-science/net-004-semantic-backpressure-and-evidence-dependencies/)
:::

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un dibujo del flujo de Learn coloca una revisión antes de publicar. Aun así puede permitir otra ruta que evite esa casilla. Para saber si la revisión es estructuralmente obligatoria, fije entrada y destino de publicación y examine todas las rutas permitidas. La posición en el dibujo o la frecuencia de uso no establecen necesidad.

Aquí una arista significa un siguiente paso permitido. No exige terminar todos los predecesores como haría una unión de evidencias. Un vértice domina el destino cuando todas las rutas desde la entrada lo contienen. Incluya entrada y destino en la intersección e identifique después la guarda intermedia propuesta. Si existe un desvío, consérvelo: explica mejor el fallo de obligatoriedad que un porcentaje.

El grafo fijo tiene dos ramas que se reúnen en revisión. Ambas rutas cruzan la guarda. El control añade una rama directa a publicación; la guarda anterior deja de ser obligatoria aunque se conserven las rutas originales. Mantener la etiqueta o añadir otra insignia verde no elimina el nuevo camino. Una auditoría estructural necesita el inventario completo y su versión.

La documentación de NetworkX aporta el concepto de dominancia dirigida relativo a una entrada. Enumerar rutas a mano es una alternativa pequeña, no un nuevo motor de grafos. El requisito comprueba si ciertas evidencias satisfacen una regla; aquí se pregunta si todas las rutas la encuentran. Una guarda puede dominar y comprobar algo incorrecto. A la inversa, una arista ausente del dibujo no prueba un desvío real. Se necesitan código y recorridos ligados a revisiones antes de afirmaciones operativas.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: net-004-semantic-backpressure-and-evidence-dependencies](../../network-science/net-004-semantic-backpressure-and-evidence-dependencies/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.dominance.immediate_dominators.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "nodes": [
      "S",
      "A",
      "B",
      "R",
      "P"
    ],
    "edges": [
      [
        "S",
        "A"
      ],
      [
        "S",
        "B"
      ],
      [
        "A",
        "R"
      ],
      [
        "B",
        "R"
      ],
      [
        "R",
        "P"
      ]
    ],
    "start": "S",
    "target": "P",
    "candidate": "R"
  },
  "formula": "Enumerate all simple directed start-to-target paths. Dominators are their vertex-set intersection ordered by nodes. Candidate mandatory iff it belongs to that intersection; bypass is lexicographically first path omitting candidate or null. Require at least one target path.",
  "expected": {
    "dominators": [
      "S",
      "R",
      "P"
    ],
    "candidate_mandatory": true,
    "bypass": null
  },
  "negative_control": {
    "values": {
      "nodes": [
        "S",
        "A",
        "B",
        "R",
        "P"
      ],
      "edges": [
        [
          "S",
          "A"
        ],
        [
          "S",
          "B"
        ],
        [
          "A",
          "R"
        ],
        [
          "B",
          "R"
        ],
        [
          "R",
          "P"
        ],
        [
          "B",
          "P"
        ]
      ],
      "start": "S",
      "target": "P",
      "candidate": "R"
    },
    "expected": {
      "dominators": [
        "S",
        "P"
      ],
      "candidate_mandatory": false,
      "bypass": [
        "S",
        "B",
        "P"
      ]
    },
    "why": "An added publication route avoids the declared review gate."
  },
  "input_types": {
    "nodes": "ordered list of unique strings",
    "edges": "directed pairs of listed nodes",
    "start": "listed node",
    "target": "reachable listed node",
    "candidate": "listed node"
  },
  "assumptions": [
    "Graph edges mean allowed traversal, not AND-required evidence joins.",
    "Graph includes every allowed route for the stated entry and target."
  ],
  "limits": "Dominance is relative to the graph and entry. It is not authorization, successful review, runtime enforcement or security certification."
}
```

### Ejercicio 1

Obtenga los dominadores del destino fijo.

<details><summary>Respuesta 1</summary>

En el orden declarado son `[S,R,P]`. Toda ruta permitida pasa por revisión; entrada y destino también pertenecen por definición.

</details>

### Ejercicio 2

Muestre el desvío del control.

<details><summary>Respuesta 2</summary>

La ruta `[S,B,P]` omite `R`. Los dominadores pasan a `[S,P]` y la afirmación de guarda obligatoria es `false`.

</details>

### Ejercicio 3

¿Demuestra la dominancia una revisión correcta?

<details><summary>Respuesta 3</summary>

No. Demuestra pertenencia a rutas según el grafo. El predicado real, la identidad de evidencias y la autoridad necesitan validación aparte.

</details>

### Ejercicio 4

¿Puede el mismo grafo representar una unión de requisitos?

<details><summary>Respuesta 4</summary>

Solo tras redefinir su semántica. Rutas de elección y requisitos conjuntivos responden a preguntas distintas; un desvío no es automáticamente una condición AND incumplida.

</details>

### Ejercicio 5

¿Qué ocurre si publicación es inalcanzable?

<details><summary>Respuesta 5</summary>

No informe una guarda satisfecha desde una intersección vacía de rutas. Señale el destino inalcanzable; el modelo exige accesibilidad antes de evaluar necesidad.

</details>

## Tarea con consulta de fuentes

Audite si una ruta propuesta de publicación de Learn debe encontrar su guarda de revisión.

**Referencia manual directa:** Dibuje todas las rutas permitidas desde la entrada e interseque sus conjuntos de vértices.

**Criterio de refutación:** Una ruta permitida hacia publicación omite la guarda supuestamente obligatoria.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Obtenga los dominadores del destino fijo. — Decisión sin resolver.
- Ejercicio 2: Muestre el desvío del control. — Decisión sin resolver.
- Ejercicio 3: ¿Demuestra la dominancia una revisión correcta? — Decisión sin resolver.
- Ejercicio 4: ¿Puede el mismo grafo representar una unión de requisitos? — Decisión sin resolver.
- Ejercicio 5: ¿Qué ocurre si publicación es inalcanzable? — Decisión sin resolver.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
