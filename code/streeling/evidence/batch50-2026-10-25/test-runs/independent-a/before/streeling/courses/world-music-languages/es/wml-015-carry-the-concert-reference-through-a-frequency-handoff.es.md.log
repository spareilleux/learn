---
module_id: wml-015-carry-the-concert-reference-through-a-frequency-handoff
department: world-music-languages
course: "Conservar el diapasón de referencia al transferir frecuencias"
level: advanced
prerequisites: ["wml-004-preserve-intonation-beyond-pitch-classes"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar el diapasón de referencia al transferir frecuencias

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Dos herramientas pueden coincidir en todos los intervalos de una frase y discrepar en sus frecuencias absolutas. Omitir el diapasón de referencia puede explicarlo. Para una transferencia de [GA](https://github.com/GuitarAlchemist/ga), cambiamos la calibración sin modificar números de notas ni intervalos. Se distingue de transponer: las identidades escritas permanecen fijas y cambia la referencia.

## Leer la evidencia conservada

La lectura principal describe la referencia convencional y la relación de cents. La alternativa es construida, sin afirmaciones sobre un conjunto musical real. El registro conserva referencias y advierte que aceptar una frecuencia no demuestra su realización acústica.

[Prerrequisito](../../world-music-languages/en/wml-004-preserve-intonation-beyond-pitch-classes.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "reference_a_hz": 442,
    "comparison_a_hz": 440,
    "midi_notes": [
      69,
      81
    ]
  },
  "formula": "f(n)=reference*2^((n-69)/12); calibration_ratio=reference/comparison; calibration_cents=1200*log2(calibration_ratio); octave_ratio=f(81)/f(69)",
  "expected": {
    "frequencies_hz": [
      442,
      884
    ],
    "calibration_ratio": 1.0045454545454546,
    "calibration_cents": 7.851415040126504,
    "octave_ratio": 2
  },
  "negative_control": {
    "values": {
      "reference_a_hz": 440,
      "comparison_a_hz": 440,
      "midi_notes": [
        69,
        81
      ]
    },
    "expected": {
      "frequencies_hz": [
        440,
        880
      ],
      "calibration_ratio": 1,
      "calibration_cents": 0,
      "octave_ratio": 2
    }
  }
}
```

## Separar calibración e identidad de nota

La referencia relaciona una coordenada de nota con frecuencia física. Cambiar esa correspondencia conserva la coordenada escrita. Transponer cambia, en cambio, la coordenada según una transformación musical declarada. Ambas operaciones pueden producir cambios de frecuencia parecidos en una nota, pero conservan significados distintos al transferir datos. Una salida más aguda no basta para inferir la operación.

En este modelo, las razones entre notas cancelan la referencia común. Una frase puede conservar todos sus intervalos y fallar una comprobación absoluta. También explica por qué la octava es una prueba débil de calibración. Una comparación útil debe incluir una frecuencia absoluta objetivo con referencia y unidades, distinguiendo valor solicitado y valor realizado estimado.

La calibración alternativa es una entrada didáctica, no una recomendación para un conjunto. Instrumentos, contextos y prácticas pueden elegir otras referencias o ajustes no uniformes. Una transferencia futura podría combinar diapasón y razones por grado; ninguno debe sustituir silenciosamente al otro. La tabla directa hace visible la separación antes de crear una abstracción de afinación. Si se pierde la referencia, declare esa entrada ausente en vez de adivinarla por un nombre familiar o afirmar que una transposición automática la corrigió.

### Ejercicio 1

Convierta la lista principal a frecuencias con su referencia declarada.

<details><summary>Respuesta 1</summary>

Las frecuencias esperadas aparecen abajo. Los números de nota no las determinan por sí solos si el receptor desconoce la referencia de conversión.

</details>

### Ejercicio 2

Calcule la razón de calibración y el desplazamiento en cents respecto a la referencia comparativa.

<details><summary>Respuesta 2</summary>

Ambos se aplican por igual a cada nota del modelo. Un desplazamiento aditivo en hercios no conservaría el mismo cambio en cents entre registros.

</details>

### Ejercicio 3

Compruebe la razón de octava. ¿Detecta una referencia olvidada?

<details><summary>Respuesta 3</summary>

La octava sigue siendo exacta en el caso principal y el control. Una prueba de intervalos solamente no detecta esta diferencia de frecuencia absoluta.

</details>

### Ejercicio 4

Aplique el control con la referencia comparativa. ¿Qué discrepancia desaparece?

<details><summary>Respuesta 4</summary>

El desplazamiento de calibración pasa a cero y cambian las frecuencias absolutas. Las identidades escritas y la razón de octava permanecen iguales.

</details>

### Ejercicio 5

¿Qué refuta que un receptor conserve la calibración original?

<details><summary>Respuesta 5</summary>

Reconstruir las frecuencias de control desde la entrada principal con referencia refuta la conservación. Incluso una solicitud fiel exige medir la salida antes de validar el motor.

</details>

## Tarea con consulta de fuentes

Calcule las tablas a mano y siga el campo de referencia conservado. Proponga un registro que distinga identidad escrita, calibración y frecuencia prevista. Formule el criterio de refutación absoluto antes de que un agente recomiende afinación o transposición.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
