---
title: Interpretar un proyecto de tejido con varios lizos
description: Interpretar un proyecto de tejido con varios lizos — Semiótica
sidebar:
  label: SEM-018 · Interpretar un proyecto de tejido con varios lizos
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-018-interpret-a-multi-shaft-weaving-draft.es.md
---

:::note[Streeling University]
**SEM-018** · Interpretar un proyecto de tejido con varios lizos · avanzado · 45 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-018-interpret-a-multi-shaft-weaving-draft.es.md) · [Mi diario](../../journal/)

Requisitos previos: [VC-007](../../visual-computing/vc-007-weave-seams-as-scene-contracts/)
:::

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

La escena artesanal IX tiene una regla de cruces alternos, pero un panel más general necesita interpretar un enhebrado y una secuencia de levantamientos de lizos. Una fórmula de paridad alterna no expresa todas las pasadas del ejemplo. Declaramos una convención didáctica de calada ascendente: un lizo levantado coloca sus hilos de urdimbre sobre la trama en esa pasada. La operación compone ambos registros en un diseño de entrelazado, sin simular un telar.

Lea una fila siguiendo la identidad del enhebrado y comprobando si su lizo pertenece al conjunto levantado. Varios hilos pueden compartir lizo, de modo que un levantamiento cambia varios cruces. Distinga etiqueta de lizo e índice de hilo: una es asignación de control y el otro dirección espacial. La fila booleana indica qué hebra queda arriba según la convención. No especifica grosor, fuerzas de contacto ni viabilidad textil.

El control con fila ausente va más allá de comparar apariencias. Sustituir evidencia ausente por conjunto vacío inventaría una instrucción de todo abajo y un panel completo. Devuelva una fila incompleta conservando las anteriores conocidas. Un futuro DSL artesanal componible debería preservar esta diferencia, aunque aquí solo se pide una tabla manual. Un agente no debe admitir un proyecto incompleto como escena [Godot](https://docs.godotengine.org/en/4.5/) porque las filas conocidas parezcan coherentes.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "threading": [
      0,
      1,
      2,
      0
    ],
    "lift_plan": [
      [
        0,
        2
      ],
      [
        1
      ],
      [
        0,
        1
      ]
    ]
  },
  "formula": "drawdown[pick][warp]=threading[warp] in lift_plan[pick]; a missing lift-plan row yields null and status incomplete rather than false cells",
  "expected": {
    "status": "complete",
    "drawdown": [
      [
        true,
        false,
        true,
        true
      ],
      [
        false,
        true,
        false,
        false
      ],
      [
        true,
        true,
        false,
        true
      ]
    ]
  },
  "negative_control": {
    "values": {
      "threading": [
        0,
        1,
        2,
        0
      ],
      "lift_plan": [
        [
          0,
          2
        ],
        [
          1
        ],
        null
      ]
    },
    "expected": {
      "status": "incomplete",
      "drawdown": [
        [
          true,
          false,
          true,
          true
        ],
        [
          false,
          true,
          false,
          false
        ],
        null
      ]
    }
  }
}
```

### Ejercicio 1

Interprete la primera pasada.

<details><summary>Respuesta 1</summary>

La fila es `[true,false,true,true]`: la asignación repetida levanta ambos hilos correspondientes. Índices espaciales y lizos son distintos.

</details>

### Ejercicio 2

Interprete la segunda pasada.

<details><summary>Respuesta 2</summary>

La fila es `[false,true,false,false]`. El lizo levantado afecta exactamente a sus hilos asignados, sin importar su posición en el arreglo.

</details>

### Ejercicio 3

Interprete la última pasada registrada.

<details><summary>Respuesta 3</summary>

La fila es `[true,true,false,true]`. Un único bit de paridad alterna no reconstruye este patrón.

</details>

### Ejercicio 4

Aplique el control de levantamiento ausente.

<details><summary>Respuesta 4</summary>

La última fila es `null` y el estado `incomplete`. Se conservan filas anteriores; ausencia no equivale a conjunto vacío.

</details>

### Ejercicio 5

¿Un diseño completo demuestra un tejido físico?

<details><summary>Respuesta 5</summary>

No. Establece esta interpretación finita según la convención declarada. Mecánica del hilo, fabricación y lectura humana siguen sin probar.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje columnas de lizos y filas de pasadas a mano y derive los cruces antes de mostrarlos a un asistente. Compare el plan general con la escena alterna confirmada y escriba la frontera semántica ausente para ampliarla.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

Un intérprete que produzca una última fila definida de todo abajo para el control ausente ha inventado una instrucción.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: vc-007-weave-seams-as-scene-contracts](../../visual-computing/vc-007-weave-seams-as-scene-contracts/)
- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/streeling/weave-godot/trial.gd)
- [Lectura primaria](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Paquete inventado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
