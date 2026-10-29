---
title: Valorar una prueba de evidencia por su información esperada
description: Valorar una prueba de evidencia por su información esperada — Teoría de la información
sidebar:
  label: INF-013 · Valorar una prueba de evidencia por su información esperada
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/es/inf-013-value-an-evidence-probe-by-expected-information.es.md
---

:::note[Streeling University]
**INF-013** · Valorar una prueba de evidencia por su información esperada · intermedio · 45 minutos

Generado por el departamento *Teoría de la información* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/es/inf-013-value-an-evidence-probe-by-expected-information.es.md) · [Mi diario](../../journal/)

Requisitos previos: [INF-001](../../information-theory/inf-001-entropy-of-governance/), [COG-008](../../cognitive-science/cog-008-choose-probes-that-distinguish-reasoning-models/)
:::

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Varias explicaciones encajan con un handoff fallido. Un compañero propone otra prueba porque produce un informe detallado. El detalle solo ayuda si el resultado distingue las explicaciones relevantes. El prerrequisito busca respuestas separadoras; esta lección calcula la incertidumbre esperada después de una partición declarada de hipótesis. Explicita probabilidades en vez de considerar más informativo el informe más largo.

La distribución previa asigna igual probabilidad a alternativas construidas. Una prueba determinista agrupa hipótesis según el resultado que predicen. Renormalice las probabilidades originales dentro de cada grupo antes de calcular entropía. Promedie después usando las probabilidades de los resultados. La esperanza se forma antes de observar la prueba. No describe un informe medido ni justifica cambiar la distribución tras una conversación no registrada.

La definición original de [Shannon](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf) aporta la medida logarítmica. La base elegida produce bits y las alternativas equiprobables permiten comprobar contando. La partición equilibrada deja el mismo número de alternativas tras cada resultado. El control constante las conserva todas. Así, repetir un resumen sin observación discriminante puede añadir palabras sin añadir información bajo este modelo.

El registro conservado rechaza contar una relectura como otro ensayo y advierte que los resultados históricos no calibran una distribución construida. Una etapa componible podría incluir hipótesis, verosimilitudes e identidad del resultado; su utilidad para revisar sigue como hipótesis de dogfooding. La referencia directa es una partición y tabla manuscritas. El aumento de información no decide por sí solo la mejor acción: coste de la prueba y consecuencias de errores requieren otro modelo.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: inf-001-entropy-of-governance](../../information-theory/inf-001-entropy-of-governance/)

[Prerrequisito: cog-008-choose-probes-that-distinguish-reasoning-models](../../cognitive-science/cog-008-choose-probes-that-distinguish-reasoning-models/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lectura primaria: Shannon 1948 corrected reprint, section 6](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf)

## Modelo fijado y control

```json
{
  "values": {
    "hypotheses": [
      "a",
      "b",
      "c",
      "d"
    ],
    "probabilities": [
      0.25,
      0.25,
      0.25,
      0.25
    ],
    "probe_outcomes": [
      "left",
      "left",
      "right",
      "right"
    ]
  },
  "formula": "H=-sum(p*log2(p)); expected posterior entropy=sum(P(outcome)*H(hypothesis|outcome)); information gain=prior entropy-expected posterior entropy.",
  "expected": {
    "prior_bits": 2,
    "expected_posterior_bits": 1,
    "information_gain_bits": 1,
    "outcome_probabilities": {
      "left": 0.5,
      "right": 0.5
    }
  },
  "negative_control": {
    "values": {
      "hypotheses": [
        "a",
        "b",
        "c",
        "d"
      ],
      "probabilities": [
        0.25,
        0.25,
        0.25,
        0.25
      ],
      "probe_outcomes": [
        "same",
        "same",
        "same",
        "same"
      ]
    },
    "expected": {
      "prior_bits": 2,
      "expected_posterior_bits": 2,
      "information_gain_bits": 0,
      "outcome_probabilities": {
        "same": 1
      }
    },
    "why": "An outcome shared by all hypotheses cannot reduce uncertainty."
  },
  "assumptions": [
    "Prior probabilities are authored and sum to unity.",
    "Each hypothesis deterministically predicts one error-free probe outcome."
  ],
  "limits": "Bits quantify this model uncertainty, not task utility, truth, time savings or observed experimental evidence."
}
```

### Ejercicio 1

Calcule la entropía previa de las alternativas construidas.

<details><summary>Respuesta 1</summary>

Es `2` bits. Cada alternativa tiene probabilidad `0.25` y la entropía es `log2(4)`. Es incertidumbre dentro del modelo estipulado, sin medir fallos reales de agentes.

</details>

### Ejercicio 2

Calcule probabilidades de resultados y entropía posterior esperada.

<details><summary>Respuesta 2</summary>

Los resultados `left` y `right` tienen probabilidad `0.5` cada uno. Cada cual deja dos alternativas equiprobables con entropía `1` bit; la entropía esperada es `1` bit.

</details>

### Ejercicio 3

¿Cuál es la ganancia principal y cuándo se define esa esperanza?

<details><summary>Respuesta 3</summary>

Es `2-1=1` bit, antes de observar el resultado. Un resultado real elegiría un grupo posterior concreto; deben conservarse su probabilidad e identidad, sin sustituirlas por la esperanza.

</details>

### Ejercicio 4

Aplique el control constante y explique el resultado.

<details><summary>Respuesta 4</summary>

El único resultado tiene probabilidad `1`, la entropía sigue en `2` bits y la ganancia es `0`. La prueba no distingue hipótesis aunque emita un mensaje.

</details>

### Ejercicio 5

¿La prueba más informativa produce necesariamente la mejor decisión?

<details><summary>Respuesta 5</summary>

No. Importan coste, consecuencias, errores del modelo y ruido. Aquí no se proporcionan esas cantidades. Conserve la partición manual y rechace que la ganancia inventada demuestre una investigación real exitosa.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
