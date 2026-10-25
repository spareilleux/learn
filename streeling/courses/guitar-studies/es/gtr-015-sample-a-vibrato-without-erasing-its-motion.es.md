---
module_id: gtr-015-sample-a-vibrato-without-erasing-its-motion
department: guitar-studies
course: "Muestrear un vibrato sin borrar su movimiento"
level: advanced
prerequisites: ["gtr-013-judge-a-bend-with-an-uncertainty-budget"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Muestrear un vibrato sin borrar su movimiento

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Una curva de altura aparentemente plana puede ocultar movimiento entre muestras. Para explicar una práctica de [GA](https://github.com/GuitarAlchemist/ga), distinga velocidad del vibrato, amplitud en cents y rejilla de observación antes de evaluar una nota sostenida. Construimos una trayectoria continua y examinamos instantes elegidos. Sus extremos y sus valores muestreados responden a preguntas distintas.

## Leer la evidencia conservada

La referencia de notación incluye atributos de reproducción de ornamentos para líneas onduladas. Esos campos no definen nuestra sinusoide en cents. El registro de entonación conservado aporta una convención de frecuencia, no una interpretación de vibrato.

[Prerrequisito](../../guitar-studies/en/gtr-013-judge-a-bend-with-an-uncertainty-budget.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/wavy-line/)

[Lectura principal](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "base_hz": 440,
    "extent_cents": 25,
    "rate_hz": 2,
    "times_s": [
      0,
      0.125,
      0.25,
      0.375,
      0.5
    ]
  },
  "formula": "c(t)=extent*sin(2*pi*rate*t); f(t)=base*2^(c(t)/1200)",
  "expected": {
    "cents": [
      0,
      25,
      0,
      -25,
      0
    ],
    "period_s": 0.5,
    "peak_to_peak_cents": 50
  },
  "negative_control": {
    "values": {
      "base_hz": 440,
      "extent_cents": 25,
      "rate_hz": 4,
      "times_s": [
        0,
        0.125,
        0.25,
        0.375,
        0.5
      ]
    },
    "expected": {
      "cents": [
        0,
        0,
        0,
        0,
        0
      ],
      "period_s": 0.25,
      "peak_to_peak_cents": 50
    }
  }
}
```

## Definir el gesto antes de evaluar su traza muestreada

La velocidad describe repeticiones por tiempo y la amplitud describe la desviación alrededor de la referencia. El intérprete puede cambiar ambas de forma independiente. La trayectoria es simétrica en cents: sus frecuencias extremas tienen razones recíprocas respecto a la portadora. Una curva simétrica en hercios describiría otro gesto. Nombre la coordenada antes de interpretar altura media o excursión máxima.

Los tiempos de muestreo observan la trayectoria, no la definen por completo. En particular, el control rápido no puede reconstruirse solo con sus muestras: una altura continua fija también encaja. Conocer el intervalo de muestreo no identifica la curva producida sin otra hipótesis de ancho de banda o modelo. Etiquetar el movimiento con seguridad excedería la evidencia suministrada.

Para una herramienta futura, conserve por separado estimaciones brutas con tiempo, incertidumbre y gesto previsto. Una línea suave entre puntos separados es una propuesta de interpolación, no una medida intermedia. El dibujo directo debe mostrar ese vacío antes de que un DSL añada una instrucción o un agente la puntúe. Una traza más densa podría comprobar el movimiento; el seguimiento real también tendría que separar cambio de altura, cambio de parcial dominante y error de octava.

### Ejercicio 1

Distinga amplitud y excursión de pico a pico en la trayectoria principal.

<details><summary>Respuesta 1</summary>

La amplitud en cents mide un solo lado de la oscilación. La excursión de pico a pico vale el doble, según los resultados; ninguna es una medida de una interpretación real.

</details>

### Ejercicio 2

Evalúe la trayectoria en los instantes declarados e identifique su periodo.

<details><summary>Respuesta 2</summary>

El vector indicado pasa por los extremos positivo y negativo. El periodo es el inverso de la velocidad y no depende de la frecuencia portadora.

</details>

### Ejercicio 3

¿Cómo se convierte la curva en cents en una curva de frecuencia?

<details><summary>Respuesta 3</summary>

Aplique la relación exponencial mostrada. Sumar una cantidad fija de hercios no preservaría una excursión simétrica en cents alrededor de la referencia.

</details>

### Ejercicio 4

Aplique el control más rápido. ¿Demuestra ausencia de vibrato su vector nulo?

<details><summary>Respuesta 4</summary>

No. La rejilla coincide con cruces por cero, aunque la amplitud continua sigue igual. El control refuta esa conclusión basada solo en estas muestras.

</details>

### Ejercicio 5

¿Qué refuta que esta rejilla identifique la amplitud del vibrato?

<details><summary>Respuesta 5</summary>

Distintas amplitudes o velocidades continuas compatibles con el mismo vector impiden la identificación. Conserve tiempos, fase supuesta y una observación independiente más densa antes de puntuar una interpretación.

</details>

## Tarea con consulta de fuentes

Dibuje las curvas continuas y marque los instantes de muestreo antes de usar calculadora. Explique el movimiento oculto del control y proponga un registro para una herramienta futura. Compare su dibujo manual con cualquier propuesta de notación o agente, sin afirmar que se analizó una grabación.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
