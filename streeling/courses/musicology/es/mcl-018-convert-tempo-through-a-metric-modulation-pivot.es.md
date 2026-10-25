---
module_id: mcl-018-convert-tempo-through-a-metric-modulation-pivot
department: musicology
course: "Convertir el tempo mediante un pivote de modulación métrica"
level: advanced
prerequisites: ["mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Convertir el tempo mediante un pivote de modulación métrica

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Un guitarrista recibe un ejercicio con una relación métrica y un tempo nuevo. Copiar el número anterior de pulsaciones puede romper la relación aunque conserve los símbolos. Deducimos la nueva velocidad de negras mediante un pivote de igual duración. La operación conecta dos coordenadas locales de tempo; amplía la simple identificación de unidad de un metrónomo.

Convierta primero el pivote antiguo en segundos con la duración de la negra antigua. Divida después esa duración por el número de negras nuevas del pivote de destino. Este orden muestra el sentido de la razón. Usar la inversa no conservaría la duración del pivote. El caso fijo iguala una negra antigua con puntillo y una negra nueva, por lo que la nueva dura más.

El control identidad usa pivotes iguales y conserva la velocidad original. Detecta fórmulas que cambian el tempo solo porque aparece una relación métrica. El elemento MusicXML describe la notación del signo sin demostrar importación o reproducción en GA. Una comparación real debe conservar ambas unidades, tempo de origen e instantes de eventos. La igualdad no demuestra acento cultural, expresividad ni intención de dirección. Una cadena manual de duraciones basta antes de proponer un DSL de modulación métrica.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/music-phrase-2026-10-22/melody-constraints.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/metronome-note/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "old_quarter_bpm": 120,
    "old_pivot_quarters": 1.5,
    "new_pivot_quarters": 1
  },
  "formula": "old_quarter_s=60/old_bpm; pivot_s=old_pivot*old_quarter_s; new_quarter_s=pivot_s/new_pivot; new_bpm=old_bpm*new_pivot/old_pivot",
  "expected": {
    "old_quarter_s": 0.5,
    "pivot_s": 0.75,
    "new_quarter_s": 0.75,
    "new_quarter_bpm": 80
  },
  "negative_control": {
    "values": {
      "old_quarter_bpm": 120,
      "old_pivot_quarters": 1.5,
      "new_pivot_quarters": 1.5
    },
    "expected": {
      "old_quarter_s": 0.5,
      "pivot_s": 0.75,
      "new_quarter_s": 0.5,
      "new_quarter_bpm": 120
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga igualdad instantánea exacta entre las duraciones de pivotes. Cada longitud usa su propia coordenada de negra. No hay rampa, expresividad medida ni resultado de importación ejecutada.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Convierta la negra antigua y el pivote en segundos.

<details><summary>Respuesta 1</summary>

Use primero la velocidad anterior y multiplique por la longitud del pivote en negras antiguas.

</details>

### Ejercicio 2

Derive la duración de la nueva negra.

<details><summary>Respuesta 2</summary>

Divida la duración común por la longitud del pivote en negras nuevas.

</details>

### Ejercicio 3

¿En qué sentido cambia la velocidad principal?

<details><summary>Respuesta 3</summary>

Disminuye: una negra nueva ocupa la duración mayor de la antigua negra con puntillo.

</details>

### Ejercicio 4

¿Qué establece el control identidad?

<details><summary>Respuesta 4</summary>

Los pivotes iguales conservan duración y velocidad de la negra con esta regla.

</details>

### Ejercicio 5

¿Qué refuta la modulación informada?

<details><summary>Respuesta 5</summary>

Si difieren las duraciones de los pivotes en segundos, la igualdad y el tempo calculado son incompatibles.

</details>

## Tarea con consulta de fuentes

Prepare una nota con ambos relojes para una importación GA propuesta. Conserve la igualdad exacta antes de elegir el tempo final.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
