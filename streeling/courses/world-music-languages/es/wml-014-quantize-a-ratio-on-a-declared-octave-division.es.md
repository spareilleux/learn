---
module_id: wml-014-quantize-a-ratio-on-a-declared-octave-division
department: world-music-languages
course: "Cuantizar una razón sobre una división declarada de la octava"
level: advanced
prerequisites: ["wml-004-preserve-intonation-beyond-pitch-classes"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Cuantizar una razón sobre una división declarada de la octava

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Un paso entero no tiene tamaño musical fijo sin su división de la octava. Una transferencia de escala de [GA](https://github.com/GuitarAlchemist/ga) que conserve el número y pierda la rejilla puede cambiar el intervalo previsto. Aproximamos una razón construida sobre divisiones iguales y conservamos el residuo. Objetivo, representación y error siguen siendo magnitudes distintas.

## Leer la evidencia conservada

La lectura principal define los cents mediante una razón multiplicativa. El registro conservado ya muestra una proyección discreta que borra una diferencia. Hacemos variable la rejilla de destino sin atribuirla a una cultura ni afirmar que el motor la admita.

[Prerrequisito](../../world-music-languages/en/wml-004-preserve-intonation-beyond-pitch-classes.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "target_ratio": 1.25,
    "octave_divisions": 19
  },
  "formula": "target_cents=1200*log2(ratio); step=floor(divisions*log2(ratio)+0.5); represented_cents=1200*step/divisions; error_cents=represented_cents-target_cents",
  "expected": {
    "target_cents": 386.3137138648348,
    "step": 6,
    "represented_cents": 378.94736842105266,
    "error_cents": -7.366345443782166
  },
  "negative_control": {
    "values": {
      "target_ratio": 1.25,
      "octave_divisions": 12
    },
    "expected": {
      "target_cents": 386.3137138648348,
      "step": 4,
      "represented_cents": 400,
      "error_cents": 13.686286135165204
    }
  }
}
```

## Separar aproximación e interpretación cultural

Dividir igualmente la octava es una construcción matemática. El número de pasos no identifica por sí solo tradición, repertorio ni entonación de un intérprete. Una rejilla puede aproximar bien una razón y representar mal otros intervalos importantes. Elegirla por un error pequeño exige un objetivo declarado, no una afirmación universal de superioridad.

El residuo con signo también indica la dirección que separa representación y razón solicitada. Un error absoluto ocultaría esa dirección. A la inversa, guardar solo el residuo sin razón y rejilla tampoco basta: el receptor debe conocer la referencia de la corrección. Conserve esos campos como magnitudes construidas distintas.

La frontera discreta del catálogo muestra por qué un registro orientativo no equivale a soporte de ejecución. Almacenar un identificador de rejilla difiere de poder realizar sus frecuencias en un instrumento. Un diapasón temperado corriente puede necesitar otra técnica o instrumento; una entrada del software aún exige medir la salida. La tabla manual basta para revelar pérdida antes de proponer un DSL de afinación. Una implementación más rica solo se justifica tras definir uso musical y requisitos medibles de conservación.

### Ejercicio 1

Convierta la razón objetivo a cents. ¿Cambia ese objetivo con la rejilla de destino?

<details><summary>Respuesta 1</summary>

El valor objetivo permanece igual en ambos casos. Describe la razón solicitada antes de cuantizar, independientemente de la rejilla elegida.

</details>

### Ejercicio 2

Elija el paso más próximo en la rejilla principal. ¿Qué convención importa ante un empate?

<details><summary>Respuesta 2</summary>

Use el paso mostrado. La regla construida redondea empates hacia arriba; aunque aquí no hay empate, la convención forma parte de una transferencia reproducible.

</details>

### Ejercicio 3

Calcule el intervalo representado y el error con signo. ¿Qué significa un residuo negativo?

<details><summary>Respuesta 3</summary>

El intervalo representado queda por debajo del objetivo. El residuo es un error de aproximación en esa rejilla, no un guitarrista observado tocando bajo de afinación.

</details>

### Ejercicio 4

Aplique el control con otra rejilla. ¿Qué valores deben cambiar?

<details><summary>Respuesta 4</summary>

Cambian el paso, los cents representados y el residuo; el objetivo permanece fijo. Comparar enteros brutos entre rejillas mezclaría unidades incompatibles.

</details>

### Ejercicio 5

¿Qué refuta una transferencia anunciada como fiel a la razón exacta?

<details><summary>Respuesta 5</summary>

Sustituir el objetivo solo por el paso aproximado pierde el residuo no nulo. Conserve razón y rejilla; la idoneidad musical necesita evidencia y juicio humanos apropiados para la tradición.

</details>

## Tarea con consulta de fuentes

Construya a mano la tabla objetivo/rejilla/error antes de recibir ayuda. Examine la proyección conservada y proponga un registro con razón e identidad de rejilla. Rechace una afirmación de exactitud si se descarta el residuo; deje pendientes interpretación cultural y soporte de afinación.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
