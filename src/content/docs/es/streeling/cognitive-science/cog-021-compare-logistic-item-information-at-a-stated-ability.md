---
title: Comparar la información de ítems logísticos a una habilidad dada
description: Comparar la información de ítems logísticos a una habilidad dada — Ciencia cognitiva
sidebar:
  label: COG-021 · Comparar la información de ítems logísticos a una habilidad dada
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-021-compare-logistic-item-information-at-a-stated-ability.es.md
---

:::note[Streeling University]
**COG-021** · Comparar la información de ítems logísticos a una habilidad dada · intermedio · 45 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-021-compare-logistic-item-information-at-a-stated-ability.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-020](../../cognitive-science/cog-020-screen-an-item-using-the-rest-score/)
:::

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un diseñador de práctica de GA quiere comparar preguntas de altura antes de recoger respuestas. La proporción de aciertos no indica dónde un ítem distingue habilidades cercanas. El modelo logístico explicita esa dependencia: la dificultad desplaza la curva en el eje de habilidad y la discriminación modifica su pendiente. Aquí son supuestos, no propiedades estimadas de un ejercicio real.

Para una respuesta de Bernoulli, se deriva la log-verosimilitud respecto a la habilidad. La esperanza del cuadrado de esa derivada produce la discriminación al cuadrado por las probabilidades de acierto y error. La información es local y depende del modelo elegido. No es la entropía de un mensaje, una medida de exactitud ni evidencia de dominio del contenido.

Calcule las probabilidades y la información de ambos candidatos en cada nivel declarado. Una discriminación mayor no garantiza una ventaja cuando la dificultad queda lejos de la habilidad. El control desplaza esta última y cambia el orden. Se trata de comparar modelos antes de seleccionar preguntas, no de un tutor adaptativo implementado. La incertidumbre de los parámetros, las habilidades múltiples y las respuestas por azar exigirían otro análisis.

## Fuentes y alcance del proyecto

[Prerrequisito: cog-020-screen-an-item-using-the-rest-score](../../cognitive-science/cog-020-screen-an-item-using-the-rest-score/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://quantdev.ssri.psu.edu/sites/qdev/files/IRT_tutorial_FA17_2.html)

[Lectura primaria](https://www.publichealth.columbia.edu/research/population-health-methods/item-response-theory)

## Modelo fijo y control negativo

```json
{
  "values": {
    "theta": 0,
    "items": [
      [
        1,
        0
      ],
      [
        2,
        1
      ]
    ],
    "round_digits": 12
  },
  "formula": "For each [a,b], P=1/(1+exp(-a*(theta-b))); I=a*a*P*(1-P). Round only displayed probabilities/information to round_digits; choose largest unrounded I, retaining ties.",
  "expected": {
    "probabilities": [
      0.5,
      0.119202922022
    ],
    "information": [
      0.25,
      0.419974341614
    ],
    "best_indices": [
      1
    ]
  },
  "negative_control": {
    "values": {
      "theta": -1,
      "items": [
        [
          1,
          0
        ],
        [
          2,
          1
        ]
      ],
      "round_digits": 12
    },
    "expected": {
      "probabilities": [
        0.26894142137,
        0.017986209962
      ],
      "information": [
        0.196611933241,
        0.070650824853
      ],
      "best_indices": [
        0
      ]
    },
    "why": "Moving ability changes which item is locally informative."
  },
  "input_types": {
    "theta": "finite real ability",
    "items": "ordered [positive discrimination a, finite difficulty b] pairs",
    "round_digits": "nonnegative integer"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No real learner ability, fitted item parameters, guessing model or adaptive tutoring result is observed."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Calcular a mano probabilidades e información antes de comparar ítems.

**Criterio de refutación:** Se reutiliza el orden tras cambiar la habilidad sin recalcular.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

¿Qué ítem aporta más información en el caso fijo?

> **Respuesta:** Gana el índice `1`: la información es `0.419974341614`, frente a `0.25`. Su probabilidad de acierto es menor; información y facilidad son distintas.

### Ejercicio 2

Aplique el control de habilidad.

> **Respuesta:** Con `theta=-1`, gana el índice `0` con `0.196611933241`, frente a `0.070650824853`. El orden es condicional.

### Ejercicio 3

¿El cálculo estima la habilidad?

> **Respuesta:** No. La habilidad y los parámetros son entradas estipuladas. Estimarlos requiere respuestas y un modelo de medición justificado.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Gana el índice `1`: la información es `0.419974341614`, frente a `0.25`. Su probabilidad de acierto es menor; información y facilidad son distintas.
- Ejercicio 2: Con `theta=-1`, gana el índice `0` con `0.196611933241`, frente a `0.070650824853`. El orden es condicional.
- Ejercicio 3: No. La habilidad y los parámetros son entradas estipuladas. Estimarlos requiere respuestas y un modelo de medición justificado.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
