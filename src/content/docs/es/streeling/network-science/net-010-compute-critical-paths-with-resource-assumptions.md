---
title: Calcular rutas críticas con supuestos de recursos
description: Calcular rutas críticas con supuestos de recursos — Ciencia de redes
sidebar:
  label: NET-010 · Calcular rutas críticas con supuestos de recursos
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/es/net-010-compute-critical-paths-with-resource-assumptions.es.md
---

:::note[Streeling University]
**NET-010** · Calcular rutas críticas con supuestos de recursos · intermedio · 45 minutos

Generado por el departamento *Ciencia de redes* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/es/net-010-compute-critical-paths-with-resource-assumptions.es.md) · [Mi diario](../../journal/)

Requisitos previos: [NET-007](../../network-science/net-007-separate-dag-readiness-from-admission/)
:::

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [net-007-separate-dag-readiness-from-admission.md](../../network-science/net-007-separate-dag-readiness-from-admission/)
- [dag.rs](https://raw.githubusercontent.com/GuitarAlchemist/ix/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/dag.rs)

Un coordinador dibuja las dependencias de un pipeline de cursos y anuncia su ruta más larga como plazo prometido. Solo es una cota inferior por dependencias si las tareas compiten también por recursos. El requisito previo introduce la admisión de trabajadores. Esta lección mantiene el grafo y añade un recurso exclusivo que retrasa la finalización factible respecto de la ruta más larga.

El código de IX fijado aporta predecesores y orden topológico. No asigna nuestras duraciones ni reservas de recursos, que pertenecen al caso didáctico elaborado. Las tareas en conflicto pueden representar actividades que requieren el mismo evaluador reservado o dispositivo durante toda su ejecución. Es una interpretación ilustrativa: no se observó disponibilidad, rendimiento de servicios ni ritmo humano real.

Calcule primero las finalizaciones más tempranas suponiendo recursos ilimitados. Un nodo empieza tras terminar todos sus predecesores; el máximo determina el inicio más temprano de una unión. Mantenga las duraciones en ticks, sin convertirlas en días sin pruebas. Este cálculo se reproduce con el grafo y los costes, pero omite por construcción los conflictos de recursos.

Imponga después la exclusividad. Las tareas afectadas deben ejecutarse en secuencia aunque el grafo las deje listas al mismo tiempo tras su predecesor común. Ambos órdenes tienen la misma ocupación total en este caso pequeño. La unión final espera a ambas. Un calendario válido enumera intervalos para comprobar directamente dependencias y ausencia de solapamiento. Un orden topológico por sí solo no aporta inicios ni demuestra una asignación factible.

El control negativo elimina el conflicto y conserva duraciones y aristas. La ejecución paralela alcanza entonces la cota de dependencias. Para la tarea asistida por fuentes, examine la consulta de predecesores de IX y la distinción del requisito previo entre anchura y trabajadores activos. Dibuje ambos calendarios a mano antes de pedir optimizaciones. Rechace plazos que solapen reservas exclusivas o traten un tick elaborado como duración de producción medida. Conserve el calendario rápido inviable como contraejemplo.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "durations_ticks": {
      "A": 2,
      "B": 4,
      "C": 3,
      "D": 1
    },
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
        "B",
        "D"
      ],
      [
        "C",
        "D"
      ]
    ],
    "shared_resource_jobs": [
      "B",
      "C"
    ],
    "resource_capacity": 1
  },
  "formula": "earliest_finish(v)=duration(v)+max(earliest_finish(predecessors)); add explicit non-overlap for shared exclusive resource",
  "expected": {
    "unlimited_earliest_finish": {
      "A": 2,
      "B": 6,
      "C": 5,
      "D": 7
    },
    "dependency_lower_bound": 7,
    "resource_schedule": {
      "A": [
        0,
        2
      ],
      "B": [
        2,
        6
      ],
      "C": [
        6,
        9
      ],
      "D": [
        9,
        10
      ]
    },
    "resource_makespan": 10,
    "alternative_resource_order_makespan": 10
  },
  "negative_control": "Removing the resource conflict permits B and C to overlap and finish in7ticks.",
  "assumptions": [
    "Exact nonpreemptive durations, no overhead, both B and C require the same exclusive resource for their whole duration, others unconstrained."
  ],
  "limits": "No optimal scheduler implementation, real worker utilization or IX timing was measured."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Calcule las finalizaciones con recursos ilimitados.

<details>
<summary>Respuesta 1</summary>

A `2`, B `6`, C `5`, D `7`; duración de la ruta más larga `7`.

</details>

### Ejercicio 2

Indique un calendario con recurso exclusivo.

<details>
<summary>Respuesta 2</summary>

A `[0,2)`, B `[2,6)`, C `[6,9)`, D `[9,10)`; fin `10`.

</details>

### Ejercicio 3

Invierta el orden del recurso.

<details>
<summary>Respuesta 3</summary>

C `[2,5)`, B `[5,9)`, D `[9,10)` siguen terminando en `10`.

</details>

### Ejercicio 4

Evalúe el control sin conflicto.

<details>
<summary>Respuesta 4</summary>

Solape B y C tras A; D termina en `7`, alcanzando la cota de dependencias.

</details>

### Ejercicio 5

¿Qué refuta un calendario propuesto?

<details>
<summary>Respuesta 5</summary>

Un predecesor pendiente o reservas exclusivas solapadas; no se deduce un tiempo real.

</details>

[Paquete de pruebas fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
