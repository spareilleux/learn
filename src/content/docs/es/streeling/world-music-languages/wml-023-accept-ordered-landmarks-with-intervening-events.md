---
title: Reconocer hitos ordenados con eventos intermedios
description: Reconocer hitos ordenados con eventos intermedios — Músicas y lenguas del mundo
sidebar:
  label: WML-023 · Reconocer hitos ordenados con eventos intermedios
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-023-accept-ordered-landmarks-with-intervening-events.es.md
---

:::note[Streeling University]
**WML-023** · Reconocer hitos ordenados con eventos intermedios · avanzado · 55 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-023-accept-ordered-landmarks-with-intervening-events.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-012](../../world-music-languages/wml-012-preserve-direction-in-a-melodic-inventory/)
:::

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una frase didáctica puede exigir hitos ordenados permitiendo ornamentos entre ellos. La búsqueda contigua es demasiado estricta y la pertenencia sin orden demasiado permisiva. Avance el siguiente hito solo al encontrar su etiqueta; conserve índices como testigo. Un hito repetido requiere un evento posterior distinto. La regla se elabora para un ejercicio [GA](https://github.com/GuitarAlchemist/ga). No define ornamentación de una tradición, no juzga estilo ni decide qué notas añadidas aceptaría un músico.

## Supuestos y límites específicos

El recorrido finito consume cada evento como máximo una vez e ignora etiquetas extra según la regla estipulada. Hitos repetidos necesitan eventos posteriores distintos. No se proporciona juicio estilístico, tolerancia temporal ni reconocedor de interpretaciones.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../world-music-languages/wml-012-preserve-direction-in-a-melodic-inventory/)

[Artefacto de proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "landmarks": [
      "a",
      "c",
      "e"
    ],
    "events": [
      "a",
      "b",
      "c",
      "d",
      "e"
    ]
  },
  "formula": "scan events left to right; advance next landmark on equality; witness stores consumed event indices; accepted iff all landmarks consumed",
  "expected": {
    "witness": [
      0,
      2,
      4
    ],
    "consumed": 3,
    "accepted": true
  },
  "negative_control": {
    "values": {
      "landmarks": [
        "a",
        "c",
        "e"
      ],
      "events": [
        "e",
        "b",
        "c",
        "d",
        "a"
      ]
    },
    "expected": {
      "witness": [
        4
      ],
      "consumed": 1,
      "accepted": false
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** El testigo es `[0,2,4]`; se consumen los 3 hitos pese a eventos intermedios.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** Una subsecuencia ordenada difiere de un motivo contiguo y de pertenencia sin orden.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** Ignorar todas las etiquetas adicionales es una regla estipulada, no un juicio musical sobre ornamentos.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** El control de orden invertido solo consume el índice 4 y falla pese a contener las mismas etiquetas.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Un registro aceptado sin testigo completo estrictamente creciente refuta el reconocimiento ordenado anunciado.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
