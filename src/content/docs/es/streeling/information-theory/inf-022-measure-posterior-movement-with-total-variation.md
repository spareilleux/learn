---
title: Medir el cambio posterior con variación total
description: Medir el cambio posterior con variación total — Teoría de la información
sidebar:
  label: INF-022 · Medir el cambio posterior con variación total
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/es/inf-022-measure-posterior-movement-with-total-variation.es.md
---

:::note[Streeling University]
**INF-022** · Medir el cambio posterior con variación total · intermedio · 45 minutos

Generado por el departamento *Teoría de la información* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/es/inf-022-measure-posterior-movement-with-total-variation.es.md) · [Mi diario](../../journal/)

Requisitos previos: [INF-013](../../information-theory/inf-013-value-an-evidence-probe-by-expected-information/), [INF-003](../../information-theory/inf-003-verdict-distribution-drift/)
:::

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un informe agéntico anuncia que una observación modificó una creencia. ¿Cuánto cambió realmente la distribución declarada? Una explicación más larga puede no moverla si las hipótesis predicen igualmente la observación. Esta lección combina una actualización bayesiana finita con una distancia acotada entre distribuciones.

Multiplique cada masa previa por la verosimilitud de la observación bajo esa hipótesis. Sume los productos para obtener la probabilidad marginal y normalice. Las verosimilitudes no deben sumar la unidad entre hipótesis: pertenecen a experimentos condicionales distintos. Un normalizador nulo haría imposible la observación bajo el modelo; no debe ocultarse inventando una distribución posterior.

La variación total es la mitad de la suma de diferencias absolutas entre coordenadas. Mide el mayor cambio de probabilidad de un evento en este espacio finito. El caso informativo desplaza masa hacia una hipótesis; el control de verosimilitudes iguales conserva la distribución previa. Ningún resultado demuestra la hipótesis favorecida. Identidad de la observación, adecuación del modelo y ausencia de doble conteo necesitan comprobaciones separadas. No se ejecuta ningún servicio real de creencias.

## Fuentes y alcance del proyecto

[Prerrequisito: inf-013-value-an-evidence-probe-by-expected-information](../../information-theory/inf-013-value-an-evidence-probe-by-expected-information/)

[Prerrequisito: inf-003-verdict-distribution-drift](../../information-theory/inf-003-verdict-distribution-drift/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://www.cs.cornell.edu/courses/cs2800/2016fa/lectures/lec17-prob.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "prior": [
      "1/2",
      "1/2"
    ],
    "likelihood": [
      "4/5",
      "1/5"
    ]
  },
  "formula": "Products prior[i]*likelihood[i] give unnormalized mass; normalizer=sum(products)>0; posterior=products/normalizer; total_variation=sum(abs(posterior[i]-prior[i]))/2. All arithmetic is exact rational.",
  "expected": {
    "unnormalized": [
      "2/5",
      "1/10"
    ],
    "normalizer": "1/2",
    "posterior": [
      "4/5",
      "1/5"
    ],
    "total_variation": "3/10"
  },
  "negative_control": {
    "values": {
      "prior": [
        "1/2",
        "1/2"
      ],
      "likelihood": [
        "2/5",
        "2/5"
      ]
    },
    "expected": {
      "unnormalized": [
        "1/5",
        "1/5"
      ],
      "normalizer": "2/5",
      "posterior": [
        "1/2",
        "1/2"
      ],
      "total_variation": "0"
    },
    "why": "An equally predicted observation is not discriminating evidence."
  },
  "input_types": {
    "prior": "nonnegative rational strings summing to one",
    "likelihood": "same-length rational strings in closed unit interval with positive marginal"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No real likelihood calibration, causal claim, posterior truth guarantee or production belief update is observed."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Escribir la tabla ponderada por verosimilitud, normalizar y calcular diferencias absolutas.

**Criterio de refutación:** La actualización modifica masas iguales bajo verosimilitudes iguales sin otro supuesto.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Normalice los productos fijos.

> **Respuesta:** Los productos son `[2/5,1/10]`, el normalizador `1/2` y la posterior `[4/5,1/5]`.

### Ejercicio 2

Calcule el cambio y el control.

> **Respuesta:** La variación total fija es `3/10`. Verosimilitudes iguales dan `[1/2,1/2]` y cambio `0`.

### Ejercicio 3

¿Hay que normalizar primero las verosimilitudes entre hipótesis?

> **Respuesta:** No. Condicionan la misma observación a hipótesis distintas. Normalice los productos ponderados por la previa y conserve el modelo de verosimilitud.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Los productos son `[2/5,1/10]`, el normalizador `1/2` y la posterior `[4/5,1/5]`.
- Ejercicio 2: La variación total fija es `3/10`. Verosimilitudes iguales dan `[1/2,1/2]` y cambio `0`.
- Ejercicio 3: No. Condicionan la misma observación a hipótesis distintas. Normalice los productos ponderados por la previa y conserve el modelo de verosimilitud.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
