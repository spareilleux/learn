---
title: Separar la liberación de la tecla de la del pedal
description: Separar la liberación de la tecla de la del pedal — Musicología
sidebar:
  label: MCL-015 · Separar la liberación de la tecla de la del pedal
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/es/mcl-015-separate-key-release-from-pedal-release.es.md
---

:::note[Streeling University]
**MCL-015** · Separar la liberación de la tecla de la del pedal · avanzado · 60 minutos

Generado por el departamento *Musicología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/es/mcl-015-separate-key-release-from-pedal-release.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MCL-012](../../musicology/mcl-012-merge-ties-without-merging-slurs/)
:::

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Un acompañamiento puede mantener una nota bajo pedal después de soltar su tecla. Confundir ese instante con el fin inmediato del sonido acorta la retención prevista; prolongar todas las notas posteriores la alarga demasiado. Para una transferencia de acompañamiento de [GA](https://github.com/GuitarAlchemist/ga), seguimos la orden de liberación y dejamos la cola acústica fuera del modelo.

## Leer la evidencia conservada

La referencia de reproducción distingue el ajuste del pedal de resonancia de un evento de nota. El registro temporal conservado tiene finales explícitos, pero no una regla de pedal. Nuestra regla es una extensión didáctica propuesta, sin cambiar importadores ni atribuir comportamiento de piano al motor de guitarra.

[Prerrequisito](../../musicology/mcl-012-merge-ties-without-merging-slurs/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/sound/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "notes": [
      {
        "id": "a",
        "on": 0,
        "key_off": 0.5
      },
      {
        "id": "b",
        "on": 1,
        "key_off": 1.5
      }
    ],
    "pedal_down": 0.25,
    "pedal_up": 2
  },
  "formula": "release_i=pedal_up if pedal_down<=key_off_i<pedal_up else key_off_i; scheduled_hold_i=release_i-on_i",
  "expected": {
    "release_times": [
      2,
      2
    ],
    "scheduled_holds": [
      2,
      1
    ]
  },
  "negative_control": {
    "values": {
      "notes": [
        {
          "id": "a",
          "on": 0,
          "key_off": 0.5
        },
        {
          "id": "b",
          "on": 1,
          "key_off": 1.5
        }
      ],
      "pedal_down": 0.25,
      "pedal_up": 0.75
    },
    "expected": {
      "release_times": [
        0.75,
        1.5
      ],
      "scheduled_holds": [
        0.75,
        0.5
      ]
    }
  }
}
```

## Precisar qué límite controla realmente el evento

Los finales conservados describen intervalos construidos, no medidas de silencio. Añadir estado de pedal introduce otra capa de programación. Soltar la tecla termina esa acción; la regla decide cuándo el pedal permite liberar. La envolvente acústica posterior es otro proceso. Una transferencia fiable nombra esos límites en vez de reunirlos en un campo ambiguo de duración.

La lección excluye deliberadamente precedencia simultánea y repeticiones de la misma altura. Son importantes en un programador completo. Cambiar pedal al soltar la tecla exige una política de orden; repetir una altura exige identidades para que una liberación no corte otro evento. Aquí los tiempos e identificadores distintos hacen innecesarias esas entradas para el cálculo pequeño, sin probar que una futura implementación resuelva los casos excluidos.

Tampoco debe transferirse silenciosamente la metáfora del pedal a la guitarra física. Liberación del dedo, apagado y resonancia obedecen otros mecanismos. Lo útil en común es conservar un límite de acción explícito. Una cronología basta para mostrar la pérdida al omitir el pedal. Antes de convertirlo en un DSL multiinstrumento, compare el registro propuesto con esa cronología y enumere la semántica adicional que cada instrumento necesita realmente.

### Ejercicio 1

Identifique los eventos de liberación de las notas principales. ¿Coinciden tecla suelta y liberación programada?

<details><summary>Respuesta 1</summary>

Son distintos en el caso principal. Ambas teclas se sueltan con el pedal bajado; la regla retrasa sus órdenes hasta levantarlo.

</details>

### Ejercicio 2

Calcule los tiempos de liberación y las duraciones de retención programada.

<details><summary>Respuesta 2</summary>

Las matrices figuran arriba. Reste a cada liberación su propio inicio; no use el primer inicio para todas las notas ni sustituya su identidad por la altura.

</details>

### Ejercicio 3

¿Una liberación programada significa que la onda pasa a cero en ese instante?

<details><summary>Respuesta 3</summary>

No. Es un límite de comando. Una envolvente o un instrumento físico puede seguir decayendo; no se ha aportado ni medido ninguna cola.

</details>

### Ejercicio 4

Aplique el control con pedal levantado antes. ¿Por qué no se prolonga la nota posterior?

<details><summary>Respuesta 4</summary>

Su tecla se suelta después de levantar el pedal. La primera nota se prolonga hasta ese límite anterior; la posterior conserva su propia liberación de tecla.

</details>

### Ejercicio 5

¿Qué refuta un exportador anunciado como fiel al calendario de liberación?

<details><summary>Respuesta 5</summary>

Omitir el intervalo de pedal o dar matrices idénticas al caso principal y al control borra la distinción requerida. La fidelidad acústica necesita otra observación.

</details>

## Tarea con consulta de fuentes

Dibuje a mano los estados de cada nota y del pedal. Examine el significado de los finales conservados y proponga un registro separado de órdenes. Use el control contra una exportación antes de automatizar la reproducción; deje sin evaluar la caída real y la técnica de sostenimiento en guitarra.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
