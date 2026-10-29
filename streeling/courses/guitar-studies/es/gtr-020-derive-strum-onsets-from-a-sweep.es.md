---
module_id: gtr-020-derive-strum-onsets-from-a-sweep
department: guitar-studies
course: "Deducir los ataques de un acorde a partir de un barrido"
level: advanced
prerequisites: ["gtr-010-separate-muting-from-releasing-a-fretted-note"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Deducir los ataques de un acorde a partir de un barrido

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Un acorde contiene varias notas, pero la púa alcanza sus cuerdas en momentos distintos. Un ejercicio GA que las programa simultáneamente puede conservar alturas y perder el rasgueo solicitado. Convertimos un barrido declarado por coordenadas de cuerdas en instantes de ataque. El recorrido por cuerdas apagadas se conserva, en lugar de comprimir la lista de cuerdas sonoras.

Use velocidad constante y origen en la cuerda extrema según la dirección. Calcule cada cruce como distancia dividida por velocidad y conserve eventos solo para cuerdas sonoras. Apagar elimina un evento de altura, no la coordenada de la cuerda. Reconstruir espacios iguales a partir de la lista reducida acortaría silenciosamente el recorrido.

El control inverso atraviesa la misma geometría y conserva la dispersión total, pero la nota interior entra en otro instante relativo. Un informe basado solo en dispersión pierde orden y separación de ataques. Guarde la lista ordenada si el ejercicio necesita ese detalle. El material de ocupación distingue sonido y técnica sin medir el barrido. Contacto de púa, deformación, separación real y respuesta acústica pueden desplazar los ataques observados. El mapa construido sirve como referencia manual para una propuesta de transferencia de articulación, sin demostrar reproducción sincronizada, grabación ni ejecución real.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../guitar-studies/en/gtr-010-separate-muting-from-releasing-a-fretted-note.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "positions_mm": [
      0,
      10,
      20,
      30,
      40,
      50
    ],
    "sounding_indices": [
      0,
      2,
      5
    ],
    "speed_mm_s": 1000,
    "direction": 1
  },
  "formula": "origin=min(positions) if direction=1 else max(positions); t[i]=abs(position[i]-origin)/speed; events=sort((t[i],i) for sounding i); spread=max(t)-min(t)",
  "expected": {
    "events_time_s_and_index": [
      [
        0,
        0
      ],
      [
        0.02,
        2
      ],
      [
        0.05,
        5
      ]
    ],
    "spread_s": 0.05
  },
  "negative_control": {
    "values": {
      "positions_mm": [
        0,
        10,
        20,
        30,
        40,
        50
      ],
      "sounding_indices": [
        0,
        2,
        5
      ],
      "speed_mm_s": 1000,
      "direction": -1
    },
    "expected": {
      "events_time_s_and_index": [
        [
          0,
          5
        ],
        [
          0.03,
          2
        ],
        [
          0.05,
          0
        ]
      ],
      "spread_s": 0.05
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga coordenadas paralelas fijas, velocidad constante positiva y excitación instantánea en cada cruce. Las cuerdas apagadas no generan evento de altura. Flexibilidad de púa y latencia acústica siguen sin medirse.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Calcule los ataques en la dirección principal.

<details><summary>Respuesta 1</summary>

Use coordenadas originales y velocidad; las cuerdas apagadas siguen contribuyendo a la distancia.

</details>

### Ejercicio 2

¿Por qué mantener una cuerda apagada en la geometría?

<details><summary>Respuesta 2</summary>

Elimina una excitación sin acercar las demás cuerdas.

</details>

### Ejercicio 3

¿Qué conserva invertir el barrido?

<details><summary>Respuesta 3</summary>

Conserva el tiempo entre extremos y la dispersión total con esta convención de origen.

</details>

### Ejercicio 4

¿Qué cambia el control inverso?

<details><summary>Respuesta 4</summary>

Invierte el orden y cambia el retraso del evento interior respecto al primer ataque.

</details>

### Ejercicio 5

¿Qué refuta una transferencia basada solo en dispersión?

<details><summary>Respuesta 5</summary>

El control mantiene la dispersión y cambia la lista ordenada; ese escalar no reconstruye la articulación solicitada.

</details>

## Tarea con consulta de fuentes

Dibuje todas las cuerdas, incluidas las apagadas, antes de calcular eventos ordenados. Compare ambas direcciones en un registro GA propuesto.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
