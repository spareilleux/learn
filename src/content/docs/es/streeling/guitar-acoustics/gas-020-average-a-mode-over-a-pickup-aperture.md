---
title: Promediar un modo sobre la apertura de un captador
description: Promediar un modo sobre la apertura de un captador — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-020 · Promediar un modo sobre la apertura de un captador
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-020-average-a-mode-over-a-pickup-aperture.es.md
---

:::note[Streeling University]
**GAS-020** · Promediar un modo sobre la apertura de un captador · avanzado · 45 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-020-average-a-mode-over-a-pickup-aperture.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-015](../../guitar-acoustics/gas-015-separate-mode-excitation-from-observation/)
:::

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Un control de captador propuesto mueve un observador puntual sin declarar su anchura sensible. Un modelo puede combinar desplazamientos de una región; diferentes partes del modo se cancelan aunque el centro no sea un nodo. Estudiamos una media espacial uniforme construida. El prerrequisito ya separa excitación y observación puntual. La operación nueva integra la observación sin cambiar el pulsado.

Integre cada seno sobre la apertura centrada y divida por la anchura. Esta normalización conservaría la amplitud de un campo espacial constante al ampliar la apertura. El resultado es el valor central multiplicado por un factor sinc dependiente de la anchura. Importan los signos: la cancelación ocurre antes de tomar el módulo. Promediar módulos borraría la cancelación estudiada.

En el caso fijo, los modos impares considerados tienen valores centrales no nulos y atenuaciones distintas. Los pares ya se anulan en el centro y siguen ausentes con este núcleo simétrico. Eso no significa que la anchura sea irrelevante: depende del centro, los modos y la simetría. El control puntual recupera los valores centrales sin cambiar la excitación. Conserve núcleo y normalización en cualquier propuesta GA. Un captador real tiene otra física; la integral plantea una pregunta de calibración sin medir ni implementar su respuesta.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../guitar-acoustics/gas-015-separate-mode-excitation-from-observation/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "center_fraction": 0.5,
    "width_fraction": 0.5,
    "modes": [
      1,
      2,
      3,
      4
    ]
  },
  "formula": "point_n=sin(n*pi*c); aperture_n=point_n*sin(n*pi*w/2)/(n*pi*w/2); aperture_n=point_n when w=0",
  "expected": {
    "point": [
      1,
      0,
      -1,
      0
    ],
    "aperture": [
      0.9003163161571061,
      0,
      -0.3001054387190354,
      0
    ]
  },
  "negative_control": {
    "values": {
      "center_fraction": 0.5,
      "width_fraction": 0,
      "modes": [
        1,
        2,
        3,
        4
      ]
    },
    "expected": {
      "point": [
        1,
        0,
        -1,
        0
      ],
      "aperture": [
        1,
        0,
        -1,
        0
      ]
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga modos sinusoidales y apertura uniforme normalizada enteramente dentro de la cuerda. Conserve medias con signo. Detección electromagnética, respuesta de velocidad y calibración real necesitan otro modelo y observaciones.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Calcule los valores puntuales con signo en el centro.

<details><summary>Respuesta 1</summary>

Los senos alternan entre vientres y nodos; conserve los signos además de los módulos.

</details>

### Ejercicio 2

¿Por qué dividir la integral por la anchura?

<details><summary>Respuesta 2</summary>

El modelo es una media. Sin división, cambiar la anchura también cambiaría la normalización.

</details>

### Ejercicio 3

¿Qué modo no nulo queda más atenuado?

<details><summary>Respuesta 3</summary>

El modo impar más alto pierde una fracción mayor de su amplitud puntual por cancelación espacial.

</details>

### Ejercicio 4

¿Qué recupera el control de anchura nula?

<details><summary>Respuesta 4</summary>

El límite declarado recupera cada valor puntual manteniendo la excitación y el centro.

</details>

### Ejercicio 5

¿Qué refuta una fidelidad deducida solo del punto?

<details><summary>Respuesta 5</summary>

Centros iguales con valores promediados distintos demuestran que el centro solo no especifica esta observación.

</details>

## Tarea con consulta de fuentes

Derive la integral a mano y redacte una revisión que conserve la anchura. Mantenga abiertas las cuestiones electromagnéticas y las mediciones.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
