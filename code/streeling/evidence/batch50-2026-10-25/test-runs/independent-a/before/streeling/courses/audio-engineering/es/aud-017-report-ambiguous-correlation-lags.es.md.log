---
module_id: aud-017-report-ambiguous-correlation-lags
department: audio-engineering
course: "Informar de retardos de correlación ambiguos"
level: advanced
prerequisites: ["aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Informar de retardos de correlación ambiguos

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Un algoritmo puede devolver un desplazamiento preciso en muestras aunque varias respuestas optimicen por igual su criterio. Los sonidos periódicos de guitarra permiten mostrar ese riesgo. Antes de compensar una comparación de [GA](https://github.com/GuitarAlchemist/ga), distinga el criterio con signo de su magnitud y conserve los empates. El retardo elegido depende de una convención; no es una marca temporal de la fuente.

## Leer la evidencia conservada

La referencia oficial define una correlación lineal con extensión por ceros. Por eso escribimos aparte nuestra suma circular. El script conservado compara valores sin estimar retardos; el cálculo propuesto añade una operación de revisión distinta.

[Prerrequisito](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/run.mjs)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.correlate.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "x": [
      1,
      0,
      -1,
      0
    ],
    "y": [
      0,
      1,
      0,
      -1
    ],
    "lags": [
      0,
      1,
      2,
      3
    ]
  },
  "formula": "C(k)=sum_n x[n]*y[(n+k)%N]; signed_argmax=argmax(C); absolute_argmax=argmax(abs(C))",
  "expected": {
    "correlation": [
      0,
      2,
      0,
      -2
    ],
    "signed_argmax": [
      1
    ],
    "absolute_argmax": [
      1,
      3
    ]
  },
  "negative_control": {
    "values": {
      "x": [
        1,
        0,
        0,
        0
      ],
      "y": [
        0,
        1,
        0,
        0
      ],
      "lags": [
        0,
        1,
        2,
        3
      ]
    },
    "expected": {
      "correlation": [
        0,
        1,
        0,
        0
      ],
      "signed_argmax": [
        1
      ],
      "absolute_argmax": [
        1
      ]
    }
  }
}
```

## Separar la elección del estimador de la evidencia de unicidad

La correlación circular considera contiguas la última muestra y la primera. Conviene a esta construcción periódica, pero puede crear una falsa coincidencia en el corte de una grabación normal. La correlación lineal elige otros límites. El nombre de una función no basta para deducir la convención. Conserve la ecuación e indique si el registro se hizo periódico o se recortó de una toma más larga.

Maximizar la magnitud también concede igual valor a una inversión de polaridad. Puede ser apropiado si la polaridad es una perturbación declarada, pero cambia la pregunta de una comparación que exige muestras intactas. Un pico negativo no se convierte en evidencia positiva solo por su gran magnitud. El registro debe separar el criterio para elegir el desplazamiento de las transformaciones aplicadas después.

Una regla de desempate permite salidas reproducibles sin establecer identificabilidad. Elegir el primer retardo siempre devuelve una respuesta aunque los datos no permitan decidir. El vector manual es la referencia mínima y expone todos los candidatos. Antes de automatizar con tomas reales, declare rango, límites, criterio y desempate. Un disparo registrado o una señal independiente del ataque podría aportar la evidencia temporal ausente; el registro periódico solo no puede hacerlo.

### Ejercicio 1

Evalúe la suma circular para cada retardo declarado. ¿Por qué forma parte de la respuesta la convención?

<details><summary>Respuesta 1</summary>

El vector de correlación aparece abajo. Envolver los índices difiere de extender con ceros; invertir el signo del retardo también cambiaría su interpretación.

</details>

### Ejercicio 2

Encuentre todos los máximos del criterio con signo. ¿Qué información conserva el signo?

<details><summary>Respuesta 2</summary>

El máximo con signo selecciona la coincidencia positiva. Distingue esa coincidencia de una forma de onda con polaridad invertida dentro del producto declarado.

</details>

### Ejercicio 3

Maximice ahora la magnitud. ¿Puede anunciarse un retardo identificado de forma única?

<details><summary>Respuesta 3</summary>

El criterio absoluto tiene la pareja de máximos indicada. Devolver siempre el primero hace determinista la elección, pero no elimina la ambigüedad de los datos.

</details>

### Ejercicio 4

Aplique el control impulsional. ¿Qué aporta al diagnóstico?

<details><summary>Respuesta 4</summary>

Ambos criterios tienen el mismo máximo único. Un método que siga encontrando empate trata mal este control; esa unicidad no se generaliza a la entrada periódica.

</details>

### Ejercicio 5

¿Qué refutaría un registro que afirmase tener un máximo absoluto único?

<details><summary>Respuesta 5</summary>

Otro retardo con el mismo valor del criterio refuta la unicidad. Conserve el criterio completo, el rango permitido y la política de polaridad antes de compensar.

</details>

## Tarea con consulta de fuentes

Calcule los vectores a mano y prepare un registro de retardo para una comparación propuesta de GA. Conserve los empates y explique si se permite invertir la polaridad. Compárelo con una comparación directa sin alineación; deje sin resolver la latencia real y la fidelidad del audio.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
