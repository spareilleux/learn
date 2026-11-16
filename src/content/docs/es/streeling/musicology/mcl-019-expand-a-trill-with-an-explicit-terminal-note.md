---
title: Desarrollar un trino con una nota final explícita
description: Desarrollar un trino con una nota final explícita — Musicología
sidebar:
  label: MCL-019 · Desarrollar un trino con una nota final explícita
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/es/mcl-019-expand-a-trill-with-an-explicit-terminal-note.es.md
---

:::note[Streeling University]
**MCL-019** · Desarrollar un trino con una nota final explícita · avanzado · 45 minutos

Generado por el departamento *Musicología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/es/mcl-019-expand-a-trill-with-an-explicit-terminal-note.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MCL-014](../../musicology/mcl-014-declare-where-grace-notes-take-their-time/)
:::

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Un ejercicio GA pide alternar alturas durante un tiempo fijo y terminar en la principal, pero su número de eventos acaba en la auxiliar. Ambas alturas aparecen y aun así falla el requisito final. Desarrollamos una política finita de trino y comprobamos su terminación. Amplía la asignación de tiempo alrededor de una nota principal del prerrequisito.

Declare inicio, altura auxiliar, número de eventos y duración antes de generar la secuencia. Con duraciones iguales, cada ataque es un múltiplo entero de la duración elemental y el último evento termina en la frontera prevista. La altura final depende de la paridad. Cambiar el número conservando la duración modifica separación y terminación, no solo la etiqueta.

La referencia MusicXML distingue nota inicial, recuento de reproducción y posible giro final. Esos campos motivan conservar las distinciones sin imponer nuestro espaciado a una práctica histórica. Un giro final añadiría eventos excluidos del modelo. El control cambia solo el número y termina en la otra altura. Conserve las listas de alturas y ataques si el ejercicio exige una terminación. Una tabla manual de alternancia resuelve esta cuestión antes de proponer un DSL de ornamentos o una función del motor.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../musicology/mcl-014-declare-where-grace-notes-take-their-time/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/music-phrase-2026-10-22/melody-constraints.json)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/trill-mark/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "main_pitch": 60,
    "alternate_pitch": 62,
    "note_count": 6,
    "duration_s": 1.2
  },
  "formula": "pitch[i]=main if i%2==0 else alternate; onset[i]=i*duration/count for i=0..count-1; duration_each=duration/count; terminal=pitch[count-1]",
  "expected": {
    "pitches": [
      60,
      62,
      60,
      62,
      60,
      62
    ],
    "onsets_s": [
      0,
      0.2,
      0.4,
      0.6,
      0.8,
      1
    ],
    "duration_each_s": 0.2,
    "terminal_pitch": 62
  },
  "negative_control": {
    "values": {
      "main_pitch": 60,
      "alternate_pitch": 62,
      "note_count": 5,
      "duration_s": 1.2
    },
    "expected": {
      "pitches": [
        60,
        62,
        60,
        62,
        60
      ],
      "onsets_s": [
        0,
        0.24,
        0.48,
        0.72,
        0.96
      ],
      "duration_each_s": 0.24,
      "terminal_pitch": 60
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga recuento finito positivo, inicio principal, duraciones iguales y ningún giro final. Alturas y soporte son explícitos. No se establece realización estilística ni interpretación musical.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Desarrolle la secuencia contando también el primer evento.

<details><summary>Respuesta 1</summary>

Empieza en la principal y alterna exactamente durante el número declarado de eventos.

</details>

### Ejercicio 2

Derive ataques y duración elemental.

<details><summary>Respuesta 2</summary>

Divida el soporte por el número y use múltiplos sucesivos; el último evento acaba en la frontera.

</details>

### Ejercicio 3

¿Termina el caso principal en la principal?

<details><summary>Respuesta 3</summary>

No. Su número par y su inicio principal producen una terminación auxiliar.

</details>

### Ejercicio 4

¿Qué cambia el control impar?

<details><summary>Respuesta 4</summary>

Termina en la principal con eventos iguales más largos y el mismo soporte total.

</details>

### Ejercicio 5

¿Qué refuta conservar el ornamento?

<details><summary>Respuesta 5</summary>

Otra terminación, número o soporte rechaza la propiedad correspondiente según esta política.

</details>

## Tarea con consulta de fuentes

Desarrolle el trino a mano y compruebe su terminación. Proponga un registro que separe número, inicio y posible giro final.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
