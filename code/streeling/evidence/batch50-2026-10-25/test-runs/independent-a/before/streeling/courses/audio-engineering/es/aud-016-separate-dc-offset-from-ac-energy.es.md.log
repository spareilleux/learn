---
module_id: aud-016-separate-dc-offset-from-ac-energy
department: audio-engineering
course: "Separar el desplazamiento continuo de la energía alterna"
level: advanced
prerequisites: ["aud-005-pcm-guards-and-format-boundaries"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separar el desplazamiento continuo de la energía alterna

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Un búfer de guitarra puede respetar los límites de cada muestra y aun así tener un desplazamiento continuo. Al igualar el valor eficaz total, dos componentes alternas idénticas podrían parecer de distinto nivel. Esta lección descompone un registro finito antes de elegir la ganancia. Así permite revisar el script de [GA](https://github.com/GuitarAlchemist/ga) conservado, cuyo cálculo eficaz eleva las muestras al cuadrado sin restar su media.

## Leer la evidencia conservada

Lea el control de muestras y la acumulación del valor eficaz. Establecen el cálculo de esa revisión, pero no garantizan media nula en todo búfer futuro. La secuencia siguiente es un ejemplo creado para la lección; no procede de un nuevo renderizado.

[Prerrequisito](../../audio-engineering/en/aud-005-pcm-guards-and-format-boundaries.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/run.mjs)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "samples": [
      0,
      1,
      0,
      1
    ]
  },
  "formula": "mean=sum(x)/N; ac_i=x_i-mean; total_ms=sum(x_i^2)/N; ac_ms=sum(ac_i^2)/N; total_ms=mean^2+ac_ms",
  "expected": {
    "mean": 0.5,
    "ac_samples": [
      -0.5,
      0.5,
      -0.5,
      0.5
    ],
    "total_ms": 0.5,
    "ac_ms": 0.25,
    "total_rms": 0.7071067811865476,
    "ac_rms": 0.5
  },
  "negative_control": {
    "values": {
      "samples": [
        -0.5,
        0.5,
        -0.5,
        0.5
      ]
    },
    "expected": {
      "mean": 0,
      "ac_samples": [
        -0.5,
        0.5,
        -0.5,
        0.5
      ],
      "total_ms": 0.25,
      "ac_ms": 0.25,
      "total_rms": 0.5,
      "ac_rms": 0.5
    }
  }
}
```

## Elegir la magnitud antes de modificar la señal

La media depende del registro elegido. Incluso una señal alterna puede tener media finita no nula si la ventana corta sus ciclos de forma desigual. Atribuirlo a un defecto físico requeriría evidencia adicional. Aquí es simplemente la coordenada constante de las muestras conservadas. Centrar describe esas muestras; registre la transformación y conserve también la entrada intacta.

La descomposición se obtiene escribiendo cada muestra como su media más el resto centrado. Como ese resto tiene media nula, el término cruzado desaparece al promediar. Por eso la identidad corresponde a magnitudes cuadráticas. También explica que una resta muestra a muestra reduzca la energía calculada aunque la forma alterna permanezca igual. Una ganancia elegida después a partir del valor eficaz total original modificaría esa forma alterna.

Para revisar la fuente, prepare una tabla con muestra original, media, valor centrado y contribuciones cuadráticas. Ese cálculo directo basta para cuestionar un informe de nivel engañoso. Un nuevo nodo de análisis o un agente solo ayuda si conserva con igual claridad los límites y el historial de transformaciones. Antes de procesar audio real, decida si el experimento trata el búfer original, su componente centrada o la salida de un filtro definido: son artefactos distintos.

### Ejercicio 1

Calcule la media y la secuencia centrada. ¿Por qué conservar los límites del registro?

<details><summary>Respuesta 1</summary>

La media y la secuencia alterna del caso principal aparecen abajo. Cambiar los límites cambia la media; ni el nombre del archivo ni un control de picos aportan ese cálculo.

</details>

### Ejercicio 2

Descomponga la media cuadrática. ¿Se deben restar amplitudes eficaces?

<details><summary>Respuesta 2</summary>

Aplique la identidad mostrada a las medias cuadráticas. El término cruzado desaparece porque la secuencia centrada suma cero. Restar amplitudes eficaces daría otro resultado.

</details>

### Ejercicio 3

Compare el valor eficaz total y el alterno del caso principal. ¿Cuál describe la componente centrada?

<details><summary>Respuesta 3</summary>

El valor eficaz alterno describe la componente centrada. El total también incluye la contribución constante; su igualdad no garantiza la misma energía alterna.

</details>

### Ejercicio 4

Aplique el control. ¿Qué componente cambia y qué comparación se conserva?

<details><summary>Respuesta 4</summary>

La media pasa a cero, mientras que las muestras centradas y su valor eficaz permanecen iguales. Un informe que les atribuya una diferencia alterna confunde las magnitudes.

</details>

### Ejercicio 5

¿Restar esa media valida la cadena en tiempo continuo o el resultado de escucha?

<details><summary>Respuesta 5</summary>

No. Centrar un registro puede cambiar sus extremos y no establece la respuesta transitoria de un filtro. La implementación continua y el juicio de escucha requieren observaciones propias.

</details>

## Tarea con consulta de fuentes

Redacte una nota de comparación para el script. Calcule ambas descomposiciones a mano y localice la acumulación en la fuente. Indique si la ganancia propuesta busca igualar el valor total o el alterno. Rechace un informe que cambie el denominador o centre solo una entrada sin declararlo.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
