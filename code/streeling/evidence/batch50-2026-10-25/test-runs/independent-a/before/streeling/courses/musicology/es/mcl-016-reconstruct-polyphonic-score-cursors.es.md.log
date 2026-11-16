---
module_id: mcl-016-reconstruct-polyphonic-score-cursors
department: musicology
course: "Reconstruir cursores de una partitura polifónica"
level: advanced
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Reconstruir cursores de una partitura polifónica

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Una partitura serializada puede describir una voz completa antes de volver al principio para otra. Sumar las duraciones como sonidos consecutivos convierte simultaneidad en sucesión. Una transferencia de frase de [GA](https://github.com/GuitarAlchemist/ga) requiere interpretar el cursor antes de convertir el tempo. Reconstruimos los intervalos a partir de una breve secuencia de operaciones.

## Leer la evidencia conservada

La referencia usa retroceso y avance para coordinar voces y prohíbe al retroceso cruzar medidas o cambios de divisiones. El registro conservado ya utiliza intervalos absolutos. Explicamos una posible conversión hacia ellos, sin afirmar que exista un analizador que la ejecute.

[Prerrequisito](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/backup/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "measure_units": 4,
    "operations": [
      {
        "op": "note",
        "id": "a",
        "duration": 4
      },
      {
        "op": "backup",
        "duration": 4
      },
      {
        "op": "note",
        "id": "b",
        "duration": 2
      },
      {
        "op": "forward",
        "duration": 2
      }
    ]
  },
  "formula": "cursor=0; note records [cursor,cursor+duration) then advances; backup subtracts duration; forward adds duration; valid=all cursor states within [0,measure_units]",
  "expected": {
    "note_intervals": {
      "a": [
        0,
        4
      ],
      "b": [
        0,
        2
      ]
    },
    "cursor_states": [
      0,
      4,
      0,
      2,
      4
    ],
    "final_cursor": 4,
    "valid": true
  },
  "negative_control": {
    "values": {
      "measure_units": 4,
      "operations": [
        {
          "op": "note",
          "id": "a",
          "duration": 4
        },
        {
          "op": "backup",
          "duration": 2
        },
        {
          "op": "note",
          "id": "b",
          "duration": 2
        },
        {
          "op": "forward",
          "duration": 2
        }
      ]
    },
    "expected": {
      "note_intervals": {
        "a": [
          0,
          4
        ],
        "b": [
          2,
          4
        ]
      },
      "cursor_states": [
        0,
        4,
        2,
        4,
        6
      ],
      "final_cursor": 6,
      "valid": false
    }
  }
}
```

## Separar el recorrido documental del tiempo musical

El cursor de serialización sitúa eventos mientras se lee el documento. No es necesariamente un reloj de reproducción monótono. El retroceso lo demuestra: el lector vuelve atrás sin invertir la música. Convertir el cursor en intervalos absolutos permite después una cronología monótona sin perder la colocación de voces.

La unidad fija de divisiones debe acompañar a cada duración. Un cambio dentro de la medida exigiría otra conversión; no se puede restar una duración antigua de un cursor expresado en unidades nuevas. Las restricciones de la referencia tienen valor semántico, no solo formal. Nuestro modelo evita esos cambios para que la aritmética se inspeccione directamente.

Igualar el cursor final tampoco garantiza corrección completa. Una secuencia inválida podría acabar donde corresponde tras excursiones ilegales; finales correctos no preservan necesariamente voces o articulación. Por eso conservamos todos los estados y el último. El registro manual ya detecta el solapamiento cambiado y el desbordamiento del control. Un importador futuro debe conservar esos testigos antes de añadir mapa de tempo, conducción de voces o asignación a guitarra, que dependen de intervalos reconstruidos correctamente.

### Ejercicio 1

Recorra la secuencia principal y registre cada estado del cursor. ¿Es el retroceso música de duración negativa?

<details><summary>Respuesta 1</summary>

Los estados aparecen abajo. El retroceso reposiciona el cursor de serialización; no crea una nota de duración sonora negativa.

</details>

### Ejercicio 2

Deduzca los intervalos de ambas notas. ¿Son sucesivas o se solapan?

<details><summary>Respuesta 2</summary>

Empiezan juntas y se solapan durante la duración de la más corta. El orden documental no establece por sí solo el orden de reproducción.

</details>

### Ejercicio 3

¿Qué aporta la operación de avance?

<details><summary>Respuesta 3</summary>

Desplaza el cursor sin añadir un evento sonoro en esta secuencia construida. Separe tiempo silencioso, nueva nota y duración de la nota anterior.

</details>

### Ejercicio 4

Aplique el control con retroceso reducido. ¿Dónde cambian la colocación y el respeto del límite?

<details><summary>Respuesta 4</summary>

La voz posterior empieza más tarde y el cursor final supera la medida declarada. Conserve ambos hechos en lugar de limitar artificialmente el cursor y ocultar la entrada inválida.

</details>

### Ejercicio 5

¿Qué refuta una exportación anunciada como fiel a la polifonía?

<details><summary>Respuesta 5</summary>

Una lista que serialice las notas principales o mantenga los mismos inicios para el control pierde la cronología requerida. Un cursor fuera de límites invalida la entrada antes de programarla.

</details>

## Tarea con consulta de fuentes

Reconstruya ambas tablas a mano antes de consultar respuestas. Compare los intervalos absolutos con el registro conservado. Proponga una transferencia que guarde unidades de división y voces, usando el desbordamiento de medida como criterio de refutación antes de implementar un analizador o DSL.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
