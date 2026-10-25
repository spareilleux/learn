---
title: Declarar equivalencia bajo un período distinto de la octava
description: Declarar equivalencia bajo un período distinto de la octava — Músicas y lenguas del mundo
sidebar:
  label: WML-017 · Declarar equivalencia bajo un período distinto de la octava
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-017-declare-equivalence-under-a-non-octave-period.es.md
---

:::note[Streeling University]
**WML-017** · Declarar equivalencia bajo un período distinto de la octava · avanzado · 45 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-017-declare-equivalence-under-a-non-octave-period.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-014](../../world-music-languages/wml-014-quantize-a-ratio-on-a-declared-octave-division/)
:::

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Una transferencia supone que toda repetición es una octava y reduce las frecuencias de ese modo. Es una elección de representación, no una consecuencia de un campo genérico de período. Comparamos equivalencia exacta bajo un período construido con equivalencia de octava. Cambia la relación de agrupación, mientras el prerrequisito mantenía la octava y modificaba su subdivisión.

Normalice cada razón positiva en el intervalo semiabierto desde la unidad hasta el período excluido. Guarde por separado el número entero de períodos retirados como coordenada de registro. Las razones normalizadas iguales solo son equivalentes bajo ese período. La frontera evita duplicar el extremo superior de un registro y el inferior del siguiente. Las fracciones exactas permiten comprobar identidades sin tolerancia en cents.

El control usa las mismas razones con otro período. Desaparecen algunas equivalencias y aparece otra pareja. Un registro limitado a clases de octava no reconstruye ambas reglas sin conservar la identidad del período. Es un ejercicio matemático sin atribución a una tradición. El registro conservado ya distingue razones exactas y proyección entera. Añada período y cuenta de registro antes de proponer un DSL. No se ejecutó audio, juicio de escucha ni conversión de catálogo; la normalización manual solo produce las clases declaradas.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../world-music-languages/wml-014-quantize-a-ratio-on-a-declared-octave-division/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "ratios": [
      "1",
      "3",
      "9",
      "2"
    ],
    "period_ratio": "3"
  },
  "formula": "choose integer k with 1<=r/P^k<P; canonical=r/P^k; equivalence groups share exact canonical ratio; retain k separately",
  "expected": {
    "period_counts": [
      0,
      1,
      2,
      0
    ],
    "canonical_ratios": [
      "1",
      "1",
      "1",
      "2"
    ],
    "equivalence_groups": [
      [
        0,
        1,
        2
      ],
      [
        3
      ]
    ]
  },
  "negative_control": {
    "values": {
      "ratios": [
        "1",
        "3",
        "9",
        "2"
      ],
      "period_ratio": "2"
    },
    "expected": {
      "period_counts": [
        0,
        1,
        3,
        1
      ],
      "canonical_ratios": [
        "1",
        "3/2",
        "9/8",
        "1"
      ],
      "equivalence_groups": [
        [
          0,
          3
        ],
        [
          1
        ],
        [
          2
        ]
      ]
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga razones racionales positivas exactas y período racional superior a la unidad. Use el intervalo canónico semiabierto. La equivalencia es una relación elegida, no identidad cultural ni prueba perceptiva.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Normalice las razones y conserve sus cuentas de períodos.

<details><summary>Respuesta 1</summary>

Divida exactamente por el período; los valores mostrados quedan en su intervalo fundamental semiabierto.

</details>

### Ejercicio 2

¿Qué razones pertenecen al mismo grupo principal?

<details><summary>Respuesta 2</summary>

Las que comparten razón canónica exacta, aunque difieran sus cuentas de períodos.

</details>

### Ejercicio 3

¿Por qué guardar la cuenta de períodos?

<details><summary>Respuesta 3</summary>

Distingue registros identificados por la normalización y permite reconstruir la razón original.

</details>

### Ejercicio 4

¿Qué cambia con el control de período de octava?

<details><summary>Respuesta 4</summary>

Cambian razones canónicas y grupos porque cambia la propia relación.

</details>

### Ejercicio 5

¿Qué refuta una transferencia sin período?

<details><summary>Respuesta 5</summary>

Un registro incapaz de distinguir estas relaciones no conserva la semántica de período solicitada.

</details>

## Tarea con consulta de fuentes

Construya ambas tablas a mano. Proponga una transferencia GA con período exacto, razón canónica y registro sin atribuir una tradición.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
