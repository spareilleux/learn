---
module_id: "inf-023-deinterleave-burst-erasures-without-inventing-recovery"
department: "information-theory"
course: "Desentrelazar borrados en ráfaga sin inventar recuperación"
title: "Desentrelazar borrados en ráfaga sin inventar recuperación"
level: "intermediate"
prerequisites: ["inf-020-separate-parity-detection-from-correction", "inf-012-retain-event-order-in-a-handoff-summary"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Desentrelazar borrados en ráfaga sin inventar recuperación

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un futuro transporte de audio de guitarra podría repartir el efecto de una breve pérdida de paquetes en ráfaga. El entrelazado cambia de dónde provienen posiciones transmitidas consecutivamente. Puede reducir la concentración de símbolos ausentes dentro de un bloque. No recrea valores nunca recibidos, y contar posiciones no demuestra mejoras perceptivas.

Escriba los bloques originales en una matriz rectangular y lea las columnas para obtener el orden entrelazado. Cada índice transmitido corresponde a una fila y columna originales. Borre las posiciones declaradas e invierta después la correspondencia para recuperar la disposición original. Conserve un marcador explícito de ausencia. Se reconstruye la disposición, no los valores perdidos.

El control transmite los mismos símbolos por filas. La misma ráfaga borra entonces un bloque completo en vez de repartir las pérdidas. La cantidad total de símbolos ausentes no cambia. Una corrección posterior necesitaría redundancia real, una especificación del código y pruebas independientes del decodificador. Tampoco se modelan latencia de almacenamiento ni memoria del receptor; la RFC advierte que el entrelazado puede añadir demora. Una tabla manual de permutación precede cualquier cambio del transporte real de audio.

## Fuentes y alcance del proyecto

[Prerrequisito: inf-020-separate-parity-detection-from-correction](../../information-theory/en/inf-020-separate-parity-detection-from-correction.md)

[Prerrequisito: inf-012-retain-event-order-in-a-handoff-summary](../../information-theory/en/inf-012-retain-event-order-in-a-handoff-summary.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://www.rfc-editor.org/rfc/rfc8088.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "blocks": [
      [
        "A",
        "B",
        "C"
      ],
      [
        "D",
        "E",
        "F"
      ],
      [
        "G",
        "H",
        "I"
      ]
    ],
    "order": "column-major",
    "erased_indices": [
      0,
      1,
      2
    ]
  },
  "formula": "Serialize rectangular blocks in declared row-major or column-major position order. Replace erased zero-based wire indices by null, inverse-map positions, then count nulls per original block. Do not infer erased values.",
  "expected": {
    "wire": [
      "A",
      "D",
      "G",
      "B",
      "E",
      "H",
      "C",
      "F",
      "I"
    ],
    "reconstructed": [
      [
        null,
        "B",
        "C"
      ],
      [
        null,
        "E",
        "F"
      ],
      [
        null,
        "H",
        "I"
      ]
    ],
    "missing_per_block": [
      1,
      1,
      1
    ],
    "missing_total": 3
  },
  "negative_control": {
    "values": {
      "blocks": [
        [
          "A",
          "B",
          "C"
        ],
        [
          "D",
          "E",
          "F"
        ],
        [
          "G",
          "H",
          "I"
        ]
      ],
      "order": "row-major",
      "erased_indices": [
        0,
        1,
        2
      ]
    },
    "expected": {
      "wire": [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I"
      ],
      "reconstructed": [
        [
          null,
          null,
          null
        ],
        [
          "D",
          "E",
          "F"
        ],
        [
          "G",
          "H",
          "I"
        ]
      ],
      "missing_per_block": [
        3,
        0,
        0
      ],
      "missing_total": 3
    },
    "why": "The same burst has different block concentration, but no values are recovered."
  },
  "input_types": {
    "blocks": "rectangular nonempty array of distinct symbol strings",
    "order": "row-major or column-major",
    "erased_indices": "distinct valid zero-based transmitted positions"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No redundancy, erasure correction, packet capture, perceptual benefit, latency measurement or implemented RTP payload is claimed."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Dibujar la permutación y su inversa, marcar borrados y contar celdas ausentes.

**Criterio de refutación:** El desentrelazado anuncia valores perdidos sin redundancia ni retransmisión.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Escriba el orden transmitido entrelazado.

> **Respuesta:** Leer columnas da `[A,D,G,B,E,H,C,F,I]`; los índices `[0,1,2]` borran el primer símbolo de cada bloque.

### Ejercicio 2

Compare las pérdidas del control.

> **Respuesta:** El entrelazado deja `[1,1,1]` ausencias por bloque; el orden por filas deja `[3,0,0]`. Ambos totales son `3`.

### Ejercicio 3

¿Puede la permutación inversa rellenar los valores ausentes?

> **Respuesta:** No. Las posiciones ausentes siguen en `null`; la permutación cambia la ubicación sin añadir información redundante.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Leer columnas da `[A,D,G,B,E,H,C,F,I]`; los índices `[0,1,2]` borran el primer símbolo de cada bloque.
- Ejercicio 2: El entrelazado deja `[1,1,1]` ausencias por bloque; el orden por filas deja `[3,0,0]`. Ambos totales son `3`.
- Ejercicio 3: No. Las posiciones ausentes siguen en `null`; la permutación cambia la ubicación sin añadir información redundante.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
