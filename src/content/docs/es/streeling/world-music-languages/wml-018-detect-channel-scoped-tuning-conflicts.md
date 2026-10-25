---
title: Detectar conflictos de afinación por canal
description: Detectar conflictos de afinación por canal — Músicas y lenguas del mundo
sidebar:
  label: WML-018 · Detectar conflictos de afinación por canal
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-018-detect-channel-scoped-tuning-conflicts.es.md
---

:::note[Streeling University]
**WML-018** · Detectar conflictos de afinación por canal · avanzado · 45 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-018-detect-channel-scoped-tuning-conflicts.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-004](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)
:::

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Una transferencia conserva desplazamientos en cents y envía notas simultáneas por un canal de variación de tono compartido. Cada valor puede ser correcto y su realización incompatible. Codificamos una conversión declarada y comprobamos concurrencia en la frontera del canal. La operación amplía conservar una razón: pregunta si el alcance del transporte puede llevar las peticiones simultáneas.

El resumen oficial describe el mensaje por canal, orden de bytes y sensibilidad del receptor. Declare esa sensibilidad antes de convertir cents en un entero. Mantenga primero el byte menos significativo y después el más significativo; intercambiarlos cambia el valor. El redondeo simétrico es construido y evita extremos que exigirían una política de rango completa.

El canal tiene aquí un solo ajuste en cada instante. Dos notas superpuestas que exigen valores distintos en el mismo canal entran en conflicto. El control de canales distintos conserva desplazamientos y bytes y elimina la colisión de estado compartido. No certifica independencia real de canales ni configura la sensibilidad. El soporte semiabierto explicita las fronteras; se excluyen colas de liberación. Una tabla manual basta antes de implementar asignación o un DSL de afinación. No se enviaron mensajes ni se afirma una entonación interpretada o culturalmente preferida.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lectura primaria](https://midi.org/summary-of-midi-1-0-messages)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "sensitivity_cents": 200,
    "notes": [
      {
        "id": "A",
        "channel": 0,
        "start": 0,
        "end": 1,
        "offset_cents": 0
      },
      {
        "id": "B",
        "channel": 0,
        "start": 0,
        "end": 1,
        "offset_cents": 25
      }
    ]
  },
  "formula": "bend=8192+floor(8192*cents/sensitivity+0.5); LSB=bend%128; MSB=bend//128; conflict iff same channel and max(starts)<min(ends) and unequal bend; note support is half-open",
  "expected": {
    "bend_values": [
      8192,
      9216
    ],
    "lsb_msb": [
      [
        0,
        64
      ],
      [
        0,
        72
      ]
    ],
    "conflict_pairs": [
      [
        "A",
        "B"
      ]
    ]
  },
  "negative_control": {
    "values": {
      "sensitivity_cents": 200,
      "notes": [
        {
          "id": "A",
          "channel": 0,
          "start": 0,
          "end": 1,
          "offset_cents": 0
        },
        {
          "id": "B",
          "channel": 1,
          "start": 0,
          "end": 1,
          "offset_cents": 25
        }
      ]
    },
    "expected": {
      "bend_values": [
        8192,
        9216
      ],
      "lsb_msb": [
        [
          0,
          64
        ],
        [
          0,
          72
        ]
      ],
      "conflict_pairs": []
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga sensibilidad declarada, valores codificados interiores y ajustes iguales del receptor. Los soportes son semiabiertos y se excluyen colas. Canales distintos eliminan el conflicto modelado sin certificar independencia real.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Codifique los desplazamientos con la sensibilidad declarada.

<details><summary>Respuesta 1</summary>

Los enteros mostrados conservan el centro neutro y el desplazamiento positivo según la conversión.

</details>

### Ejercicio 2

Separe cada entero en bytes ordenados.

<details><summary>Respuesta 2</summary>

El byte bajo contiene el resto y el alto el cociente entero en la base declarada, como se muestra.

</details>

### Ejercicio 3

¿Por qué entran en conflicto las notas principales?

<details><summary>Respuesta 3</summary>

Sus soportes semiabiertos se superponen en un canal con valores de variación distintos.

</details>

### Ejercicio 4

¿Qué establece el control de canales distintos?

<details><summary>Respuesta 4</summary>

Elimina este conflicto de alcance sin cambiar valores ni bytes; la configuración del receptor sigue sin probarse.

</details>

### Ejercicio 5

¿Qué refuta la realización en un canal compartido?

<details><summary>Respuesta 5</summary>

Peticiones simultáneas de variaciones distintas en un canal convencional rechazan su realización independiente según el modelo.

</details>

## Tarea con consulta de fuentes

Construya la tabla sin ayuda y redacte una nota GA con sensibilidad y orden de bytes. Deje abiertos soporte del receptor y asignación de canales.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
