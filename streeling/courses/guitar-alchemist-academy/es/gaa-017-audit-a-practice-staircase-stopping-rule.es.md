---
module_id: gaa-017-audit-a-practice-staircase-stopping-rule
department: guitar-alchemist-academy
course: "Auditar la regla de parada de una escalera de práctica"
level: advanced
prerequisites: ["gaa-010-define-a-practice-pass-before-counting-success"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Auditar la regla de parada de una escalera de práctica

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Un asistente sube el tempo tras un acierto, lo baja tras un fallo y presenta el último tempo como umbral personal. La actualización no justifica esa interpretación. Construimos una escalera y comprobamos exactamente su condición de parada. El prerrequisito define el acierto; la operación nueva conserva la historia secuencial necesaria para contar inversiones de dirección.

Una inversión es un cambio en la dirección de actualización, no cualquier fallo. Los fallos consecutivos continúan el descenso. La primera actualización no invierte una dirección inexistente. Guarde el tempo previo a la respuesta y el siguiente programado para no resumir el lado equivocado de la transición. La estimación declarada promedia los niveles previos en las inversiones y solo se informa cuando se cumple la parada.

El control contiene igual número de intentos completos sin cambiar de sentido. Tiene un último nivel programado, pero la estimación de parada sigue sin resolverse. Esto distingue un límite de ensayos de una regla de inversiones. Una interfaz real necesitaría límites, respuestas ausentes e interrupciones. El registro de práctica declara objetivo y ayudas permitidas; deben acompañar la historia. Ningún guitarrista produjo esta traza y la aritmética no mide un umbral. La tabla manual precede a cualquier recomendación adaptativa.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../guitar-alchemist-academy/en/gaa-010-define-a-practice-pass-before-counting-success.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "initial_tempo": 60,
    "step": 5,
    "passes": [
      true,
      true,
      false,
      false,
      true,
      false
    ],
    "required_reversals": 3
  },
  "formula": "direction=1 if pass else -1; next_tempo=current_tempo+step*direction; reversal occurs when direction differs from previous direction; stop at required_reversals; estimate=mean(pre_update_tempo at reversals) only after stop",
  "expected": {
    "pre_update_tempo": [
      60,
      65,
      70,
      65,
      60,
      65
    ],
    "post_update_tempo": [
      65,
      70,
      65,
      60,
      65,
      60
    ],
    "reversal_indices": [
      2,
      4,
      5
    ],
    "stop_index": 5,
    "estimate_tempo": 65
  },
  "negative_control": {
    "values": {
      "initial_tempo": 60,
      "step": 5,
      "passes": [
        true,
        true,
        true,
        true,
        true,
        true
      ],
      "required_reversals": 3
    },
    "expected": {
      "pre_update_tempo": [
        60,
        65,
        70,
        75,
        80,
        85
      ],
      "post_update_tempo": [
        65,
        70,
        75,
        80,
        85,
        90
      ],
      "reversal_indices": [],
      "stop_index": null,
      "estimate_tempo": null
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga resultados booleanos construidos completos y una traza de paso fijo sin límites alcanzados. La primera actualización carece de dirección previa y los índices parten de cero. El resumen no valida un umbral personal.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Siga los tempos antes y después de cada respuesta.

<details><summary>Respuesta 1</summary>

Aplique el paso fijo según la respuesta y distinga el nivel probado del siguiente programado.

</details>

### Ejercicio 2

¿Qué cambios son inversiones reales?

<details><summary>Respuesta 2</summary>

Solo cuenta cambiar respecto a la dirección anterior; repetir aciertos o fallos no crea inversiones.

</details>

### Ejercicio 3

¿Cuándo se detiene la traza principal?

<details><summary>Respuesta 3</summary>

En el ensayo mostrado donde alcanza el número requerido; la estimación usa los niveles previos declarados.

</details>

### Ejercicio 4

¿Por qué queda sin resolver la estimación del control?

<details><summary>Respuesta 4</summary>

Nunca cumple la parada por inversiones, aunque todos los ensayos estén completos y exista un último nivel.

</details>

### Ejercicio 5

¿Qué rechaza un supuesto umbral personal?

<details><summary>Respuesta 5</summary>

Sin respuestas reales ni validación de la interpretación, el resumen construido no establece un umbral del estudiante.

</details>

## Tarea con consulta de fuentes

Construya la tabla sin ayuda y proponga un registro que distinga niveles probados y programados. Deje umbral personal y adopción sin decidir.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
