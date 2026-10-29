---
title: Declarar la coordenada de un deslizamiento continuo
description: Declarar la coordenada de un deslizamiento continuo — Estudios de guitarra
sidebar:
  label: GTR-019 · Declarar la coordenada de un deslizamiento continuo
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/es/gtr-019-declare-the-coordinate-of-a-continuous-slide.es.md
---

:::note[Streeling University]
**GTR-019** · Declarar la coordenada de un deslizamiento continuo · avanzado · 45 minutos

Generado por el departamento *Estudios de guitarra* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/es/gtr-019-declare-the-coordinate-of-a-continuous-slide.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GTR-014](../../guitar-studies/gtr-014-count-legato-notes-separately-from-pick-attacks/)
:::

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Una transferencia de frase GA conserva los extremos de un deslizamiento y supone que la trayectoria queda determinada. Sin embargo, importa la coordenada interpolada. Comparamos un cambio uniforme de longitud vibrante con otro uniforme de frecuencia logarítmica. Los extremos y la duración coinciden, pero cambia la altura intermedia. La operación amplía el registro de articulaciones hacia una trayectoria continua sin crear un motor de deslizamientos.

En una cuerda ideal flexible con velocidad de onda constante, la frecuencia es inversamente proporcional a la longitud vibrante. Una recta en longitud produce una curva en frecuencia. La altura logarítmica uniforme utiliza interpolación geométrica. Ningún recorrido es el comportamiento universal de un deslizamiento; una guitarra con trastes puede introducir transiciones de contacto excluidas aquí.

La fuente de notación describe el deslizamiento como continuo y ofrece atributos de discretización. No selecciona nuestra coordenada física ni certifica que un analizador la conserve. La muestra interior distingue las políticas; los extremos solos no. Un agente que solo los guarda necesita otra convención de trayectoria. Mantenga unidades, coordenada e hipótesis de contacto en el registro. Una tabla directa comprueba la fidelidad de una abstracción. Movimiento real, contacto, seguimiento de altura y juicio del músico necesitan observaciones adicionales.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../guitar-studies/gtr-014-count-legato-notes-separately-from-pick-attacks/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/slide/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "start_length": 1,
    "end_length": 0.5,
    "start_frequency_hz": 100,
    "duration_s": 1,
    "times_s": [
      0,
      0.5,
      1
    ],
    "policy": "linear_length"
  },
  "formula": "u=t/duration; linear_length: L=(1-u)*L0+u*L1; f=f0*L0/L; linear_log_frequency: f=f0*(L0/L1)^u; L=f0*L0/f",
  "expected": {
    "length": [
      1,
      0.75,
      0.5
    ],
    "frequency_hz": [
      100,
      133.33333333333334,
      200
    ]
  },
  "negative_control": {
    "values": {
      "start_length": 1,
      "end_length": 0.5,
      "start_frequency_hz": 100,
      "duration_s": 1,
      "times_s": [
        0,
        0.5,
        1
      ],
      "policy": "linear_log_frequency"
    },
    "expected": {
      "length": [
        1,
        0.7071067811865475,
        0.5
      ],
      "frequency_hz": [
        100,
        141.4213562373095,
        200
      ]
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga velocidad de onda constante y longitud ideal continuamente variable. No hay interrupciones por trastes. Son trayectorias construidas; ninguna predice un deslizamiento ordinario con trastes ni un movimiento medido.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Derive la longitud interior para el movimiento lineal.

<details><summary>Respuesta 1</summary>

Es la interpolación aritmética entre las longitudes extremas, indicada en el caso fijo.

</details>

### Ejercicio 2

Convierta esa longitud en frecuencia con velocidad de onda constante.

<details><summary>Respuesta 2</summary>

Use la relación inversa; el punto medio aritmético de longitudes no es el de frecuencias.

</details>

### Ejercicio 3

¿Cómo interpola la altura el control?

<details><summary>Respuesta 3</summary>

Interpola la frecuencia logarítmica y produce un punto medio geométrico con otra longitud vibrante.

</details>

### Ejercicio 4

¿Prueban unos extremos comunes el mismo deslizamiento?

<details><summary>Respuesta 4</summary>

No. Los valores interiores difieren pese a compartir extremos y duración.

</details>

### Ejercicio 5

¿Qué refuta la fidelidad basada solo en extremos?

<details><summary>Respuesta 5</summary>

Un receptor que no distingue estas trayectorias interiores no puede recuperar el recorrido solicitado.

</details>

## Tarea con consulta de fuentes

Dibuje ambos recorridos antes de leer las respuestas. Redacte una nota GA que nombre la coordenada y excluya predecir el contacto ordinario con trastes.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
