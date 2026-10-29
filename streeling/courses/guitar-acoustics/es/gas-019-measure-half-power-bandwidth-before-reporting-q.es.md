---
module_id: gas-019-measure-half-power-bandwidth-before-reporting-q
department: guitar-acoustics
course: "Medir el ancho de media potencia antes de informar Q"
level: advanced
prerequisites: ["gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Medir el ancho de media potencia antes de informar Q

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Una explicación del filtro de cuerpo GA informa de un centro de resonancia y califica la respuesta de estrecha sin dar su anchura. El centro por sí solo no describe la selectividad. Introducimos una curva de potencia normalizada y calculamos dónde cae hasta la mitad del máximo. Es una operación de anchura, distinta de localizar un polo o un pico.

La curva construida permite resolver directamente los cruces. Los puntos incluyen el centro y ambos bordes exactos de media potencia; no hay interpolación oculta. Si una medición no incluyera esos cruces, habría que declarar un estimador y la resolución frecuencial. Un gráfico escaso no genera precisión ausente en los datos.

El control conserva el centro y el máximo mientras ensancha la respuesta. Los valores normalizados coinciden en frecuencias con separaciones distintas: los ejes forman parte de la matriz. El cociente de anchura cambia aunque un resumen del pico no detectaría cambios. Media amplitud es un umbral distinto de media potencia y seleccionaría otros bordes. Aquí Q es el cociente declarado entre centro y ancho de banda. Relacionarlo con decaimiento, pérdidas materiales o radio de polo del motor exigiría un modelo compatible. El curso conservado proporciona una frontera concreta, no esas equivalencias ausentes.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/run.mjs)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "center_hz": 100,
    "halfwidth_hz": 5,
    "frequencies_hz": [
      90,
      95,
      100,
      105,
      110
    ]
  },
  "formula": "P(f)=1/(1+((f-f0)/b)^2); half_power_edges=[f0-b,f0+b]; bandwidth=2*b; Q=f0/bandwidth",
  "expected": {
    "relative_power": [
      0.2,
      0.5,
      1,
      0.5,
      0.2
    ],
    "half_power_edges_hz": [
      95,
      105
    ],
    "bandwidth_hz": 10,
    "Q": 10
  },
  "negative_control": {
    "values": {
      "center_hz": 100,
      "halfwidth_hz": 10,
      "frequencies_hz": [
        80,
        90,
        100,
        110,
        120
      ]
    },
    "expected": {
      "relative_power": [
        0.2,
        0.5,
        1,
        0.5,
        0.2
      ],
      "half_power_edges_hz": [
        90,
        110
      ],
      "bandwidth_hz": 20,
      "Q": 5
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga una curva construida de potencia aislada, semianchura positiva y cruces continuos exactos. Su Q se define por el cociente mostrado. No se implica ajuste físico ni conversión de radio de polo.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Localice los bordes exactos de media potencia.

<details><summary>Respuesta 1</summary>

Iguale la potencia a la mitad del máximo; los bordes quedan a una semianchura de cada lado del centro.

</details>

### Ejercicio 2

Calcule la anchura completa y el cociente Q.

<details><summary>Respuesta 2</summary>

Reste los bordes y divida el centro por esa anchura completa, como muestra el caso fijo.

</details>

### Ejercicio 3

¿Por qué indicar potencia en lugar de amplitud?

<details><summary>Respuesta 3</summary>

El umbral de media amplitud seleccionaría otras frecuencias y otra anchura.

</details>

### Ejercicio 4

¿Qué conserva y cambia el control más ancho?

<details><summary>Respuesta 4</summary>

Conserva centro y máximo, duplica la anchura y reduce a la mitad el cociente Q.

</details>

### Ejercicio 5

¿Qué refuta una selectividad deducida solo del pico?

<details><summary>Respuesta 5</summary>

El par con centros iguales y anchuras distintas demuestra que el centro solo no determina este Q.

</details>

## Tarea con consulta de fuentes

Prepare un informe propuesto con ejes, tipo de umbral y regla de cruce. Deje sin resolver la conversión a coeficientes GA.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
