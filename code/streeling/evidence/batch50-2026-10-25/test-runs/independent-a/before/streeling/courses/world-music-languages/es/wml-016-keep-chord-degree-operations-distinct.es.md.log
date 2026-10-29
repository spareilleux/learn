---
module_id: wml-016-keep-chord-degree-operations-distinct
department: world-music-languages
course: "Distinguir las operaciones sobre grados de un acorde"
level: advanced
prerequisites: ["wml-011-preserve-the-kind-of-a-seventh-chord"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguir las operaciones sobre grados de un acorde

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Un símbolo de acorde puede conservar raíz y familia y perder si un grado se añadió, alteró o eliminó. Convertir toda instrucción en otra clase de altura puede conservar una nota que debía desaparecer. Para una explicación armónica de [GA](https://github.com/GuitarAlchemist/ga), ejecutamos un programa pequeño de cambios antes de proyectar a clases de altura.

## Leer la evidencia conservada

La referencia distingue adición, alteración y sustracción respecto a la familia del acorde. Nuestros controles estrictos de colisión son una política construida adicional, no una promesa de conformidad. La aceptación específica del registro conservado justifica guardar más que una familia general.

[Prerrequisito](../../world-music-languages/en/wml-011-preserve-the-kind-of-a-seventh-chord.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.w3.org/2021/06/musicxml40/musicxml-reference/data-types/degree-type-value/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "degrees": {
      "1": 0,
      "3": 4,
      "5": 7,
      "7": 10
    },
    "operations": [
      {
        "op": "add",
        "degree": 9,
        "semitones": 14
      },
      {
        "op": "alter",
        "degree": 5,
        "delta": -1
      },
      {
        "op": "subtract",
        "degree": 3
      }
    ]
  },
  "formula": "add requires absent degree and inserts declared offset; alter requires present degree and adds delta; subtract requires present degree and removes it; pcs=sorted(set(offset%12))",
  "expected": {
    "degrees": {
      "1": 0,
      "5": 6,
      "7": 10,
      "9": 14
    },
    "pitch_classes": [
      0,
      2,
      6,
      10
    ],
    "valid": true
  },
  "negative_control": {
    "values": {
      "degrees": {
        "1": 0,
        "3": 4,
        "5": 7,
        "7": 10
      },
      "operations": [
        {
          "op": "add",
          "degree": 9,
          "semitones": 14
        },
        {
          "op": "add",
          "degree": 5,
          "semitones": 6
        },
        {
          "op": "subtract",
          "degree": 3
        }
      ]
    },
    "expected": {
      "valid": false,
      "rejected_operation_index": 1,
      "reason": "duplicate_degree",
      "degree": 5
    }
  }
}
```

## Conservar el cambio antes de proyectar su resultado

El mapa de grados mantiene relación con la familia original. El conjunto final responde qué clases quedan tras los cambios, pero no reconstruye de forma única cómo se obtuvieron. Distintas escrituras o programas pueden converger en el mismo conjunto. Para explicar o transferir fielmente notación, el historial forma parte del significado previsto y no es un detalle descartable.

El rechazo de añadir un grado existente es deliberadamente estricto. Otra interfaz podría reemplazar o admitir duplicados, pero tendría que declararlo. Aquí se hace visible una instrucción ambigua antes de que el receptor invente una resolución. El control no demuestra que la especificación exija nuestro error exacto; comprueba la política adicional prometida por este programa didáctico.

Los mapas intermedios evitan además reunir todas las alturas vistas en lugar de las que quedan al final. Esa colección desharía la sustracción y produciría un acorde aparentemente más rico. El registro manual basta para revelar el fallo. Antes de proponer una gramática componible o explicación de agente, conserve raíz, familia, operaciones ordenadas y texto original junto al resultado proyectado. Análisis real, terminología aceptada por músicos y una disposición útil en guitarra necesitarían evidencia adicional al pequeño programa simbólico.

### Ejercicio 1

Parta del mapa de grados y aplique la adición. ¿Por qué conservar la clave del grado compuesto?

<details><summary>Respuesta 1</summary>

El grado añadido conserva su desplazamiento con información de octava. Su clase podría coincidir con otro grado; proyectar pronto borraría la identidad del cambio.

</details>

### Ejercicio 2

Aplique la alteración al grado existente. ¿Añade otra copia del grado?

<details><summary>Respuesta 2</summary>

No. Modifica el desplazamiento del grado existente bajo el programa declarado. Conservar desplazamientos antiguo y nuevo efectuaría otra operación musical.

</details>

### Ejercicio 3

Aplique la sustracción y derive el conjunto de clases de altura.

<details><summary>Respuesta 3</summary>

El mapa y el conjunto finales aparecen abajo. El grado eliminado está ausente; unir todas las alturas intermedias lo conservaría incorrectamente.

</details>

### Ejercicio 4

Aplique el control con adición en vez de alteración. ¿Por qué rechazarlo?

<details><summary>Respuesta 4</summary>

El grado objetivo ya existe. La política estricta rechaza esa operación indexada en vez de adivinar un reemplazo o producir otro acorde sin avisar.

</details>

### Ejercicio 5

¿Qué refuta una exportación anunciada como fiel al programa?

<details><summary>Respuesta 5</summary>

Tratar los programas principal y de control como la misma operación válida pierde la distinción. Conserve símbolo original, familia y cambios antes de anunciar interpretación correcta.

</details>

## Tarea con consulta de fuentes

Ejecute los programas a mano conservando los mapas intermedios. Compare su aceptación con las reglas específicas de acordes existentes. Proponga una transferencia compacta con operaciones y procedencia, usando la colisión como criterio de refutación antes de implementar una gramática o un agente.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
