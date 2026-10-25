---
title: Acotar las repeticiones de un retardo con realimentación
description: Acotar las repeticiones de un retardo con realimentación — Ingeniería de audio
sidebar:
  label: AUD-021 · Acotar las repeticiones de un retardo con realimentación
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/es/aud-021-bound-feedback-delay-repeats.es.md
---

:::note[Streeling University]
**AUD-021** · Acotar las repeticiones de un retardo con realimentación · avanzado · 45 minutos

Generado por el departamento *Ingeniería de audio* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/es/aud-021-bound-feedback-delay-repeats.es.md) · [Mi diario](../../journal/)

Requisitos previos: [AUD-007](../../audio-engineering/aud-007-translate-attack-coefficients-into-time/)
:::

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Una propuesta de audio reutiliza un coeficiente de decaimiento dentro de un retardo con realimentación y lo considera seguro porque la salida inicial es pequeña. El coeficiente actúa ahora en cada vuelta del retardo, no necesariamente en cada muestra. Derive a mano la respuesta a un impulso antes de comparar duraciones o afirmar estabilidad. El script de guitarra motiva conservar el estado, pero no ejecuta esta nueva recurrencia aislada.

Solo los múltiplos sucesivos del retardo contienen los ecos del impulso. Sus amplitudes forman una progresión geométrica. El retardo fija la separación y la ganancia la razón; cambiar cada uno produce efectos distintos. La lista finita muestra los primeros retornos. La fórmula de suma absoluta describe toda la cola infinita bajo las hipótesis declaradas y exige una cota estricta de ganancia.

El control creciente puede superar temporalmente una comprobación de rango si se reduce la entrada. Eso no hace sumable su respuesta infinita. A la inversa, un sistema estable puede superar el rango de exportación para ciertas entradas. Separe estabilidad matemática, recorte y decaimiento musical. Inicialización, unidades del reloj y tratamiento numérico siguen pendientes en una implementación. Mantenga la convención de signos al consultar la fuente, que también presenta otra notación del denominador.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../audio-engineering/aud-007-translate-attack-coefficients-into-time/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lectura primaria](https://www.dsprelated.com/freebooks/pasp/Feedback_Comb_Filters.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "delay_samples": 2,
    "gain": 0.5,
    "count": 7,
    "impulse": [
      1,
      0,
      0,
      0,
      0,
      0,
      0
    ]
  },
  "formula": "y[n]=x[n]+g*y[n-M]; y[n<0]=0; stable=abs(g)<1; absolute_sum_infinite=1/(1-abs(g)) if stable else null",
  "expected": {
    "output": [
      1,
      0,
      0.5,
      0,
      0.25,
      0,
      0.125
    ],
    "stable": true,
    "absolute_sum_infinite": 2
  },
  "negative_control": {
    "values": {
      "delay_samples": 2,
      "gain": 1.1,
      "count": 7,
      "impulse": [
        1,
        0,
        0,
        0,
        0,
        0,
        0
      ]
    },
    "expected": {
      "output": [
        1,
        0,
        1.1,
        0,
        1.21,
        0,
        1.331
      ],
      "stable": false,
      "absolute_sum_infinite": null
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga estado inicial nulo, retardo entero positivo y ganancia real constante. Ningún limitador modifica la recurrencia. La cola infinita matemática difiere de la robustez numérica y del rango de exportación.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Siga los primeros retornos y las muestras intermedias.

<details><summary>Respuesta 1</summary>

Los retornos no nulos están separados por el retardo declarado; las muestras intermedias siguen siendo nulas con este estado inicial.

</details>

### Ejercicio 2

¿Qué entrada fija la separación y cuál la razón de amplitudes?

<details><summary>Respuesta 2</summary>

El retardo controla la separación. La ganancia constante controla la razón entre retornos sucesivos.

</details>

### Ejercicio 3

¿Por qué es absolutamente sumable el caso estable?

<details><summary>Respuesta 3</summary>

La magnitud de la ganancia es estrictamente menor que la unidad; las amplitudes tienen la suma geométrica convergente mostrada.

</details>

### Ejercicio 4

¿Certifica una salida breve el control creciente?

<details><summary>Respuesta 4</summary>

No. Su prefijo es finito, pero los retornos crecen y la suma absoluta infinita no converge.

</details>

### Ejercicio 5

¿Qué refuta la recurrencia anunciada como estable?

<details><summary>Respuesta 5</summary>

Una ganancia fuera de la cota estricta, o una traza incompatible con la recurrencia, rechaza la afirmación dentro del modelo.

</details>

## Tarea con consulta de fuentes

Prepare la tabla del impulso y separe la cota de la cola de un futuro control PCM. Este caso construido por sí solo no justifica cambiar el motor.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
