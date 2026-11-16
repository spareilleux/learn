---
module_id: mcl-017-integrate-a-tempo-ramp-in-beat-coordinates
department: musicology
course: "Integrar una rampa de tempo en coordenadas de pulsos"
level: advanced
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Integrar una rampa de tempo en coordenadas de pulsos

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Una aceleración llamada lineal queda incompleta sin nombrar la variable independiente. Un tempo lineal respecto a la posición musical no suele ser lineal en tiempo transcurrido. Para una rampa de práctica de [GA](https://github.com/GuitarAlchemist/ga) propuesta, integramos segundos por pulso y comparamos con la media de tempos extremos. Extendemos el mapa por escalones con un modelo continuo distinto.

## Leer la evidencia conservada

La referencia define tempo en negras por minuto, sin fijar nuestra interpolación continua. El registro de frase conserva tempo constante; aplicarle esta rampa sería otra propuesta que necesita límites de eventos explícitos.

[Prerrequisito](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/sound/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "start_bpm": 60,
    "end_bpm": 120,
    "quarter_beats": 4
  },
  "formula": "slope=(B1-B0)/Q; duration=60*log(B1/B0)/slope if slope!=0 else 60*Q/B0; endpoint_average_duration=60*Q/((B0+B1)/2)",
  "expected": {
    "slope_bpm_per_quarter": 15,
    "duration_s": 2.772588722239781,
    "endpoint_average_duration_s": 2.6666666666666665
  },
  "negative_control": {
    "values": {
      "start_bpm": 60,
      "end_bpm": 60,
      "quarter_beats": 4
    },
    "expected": {
      "slope_bpm_per_quarter": 0,
      "duration_s": 4,
      "endpoint_average_duration_s": 4
    }
  }
}
```

## Incluir la coordenada de interpolación en la propuesta

Los tempos extremos no determinan el trayecto intermedio. Un editor puede interpolar BPM en segundos, otro en posición musical y otro duración por pulso. Todos pueden cumplir los extremos y programar de forma distinta las notas internas. El registro debe nombrar magnitud y coordenada interpoladas, no guardar solo extremos y la palabra lineal.

En este modelo por pulsos, cada pequeño intervalo contribuye al tiempo según el inverso de su tempo local. Las partes lentas consumen más segundos por pulso que las rápidas. Esa asimetría explica por qué falla en general el atajo de la media. La integral exacta es referencia para una aproximación numérica futura, no evidencia de que un programador alcance realmente esas marcas.

El control constante importa porque la singularidad aparente es evitable. Una especificación puede declarar el límite en vez de forzar una fórmula no constante con división indefinida. Cerca del límite, una implementación necesitaría evaluación estable, otro problema de código. La derivación directa basta para rechazar el atajo. Solo después de conservar posiciones, política de coordenadas y rama constante debería el proyecto considerar un nodo DSL o un agente que genere frases aceleradas.

### Ejercicio 1

Deduzca la pendiente sobre el tramo musical declarado. ¿Qué coordenada utiliza?

<details><summary>Respuesta 1</summary>

La pendiente mostrada es por posición de negra. Reutilizarla como cambio por segundo definiría otra trayectoria y, en general, otra duración.

</details>

### Ejercicio 2

Deduzca el tiempo integrando segundos por pulso. ¿Por qué aparece un logaritmo?

<details><summary>Respuesta 2</summary>

Los segundos por pulso son el inverso del tempo lineal con conversión de minutos. Su integral es logarítmica y produce la duración mostrada para esta rampa positiva.

</details>

### Ejercicio 3

Compare la media de tempos extremos con el resultado integrado.

<details><summary>Respuesta 3</summary>

El atajo subestima la duración construida. Invertir la media del tempo no equivale a promediar su inverso a lo largo del intervalo musical.

</details>

### Ejercicio 4

Aplique el control constante. ¿Por qué evitar dividir por pendiente nula?

<details><summary>Respuesta 4</summary>

La rama constante da la duración indicada y coincide con el atajo. La expresión no constante quedaría indefinida aunque su límite físico sea finito.

</details>

### Ejercicio 5

¿Qué refuta una conversión anunciada como lineal en posición musical?

<details><summary>Respuesta 5</summary>

Un tiempo final incompatible con la duración integrada refuta esa conversión. Una rampa declarada lineal en segundos debe juzgarse con su propia ecuación.

</details>

## Tarea con consulta de fuentes

Derive la integral y el límite constante a mano, y compárelos con el reloj fijo del registro. Proponga un registro que nombre coordenada e interpolación. Use la discrepancia del atajo como criterio de refutación antes de recomendar una abstracción de programación temporal.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
