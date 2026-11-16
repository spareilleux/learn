---
module_id: "net-014-bound-throughput-with-a-capacity-cut"
department: "network-science"
course: "Acotar el caudal mediante un corte de capacidad"
level: "intermediate"
prerequisites: ["net-010-compute-critical-paths-with-resource-assumptions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Acotar el caudal mediante un corte de capacidad

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un coordinador añade rutas entre etapas ficticias de evidencia y anuncia más rendimiento porque existen más caminos. Varios caminos pueden compartir el enlace final. La alcanzabilidad y el número de rutas no contemplan la conservación de capacidad. El curso previo mide una duración finita de programación; aquí acotamos un caudal estacionario idealizado.

La documentación oficial de NetworkX define capacidades y el valor de un flujo. Usamos el concepto sin ejecutar la biblioteca. Muestre un flujo factible y un corte con igual capacidad: el primero atestigua un límite inferior y el segundo uno superior. Su coincidencia certifica el óptimo del grafo construido. Contar caminos no aporta ninguno de esos testigos.

El corte del destino es fácil de inspeccionar: toda unidad entregada entra por alguna arista entrante. El control reduce una capacidad sin eliminar aristas. Persisten las rutas, pero baja el límite. Aplicarlo a un pipeline real exigiría unidades compatibles, capacidades observadas e hipótesis de carga.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: net-010-compute-critical-paths-with-resource-assumptions](../../network-science/en/net-010-compute-critical-paths-with-resource-assumptions.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.flow.maximum_flow.html)

## Modelo fijo y control

```json
{
  "values": {
    "nodes": [
      "s",
      "a",
      "b",
      "t"
    ],
    "edges": [
      [
        "s",
        "a",
        3
      ],
      [
        "s",
        "b",
        2
      ],
      [
        "a",
        "t",
        2
      ],
      [
        "b",
        "t",
        2
      ],
      [
        "a",
        "b",
        1
      ]
    ],
    "source": "s",
    "sink": "t"
  },
  "formula": "Nonnegative flow obeys capacities and conservation at a,b. Maximize source outflow; minimum cut is minimum sum of directed capacities from source-side set to its complement.",
  "expected": {
    "maximum_flow": 4,
    "minimum_cut_capacity": 4,
    "sink_cut_capacity": 4,
    "simple_path_count": 3
  },
  "negative_control": {
    "values": {
      "nodes": [
        "s",
        "a",
        "b",
        "t"
      ],
      "edges": [
        [
          "s",
          "a",
          3
        ],
        [
          "s",
          "b",
          2
        ],
        [
          "a",
          "t",
          2
        ],
        [
          "b",
          "t",
          1
        ],
        [
          "a",
          "b",
          1
        ]
      ],
      "source": "s",
      "sink": "t"
    },
    "expected": {
      "maximum_flow": 3,
      "minimum_cut_capacity": 3,
      "sink_cut_capacity": 3,
      "simple_path_count": 3
    },
    "why": "One sink capacity falls while reachability and path count remain unchanged."
  },
  "assumptions": [
    "Directed capacities use common hypothetical items per tick; divisible steady flow.",
    "No latency, node capacity, semantic mismatch or queue storage limit."
  ],
  "limits": "Flow bounds are not an observed worker rate, a finite nonpreemptive schedule or delivery guarantee.",
  "input_types": {
    "nodes": "set<string>",
    "edges": "list<[from,to,nonnegative capacity]>",
    "source": "node",
    "sink": "different node"
  }
}
```

### Ejercicio 1

Dé un flujo factible.

<details><summary>Respuesta 1</summary>

Envíe `2` unidades por `s-a-t` y `2` por `s-b-t`, con `0` por `a-b`. El total es `4` y cumple conservación.

</details>

### Ejercicio 2

Dé un límite superior coincidente.

<details><summary>Respuesta 2</summary>

Las aristas que entran en `t` suman `4`. Todo flujo entregado cruza ese corte, así que `4` también es un límite superior.

</details>

### Ejercicio 3

Cuente las rutas simples.

<details><summary>Respuesta 3</summary>

Hay `3`: `s-a-t`, `s-b-t` y `s-a-b-t`. El número de rutas no es capacidad.

</details>

### Ejercicio 4

Aplique el control de capacidad reducida.

<details><summary>Respuesta 4</summary>

El flujo máximo y la capacidad del corte pasan a `3`; siguen existiendo `3` rutas. Menos capacidad no implica perder alcanzabilidad.

</details>

### Ejercicio 5

¿El óptimo garantiza una tasa real de entrega?

<details><summary>Respuesta 5</summary>

No. El flujo estacionario divisible omite granularidad, fallos, tiempos y compatibilidad semántica. El óptimo depende del modelo.

</details>

## Tarea con consulta de fuentes

Prepare una nota de corte de capacidad para un pipeline de evidencia ficticio de Learn.

**Referencia manual directa:** Dibuje balances de conservación, un flujo factible y un corte separador.

**Criterio de refutación:** Una tasa declarada supera un corte separador o se usa el número de rutas como capacidad.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
