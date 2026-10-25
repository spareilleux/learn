---
module_id: gaa-014-hold-out-whole-transposition-families
department: guitar-alchemist-academy
course: "Reservar familias completas de transposición para la evaluación"
level: advanced
prerequisites: ["gaa-009-test-transposition-beyond-a-memorized-fret-pattern"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Reservar familias completas de transposición para la evaluación

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Una prueba puede tener identificadores nuevos y repetir, transpuesto, un patrón ensayado. [GA](https://github.com/GuitarAlchemist/ga) debe indicar qué se reserva antes de interpretar una puntuación como transferencia. Definimos una clave de familia con intervalos ordenados y auditamos la partición. El resultado describe la exposición a patrones; el aprendizaje real sigue siendo una cuestión empírica.

## Leer la evidencia conservada

La lectura sobre validación por grupos explica por qué muestras dependientes no deberían cruzar la separación entre entrenamiento y evaluación. Aquí los grupos son familias construidas. El registro conservado distingue las pistas permitidas, sin intentos reales de estos nuevos ejercicios.

[Prerrequisito](../../guitar-alchemist-academy/en/gaa-009-test-transposition-beyond-a-memorized-fret-pattern.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://scikit-learn.org/stable/modules/cross_validation.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "train": [
      {
        "id": "a",
        "notes": [
          60,
          64,
          67
        ]
      },
      {
        "id": "b",
        "notes": [
          60,
          63,
          67
        ]
      }
    ],
    "test": [
      {
        "id": "c",
        "notes": [
          62,
          66,
          69
        ]
      },
      {
        "id": "d",
        "notes": [
          62,
          67,
          69
        ]
      }
    ]
  },
  "formula": "family(notes)=tuple(note-note[0]); overlap=sorted(set(train families) intersect set(test families)); family_disjoint=(overlap empty)",
  "expected": {
    "overlap": [
      [
        0,
        4,
        7
      ]
    ],
    "family_disjoint": false,
    "distinct_item_ids": 4
  },
  "negative_control": {
    "values": {
      "train": [
        {
          "id": "a",
          "notes": [
            60,
            64,
            67
          ]
        },
        {
          "id": "b",
          "notes": [
            60,
            63,
            67
          ]
        }
      ],
      "test": [
        {
          "id": "d",
          "notes": [
            62,
            67,
            69
          ]
        },
        {
          "id": "e",
          "notes": [
            65,
            70,
            72
          ]
        }
      ]
    },
    "expected": {
      "overlap": [],
      "family_disjoint": true,
      "distinct_item_ids": 4
    }
  }
}
```

## Definir la exposición al nivel que necesita la evaluación

La clave de ejercicio y la de familia cumplen objetivos distintos. La primera distingue una consigna o archivo concreto; la segunda agrupa material según la transformación elegida. Ninguna es la unidad correcta para cualquier evaluación. La afirmación de aprendizaje determina qué familiaridad facilitaría demasiado la prueba, y la regla debe escribirse antes de examinar la puntuación.

La regla elegida conserva orden y diferencias respecto a la primera nota. Agrupa transposiciones exactas, pero no inversiones, variantes rítmicas o notas desplazadas de octava salvo que coincidan sus diferencias ordenadas. Una partición válida solo certifica esa definición. Ampliar la regla después de ver respuestas cambiaría el material considerado reservado y exigiría otro informe.

El control contiene ejercicios relacionados dentro de evaluación, algo permitido por la regla limitada entre particiones. Eso no hace independientes sus futuras respuestas. Un informe podría necesitar agregación por familia u otro modelo de dependencia. Distinga prevención de filtraciones de exposición y estimación de incertidumbre. Una tabla directa de notas, claves y particiones basta para auditar la frontera actual. Un generador automático debe conservarla en vez de tratar identificadores nuevos como evidencia de novedad.

### Ejercicio 1

Calcule una clave para cada ejercicio principal. ¿Qué información de orden conserva?

<details><summary>Respuesta 1</summary>

Reste la primera altura de cada altura, manteniendo el orden. La clave conserva diferencias dirigidas y relaciones de registro, en vez de un conjunto desordenado de clases de altura.

</details>

### Ejercicio 2

Interseque las claves de entrenamiento y evaluación. ¿Bastan identificadores únicos?

<details><summary>Respuesta 2</summary>

El solapamiento mostrado refuta la separación de familias. Todos los identificadores pueden ser únicos y seguir existiendo patrones relacionados en ambas partes.

</details>

### Ejercicio 3

¿Demuestra el solapamiento que alguien hizo trampa o no aprendió nada?

<details><summary>Respuesta 3</summary>

No. Describe el diseño y limita la interpretación de transferencia. No aporta respuestas reales, intenciones ni cambios de habilidad.

</details>

### Ejercicio 4

Aplique el control. ¿Qué se ha corregido y qué queda pendiente?

<details><summary>Respuesta 4</summary>

Desaparece el solapamiento de las familias elegidas. El timbre, el ritmo, la exposición a fuentes y la dificultad aún podrían vincular condiciones o proporcionar pistas.

</details>

### Ejercicio 5

¿Qué refuta una partición anunciada como disjunta por familias?

<details><summary>Respuesta 5</summary>

Cualquier clave conservada en ambas particiones es un contraejemplo. Mantenga las notas originales y la regla para que otra persona pueda cuestionar la agrupación.

</details>

## Tarea con consulta de fuentes

Construya la tabla de familias a mano antes de pedir ayuda. Audite las particiones y la política de pistas conservada, y proponga un manifiesto de ejercicios. Identifique el solapamiento y otra dependencia sin resolver antes de recomendar generación automática de cuestionarios.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
