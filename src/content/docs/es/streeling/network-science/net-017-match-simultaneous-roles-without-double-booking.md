---
title: Asignar roles simultáneos sin doble reserva
description: Asignar roles simultáneos sin doble reserva — Ciencia de redes
sidebar:
  label: NET-017 · Asignar roles simultáneos sin doble reserva
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/es/net-017-match-simultaneous-roles-without-double-booking.es.md
---

:::note[Streeling University]
**NET-017** · Asignar roles simultáneos sin doble reserva · intermedio · 45 minutos

Generado por el departamento *Ciencia de redes* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/es/net-017-match-simultaneous-roles-without-double-booking.es.md) · [Mi diario](../../journal/)

Requisitos previos: [NET-003](../../network-science/net-003-worker-lane-coverage-and-fragility/), [NET-014](../../network-science/net-014-bound-throughput-with-a-capacity-cut/)
:::

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Una tabla de capacidades de Demerzel da al menos un candidato a cada rol solicitado. El coordinador supone entonces que todos pueden ejecutarse simultáneamente. Esa inferencia reserva dos veces un worker si varios roles solo tienen ese candidato. El curso de cobertura cuenta rutas por clase; aquí se pregunta si workers distintos pueden ocupar todos los roles simultáneos.

Dibuje un grafo bipartito con roles y workers en lados separados. Una arista declara que el worker puede ocupar ese rol. Un emparejamiento no usa ningún vértice dos veces. Para mostrar viabilidad, escriba el emparejamiento completo. Para mostrar imposibilidad, encuentre un subconjunto de roles cuyo conjunto combinado de candidatos sea menor. Esos roles no pueden recibir workers distintos aunque otros roles tengan alternativas.

En el caso fijo, redacción y revisión tienen candidato, pero comparten el mismo candidato único. Las alternativas de traducción no resuelven ese obstáculo. El control añade una arista de revisión y permite asignación completa. Conserve el testigo de asignación y el subconjunto deficiente; contar roles cubiertos pierde la explicación del primer fallo.

NetworkX documenta el emparejamiento bipartito de cardinalidad máxima. El ejemplo pequeño se resuelve por inspección y recuento de vecinos, sin instalar ni ejecutar el paquete. El requisito de caudal trata capacidades de una red; aquí el contrato central es exclusividad de workers e identidad de roles. La revisión humana real puede exigir independencia, experiencia y consentimiento. Las candidaturas no prueban esas condiciones. Un planificador de agentes debería conservarlas antes de considerar esta asignación permiso para despachar trabajo.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: net-003-worker-lane-coverage-and-fragility](../../network-science/net-003-worker-lane-coverage-and-fragility/)

[Requisito previo: net-014-bound-throughput-with-a-capacity-cut](../../network-science/net-014-bound-throughput-with-a-capacity-cut/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.bipartite.matching.maximum_matching.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "candidates": {
      "draft": [
        "w1"
      ],
      "review": [
        "w1"
      ],
      "translate": [
        "w2",
        "w3"
      ]
    }
  },
  "formula": "Choose injective role-to-worker assignments over candidate edges, allowing unfilled roles. Maximize assigned count, then choose lexicographically smallest sorted [role,worker] list. For each role subset U compute neighbours N(U); deficient if len(N(U))<len(U). Choose obstruction by smallest subset size, then lexical role list.",
  "expected": {
    "all_roles_covered": true,
    "maximum_count": 2,
    "matching": [
      [
        "draft",
        "w1"
      ],
      [
        "translate",
        "w2"
      ]
    ],
    "obstruction": {
      "roles": [
        "draft",
        "review"
      ],
      "workers": [
        "w1"
      ],
      "deficiency": 1
    }
  },
  "negative_control": {
    "values": {
      "candidates": {
        "draft": [
          "w1"
        ],
        "review": [
          "w1",
          "w2"
        ],
        "translate": [
          "w2",
          "w3"
        ]
      }
    },
    "expected": {
      "all_roles_covered": true,
      "maximum_count": 3,
      "matching": [
        [
          "draft",
          "w1"
        ],
        [
          "review",
          "w2"
        ],
        [
          "translate",
          "w3"
        ]
      ],
      "obstruction": null
    },
    "why": "An extra review candidate removes the bottleneck and permits distinct workers for every role."
  },
  "input_types": {
    "candidates": "mapping of role strings to unique worker-string lists"
  },
  "assumptions": [
    "Each role requires one worker and each worker occupies at most one role in this simultaneous window.",
    "Candidate edges are hypothetical admissibility declarations, not live staffing or trust evidence."
  ],
  "limits": "A matching is a finite allocation witness, not authority, competence validation, independent human review or an actual dispatched fleet."
}
```

### Ejercicio 1

¿Se cumple la cobertura marginal?

<details><summary>Respuesta 1</summary>

Sí: cada rol tiene algún candidato, así que es `true`. Todavía no afirma nada sobre asignaciones simultáneas distintas.

</details>

### Ejercicio 2

Encuentre el obstáculo de asignación.

<details><summary>Respuesta 2</summary>

Los roles `[draft,review]` tienen vecinos `[w1]`, con deficiencia `1`. Ninguna asignación inyectiva cubre ambos en la misma ventana.

</details>

### Ejercicio 3

Dé un emparejamiento máximo fijo.

<details><summary>Respuesta 3</summary>

La regla de desempate elige `[[draft,w1],[translate,w2]]`, de tamaño `2`. Revisión queda vacía explícitamente; reutilizar su worker violaría la exclusividad.

</details>

### Ejercicio 4

Aplique el control con una arista adicional.

<details><summary>Respuesta 4</summary>

El emparejamiento completo es `[[draft,w1],[review,w2],[translate,w3]]`, de tamaño `3`; el campo de subconjunto deficiente es `null`. Los workers siguen siendo distintos.

</details>

### Ejercicio 5

¿Demuestra el emparejamiento una revisión independiente?

<details><summary>Respuesta 5</summary>

No. Identificadores distintos no prueban personas distintas, fuentes independientes, experiencia ni autorización. Añada esas restricciones y sus evidencias antes de despachar.

</details>

## Tarea con consulta de fuentes

Revise una propuesta de roles simultáneos para una ventana ficticia de producción de Demerzel.

**Referencia manual directa:** Dibuje candidaturas, construya una asignación inyectiva o cuente un subconjunto deficiente.

**Criterio de refutación:** La propuesta solo cubre todos los roles asignando un worker dos veces en la misma ventana.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: ¿Se cumple la cobertura marginal? — Decisión sin resolver.
- Ejercicio 2: Encuentre el obstáculo de asignación. — Decisión sin resolver.
- Ejercicio 3: Dé un emparejamiento máximo fijo. — Decisión sin resolver.
- Ejercicio 4: Aplique el control con una arista adicional. — Decisión sin resolver.
- Ejercicio 5: ¿Demuestra el emparejamiento una revisión independiente? — Decisión sin resolver.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
