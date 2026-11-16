---
title: Comprobar restricciones de dirección al cambiar de cuerda
description: Comprobar restricciones de dirección al cambiar de cuerda — Estudios de guitarra
sidebar:
  label: GTR-018 · Comprobar restricciones de dirección al cambiar de cuerda
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/es/gtr-018-check-direction-constraints-at-string-crossings.es.md
---

:::note[Streeling University]
**GTR-018** · Comprobar restricciones de dirección al cambiar de cuerda · avanzado · 45 minutos

Generado por el departamento *Estudios de guitarra* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/es/gtr-018-check-direction-constraints-at-string-crossings.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GTR-007](../../guitar-studies/gtr-007-carry-picking-phase-across-bar-lines/)
:::

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Un asistente puede mantener correctamente las etiquetas de golpes sin indicar qué cuerda debe alcanzar la púa. Una secuencia válida como reloj simbólico puede incumplir una política de barrido continuo. Comprobamos el sentido entre cuerdas consecutivas. La geometría amplía así el seguimiento de fase sobre una sola cuerda del prerrequisito, sin decidir la comodidad real.

Declare primero la orientación de los números. Según esta política, los golpes descendentes repetidos entre cuerdas diferentes continúan hacia números menores. Los ascendentes exigen el sentido contrario. Cambiar de golpe o repetir una cuerda queda fuera de esta exclusión concreta; no demuestra facilidad. La regla prohíbe un reposicionamiento aéreo no registrado. Un guitarrista puede elegir otra política, pero deberá cambiar explícitamente el modelo y la evidencia necesaria.

La frase principal invierte el desplazamiento manteniendo el mismo golpe: una transición pasa y otra falla. El control monótono elimina esa inversión conservando los golpes. Separa así geometría y aritmética de fase. Mantenga el testigo de la transición, en lugar de un simple recuento de golpes descendentes. El material conservado motiva un registro de instrucciones, pero no hubo interpretación ni salida de un solucionador GA. Un diagrama manual de flechas basta antes de proponer una abstracción de trayectorias.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../guitar-studies/gtr-007-carry-picking-phase-across-bar-lines/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "strings": [
      3,
      2,
      3
    ],
    "strokes": [
      "D",
      "D",
      "D"
    ]
  },
  "formula": "for equal consecutive strokes on different strings: legal iff (D and next_string<previous_string) or (U and next_string>previous_string); otherwise legal; plan_legal=all(transition_legal)",
  "expected": {
    "transition_legal": [
      true,
      false
    ],
    "plan_legal": false
  },
  "negative_control": {
    "values": {
      "strings": [
        3,
        2,
        1
      ],
      "strokes": [
        "D",
        "D",
        "D"
      ]
    },
    "expected": {
      "transition_legal": [
        true,
        true
      ],
      "plan_legal": true
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga la numeración declarada y barridos continuos para golpes sucesivos iguales entre cuerdas, sin reposicionamiento aéreo. Es una política restringida, no una ley biomecánica ni un juicio de comodidad.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Identifique el sentido del primer cambio de cuerda.

<details><summary>Respuesta 1</summary>

Va hacia un número menor y respeta el barrido descendente repetido declarado.

</details>

### Ejercicio 2

¿Por qué falla la segunda transición?

<details><summary>Respuesta 2</summary>

Invierte el desplazamiento manteniendo el golpe descendente, algo excluido por el barrido continuo.

</details>

### Ejercicio 3

¿Podría otra política permitir un reposicionamiento aéreo?

<details><summary>Respuesta 3</summary>

Sí, pero añadiría una acción y un requisito temporal ausentes de las etiquetas actuales.

</details>

### Ejercicio 4

¿Por qué pasa el control monótono?

<details><summary>Respuesta 4</summary>

Todos los cambios con el mismo golpe siguen el sentido numérico permitido por la regla.

</details>

### Ejercicio 5

¿Qué refuta una conclusión universal sobre técnica?

<details><summary>Respuesta 5</summary>

La tabla supone una política restringida y no contiene observaciones de intérpretes; no demuestra imposibilidad general ni comodidad.

</details>

## Tarea con consulta de fuentes

Dibuje cada desplazamiento de la púa y anote la política de movimiento. Conserve la transición fallida como testigo.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
