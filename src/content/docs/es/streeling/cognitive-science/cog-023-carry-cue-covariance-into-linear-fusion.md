---
title: Incorporar la covarianza de las señales a su fusión lineal
description: Incorporar la covarianza de las señales a su fusión lineal — Ciencia cognitiva
sidebar:
  label: COG-023 · Incorporar la covarianza de las señales a su fusión lineal
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-023-carry-cue-covariance-into-linear-fusion.es.md
---

:::note[Streeling University]
**COG-023** · Incorporar la covarianza de las señales a su fusión lineal · intermedio · 45 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-023-carry-cue-covariance-into-linear-fusion.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-005](../../cognitive-science/cog-005-separate-pitch-estimates-from-listener-reports/), [CYB-015](../../cybernetics/cyb-015-carry-covariance-through-smoothed-telemetry/)
:::

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Una interfaz de guitarra puede mostrar una estimación de altura y una señal visual obtenidas en parte de la misma grabación. Suponer independencia puede exagerar la ganancia de precisión al combinarlas. Aquí ambas estiman sin sesgo la misma magnitud escalar. Sus varianzas y covarianza se estipulan para examinar la decisión antes de recoger datos perceptivos.

Escriba la estimación fusionada como una suma cuyos pesos suman la unidad. Al desarrollar su varianza aparece un término de covarianza. Derive el polinomio respecto al primer peso para hallar el mínimo sin exigir pesos positivos. Una covarianza positiva puede producir un peso negativo: la señal más ruidosa ayuda entonces a restar error compartido. Esto no justifica desplegar esos pesos sin comprobar sesgos y estimaciones de covarianza.

La matriz fija es definida positiva. El control elimina los términos fuera de la diagonal y recupera pesos de varianza inversa. Reutilizarlos en el caso correlacionado produce una varianza real peor. Compare también con la señal individual más precisa. El resumen perceptivo citado motiva elegir bien el comparador; la optimización con covarianza se deriva aquí, sin atribuirle una ecuación no leída del artículo.

## Fuentes y alcance del proyecto

[Prerrequisito: cog-005-separate-pitch-estimates-from-listener-reports](../../cognitive-science/cog-005-separate-pitch-estimates-from-listener-reports/)

[Prerrequisito: cyb-015-carry-covariance-through-smoothed-telemetry](../../cybernetics/cyb-015-carry-covariance-through-smoothed-telemetry/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://pubmed.ncbi.nlm.nih.gov/37730934/)

## Modelo fijo y control negativo

```json
{
  "values": {
    "estimates": [
      10,
      14
    ],
    "variances": [
      1,
      4
    ],
    "covariance": 1.5
  },
  "formula": "For unbiased estimates, w1=(v2-c)/(v1+v2-2*c), w2=1-w1; fused=w1*x1+w2*x2; variance=w1*w1*v1+w2*w2*v2+2*w1*w2*c. Weights are unconstrained real numbers summing to one.",
  "expected": {
    "weights": [
      1.25,
      -0.25
    ],
    "fused": 9,
    "variance": 0.875,
    "independence_weight_variance": 1.28
  },
  "negative_control": {
    "values": {
      "estimates": [
        10,
        14
      ],
      "variances": [
        1,
        4
      ],
      "covariance": 0
    },
    "expected": {
      "weights": [
        0.8,
        0.2
      ],
      "fused": 10.8,
      "variance": 0.8,
      "independence_weight_variance": 0.8
    },
    "why": "Covariance changes the optimum; inverse-variance weights assume independence."
  },
  "input_types": {
    "estimates": "two finite unbiased scalar estimates",
    "variances": "two positive marginal variances",
    "covariance": "finite covariance giving a positive-definite covariance matrix"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No perceptual fusion, actual detector variance, unbiasedness test or deployed interface gain is measured."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Desarrollar la varianza del error fusionado y derivar el polinomio.

**Criterio de refutación:** La ganancia de precisión anunciada omite la covarianza.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Halle los pesos del caso correlacionado.

> **Respuesta:** Los pesos `[1.25,-0.25]` suman `1`; la estimación vale `9` y la varianza `0.875`. El modelo permite un peso negativo.

### Ejercicio 2

Aplique el control de independencia.

> **Respuesta:** Con covarianza `0`, los pesos son `[0.8,0.2]`, la estimación `10.8` y la varianza `0.8`. Esos pesos dan `1.28` bajo la covarianza original.

### Ejercicio 3

¿Un peso negativo demuestra que la entrada es inválida?

> **Respuesta:** No. La matriz es definida positiva y los pesos no están restringidos. Exigir pesos no negativos definiría otro problema.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Los pesos `[1.25,-0.25]` suman `1`; la estimación vale `9` y la varianza `0.875`. El modelo permite un peso negativo.
- Ejercicio 2: Con covarianza `0`, los pesos son `[0.8,0.2]`, la estimación `10.8` y la varianza `0.8`. Esos pesos dan `1.28` bajo la covarianza original.
- Ejercicio 3: No. La matriz es definida positiva y los pesos no están restringidos. Exigir pesos no negativos definiría otro problema.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
