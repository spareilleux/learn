---
title: Hacer el balance de energía en una unión de impedancias
description: Hacer el balance de energía en una unión de impedancias — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-018 · Hacer el balance de energía en una unión de impedancias
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-018-account-for-energy-at-an-impedance-junction.es.md
---

:::note[Streeling University]
**GAS-018** · Hacer el balance de energía en una unión de impedancias · avanzado · 45 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-018-account-for-energy-at-an-impedance-junction.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-011](../../guitar-acoustics/gas-011-track-reflection-polarity-at-string-boundaries/)
:::

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Una revisión de un modelo de guitarra observa una amplitud transmitida mayor que la incidente y la interpreta como creación de energía. Esa conclusión olvida la impedancia asociada a la variable de onda. Una unión de presión deliberadamente sencilla permite distinguir razones de amplitud y fracciones de energía antes de aplicar este lenguaje a un puente. El balance añade una operación distinta al signo de desplazamiento del prerrequisito; las variables son diferentes.

La fuente deriva continuidad de presión y flujo con impedancias reales positivas. En nuestro caso construido, la razón de presión transmitida supera la unidad y la fracción de potencia permanece por debajo. Elevar la amplitud al cuadrado sin la razón de impedancias produciría un balance incorrecto. Las fracciones reflejada y transmitida reconstruyen la incidente bajo las condiciones ideales declaradas. Signos y direcciones siguen la convención de ondas viajeras.

El control adaptado cambia la relación de frontera y elimina la reflexión; no silencia la onda transmitida. Esta distinción importa antes de proponer amortiguar un retorno mediante un ajuste de transmisión. Un puente real tiene interacciones más complejas; aquí no hay curva medida ni parámetro de acoplamiento calibrado. Una tabla directa de presión y potencia ponderada debe preceder a cualquier DSL de uniones. No convierta este resultado en una regla de desplazamiento.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../guitar-acoustics/gas-011-track-reflection-polarity-at-string-boundaries/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lectura primaria](https://www.dsprelated.com/freebooks/pasp/Scattering_Impedance_Changes.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "incident_pressure": 1,
    "impedance_left": 1,
    "impedance_right": 3
  },
  "formula": "r=(Z2-Z1)/(Z1+Z2); t=1+r; reflected_fraction=r^2; transmitted_fraction=(Z1/Z2)*t^2; total=reflected_fraction+transmitted_fraction",
  "expected": {
    "pressure_reflection": 0.5,
    "pressure_transmission": 1.5,
    "reflected_fraction": 0.25,
    "transmitted_fraction": 0.75,
    "total": 1
  },
  "negative_control": {
    "values": {
      "incident_pressure": 1,
      "impedance_left": 1,
      "impedance_right": 1
    },
    "expected": {
      "pressure_reflection": 0,
      "pressure_transmission": 1,
      "reflected_fraction": 0,
      "transmitted_fraction": 1,
      "total": 1
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga incidencia plana normal, impedancias reales positivas y unión sin pérdidas ni estado almacenado. No llega onda desde la derecha. Estas razones de presión no sustituyen las de desplazamiento de cuerda.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Derive las razones de presión reflejada y transmitida.

<details><summary>Respuesta 1</summary>

La reflexión es la diferencia de impedancias dividida por su suma; añada la unidad para la transmisión de presión en esta convención.

</details>

### Ejercicio 2

¿Por qué una amplitud superior a la unidad no viola la energía?

<details><summary>Respuesta 2</summary>

La potencia transmitida también utiliza la razón de impedancias; la amplitud sola no es una fracción de potencia.

</details>

### Ejercicio 3

Compruebe el balance completo.

<details><summary>Respuesta 3</summary>

Las fracciones mostradas suman toda la fracción incidente para esta unión sin pérdidas.

</details>

### Ejercicio 4

¿Qué ocurre en el control adaptado?

<details><summary>Respuesta 4</summary>

Desaparece la reflexión mientras la presión y la potencia atraviesan la frontera adaptada.

</details>

### Ejercicio 5

¿Qué rechaza una interpretación directa del puente?

<details><summary>Respuesta 5</summary>

Sin identificar la variable ni medir un modelo de impedancia, este resultado de onda plana no permite una afirmación calibrada sobre el puente.

</details>

## Tarea con consulta de fuentes

Anote un diagrama GA propuesto con tipos de variables y balance ponderado. Mantenga la frontera adaptada como contracaso obligatorio.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
